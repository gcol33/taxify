# taxify

[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Offline Taxonomic Name Matching Against Local Darwin Core Snapshots**

Match taxonomic names against locally stored backbone databases, resolve
synonyms, and enrich results with trait and status data. No API calls,
no internet dependency, no rate limits. Nine backends, twelve enrichment
layers, and a unified 16-column output schema.

## Quick Start

``` r

# install.packages("pak")
pak::pak("gcol33/taxify")

library(taxify)

# Match names against WFO (downloads backbone on first use, ~120 MB)
result <- taxify(c(
  "Quercus robur",
  "Pinus abies",            # synonym of Picea abies
  "Quercus robus",          # typo, fuzzy-corrected
  "Taraxacum officinale"
))

# Add conservation status and common names
result |>
  add_conservation_status() |>
  add_common_names()
```

## Statement of Need

taxize was removed from CRAN because its web API dependencies broke.
WorldFlora works offline but only supports WFO, chokes on large batches,
and offers no enrichment pipeline.

taxify provides offline matching against 9 backbone databases with fuzzy
matching in C, synonym resolution, hybrid name handling, and a
pipe-based enrichment system for joining trait and status data from 12
published datasets.

## Features

### Matching

- Exact match (case-sensitive and case-insensitive)
- Fuzzy match with configurable algorithm (Damerau-Levenshtein,
  Levenshtein, Jaro-Winkler) and threshold
- Synonym resolution to accepted names
- Best-match selection (ACCEPTED \> SYNONYM, SPECIES \> higher ranks)
- Multi-backend fallback chains:
  `taxify(names, backend = c("wfo", "col", "gbif"))`

### Backends

| Backend          | Scope                       | Approx. names |
|------------------|-----------------------------|---------------|
| WFO              | Vascular plants             | ~400k         |
| COL              | All kingdoms                | ~4.5M         |
| GBIF             | All kingdoms                | ~10M          |
| ITIS             | US focus, freshwater/marine | ~900k         |
| NCBI             | All life                    | ~2.5M         |
| OTT              | All life (synthetic)        | ~4M           |
| WoRMS            | Marine/aquatic              | ~600k         |
| Species Fungorum | Fungi                       | ~500k         |
| AlgaeBase        | Algae                       | –             |

### Enrichments

``` r

taxify(names) |>
  add_conservation_status() |>  # IUCN Red List
  add_invasive_status("AT") |>  # GRIIS by country
  add_woodiness() |>            # Zanne et al.
  add_common_names("en")        # GBIF vernacular names
```

Twelve enrichment layers join trait and status data via
backbone-resolved accepted names:

| Enrichment | Source | Taxa |
|----|----|----|
| [`add_conservation_status()`](https://gcol33.github.io/taxify/reference/add_conservation_status.md) | IUCN Red List | All |
| [`add_invasive_status()`](https://gcol33.github.io/taxify/reference/add_invasive_status.md) | GRIIS | All |
| [`add_wcvp()`](https://gcol33.github.io/taxify/reference/add_wcvp.md) | WCVP | Plants |
| [`add_woodiness()`](https://gcol33.github.io/taxify/reference/add_woodiness.md) | Zanne et al. | Plants |
| [`add_eive()`](https://gcol33.github.io/taxify/reference/add_eive.md) | EIVE 1.0 | European plants |
| [`add_diaz_traits()`](https://gcol33.github.io/taxify/reference/add_diaz_traits.md) | Diaz et al. | Plants |
| [`add_leda()`](https://gcol33.github.io/taxify/reference/add_leda.md) | LEDA Traitbase | NW European plants |
| [`add_elton_traits()`](https://gcol33.github.io/taxify/reference/add_elton_traits.md) | EltonTraits 1.0 | Birds, mammals |
| [`add_avonet()`](https://gcol33.github.io/taxify/reference/add_avonet.md) | AVONET | Birds |
| [`add_pantheria()`](https://gcol33.github.io/taxify/reference/add_pantheria.md) | PanTHERIA | Mammals |
| [`add_amphibio()`](https://gcol33.github.io/taxify/reference/add_amphibio.md) | AmphiBIO | Amphibians |
| [`add_common_names()`](https://gcol33.github.io/taxify/reference/add_common_names.md) | GBIF | All |

Custom data can be joined via
[`add_data()`](https://gcol33.github.io/taxify/reference/add_data.md),
which accepts data.frames, CSV, XLSX, SQLite, and .vtr files.

### Name Cleaning

- Authorship stripping (parenthesized and trailing)
- Qualifier detection (cf., aff., s.l., s.str., agg.)
- Hybrid marker normalization (×, x, X)
- Latin orthographic normalization (ae/oe alternations)
- Bracket, number, and whitespace cleanup

### Genus Register

``` r

lookup_genus("Quercus")
#>     genus   kingdom       family life_form
#> 1 Quercus Plantae   Fagaceae     plant

taxify_register_coverage("Quercus")
#>     genus backend version
#> 1 Quercus     wfo 2024.12
#> 2 Quercus     col 2024-12
#> 3 Quercus    gbif 2024-08
```

## Installation

``` r

# Install from GitHub (vectra is installed automatically)
# install.packages("pak")
pak::pak("gcol33/taxify")
```

## Usage

``` r

library(taxify)

# Single backend (WFO for plants)
result <- taxify(c("Quercus robur", "Pinus sylvestris"))

# Multi-backend fallback (tries WFO first, then COL, then GBIF)
result <- taxify(
  c("Quercus robur", "Gadus morhua", "Agaricus bisporus"),
  backend = c("wfo", "col", "gbif")
)

# Disable fuzzy matching for clean lists
result <- taxify(names, fuzzy = FALSE)

# Tune fuzzy matching
result <- taxify(names, fuzzy_method = "jw", fuzzy_threshold = 0.15)

# Enrich with traits
result <- taxify(plant_names) |>
  add_conservation_status() |>
  add_woodiness() |>
  add_eive()

# Join custom data
result |> add_data(my_traits, species_col = "species")

# Check the result
summary(result)
```

## Documentation

- [Getting
  started](https://gcol33.github.io/taxify/articles/quickstart.html)
- [Choosing and combining
  backends](https://gcol33.github.io/taxify/articles/backends.html)
- [Fuzzy
  matching](https://gcol33.github.io/taxify/articles/fuzzy-matching.html)
- [Enrichments](https://gcol33.github.io/taxify/articles/enrichments.html)
- [Custom
  data](https://gcol33.github.io/taxify/articles/custom-data.html)
- [Hybrid
  names](https://gcol33.github.io/taxify/articles/hybrid-names.html)
- [Migrating from taxize and
  WorldFlora](https://gcol33.github.io/taxify/articles/migration.html)
- [Large-scale
  workflows](https://gcol33.github.io/taxify/articles/large-scale.html)

## Support

> “Software is like sex: it’s better when it’s free.” – Linus Torvalds

I’m a PhD student who builds R packages in my free time because I
believe good tools should be free and open. I started these projects for
my own work and figured others might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to
say thanks. It helps with my coffee addiction.

[![Buy Me A
Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## License

MIT (see the LICENSE.md file)
