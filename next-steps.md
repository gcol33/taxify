# taxify — Next Steps

## 1. Push to GitHub

- Push taxify: `gh repo create gcol33/taxify --private --source=.`
- Push vectra changes (resolve, propagate, v4 compression, ifelse fixes)
- Verify R CMD check clean on both

## 2. Precomputed Backbones on Zenodo

### Architecture

```
Scheduled CI (every 6-12 months)
  → fetch raw data (API or bulk download per source)
  → normalize to Darwin Core schema
  → convert to compressed .vtr (v4: dict + RLE + LZ)
  → upload to Zenodo (one DOI per release)
```

`taxify_download()` fetches precomputed .vtr from Zenodo. Zero conversion on user machines.

### File layout per backend

- `{backend}.vtr` — core match columns (~100-300 MB compressed)
- `{backend}_extra.vtr` — columns for `add_*_info()` (downloaded on demand)
- `{backend}.meta` — provenance (version, date, source URL, row count)

### CI workflow

`.github/workflows/build-backbones.yml`:
- Trigger: manual dispatch or cron (every 6 months)
- Runner: ubuntu-latest with 8 GB RAM
- Steps: install R + vectra, run `tools/build-backbones/build-{backend}.R`, upload to Zenodo
- Requires `ZENODO_TOKEN` secret

## 3. Additional Backends

### Tier 1 — bulk downloads (easy)

| Backend | Source | Fetch | Scope | Priority |
|---|---|---|---|---|
| ITIS | bulk SQLite from itis.gov | download + query | all kingdoms, NA focus | high |
| NCBI | FTP taxdump.tar.gz | download + parse | molecular/genomic | high |
| WoRMS | DwCA export | download | marine species | medium |

### Tier 2 — API crawl (CI handles the slow fetch)

| Backend | Source | Fetch | Scope | Priority |
|---|---|---|---|---|
| Tropicos | REST API (paginated) | ~4 hours crawl | plants (Missouri BG) | medium |
| IUCN | REST API (key required) | ~1 hour crawl | conservation status | medium |
| BOLD | REST API | ~2 hours crawl | barcoded species | low |
| EOL | REST API | large crawl | all kingdoms (aggregator) | low |

### Per-backend implementation

Each backend needs:
1. **CI fetch script** in `tools/build-backbones/` — downloads/crawls raw data
2. **Conversion script** — normalizes to common schema, writes .vtr
3. **S3 methods** in `R/backend-{name}.R` — `match_exact`, `match_fuzzy`, `resolve_synonyms`
4. **Register** in `resolve_backend()` switch
5. **Pipe extension** `add_{name}_info()` (optional)

The S3 backend interface is O(1) effort per backend. The conversion scripts are the variable part — each source has its own quirks (GBIF has no header, COL needs family denormalization, ITIS uses SQLite, NCBI uses a flat node/name dump).

## 4. vectra Improvements

### Compression

- Measure: core-only .vtr sizes with v4 compression
- Consider: split core vs extras into separate .vtr at build time
- Write speed is now fast (18 sec for 5.3M rows) — no further optimization needed

### resolve() and propagate()

- Already implemented and tested (10/10 tests pass)
- Use in `tools/build-backbones/build-col.R` for family denormalization via vectra engine instead of R vectorized approach
- Use in `tools/build-backbones/build-gbif.R` for family_key resolution

## 5. Polish

- Vignette (`vignettes/taxify.Rmd`) — quick start, multi-backend, pipe extensions
- pkgdown site (Bootstrap 5, light-switch)
- GitHub Actions (R-CMD-check workflow)
- ASAAS edge case test suite (encoding, authorship, hybrid formulas)
- CRAN submission (after Zenodo pipeline is stable)

## 6. Update Cadence

| Source | Release cycle | Recommended fetch |
|---|---|---|
| WFO | annual (December) | every 12 months |
| COL | annual + monthly | every 6 months |
| GBIF | quarterly backbone | every 6 months |
| ITIS | continuous | every 12 months |
| NCBI | daily updates | every 6 months |
| WoRMS | continuous | every 12 months |
