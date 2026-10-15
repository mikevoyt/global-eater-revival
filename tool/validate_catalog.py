#!/usr/bin/env python3
"""Offline structural/content-integrity checks. These do not certify food facts."""
from __future__ import annotations
import collections, json, re, sys, unicodedata
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def normalize(value: str) -> str:
    value=value.lower().translate(str.maketrans({'ß':'ss','æ':'ae','œ':'oe','đ':'d','ı':'i','ł':'l'}))
    value=''.join(c for c in unicodedata.normalize('NFKD',value) if not unicodedata.combining(c))
    return re.sub(r'\s+', ' ', re.sub(r'''[.,/()'’\-_:;!?"“”]+''',' ',value)).strip()

def main() -> None:
    foods=json.loads((ROOT/'assets/data/foods.json').read_text())
    cuisines=json.loads((ROOT/'assets/data/cuisines.json').read_text())
    meta=json.loads((ROOT/'assets/data/metadata.json').read_text())
    raw=json.loads((ROOT/'archive/legacy_rows.json').read_text())
    ids=[f['id'] for f in foods]
    assert len(ids)==len(set(ids)), 'Duplicate IDs'
    cids={c['id'] for c in cuisines}
    assert len(cids)==len(cuisines), 'Duplicate cuisine IDs'
    assert all(f['cuisineId'] in cids for f in foods), 'Unknown cuisine'
    assert all(f['name'].strip() and (f['summary'].strip() or f['description'].strip()) for f in foods), 'Empty entry'
    assert all(isinstance(f['aliases'],list) and all(isinstance(a,str) for a in f['aliases']) for f in foods)
    legacy=[f for f in foods if f['provenance']=='legacy']
    additions=[f for f in foods if f['provenance']=='expansion']
    assert len(legacy)==len(raw)==1815
    assert len(additions)==meta['expansionEntries'] and len(additions)>=180
    assert meta['totalEntries']==len(foods)==len(legacy)+len(additions)
    assert meta['cuisineCount']==sum(not c['isReference'] for c in cuisines) and meta['cuisineCount']>=20
    assert meta['referenceSectionCount']==sum(c['isReference'] for c in cuisines)==2
    counts=collections.Counter(f['cuisineId'] for f in foods)
    assert all(c['count']==counts[c['id']] for c in cuisines)
    assert all(counts[c['id']]>=15 for c in cuisines)
    assert all(f['reviewStatus']=='draft' for f in additions)
    assert all(f['reviewStatus']=='needs-review' for f in legacy)
    assert all('\ufffd' not in f['name']+f['summary']+f['description'] for f in foods), 'Replacement-character corruption'
    assert normalize('Phở')=='pho'
    assert normalize('Bún bò Huế')=='bun bo hue'
    assert normalize('Pão de queijo')=='pao de queijo'
    assert normalize('Käsespätzle')=='kasespatzle'
    assert normalize('叉烧')=='叉烧'
    for query, expected in [('pho','v2-vietnamese-pho'),('mapo tofu','legacy-0090'),('soup dumplings','legacy-0113'),('dan tat','legacy-0027')]:
        f=next(f for f in foods if f['id']==expected)
        body=normalize(' '.join([f['name'],*f['aliases'],f['summary'],f['description']]))
        assert all(t in body for t in normalize(query).split()), (query,expected)
    groups=collections.defaultdict(list)
    for f in legacy:
        groups[(f['cuisineId'],normalize(f['name']))].append(f['id'])
    duplicates=[{'cuisineId':k[0],'normalizedName':k[1],'ids':v} for k,v in groups.items() if len(v)>1]
    report={**meta, 'checks':'passed', 'checksScope':'Catalog structure, identity, Unicode, representative search normalization; not Flutter compilation or culinary review.',
            'legacyDuplicateNameGroups':duplicates, 'counts':dict(sorted(counts.items()))}
    (ROOT/'docs/catalog-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(f"PASS: {len(foods)} entries; {len(legacy)} legacy + {len(additions)} draft additions; {meta['cuisineCount']} cuisines + {meta['referenceSectionCount']} references.")
    print(f"PASS: stable IDs, completeness, counts, Unicode and representative alias checks.")
    print(f"NOTE: {len(duplicates)} legacy duplicate-name groups intentionally retained for review.")

if __name__=='__main__':
    try: main()
    except (AssertionError, ValueError, KeyError, TypeError) as error:
        print('CATALOG VALIDATION FAILED:',error,file=sys.stderr);sys.exit(1)
