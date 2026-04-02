# Backbone Build Pipeline

This directory contains scripts that convert raw Darwin Core Archive (DwCA) 
files into precomputed `.vtr` files for taxify. These scripts run on CI — 
they are NOT part of the CRAN package (excluded via `.Rbuildignore`).

## Architecture

```
Raw DwCA (Zenodo/ChecklistBank/GBIF)
  → build-wfo.R / build-col.R / build-gbif.R
  → precomputed .vtr files
  → uploaded to Zenodo (one DOI per release)
  → taxify_download() fetches the .vtr directly
```

Users never run these scripts. `taxify_download()` fetches precomputed `.vtr` 
files from Zenodo — zero conversion, zero RAM spikes, instant setup.

## Scripts

| Script | Input | Output | Notes |
|---|---|---|---|
| `build-wfo.R` | WFO classification.csv (~120 MB zip) | `wfo.vtr` + `wfo.meta` | Tab-separated despite .csv extension |
| `build-col.R` | COL Taxon.tsv + SpeciesProfile.tsv (~500 MB zip) | `col.vtr` + `col_species_profile.vtr` + `col.meta` | Family denormalized via parent chain propagation |
| `build-gbif.R` | GBIF simple.txt.gz (~1.5 GB) | `gbif.vtr` + `gbif.meta` | Family denormalized via family_key FK resolution |
| `upload-zenodo.R` | .vtr files | Zenodo deposit | Requires ZENODO_TOKEN |

## Running locally (development only)

```r
source("tools/build-backbones/build-wfo.R")   # ~2 min
source("tools/build-backbones/build-col.R")    # ~15 min (family denormalization)
source("tools/build-backbones/build-gbif.R")   # ~10 min (family_key resolution)
```

## CI workflow

See `.github/workflows/build-backbones.yml`. Triggered manually or on schedule.
Requires `ZENODO_TOKEN` secret.

## Future: C/C++ conversion tools

When backbone sizes grow or conversion frequency increases, the R scripts can
be replaced with C/C++ tools that:
- Use vectra's `resolve()` for FK lookups (GBIF family_key)
- Use vectra's `propagate()` for parent-chain walks (COL family)
- Both run entirely in vectra's C engine — no R memory overhead
