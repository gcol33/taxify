# Add mammal traits from COMBINE (phylogenetically imputed values)

Joins the phylogenetically imputed COMBINE table to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. This is the companion to
[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md):
the same ~6.2k mammal species, but with the cells the reported table
leaves missing filled in by COMBINE's phylogenetic multiple-imputation
model, giving near-complete coverage for the life-history traits.
Imputed values are model estimates, not measurements, so they are
attached under their own `combine_imputed_*` columns rather than
replacing the reported values.

## Usage

``` r
add_combine_imputed(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns, mirroring
[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md)
but named `combine_imputed_*` (e.g. `combine_imputed_adult_mass_g`,
`combine_imputed_gestation_length_d`). Traits COMBINE does not impute
(for example `biogeographical_realm` and `habitat_breadth_n`) carry the
reported coverage; the life-history traits (gestation, weaning,
longevity, litter size, generation length, ...) are near-complete.

## Details

Source: COMBINE (Soria et al. 2021, Ecology, CC0), imputed table
(`trait_data_imputed.csv`). Same species set and column meanings as
[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md);
the difference is coverage. Because imputation only fills gaps, applying
both doors and comparing `combine_*` with `combine_imputed_*` shows
which values are measured versus estimated.

## References

Soria CD et al. (2021) COMBINE: a coalesced mammal database of intrinsic
and extrinsic traits. Ecology 102:e03344.
[doi:10.1002/ecy.3344](https://doi.org/10.1002/ecy.3344)

## See also

[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md)
for the measured values.

## Examples

``` r
# \donttest{
# Compare reported vs imputed gestation length for a mammal:
taxify("Vulpes vulpes", backend = "gbif") |>
  add_combine_reported() |>
  add_combine_imputed()
# }
```
