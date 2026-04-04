# taxify TODOs

## build_enrichment() — user-facing update command

Single function to pull latest upstream data and rebuild enrichment .vtr
files locally.

``` r

build_enrichment("woodiness")
```

### Behavior

1.  Fetch latest source from upstream (Dryad/Zenodo/Figshare/API)
2.  Run conversion scripts (same as taxify-backbones CI pipeline)
3.  **If conversion succeeds:**
    - Write new .vtr (atomic rename — old file intact until new one is
      ready)
    - Update meta.json (source_version, built date, nrow)
    - Message:
      `"Woodiness updated: Zanne et al. v1.0 → v1.1 (50,234 species)"`
4.  **If conversion fails:**
    - Keep old .vtr untouched
    - Warning:
      `"Upstream format changed — conversion failed. Keeping existing v1.0. Report at github.com/gcol33/taxify/issues"`

### Key design points

- Never destroys working data — old .vtr stays until new one is
  confirmed good
- No `experimental` flag — the try/keep-old behavior IS the safety
- Updates metadata so [`summary()`](https://rdrr.io/r/base/summary.html)
  reflects the new version
- Same pattern applies to `build_backbone()` for matching backends
- Pre-built .vtr via `download_enrichment()` remains the default happy
  path
- `build_enrichment()` is the power-user escape hatch when pre-built
  .vtr is outdated or unavailable

### Applies to all enrichment sources

- conservation_status (IUCN API crawl — slow, needs token)
- griis (Zenodo CSV)
- woodiness (Dryad)
- wcvp / native_range (Kew SFTP)
- eive (Zenodo)
- diaz_traits (TRY File Archive)
- elton_traits (Figshare)
- avonet (Figshare)
- pantheria (Ecological Archives)
- common_names (GBIF)

### Integration with add\_\*() functions

``` r

result |> add_woodiness()
# 1. Check for local .vtr → found → use it
# 2. Not found → check manifest for pre-built download → download → use it
# 3. Download fails or no manifest entry → stop with message:
#    "Woodiness data not available. Run build_enrichment('woodiness') to build locally."
```

`add_*()` never calls `build_enrichment()` automatically. It tells the
user what to do.
