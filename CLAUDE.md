# taxify — Claude Code Context

## What is taxify

An R package for offline taxonomic name matching against local Darwin Core backbone databases (WFO, COL, GBIF). Replaces taxize (removed from CRAN) and WorldFlora (WFO-only, painful at scale).

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
| `R/taxify.R` | Main `taxify()` function — user-facing entry point |
| `R/clean.R` | Name cleaning pipeline (qualifiers, authorship, brackets, whitespace) |
| `R/hybrid.R` | Hybrid detection (`detect_hybrid`) and formula parsing (`parse_hybrid_formula`) |
| `R/backend.R` | S3 generic definitions + `resolve_backend()` |
| `R/backend-wfo.R` | WFO backend: download, load, match_exact, match_fuzzy, resolve_synonyms |
| `R/cache.R` | Backbone path caching + `taxify_data_dir()` + `ensure_backbone()` |
| `R/pick.R` | Best-match selection (ACCEPTED > SYNONYM, SPECIES > higher, smallest ID) |
| `R/add-hybrid-info.R` | Pipe extension: hybrid parents and type |
| `R/add-wfo-info.R` | Pipe extension: extra WFO columns |
| `R/add-qualifier-info.R` | Pipe extension: qualifier extraction |
| `R/taxify-package.R` | Package doc, imports, `.onLoad()` |

## Backends

Currently WFO only. Adding a backend requires:
1. Constructor function (e.g., `col_backend()`)
2. S3 methods: `taxify_download`, `taxify_load`, `match_exact`, `match_fuzzy`, `resolve_synonyms`
3. Register in `resolve_backend()` switch

## Dependencies

- **vectra** (Imports): columnar engine, joins, string distance
- **rlang** (Imports): `%||%` operator only
- **testthat** (Suggests): testing framework
