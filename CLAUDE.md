# taxify — Claude Code Context

## What is taxify

An R package for offline taxonomic name matching against local Darwin Core backbone databases (WFO, COL, GBIF, ITIS, NCBI, OTT, WoRMS). Replaces taxize (removed from CRAN) and WorldFlora (WFO-only, painful at scale).

## Architecture

```
User input → clean_names() → match_exact() → match_fuzzy() → resolve_synonyms() → 15-col output
                  (R)            (vectra joins)   (vectra string dist)   (vectra joins)
```

- **Query engine:** vectra (C11 columnar engine, `.vtr` format)
- **Backend interface:** S3 generics on `taxify_backend` class
- **Backbone storage:** Darwin Core CSV → `.vtr` (one-time conversion)
- **Cache:** Package-level env stores `.vtr` paths (not nodes — vectra nodes are single-use)

## Key design: vectra nodes are single-use

vectra nodes are consumed on `collect()`. Every query needs a fresh `tbl(path)`. The cache stores **paths**, not nodes. The matching functions create fresh `tbl()` handles internally.

## Key design: vectra data masking

vectra's `serialize_expr` resolves bare names against the node schema first (column wins), then falls back to the caller's environment (local variable). This means `filter(genus == my_var)` works naturally — no `!!` or `eval(substitute())` needed. Use `.env$varname` if a local variable collides with a column name.

## Build & Test

```bash
# Document
"/mnt/c/Program Files/R/R-4.5.2/bin/Rscript.exe" -e 'setwd("C:/Users/Gilles Colling/Documents/dev/taxify"); devtools::document()'

# Test all
"/mnt/c/Program Files/R/R-4.5.2/bin/Rscript.exe" -e 'setwd("C:/Users/Gilles Colling/Documents/dev/taxify"); devtools::test()'

# Check
"/mnt/c/Program Files/R/R-4.5.2/bin/Rscript.exe" -e 'setwd("C:/Users/Gilles Colling/Documents/dev/taxify"); devtools::check(args = "--no-manual")'
```

Note: On Windows, use a `.run.R` temp file instead of `-e` for complex commands (segfault risk with inline `-e`).

## File Map

| File | Purpose |
|---|---|
| `R/taxify.R` | Main `taxify()` + `taxify_single()` — user-facing entry point, multi-backend fallback |
| `R/clean.R` | Name cleaning pipeline (qualifiers, authorship, brackets, whitespace) |
| `R/hybrid.R` | Hybrid detection (`detect_hybrid`) and formula parsing (`parse_hybrid_formula`) |
| `R/backend.R` | S3 generic definitions + `resolve_backend()` |
| `R/backend-wfo.R` | WFO backend: download from Zenodo, classification.txt → .vtr |
| `R/backend-col.R` | COL backend: download from ChecklistBank, Taxon.tsv → .vtr (strips namespace prefixes, builds canonicalName) |
| `R/backend-gbif.R` | GBIF backend: download simple.txt.gz (no header, positional cols), denormalizes family_key, synonym via parent_key |
| `R/backend-itis.R` | ITIS backend: download SQLite dump from itis.gov, hierarchy walk for family/genus, synonym_links table |
| `R/backend-ncbi.R` | NCBI Taxonomy: taxdump.tar.gz, pipe-delimited .dmp files, hierarchy walk, synonyms as separate name rows |
| `R/backend-ott.R` | Open Tree of Life: OTT taxonomy archive, pipe-delimited taxonomy.tsv + synonyms.tsv, hierarchy walk |
| `R/backend-worms.R` | WoRMS: DwC-A from GBIF ChecklistBank, LSID→AphiaID extraction, denormalized classification |
| `R/cache.R` | Backbone path caching + `taxify_data_dir()` + `ensure_backbone()` |
| `R/pick.R` | Best-match selection (ACCEPTED > SYNONYM, SPECIES > higher, smallest ID) |
| `R/add-hybrid-info.R` | Pipe extension: hybrid parents and type |
| `R/add-wfo-info.R` | Pipe extension: extra WFO columns |
| `R/add-col-info.R` | Pipe extension: COL extras (notho, nomenclaturalCode, kingdom/phylum/class/order, extinct/marine via SpeciesProfile) |
| `R/add-gbif-info.R` | Pipe extension: GBIF extras (notho_type, nom_status, bracket_authorship, year, origin) |
| `R/add-qualifier-info.R` | Pipe extension: qualifier extraction |
| `R/taxify-package.R` | Package doc, imports, `.onLoad()`, globalVariables |

