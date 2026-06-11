#!/usr/bin/env python3
"""
Career Guess - Career Grid answer-set builder

Purpose:
- Builds safe answer sets for the football tic-tac-toe/grid mode.
- Uses ONLY core database facts and verified fields.
- Does NOT use hints/candidate trophies as playable validation facts.

Run from project root:
  python tools\build_grid_answer_sets.py
"""
import argparse
import json
import os
import re
import unicodedata
from collections import defaultdict, Counter
from itertools import combinations

DEFAULT_PLAYERS_PATH = os.path.join('assets', 'data', 'players.json')
DEFAULT_RULES_PATH = os.path.join('assets', 'data', 'grid_category_rules.json')
DEFAULT_OUTPUT_DIR = os.path.join('assets', 'data', 'working')


def normalize_text(value: str) -> str:
    value = value or ''
    value = unicodedata.normalize('NFKD', value)
    value = ''.join(ch for ch in value if not unicodedata.combining(ch))
    value = value.lower().strip()
    value = value.replace('&', ' and ')
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def slugify(value: str) -> str:
    n = normalize_text(value)
    return n.replace(' ', '_') or 'unknown'


def position_groups(position: str):
    p = normalize_text(position)
    groups = set()
    if any(k in p for k in ['goalkeeper', 'keeper']):
        groups.add('Goalkeeper')
    if any(k in p for k in ['centre back', 'center back', 'right back', 'left back', 'full back', 'defender', 'back']):
        groups.add('Defender')
    if any(k in p for k in ['midfielder', 'midfield', 'dm', 'cm', 'am']):
        groups.add('Midfielder')
    if any(k in p for k in ['striker', 'forward', 'winger', 'attacker']):
        groups.add('Forward')
    return sorted(groups)


def person_aliases(player):
    names = set()
    for key in ['name', 'id']:
        if player.get(key):
            names.add(player[key])
    for a in player.get('acceptedAnswers') or []:
        names.add(a)
    return sorted({normalize_text(x) for x in names if normalize_text(x)})


def is_verified_item(item):
    if isinstance(item, str):
        # String honours/awards in older data are not automatically verified.
        return False
    if not isinstance(item, dict):
        return False
    return item.get('verified') is True or item.get('sourceType') == 'verified'


def item_id(item):
    if isinstance(item, str):
        return item
    if isinstance(item, dict):
        return item.get('id') or item.get('tag') or item.get('name')
    return None


def add_category(category_map, category_meta, cat_type, label, player_id):
    if not label:
        return
    cat_id = f"{cat_type}:{slugify(label)}"
    category_map[cat_id].add(player_id)
    if cat_id not in category_meta:
        category_meta[cat_id] = {
            'id': cat_id,
            'type': cat_type,
            'label': label,
            'trustLevel': 'core' if cat_type in ['nationality', 'club', 'position_group'] else 'verified',
        }


