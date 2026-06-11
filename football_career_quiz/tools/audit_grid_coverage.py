#!/usr/bin/env python3
"""
Print a compact Career Grid coverage audit after building answer sets.
"""
import json
import os
import subprocess
import sys

REPORT = os.path.join('assets', 'data', 'working', 'grid_coverage_report.json')

if not os.path.exists(REPORT):
    subprocess.check_call([sys.executable, os.path.join('tools', 'build_grid_answer_sets.py')])

with open(REPORT, 'r', encoding='utf-8') as f:
    r = json.load(f)

print('\nCAREER GRID COVERAGE AUDIT')
print('==========================')
print('Players:', r['playerCount'])
print('Categories:', r['categoryCount'])
print('Axis categories:', r['axisCategoryCount'])
print('Viable pair counts by difficulty:')
for k, v in r['viablePairCountsByDifficulty'].items():
    print(f'  {k}: {v}')
print('Duplicate name groups:', r['duplicateNameGroupsCount'])
print('\nTop 20 categories:')
for c in r['topCategories'][:20]:
    print(f"  {c['id']} -> {c['count']}")
print('\nBlocked facts for gameplay:')
for x in r['blockedFactSources']:
    print('  -', x)
