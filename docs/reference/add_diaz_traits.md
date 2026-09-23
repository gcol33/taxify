# Add seed mass and plant height (Diaz et al. 2022)

Joins species-level mean seed mass and plant height from Diaz et al.
(2022) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_diaz_traits(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- seed_mass_mg:

  Seed mass in milligrams (species-level mean).

- plant_height_m:

  Plant height in metres (species-level mean).

## Details

Source: Diaz et al. 2022, TRY File Archive (CC BY 3.0). Coverage: ~46k
plant species. Plants only.

## References

Diaz S, Kattge J, Cornelissen JHC, Wright IJ, Lavorel S, Dray S, Reu B,
Kleyer M, Wirth C, Prentice IC, et al. (2022) The global spectrum of
plant form and function: enhanced species-level trait dataset.
Scientific Data 9:755.
[doi:10.1038/s41597-022-01774-9](https://doi.org/10.1038/s41597-022-01774-9)

Diaz S, Kattge J, Cornelissen JHC, Wright IJ, Lavorel S, Dray S, Reu B,
Kleyer M, Wirth C, Prentice IC, et al. (2016) The global spectrum of
plant form and function. Nature 529:167-171.
[doi:10.1038/nature16489](https://doi.org/10.1038/nature16489)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_diaz_traits()

options(old)
```
