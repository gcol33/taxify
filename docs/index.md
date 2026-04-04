# taxify

Offline taxonomic name matching against local Darwin Core backbone
databases.

## Quick Start

``` r

# install.packages("pak")
pak::pak("gcol33/taxify")

# Match names against WFO (downloads backbone on first use, ~120 MB)
taxify(c("Quercus robur", "Pinus sylvestris", "Quercus robus"))
#>       input_name   matched_name  accepted_name    taxon_id match_type
#> 1  Quercus robur  Quercus robur  Quercus robur wfo-0000001      exact
#> 2 Pinus sylvestr. Pinus sylvestr. Pinus sylvestr. wfo-0000005      exact
#> 3  Quercus robus  Quercus robur  Quercus robur wfo-0000001      fuzzy
```

## Statement of Need

taxize was removed from CRAN in October 2024 because its API
dependencies rotted. WorldFlora works offline but only covers WFO,
chokes on large batches, and requires manual hacks for hybrid names,
encoding issues, and authorship extraction.

taxify solves this with:

- **Offline-first matching** against local Darwin Core snapshots (no API
  calls)
- **Multi-backend architecture** (WFO now, COL and GBIF planned)
- **Hybrid-native parsing** that handles `x`, `\u00d7`, and formula
  hybrids
- **Fuzzy matching in C** via vectra’s Damerau-Levenshtein, Levenshtein,
  and Jaro-Winkler implementations
- **Unified 15-column output** regardless of which backend matched the
  name
- **Pipe extensions** for extra detail without bloating the core result

## Features

### Matching

- Exact match (case-sensitive and case-insensitive)
- Fuzzy match with configurable algorithm and threshold
- Synonym resolution to accepted names
- Best-match selection (ACCEPTED \> SYNONYM, SPECIES \> higher ranks)

### Name Cleaning

- Authorship stripping (parenthesized and trailing)
- Qualifier detection (cf., aff., s.l., s.str., agg.)
- Hybrid marker normalization (`\u00d7`, `x`, `X`)
- Bracket, number, and whitespace cleanup

### Pipe Extensions

``` r

taxify(names) |>
  add_hybrid_info()      # hybrid parents and type
  add_wfo_info()         # extra WFO columns
  add_qualifier_info()   # qualifier and position
```

## Installation

``` r

# Install from GitHub
pak::pak("gcol33/taxify")

# taxify depends on vectra (also from GitHub)
pak::pak("gcol33/vectra")
```

## Usage

``` r

library(taxify)

# Basic matching (fuzzy on by default)
result <- taxify(c(
  "Quercus robur L.",           # strips authorship, exact match
  "Pinus cf. sylvestris",       # strips qualifier, exact match
  "Quercus robus",              # typo, fuzzy match
  "Quercus pedunculata",        # synonym, resolves to Q. robur
  "Quercus x hispanica",        # hybrid detection
  "Nonexistent species"         # no match
))

# Disable fuzzy
taxify("Quercus robus", fuzzy = FALSE)

# Change algorithm
taxify("Quercus robus", fuzzy_method = "jw", fuzzy_threshold = 0.15)

# Enrich with hybrid info
taxify("Quercus pyrenaica x Q. petraea") |>
  add_hybrid_info()
```

## Documentation

- [`?taxify`](https://gcol33.github.io/taxify/reference/taxify.md) –
  main function reference
- [`?add_hybrid_info`](https://gcol33.github.io/taxify/reference/add_hybrid_info.md)
  – hybrid extension
- [`?add_wfo_info`](https://gcol33.github.io/taxify/reference/add_wfo_info.md)
  – WFO extension
- [`?add_qualifier_info`](https://gcol33.github.io/taxify/reference/add_qualifier_info.md)
  – qualifier extension

## License

MIT
