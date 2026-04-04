# taxify: Enrichment Layers Plan

Enrichment layers add columns to already-matched taxify results. They
are NOT matching backends — they join on `accepted_name` from a prior
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call.

All enrichment data ships as `.vtr` files built in CI and distributed
via GitHub Releases with xdelta3 diffs (same pipeline as matching
backends). Each `.vtr` includes a `meta.json` recording source version,
DOI, build date, and row count.

------------------------------------------------------------------------

## Cross-backbone name resolution

Every enrichment `.vtr` must be joinable regardless of which backbone
produced the user’s
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result. This means the build pipeline resolves source names against
**all 7 backends** and stores the union of accepted names.

### Build pipeline (shared across all enrichments)

1.  Extract raw species names from the source dataset
2.  Run
    `taxify(names, backend = c("wfo", "col", "gbif", "itis", "ncbi", "ott", "worms"))`
3.  Collect all unique `accepted_name` values across all backends for
    each source species
4.  Emit one enrichment row per distinct `accepted_name` (with trait
    data duplicated)

### Why this works

- `enrich_simple()` joins on `accepted_name == canonical_name` — no
  change needed
- If all 7 backends agree on accepted name (common case), one row is
  stored — no bloat
- If backends disagree (e.g., WFO says “Senecio vulgaris”, COL lumps
  differently), each accepted name gets a copy of the trait data —
  correct behavior, the user finds the trait regardless of backend
- Realistic file size increase: **~1.1–1.5x** (not 7x), because backbone
  agreement is \>90%

### Why not a multi-key schema (one row per species × backend)

- Forces `enrich_simple()` to filter by backend identity — unnecessary
  coupling
- 7x file size for near-zero benefit (most rows identical across
  backends)
- Harder to extend if new backends are added

------------------------------------------------------------------------

## Enrichment Inventory

### P1 — Ship with first release