## Backends

Seven backends implemented: WFO, COL, GBIF, ITIS, NCBI, OTT, WoRMS. Adding a backend requires:
1. Constructor function (e.g., `col_backend()`)
2. S3 methods: `taxify_download`, `taxify_load`, `match_exact`, `match_fuzzy`
3. Register in `resolve_backend()` switch

**Build pipeline separation:** The taxify package contains backend R code (S3 methods, matching logic, build-from-source fallback). Pre-built `.vtr` files are built by the separate `taxify-backbones` repo (`C:\Users\Gilles Colling\Documents\dev\taxify-backbones`), which has its own shared normalize/precompute/build pipeline and CI workflows.

### Backend-specific notes

- **WFO**: Single `classification.txt` TSV. `scientificName` is canonical (no authorship). Column `genus`.
- **COL**: Single `Taxon.tsv` with `dwc:`/`col:` prefixed headers (stripped on read). `scientificName` includes authorship → `canonicalName` computed by stripping authorship. Column `genericName` (not `genus`). Status values originally lowercase (uppercased on conversion). `SpeciesProfile.tsv` stored as separate `.vtr` for extinct/marine info.
- **GBIF**: `simple.txt.gz` has NO header row (30 positional columns), `\N` for NULLs. `canonical_name` already exists. Column `genus_or_above`. No `family` text column — only `family_key` FK, denormalized during conversion via self-join. Synonyms use `parent_key` as accepted ID (not `acceptedNameUsageID`). Status values like `HOMOTYPIC_SYNONYM`, `HETEROTYPIC_SYNONYM` mapped to standard `SYNONYM`.
- **ITIS**: SQLite dump from itis.gov. Uses unified backbone schema (`canonical_name`, `taxon_id`, etc.). Relational: `taxonomic_units` + `synonym_links` + `taxon_unit_types`. Family/genus resolved via `parent_tsn` hierarchy walk. `name_usage` (valid/accepted → ACCEPTED, invalid/not accepted → SYNONYM). Column `genus` (resolved). Requires RSQLite (Suggests) for build-from-source; pre-built .vtr preferred.
- **NCBI**: `taxdump.tar.gz` with pipe-delimited `.dmp` files (names.dmp, nodes.dmp). Unified schema. Synonyms are alternative name rows for the same `tax_id`, emitted as separate rows with synthetic IDs (`tax_id_syn_N`). Family/genus via hierarchy walk. No authorship data. Aggressive noise filtering (environmental samples, unclassified, metagenomes).
- **OTT**: OTT taxonomy archive (`taxonomy.tsv` + `synonyms.tsv`, pipe-delimited). Unified schema. Synthetic taxonomy combining NCBI, GBIF, WoRMS, IRMNG. Status derived from flags column. Family/genus via hierarchy walk. Cross-references to source databases via `sourceinfo` column.
- **WoRMS**: DwC-A from GBIF ChecklistBank (dataset 1010). Unified schema. Marine-focused. `taxonID` may be LSID (stripped to numeric AphiaID). Status uses `accepted`/`unaccepted` (mapped to standard). Classification denormalized (no hierarchy walk). `SpeciesProfile.tsv` has habitat flags.

## Enrichments

Enrichment layers join external trait/status data to taxify results via `accepted_name == canonical_name`. 12 enrichments available: conservation_status, griis, wcvp, eive, elton_traits, avonet, pantheria, amphibio, common_names, woodiness, diaz_traits, leda.