def build(players, rules):
    players_by_id = {}
    aliases_to_ids = defaultdict(set)
    category_map = defaultdict(set)
    category_meta = {}
    duplicates_by_normalized_name = defaultdict(list)

    for i, p in enumerate(players):
        pid = p.get('id') or f"player_{i}"
        players_by_id[pid] = {
            'id': pid,
            'name': p.get('name', pid),
            'nationality': p.get('nationality'),
            'status': p.get('status'),
            'difficulty': p.get('difficulty'),
            'difficultyV2': p.get('difficultyV2'),
            'position': p.get('position'),
            'aliases': person_aliases(p),
        }
        for alias in players_by_id[pid]['aliases']:
            aliases_to_ids[alias].add(pid)
        duplicates_by_normalized_name[normalize_text(p.get('name', pid))].append(pid)

        # Core safe categories from current database.
        add_category(category_map, category_meta, 'nationality', p.get('nationality'), pid)
        for club in p.get('clubs') or []:
            if isinstance(club, dict):
                add_category(category_map, category_meta, 'club', club.get('name'), pid)
            elif isinstance(club, str):
                add_category(category_map, category_meta, 'club', club, pid)
        for group in position_groups(p.get('position', '')):
            add_category(category_map, category_meta, 'position_group', group, pid)

        # Verified-only categories.
        for tag in p.get('verifiedGridTags') or []:
            add_category(category_map, category_meta, 'verified_grid_tag', str(tag), pid)

        for h in p.get('honours') or []:
            if is_verified_item(h):
                hid = item_id(h)
                add_category(category_map, category_meta, 'verified_honour', hid, pid)

        for a in p.get('awards') or []:
            if is_verified_item(a):
                aid = item_id(a)
                add_category(category_map, category_meta, 'verified_award', aid, pid)

    categories = []
    for cid, ids in category_map.items():
        meta = dict(category_meta[cid])
        meta['count'] = len(ids)
        meta['playerIds'] = sorted(ids)
        categories.append(meta)
    categories.sort(key=lambda x: (-x['count'], x['type'], x['label']))

    allowed_axis_types = set(rules.get('axisTypesAllowed', []))
    axis_categories = [c for c in categories if c['type'] in allowed_axis_types]

    viable_pairs = []
    min_threshold = min(v['minAnswersPerCell'] for v in rules.get('difficultyThresholds', {}).values())
    for a, b in combinations(axis_categories, 2):
        # Nationality + nationality and same position group + same position group make no gameplay sense.
        if a['type'] == b['type'] and a['type'] in ['nationality', 'position_group']:
            continue
        inter = sorted(set(a['playerIds']).intersection(b['playerIds']))
        if len(inter) >= min_threshold:
            viable_pairs.append({
                'rowCategoryId': a['id'],
                'rowLabel': a['label'],
                'rowType': a['type'],
                'colCategoryId': b['id'],
                'colLabel': b['label'],
                'colType': b['type'],
                'answerCount': len(inter),
                'sampleAnswers': [players_by_id[x]['name'] for x in inter[:12]],
                'answerIds': inter,
            })

    viable_pairs.sort(key=lambda x: (-x['answerCount'], x['rowType'], x['rowLabel'], x['colType'], x['colLabel']))

    thresholds = rules.get('difficultyThresholds', {})
    pair_counts_by_difficulty = {}
    for diff, cfg in thresholds.items():
        mn = cfg['minAnswersPerCell']
        pair_counts_by_difficulty[diff] = sum(1 for p in viable_pairs if p['answerCount'] >= mn)

    duplicate_names = {k: v for k, v in duplicates_by_normalized_name.items() if len(v) > 1}

    report = {
        'playerCount': len(players),
        'categoryCount': len(categories),
        'axisCategoryCount': len(axis_categories),
        'viablePairCountAtLegendMinimum': len(viable_pairs),
        'viablePairCountsByDifficulty': pair_counts_by_difficulty,
        'categoryCountsByType': dict(Counter(c['type'] for c in categories)),
        'topCategories': [{k: c[k] for k in ['id', 'type', 'label', 'count']} for c in categories[:80]],
        'weakButUsefulCategories': [
            {k: c[k] for k in ['id', 'type', 'label', 'count']}
            for c in categories if c['type'] in allowed_axis_types and 1 <= c['count'] < 3
        ][:100],
        'duplicateNameGroupsCount': len(duplicate_names),
        'duplicateNameGroupsSample': {k: v for k, v in list(duplicate_names.items())[:50]},
        'blockedFactSources': rules.get('blockedFactSourcesForGrid', []),
        'safeFactSourcesForGrid': rules.get('safeFactSourcesForGrid', []),
    }

    answer_sets_preview = {
        'playersById': players_by_id,
        'categories': categories,
        'categoryIndex': {c['id']: c['playerIds'] for c in categories},
        'aliasIndex': {alias: sorted(ids) for alias, ids in aliases_to_ids.items()},
    }

    pair_preview = {
        'note': 'Only pairs with at least the lowest configured threshold are included. For the actual app, generate boards from pairs where every cell meets the selected difficulty threshold.',
        'pairCountsByDifficulty': pair_counts_by_difficulty,
        'viablePairs': viable_pairs[:2000],
    }

    return report, answer_sets_preview, pair_preview


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--players', default=DEFAULT_PLAYERS_PATH)
    parser.add_argument('--rules', default=DEFAULT_RULES_PATH)
    parser.add_argument('--out', default=DEFAULT_OUTPUT_DIR)
    args = parser.parse_args()

    if not os.path.exists(args.players):
        raise SystemExit(f'Could not find players file: {args.players}')
    if not os.path.exists(args.rules):
        raise SystemExit(f'Could not find rules file: {args.rules}')

    os.makedirs(args.out, exist_ok=True)
    with open(args.players, 'r', encoding='utf-8') as f:
        players = json.load(f)
    with open(args.rules, 'r', encoding='utf-8') as f:
        rules = json.load(f)

    report, answer_sets, pair_preview = build(players, rules)

    outputs = {
        'grid_coverage_report.json': report,
        'grid_answer_sets_preview.json': answer_sets,
        'grid_pair_answer_sets_preview.json': pair_preview,
    }
    for filename, payload in outputs.items():
        path = os.path.join(args.out, filename)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)

    print('Career Grid answer-set build complete.')
    print(f"Players: {report['playerCount']}")
    print(f"Categories: {report['categoryCount']}")
    print(f"Axis categories: {report['axisCategoryCount']}")
    print(f"Viable pairs by difficulty: {report['viablePairCountsByDifficulty']}")
    print(f"Duplicate name groups: {report['duplicateNameGroupsCount']}")
    print(f"Output folder: {args.out}")


if __name__ == '__main__':
    main()