| Enrichment | Function | Source | Species | License | Scope |
|----|----|----|----|----|----|
| Conservation status | [`add_conservation_status()`](https://gillescolling.com/taxify/reference/add_conservation_status.md) | Public sources (GBIF, IUCN API) | ~166k | Factual data | Global, all taxa |
| Invasive status | `add_invasive_status(country)` | GRIIS (Zenodo CSV) | ~23k rows (name × country) | CC BY 4.0 | Global, 196 countries |
| Woodiness | [`add_woodiness()`](https://gillescolling.com/taxify/reference/add_woodiness.md) | Zanne et al. 2014 (Dryad) | ~50k | CC0 | Plants |
| Native range | `add_native_range(region)` | WCVP (Kew SFTP) | ~340k | CC BY | Plants, global |
| Indicator values | `add_indicator_values()` | EIVE 1.0 (Dengler et al. 2023, Zenodo) | ~14.5k | CC BY 4.0 | Plants, Europe |

### P2 — Second wave

| Enrichment | Function | Source | Species | License | Scope |
|----|----|----|----|----|----|
| Seed mass + plant height | [`add_diaz_traits()`](https://gillescolling.com/taxify/reference/add_diaz_traits.md) | Diaz et al. 2022 (TRY File Archive) | ~46k | CC BY 3.0 | Plants, global |
| Bird + mammal diet/foraging | [`add_elton_traits()`](https://gillescolling.com/taxify/reference/add_elton_traits.md) | EltonTraits 1.0 (Wilman et al. 2014, Figshare) | ~15.4k | CC0 | Birds + mammals |
| Bird morphology + migration | [`add_avonet()`](https://gillescolling.com/taxify/reference/add_avonet.md) | AVONET (Tobias et al. 2022, Figshare) | ~11k | CC BY 4.0 | Birds |
| Mammal life history | [`add_pantheria()`](https://gillescolling.com/taxify/reference/add_pantheria.md) | PanTHERIA (Jones et al. 2009, Ecol. Archives) | ~5.4k | CC0 | Mammals |
| Amphibian life history | [`add_amphibio()`](https://gillescolling.com/taxify/reference/add_amphibio.md) | AmphiBIO (Oliveira et al. 2017, Figshare) | ~6.8k | CC BY 4.0 | Amphibians |
| Raunkiær + dispersal + leaf | [`add_leda()`](https://gillescolling.com/taxify/reference/add_leda.md) | LEDA Traitbase (Kleyer et al. 2008) | ~8k | Free download | Plants, NW Europe |
| Common names | `add_common_names(lang)` | GBIF backbone vernacular names | large | CC0 | Global, multi-language |

### P3 — If TRY request approved

| Enrichment | Function | Source | Species | License | Scope |
|----|----|----|----|----|----|
| Dispersal mode | `add_dispersal_mode()` | TRY (request-based, CC BY 4.0 since 2019) | TBD | CC BY 4.0 | Plants, global |

### Deferred — add on user demand

| Enrichment | Source | Reason for deferral |
|----|----|----|
| IPNI (publication citations) | IPNI bulk dump (CC BY) | Niche — serves taxonomists, not ecologists |
| Flower color | Dryad deposit (~3k species, CC0) | Too small for useful coverage |
| Pollination syndrome | No global open dataset exists | Data desert |

### Not viable

| Source | Why |
|----|----|
| BirdLife International | Custom restrictive license, no redistribution |
| CCDB (chromosomes) | No explicit license, unreliable hosting |
| Ellenberg (original) | Book publication, no open license — EIVE supersedes it |
| NatureServe | Regional (N. America) + redistribution restricted |
| Tropicos | No bulk download, API-only (~1.4M names) |

------------------------------------------------------------------------

## Function Signatures

### `add_conservation_status(result)`

``` r

# Joins on accepted_name
# Adds: conservation_status (LC/NT/VU/EN/CR/EW/EX, NA if not assessed)
# .vtr schema: canonical_name, conservation_status
# Source: compiled from publicly available sources (GBIF, IUCN API)
# Attribution: "compiled from publicly available sources including GBIF, IUCN, and national databases"
```

### `add_invasive_status(result, country)`

``` r

# Joins on accepted_name, filtered by country
# Adds: invasive_status column(s)
#   country = "AT"           → invasive_status (no suffix)
#   country = c("AT", "DE")  → invasive_status_AT, invasive_status_DE
#   country = "all"          → invasive_status_AT, ..., invasive_status_ZW
# Values: "native", "introduced", "invasive", NA
# .vtr schema: canonical_name, country_code, establishment_means, is_invasive
# Source: GRIIS (Zenodo combined CSV, CC BY 4.0, 196 countries)
```

### `add_woodiness(result)`

``` r

# Joins on accepted_name
# Adds: woodiness ("woody", "herbaceous", "variable", NA)
# .vtr schema: canonical_name, woodiness
# Source: Zanne et al. 2014, Nature (Dryad, CC0)
# Plants only
```

### `add_native_range(result, region)`

``` r

# Joins on accepted_name, filtered by TDWG botanical region
# Adds: native_status column(s) — "native", "introduced", "extinct", NA
# .vtr schema: canonical_name, tdwg_code, native_status
# Source: WCVP (Kew, CC BY)
# Plants only
# Similar API to add_invasive_status():
#   region = "EUR"            → native_status (no suffix)
#   region = c("EUR", "NAM")  → native_status_EUR, native_status_NAM
#   region = "all"            → wide format
```

### `add_indicator_values(result)`

``` r

# Joins on accepted_name
# Adds: eive_light, eive_temperature, eive_moisture, eive_reaction, eive_nutrients
# .vtr schema: canonical_name, light, temperature, moisture, reaction, nutrients
# Source: EIVE 1.0 (Dengler et al. 2023, Zenodo, CC BY 4.0)
# European vascular plants only
# Continuous values (not ordinal like Ellenberg)
```

### `add_diaz_traits(result)`

``` r

# Joins on accepted_name
# Adds: seed_mass_mg, plant_height_m (species-level means)
# .vtr schema: canonical_name, seed_mass_mg, plant_height_m
# Source: Diaz et al. 2022, TRY File Archive (CC BY 3.0)
# Plants only
```

### `add_elton_traits(result)`

``` r

# Joins on accepted_name
# Adds: diet_inv, diet_vend, diet_vect, diet_vfish, diet_vunk,
#        diet_scav, diet_fruit, diet_nect, diet_seed, diet_plantother,
#        foraging_strata_water, foraging_strata_ground, ...
#        body_mass_g, nocturnal
# .vtr schema: canonical_name + all EltonTraits columns
# Source: EltonTraits 1.0 (Wilman et al. 2014, Figshare, CC0)
# Birds + mammals only
```

### `add_avonet(result)`

``` r

# Joins on accepted_name
# Adds: beak_length, beak_depth, wing_length, tail_length, tarsus_length,
#        body_mass_g, hand_wing_index, habitat, trophic_level, trophic_niche,
#        migration (sedentary/partial/full)
# .vtr schema: canonical_name + AVONET species-level averages
# Source: AVONET (Tobias et al. 2022, Figshare, CC BY 4.0)
# Birds only
```

### `add_pantheria(result)`

``` r

# Joins on accepted_name
# Adds: body_mass_g, longevity_mo, litter_size, gestation_d, weaning_d,
#        home_range_km2, diet_breadth, habitat_breadth, ...
# .vtr schema: canonical_name + PanTHERIA columns
# Source: PanTHERIA (Jones et al. 2009, Ecological Archives, CC0)
# Mammals only
```

### `add_common_names(result, lang = "en")`

``` r

# Joins on accepted_name, filtered by language
# Adds: common_name
# .vtr schema: canonical_name, lang, common_name
# Source: GBIF backbone vernacular names (CC0)
# Multi-language via ISO 639-1 codes
```

### `add_amphibio(result)`

``` r

# Joins on accepted_name
# Adds: body_size_mm, age_maturity_d, longevity_d, litter_size,
#        reproductive_output, offspring_size_mm, direct_development,
#        larval, aquatic, fossorial, arboreal, diurnal, nocturnal_amphibio
# .vtr schema: canonical_name + AmphiBIO columns
# Source: AmphiBIO (Oliveira et al. 2017, Figshare, CC BY 4.0)
# Amphibians only
```

### `add_leda(result)`

``` r

# Joins on accepted_name
# Adds: raunkiaer_life_form, raunkiaer_variable, dispersal_type,
#        terminal_velocity_ms, seed_mass_mg, canopy_height_m,
#        leaf_mass_mg, sla_mm2_mg, clonal_growth, buoyancy
# .vtr schema: canonical_name + LEDA columns (species-level aggregates)
# Source: LEDA Traitbase (Kleyer et al. 2008, J. Ecology 96:1266-1274)
# NW European plants only
# Build note: raw LEDA has separate files per trait, multiple records per
#   species, messy naming. The taxify-backbones convert.R aggregates (median
#   for continuous, mode for categorical) and flags raunkiaer_variable=1
#   for multi-assigned species. Cross-backbone name resolution follows the
#   shared pipeline (see "Cross-backbone name resolution" section).
```

### `add_dispersal_mode(result)` — P3, pending TRY request

``` r

# Joins on accepted_name
# Adds: dispersal_mode (anemochory/zoochory/hydrochory/autochory/barochory, NA)
# Source: TRY (CC BY 4.0, request-based access)
# Plants only
```

------------------------------------------------------------------------

## .vtr Metadata

Each enrichment .vtr ships with a `meta.json`:

``` json
{
  "type": "enrichment",
  "name": "conservation_status",
  "source": "Compiled from GBIF, IUCN Red List API",
  "source_version": "2025.1",
  "source_doi": null,
  "license": "Factual data (not copyrightable)",
  "attribution": "Conservation status values compiled from publicly available sources including GBIF, IUCN, and national databases",
  "built": "2026-04-04",
  "nrow": 166000,
  "schema_version": 1
}
```

``` json
{
  "type": "enrichment",
  "name": "eive",
  "source": "EIVE 1.0 (Dengler et al. 2023)",
  "source_version": "1.0",
  "source_doi": "10.3897/VCS.98324",
  "license": "CC BY 4.0",
  "attribution": "Dengler J et al. (2023) EIVE 1.0. Vegetation Classification and Survey 4: 7-29",
  "built": "2026-04-04",
  "nrow": 14500,
  "schema_version": 1
}
```

The `source_version` field tracks the exact version of the upstream data
used to build the .vtr. This ensures reproducibility and lets users know
when their enrichment data was last refreshed.

------------------------------------------------------------------------

## Build Pipeline (taxify-backbones repo)

    taxify-backbones/
    ├── enrichment/
    │   ├── conservation-status/
    │   │   ├── crawl.R           # IUCN API crawler with checkpointing
    │   │   └── config.yml
    │   ├── griis/
    │   │   ├── download.R        # Zenodo combined CSV
    │   │   ├── convert.R         # CSV → .vtr (name × country)
    │   │   └── config.yml
    │   ├── woodiness/
    │   │   ├── download.R        # Zanne et al. from Dryad
    │   │   ├── convert.R         # → .vtr
    │   │   └── config.yml
    │   ├── wcvp/
    │   │   ├── download.R        # Kew SFTP
    │   │   ├── convert.R         # → .vtr (name × TDWG region)
    │   │   └── config.yml
    │   ├── eive/
    │   │   ├── download.R        # Zenodo
    │   │   ├── convert.R         # → .vtr
    │   │   └── config.yml
    │   ├── diaz-traits/
    │   │   ├── download.R        # TRY File Archive
    │   │   ├── convert.R         # → .vtr
    │   │   └── config.yml
    │   ├── elton-traits/
    │   │   ├── download.R        # Figshare
    │   │   ├── convert.R         # → .vtr
    │   │   └── config.yml
    │   ├── avonet/
    │   │   ├── download.R        # Figshare
    │   │   ├── convert.R         # → .vtr
    │   │   └── config.yml
    │   ├── pantheria/
    │   │   ├── download.R        # Ecological Archives
    │   │   ├── convert.R         # → .vtr
    │   │   └── config.yml
    │   ├── amphibio/
    │   │   ├── download.R        # Figshare (single CSV)
    │   │   ├── convert.R         # → .vtr (clean, minimal preprocessing)
    │   │   └── config.yml
    │   ├── leda/
    │   │   ├── download.R        # LEDA website (separate trait files)
    │   │   ├── convert.R         # → .vtr (heavy: merge traits, aggregate, name-match)
    │   │   └── config.yml
    │   └── common-names/
    │       ├── download.R        # GBIF vernacular names
    │       ├── convert.R         # → .vtr (name × lang)
    │       └── config.yml

CI workflow (`build-enrich.yml`):

``` yaml
strategy:
  matrix:
    source:
      - conservation-status  # IUCN API crawl (self-hosted, needs token)
      - griis                # Zenodo download (GitHub-hosted OK)
      - woodiness            # Dryad download (GitHub-hosted OK)
      - wcvp                 # Kew SFTP download (GitHub-hosted OK)
      - eive                 # Zenodo download (GitHub-hosted OK)
      - diaz-traits          # TRY Archive download (GitHub-hosted OK)
      - elton-traits         # Figshare download (GitHub-hosted OK)
      - avonet               # Figshare download (GitHub-hosted OK)
      - pantheria            # Ecological Archives download (GitHub-hosted OK)
      - amphibio             # Figshare download (GitHub-hosted OK)
      - leda                 # LEDA download + heavy preprocessing (GitHub-hosted OK)
      - common-names         # GBIF download (GitHub-hosted OK)
```

------------------------------------------------------------------------

## Licensing Summary

| Enrichment | Source | License | Redistribution |
|----|----|----|----|
| Conservation status | GBIF + IUCN API | Factual data | ✅ (with attribution to public sources) |
| Invasive status | GRIIS | CC BY 4.0 | ✅ (with attribution) |
| Woodiness | Zanne et al. 2014 | CC0 | ✅ (no restrictions) |
| Native range | WCVP (Kew) | CC BY | ✅ (with attribution) |
| Indicator values | EIVE 1.0 | CC BY 4.0 | ✅ (with attribution) |
| Seed mass + height | Diaz et al. 2022 | CC BY 3.0 | ✅ (with attribution) |
| Bird + mammal diet | EltonTraits 1.0 | CC0 | ✅ (no restrictions) |
| Bird morphology | AVONET | CC BY 4.0 | ✅ (with attribution) |
| Mammal traits | PanTHERIA | CC0 | ✅ (no restrictions) |
| Amphibian traits | AmphiBIO | CC BY 4.0 | ✅ (with attribution) |
| Raunkiær + dispersal + leaf | LEDA Traitbase | Free download | ✅ (with citation) |
| Common names | GBIF | CC0 | ✅ (no restrictions) |
| Dispersal mode (P3) | TRY | CC BY 4.0 | ✅ (with attribution, after request) |
