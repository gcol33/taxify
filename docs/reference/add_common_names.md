# Add common (vernacular) names

Joins GBIF vernacular names to a
[`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md) result
by looking up `accepted_name`, filtered by language.

## Usage

``` r
add_common_names(x, lang = "en", verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md).

- lang:

  Character. ISO 639-1 language code (e.g., `"en"`, `"de"`, `"fr"`).
  Default `"en"`.

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with an additional column:

- common_name:

  The vernacular name in the requested language, or `NA` if none is
  available.

## Details

Source: GBIF backbone vernacular names (CC0). Multi-language via ISO
639-1 codes. When multiple common names exist for a species in the
requested language, the first (most commonly used) is returned.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Quercus robur") |>
  add_common_names()

taxify("Quercus robur") |>
  add_common_names(lang = "de")
} # }
```