### Enrichment architecture

- **Manifest:** `inst/manifest.json` has per-enrichment metadata: `source_url`, `source_format`, `source_version`, `species_col`, `trait_cols`, `static` (boolean).
- **Disk layout:** `taxify_data_dir()/enrichment/{name}/latest/{name}.vtr + meta.json`
- **Two join patterns:** `enrich_simple()` for flat joins (woodiness, conservation_status, etc.), `enrich_by_group()` for group-filtered/pivoted joins (griis by country, wcvp by tdwg_code, common_names by lang). Group filtering is NA-safe: NCBI/OTT common names have `lang = NA` and can be queried with `add_common_names(lang = NA)`.

### Enrichment fallback chain

```
ensure_enrichment(name):
  1. version check (once per session, inlined)  # skips manifest fetch for static enrichments
  2. session cache                               # .taxify_env
  3. disk                                        # enrichment_vtr_path()
  4. download pre-built .vtr                     # download_enrichment()
  5. build_enrichment_from_source(name)          # registry-based, writes .vtr + meta.json
  6. return NULL → caller tries emergency fallback
```

If `ensure_enrichment()` returns NULL, `enrich_simple()`/`enrich_by_group()` call `try_emergency_fallback()` → `enrichment_emergency_fallback()` → downloads raw source, parses in-memory, joins via `enrich_from_dataframe()`/`enrich_from_dataframe_grouped()`. Emergency fallback is ephemeral (no disk write), warns with source URL/version/license/reason.

### Cross-backbone name resolution (build-time)

Enrichment `.vtr` files must be joinable regardless of which backbone produced the user's `taxify()` result. The build pipeline in `taxify-backbones` resolves this:

1. Source names are run through `taxify()` against **each of the 7 backends separately** (not as a fallback chain — fallback chains only return the first match)
2. The union of all unique `accepted_name` values is collected per source species
3. Each source row is expanded: one enrichment row per distinct accepted name (trait data duplicated)
4. Deduplication by `canonical_name` (+ group_col for grouped enrichments)

This means `enrich_simple()`'s exact join on `accepted_name == canonical_name` works correctly for any backbone. Realistic file size increase: ~1.1–1.5x (backends agree on >90% of names).

Implementation: `taxify-backbones/shared/resolve_names.R` → `resolve_enrichment_names(df, group_cols)`, called by every `enrichment/*/convert.R` after cleaning, before `build_enrichment_vtr()`.

### Join strategy

Both `enrich_simple()` and `enrich_by_group()` use vectorized `match()` for filling output columns (not row-level loops). The grouped variant does one `match()` per group. Emergency fallback functions use the same pattern.

Group-based enrichments (griis, wcvp, common_names) resolve `groups = "all"` from `available_groups` in the manifest (O(1)), falling back to `vectra::distinct()` scan if the manifest field is absent.

### Build registry (not S3)

`R/enrichment-build.R` uses a registry pattern (`.enrichment_build_registry`): each enrichment is a list with `{source_url, download_fn, parse_fn, requires, ...}`. 12 entries share generic download helpers (`download_curl_file`, `download_and_unzip`, `download_gbif_api_pages`) + per-enrichment parse functions (~20-50 lines each). The `common_names` entry downloads three sources (GBIF backbone, NCBI taxdump, OTT taxonomy) and `parse_common_names()` merges them via three sub-parsers (`parse_gbif_common_names`, `parse_ncbi_common_names`, `parse_ott_common_names`). GBIF provides ISO 639-1 language codes; NCBI and OTT common names have `lang = NA`.

`R/enrichment-vtr.R` has `build_local_enrichment_vtr()` — sorts by canonical_name, writes .vtr with indexes, extracts `available_groups` from group column, writes meta.json sidecar (including `static`, `group_col`, `available_groups`).

### Version checking

