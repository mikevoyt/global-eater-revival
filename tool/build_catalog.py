#!/usr/bin/env python3
"""Build the offline catalog from the unchanged legacy rows plus editable additions."""
from __future__ import annotations
import collections, hashlib, json, re, unicodedata
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def clean(value):
    value = str(value or '').strip()
    return '' if value in ('-', 'nan', 'None') else re.sub(r'\s+', ' ', value)

def slug(value):
    value = unicodedata.normalize('NFKD', value).encode('ascii','ignore').decode().lower()
    return re.sub(r'[^a-z0-9]+', '-', value).strip('-')

# Add search aliases without rewriting the historical definitions.
ALIASES = {
    1: ['Peking duck', 'Beijing roast duck'], 9: ['char siu', 'Chinese barbecue pork'],
    10: ['char siu bao', 'BBQ pork buns'], 12: ['chao fan'],
    16: ['cheung fun'], 20: ['cong you bing', 'scallion pancake'],
    27: ['dan tat'], 30: ['tofu', 'doufu'], 48: ['har gow'],
    72: ['congee', 'jook'], 81: ['lo bak go', 'radish cake'],
    90: ['mapo tofu', 'ma po tofu'], 113: ['xiao long bao', 'xiaolongbao', 'soup dumplings'],
    124: ['siu mai', 'shumai'], 128: ['guo tie', 'potstickers'],
}
REGIONS = {
 'Chinese':('Asia','CN'),'Japanese':('Asia','JP'),'Indian':('Asia','IN'),
 'Thai':('Asia','TH'),'Vietnamese':('Asia','VN'),'Korean':('Asia','KR'),
 'Filipino':('Asia','PH'),'Indonesian':('Asia','ID'),
 'French':('Europe','FR'),'Italian':('Europe','IT'),'Spanish':('Europe','ES'),
 'Greek':('Europe','GR'),'German':('Europe','DE'),
 'Turkish':('West Asia','TR'),'Lebanese':('West Asia','LB'),
 'Ethiopian':('Africa','ET'),'Moroccan':('Africa','MA'),
 'Mexican':('Americas','MX'),'Peruvian':('Americas','PE'),'Brazilian':('Americas','BR'),
 'Global pantry':('Reference','+'),'Meat cuts':('Reference','+'),
}
legacy = json.loads((ROOT/'archive/legacy_rows.json').read_text())
foods = []
for row in legacy:
    original = clean(row['Menu Item Name'])
    cuisine = clean(row['Ethnicity'])
    cuisine = {'other':'Global pantry','Other':'Global pantry','Meats':'Meat cuts'}.get(cuisine,cuisine)
    original_key = int(float(row['Primary Key']))
    aliases = []
    name = original
    if cuisine == 'Chinese' and ',' in original:
        parts = [p.strip() for p in original.split(',') if p.strip()]
        name, aliases = parts[0], parts[1:] + [original]
    elif cuisine == 'Japanese':
        m = re.match(r'^(.+?)\s*([\u3040-\u30ff\u3400-\u9fff].*)$', original)
        if m:
            name, native = m.groups(); name = name.strip(); aliases = [native, original]
    aliases.extend(ALIASES.get(original_key, []))
    foods.append(dict(id=f'legacy-{original_key:04d}', cuisineId=slug(cuisine),
        name=name, aliases=list(dict.fromkeys(aliases)), summary=clean(row['Short Description']),
        description=clean(row['Detailed Description']), category=clean(row['Category']) or 'Food term',
        facts=clean(row['Interesting Facts']), provenance='legacy', reviewStatus='needs-review',
        originalName=original, sourceRow=row['_sheet_row'], sourceId='legacy-2010', referenceUrls=[]))

cuisine = ''
for line in (ROOT/'assets/data/additions.txt').read_text().splitlines():
    if not line or line.startswith('#'): continue
    if line.startswith('['): cuisine=line[1:-1]; continue
    parts = line.split('|')
    assert len(parts)==4, line
    name, aliases, summary, category = parts
    # Content-derived IDs stay stable when rows are inserted or reordered.
    foods.append(dict(id='v2-'+slug(cuisine)+'-'+slug(name), cuisineId=slug(cuisine),
        name=name, aliases=[a for a in aliases.split(';') if a], summary=summary,
        description='', category=category, facts='', provenance='expansion',
        reviewStatus='draft', originalName=name, sourceRow=None, sourceId='expansion-v01', referenceUrls=[]))

# These are pointers for selected independently researched entries, not a claim
# that the entire starter catalog has had an editorial or allergen review.
refs = {
 'vietnamese': ['https://vietnam.travel/node/195','https://vietnam.travel/node/1121'],
 'greek': ['https://www.visitgreece.gr/en/blog/travel-tips/the-athenian-odyssey-history-culture-and-cuisine'],
 'turkish': ['https://gastronomy.goturkiye.com/turkish-cuisine'],
}
ref_names = {
 'vietnamese': {'Phở','Bánh mì','Bún chả','Bún bò Huế','Bánh xèo','Gỏi cuốn','Cơm tấm','Cao lầu','Mì Quảng','Bánh cuốn','Bún riêu','Xôi','Chè','Cà phê sữa đá'},
 'greek': {'Moussaka','Spanakopita','Gyros','Loukoumades'},
 'turkish': {'Pide','Simit','Ayran'},
}
for f in foods:
    if f['name'] in ref_names.get(f['cuisineId'],set()):
        f['referenceUrls'] = refs[f['cuisineId']]
# Keep every recovered record. Potential duplicates are reported, not discarded.
counts=collections.Counter(f['cuisineId'] for f in foods)
cuisines=[dict(id=slug(k),name=k,region=v[0],badge=v[1],isReference=v[0]=='Reference',
              count=counts[slug(k)],isNew=slug(k) not in {f['cuisineId'] for f in foods if f['provenance']=='legacy'})
          for k,v in REGIONS.items()]
cuisines.sort(key=lambda c:(c['isReference'],c['name']))
meta=dict(schemaVersion=1,catalogVersion='0.1.0',legacyEntries=len(legacy),
          expansionEntries=len(foods)-len(legacy),totalEntries=len(foods),
          cuisineCount=sum(not c['isReference'] for c in cuisines),
          referenceSectionCount=sum(c['isReference'] for c in cuisines))
for name,obj in [('foods.json',foods),('cuisines.json',cuisines),('metadata.json',meta)]:
    (ROOT/'assets/data'/name).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(meta,indent=2))
assert len({f['id'] for f in foods}) == len(foods), 'Duplicate stable ID'
assert all(f['summary'] or f['description'] for f in foods), 'Missing definition'
