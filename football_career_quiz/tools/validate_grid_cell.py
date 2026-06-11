#!/usr/bin/env python3
"""
Validate a Career Grid answer against two category IDs.

Example:
  python tools\validate_grid_cell.py --row "nationality:argentina" --col "club:liverpool" --answer "mac allister"

Run build_grid_answer_sets.py first.
"""
import argparse
import json
import os
import re
import unicodedata

DEFAULT_ANSWER_SETS = os.path.join('assets', 'data', 'working', 'grid_answer_sets_preview.json')


def normalize_text(value: str) -> str:
    value = value or ''
    value = unicodedata.normalize('NFKD', value)
    value = ''.join(ch for ch in value if not unicodedata.combining(ch))
    value = value.lower().strip()
    value = value.replace('&', ' and ')
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--row', required=True, help='Row category ID, e.g. nationality:argentina')
    parser.add_argument('--col', required=True, help='Column category ID, e.g. club:liverpool')
    parser.add_argument('--answer', required=True, help='Typed player answer or selected suggestion text')
    parser.add_argument('--answer-sets', default=DEFAULT_ANSWER_SETS)
    args = parser.parse_args()

    if not os.path.exists(args.answer_sets):
        raise SystemExit('Answer sets not found. Run: python tools\\build_grid_answer_sets.py')

    with open(args.answer_sets, 'r', encoding='utf-8') as f:
        data = json.load(f)

    row_ids = set(data['categoryIndex'].get(args.row, []))
    col_ids = set(data['categoryIndex'].get(args.col, []))
    valid_ids = row_ids.intersection(col_ids)

    answer_norm = normalize_text(args.answer)
    matched_ids = set(data['aliasIndex'].get(answer_norm, []))
    final_matches = sorted(valid_ids.intersection(matched_ids))

    if final_matches:
        names = [data['playersById'][pid]['name'] for pid in final_matches]
        print('VALID')
        print('Matched:', ', '.join(names))
    else:
        possible = [data['playersById'][pid]['name'] for pid in sorted(valid_ids)[:20]]
        answer_exists = sorted(matched_ids)
        if answer_exists:
            print('INVALID_FOR_THIS_CELL')
            print('The answer exists in the database, but does not match both categories.')
        else:
            print('ANSWER_NOT_FOUND_IN_DATABASE')
            print('Use suggestions or report missing valid answer.')
        print(f'Known valid answers for this cell: {len(valid_ids)}')
        if possible:
            print('Sample valid answers:', ', '.join(possible))


if __name__ == '__main__':
    main()
