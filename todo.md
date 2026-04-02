# taxify — Next Session TODO

## Status

M1 (WFO backend), M2 (COL backend), M3 (GBIF backend), and multi-backend fallback chain are complete. 278 tests passing, R CMD check clean. Not yet pushed to GitHub.

## What's Done

- [x] Package scaffold (DESCRIPTION, NAMESPACE, R/, tests/)
- [x] Name cleaning pipeline (authorship, qualifiers, brackets, whitespace, encoding)
- [x] Hybrid detection (nothogenus, nothospecies, formula; `x` and `×`)
- [x] S3 backend interface (generics in `backend.R`, `resolve_backend()`)
- [x] WFO backend (download from Zenodo, TSV → .vtr, match_exact, match_fuzzy, resolve_synonyms)
- [x] COL backend (download from ChecklistBank, namespace-prefixed headers, canonicalName from scientificName, SpeciesProfile.tsv)
- [x] GBIF backend (download simple.txt.gz, positional columns, family_key denormalization, parent_key synonym resolution)
- [x] `taxify()` main function (exact → fuzzy → synonym resolution → 16-col output)
- [x] Multi-backend fallback chain (`backend = c("wfo", "col", "gbif")`)
- [x] Pipe extensions: `add_hybrid_info()`, `add_wfo_info()`, `add_col_info()`, `add_gbif_info()`, `add_qualifier_info()`
- [x] Best-match selection (`pick_best()`: ACCEPTED > SYNONYM, SPECIES > higher, smallest ID)
- [x] Backbone caching (path-based, vectra nodes are single-use)
- [x] README, CLAUDE.md
- [x] Git repo initialized, initial commit
- [x] `backbone_version` output column (16th col, format: `"wfo:2024-12 (2026-04-01)"`)
- [x] `.meta` sidecar files (download date, URL, row count written alongside `.vtr`)
- [x] Simplified API: removed `version` parameter, `taxify_download()` always re-downloads latest
- [x] Download progress: size estimates in messages, `download.file()` progress bar
- [x] Simplified filenames: `wfo.vtr`, `col.vtr`, `gbif.vtr` (no version suffix)

## What's Next

### 1. End-to-End Testing with Real Backbones
- Download actual WFO, COL, GBIF backbones
- Test against ASAAS edge cases (the pain points from `plan.md`)
- Verify encoding resilience (Latin-1 author names)
- Benchmark: 1000 names, 10000 names

### 2. Push to GitHub
- Only after end-to-end testing passes
- Create remote: `gh repo create gcol33/taxify --private --source=.`
- Push with SSH key

### 3. Polish (post-push)
- Vignette (`vignettes/taxify.Rmd`)
- pkgdown site (`_pkgdown.yml`, Bootstrap 5, light-switch)
- GitHub Actions (R-CMD-check workflow)
- ASAAS edge case test suite

### 4. Future Extensions
- `add_lifeform_info()` — tree/shrub/herb from external trait database (TRY, GIFT, BIEN)

## Architecture Notes for Next Session

- vectra nodes are single-use (consumed on `collect()`). Cache stores `.vtr` paths, not nodes.
- vectra now has data masking: local R variables resolve automatically in `filter()`/`mutate()`. No `eval(substitute())` needed.
- `utils::head()` not `vectra::head()` (head is S3 method, not exported).
- vectra's `tbl_csv()` is comma-only. TSV files need `read.delim()` → `write_vtr()` conversion.
- COL DwCA is a single Taxon.tsv (not split files) with namespace-prefixed headers. `scientificName` includes authorship — `canonicalName` computed during conversion.
- GBIF simple.txt.gz has no header row (30 positional columns), `\N` for NULLs, family as FK only (denormalized during conversion), synonyms via `parent_key`.
- `taxify_download()` always re-downloads (no skip-if-exists). `taxify()` auto-downloads on first use only.
- `.meta` sidecar files store download provenance; `backbone_version` column reads from them.
- No `version` parameter anywhere — each backend has one hardcoded URL for the latest release, updated with package releases.
