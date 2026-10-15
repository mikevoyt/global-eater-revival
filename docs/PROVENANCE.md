# Recovered source material

## Historical catalog

`archive/Global Eater V1B.xls` is the recovered historical catalog associated with the original app by Mike Voytovich and Harry Kwan. The binary importer recovered **1,815 rows**, including the original IDs, names, cuisine labels, definitions, category fields and notes. The archive is unchanged.

`archive/legacy_rows.json` is the complete raw conversion. `assets/data/foods.json` is a derived app catalog with normalized whitespace, stable IDs and selected search aliases. It preserves original naming in `originalName` and links to original spreadsheet rows through `sourceRow`. Original text is not treated as newly verified.

An independent extraction supplied the first 1,000 records. All seven text fields in those 1,000 records match the binary recovery. The remaining 815 records were read from the XLS, not extrapolated from the preview.

## Historical artwork

Elliot Ling created the original icon (57×57) and splash illustration (320×480) for the original iPhone app. The files in `assets/brand/` are exact copies. Native launcher resources in `platform_assets/` are resampled versions. No new visual design has been substituted for the original illustration.

## Source code

The historical native source was not used. All Flutter code in this project is a new implementation.

## Starter expansion

180 new draft entries are stored in `assets/data/additions.txt`: 15 each for 12 new cuisines. Selected further-reading links are recorded in `tool/build_catalog.py` and embedded in those catalog entries. Coverage is not comprehensive sourcing. All original entries are marked `needs-review`; all new entries are marked `draft`.

## Exact recovered-asset SHA-256

`archive/Global Eater V1B.xls`

```text
1e3515ea75665e042fc5ab3d882c183f79bfa7f5384a1d1c3e39ce5dc3f15b4a
```

`assets/brand/original_icon.png`

```text
899361fb5949f64cfc25046111161c1bb40dc723be3362e894656c0fdb2269bf
```

`assets/brand/original_splash.png`

```text
a978df631e4e0e59376411d71594a361dfb996eb0dafd61877a1ac6fa222d310
```


## Original source baseline

`SOURCE_SHA256.json` records the 74 files in the original revival source package, before native host generation and public-project documentation changes. It is retained as a historical baseline, not a checksum manifest of the current repository. The three recovered assets above remain unchanged.
