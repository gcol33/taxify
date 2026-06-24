# Add common (vernacular) names

Joins vernacular names to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`, filtered by language.

## Usage

``` r
add_common_names(x, lang = "en", verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- lang:

  Character. ISO 639-1 language code (e.g., `"en"`, `"de"`, `"fr"`), or
  `NA` to return names without a language tag (NCBI/OTT sources).
  Default `"en"`.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with an additional column:

- common_name:

  The vernacular name in the requested language, or `NA` if none is
  available.

## Details

Common names are merged from three sources:

- GBIF backbone vernacular names (CC0) — multi-language via ISO 639-1
  codes.

- NCBI Taxonomy common names (public domain) — no language tag
  (`lang = NA`).

- Open Tree of Life common names (CC0) — no language tag (`lang = NA`).

When multiple common names exist for a species in the requested
language, the first (most commonly used) is returned.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_common_names()

taxify("Quercus robur") |>
  add_common_names(lang = "de")

options(old)
```