- `check_enrichment_version(name)` — reads local meta.json first; if `static == TRUE`, returns FALSE immediately (no manifest fetch). Otherwise compares meta version vs manifest latest.
- Version check is inlined in `ensure_enrichment()`, runs once per session (flag: `.enrichment_version_checked.*`)
- `download_enrichment()` writes `static` flag from manifest entry into meta.json, so subsequent sessions skip the manifest fetch for version-locked datasets.
- CI: `taxify-backbones/.github/workflows/check-enrichment-versions.yml` — weekly cron checks upstream sources (Zenodo/Figshare/Dryad/GBIF APIs), opens/updates a GitHub issue labeled `enrichment-outdated`

### Manifest

`inst/manifest.json` (schema v2) has `backends` and `enrichments` sections. Each enrichment entry has: `latest`, `full_url`, `nrow`, `source_url`, `source_format`, `species_col`, `trait_cols`, `static`, and optionally `available_groups` (for group-based enrichments). The package reads the manifest from GitHub raw URL, falling back to the bundled copy.

Group-based enrichments (griis, wcvp, common_names) have an `available_groups` field listing all valid group values (ISO country codes, TDWG codes, language codes). This is populated by the taxify-backbones build pipeline and synced via `sync_manifest.R`. Note: `available_groups` excludes `NA` values; NCBI/OTT common names with `lang = NA` are queryable but not listed in the manifest's `available_groups`.

### Discovery

`list_enrichments()` (exported) reads the manifest and returns a summary data.frame with name, version, nrow, static, trait_cols, and source_url.

### Enrichment file map

| File | Purpose |
|---|---|
| `R/enrichment.R` | Infrastructure: path helpers, version checking, ensure/download, `enrich_simple()`, `enrich_by_group()`, emergency fallback wiring |
| `R/enrichment-build.R` | Build registry, download helpers, 12 parse functions, `build_enrichment_from_source()`, `enrichment_emergency_fallback()` |
| `R/enrichment-vtr.R` | `build_local_enrichment_vtr()` — .vtr writer + meta.json sidecar |
| `R/enrichment-meta.R` | `register_enrichment()`, summary display for enrichment metadata |
| `R/add-data.R` | `add_data()` — user-facing function to join custom external data (CSV/XLSX/SQLite/VTR/data.frame) via backbone matching |
| `R/add-conservation-status.R` | `add_conservation_status()` — IUCN status enrichment |
| `R/add-invasive-status.R` | `add_invasive_status()` — GRIIS invasive status by country |
| `R/add-wcvp.R` | `add_wcvp()` — WCVP native range by TDWG region |
| `R/add-eive.R` | `add_eive()` — EIVE ecological indicator values |
| `R/add-elton-traits.R` | `add_elton_traits()` — EltonTraits diet/foraging (birds + mammals) |
| `R/add-avonet.R` | `add_avonet()` — AVONET bird morphology |
| `R/add-pantheria.R` | `add_pantheria()` — PanTHERIA mammal traits |
| `R/add-amphibio.R` | `add_amphibio()` — AmphiBIO amphibian traits |
| `R/add-common-names.R` | `add_common_names()` — vernacular names (GBIF + NCBI + OTT) |
| `R/add-woodiness.R` | `add_woodiness()` — Zanne et al. woody/herbaceous |
| `R/add-diaz-traits.R` | `add_diaz_traits()` — Diaz et al. seed mass + plant height |
| `R/add-leda.R` | `add_leda()` — LEDA NW European plant traits |

## Multi-backend fallback

`taxify(names, backend = c("wfo", "col", "gbif"))` tries backends in order. Names matched by an earlier backend are not re-matched. The `backend` column in the output indicates which backend matched each name.

## Dependencies

- **vectra** (Imports): columnar engine, joins, string distance
- **rlang** (Imports): `%||%` operator only
- **jsonlite** (Imports): manifest parsing, enrichment meta.json
- **DBI**, **RSQLite** (Suggests): ITIS build-from-source only
- **openxlsx2** (Suggests): XLSX reading for enrichments (EIVE, AVONET, Diaz) and `add_data()`
- **testthat** (Suggests): testing framework
