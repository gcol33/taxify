# Add European bat traits (EuroBaTrait)

Joins species-level traits of European bats (morphology, life history,
diet, foraging habitat, roost type) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_eurobat(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns. The curated set:

- eurobat_forearm_length_mm:

  Forearm length (mm).

- eurobat_body_mass_g:

  Body mass (g).

- eurobat_max_longevity_yr:

  Maximum recorded longevity (years).

- eurobat_litter_size:

  Litter size.

- eurobat_diet_type:

  Diet type (insectivorous, frugivorous, ...).

- eurobat_first_main_prey:

  First main prey item.

With `cols = "all"` the full trait set (digit lengths, wing indices,
habitat affinity scores, critical feeding areas, roost dependence,
phenology, ...) is attached under their source names.

## Details

Source: Froidevaux et al. (2023, Scientific Data, CC BY 4.0),
EuroBaTrait 1.0. Thematic measurement-or-fact tables are reduced to
species-level values (numeric by median, categorical by mode).

## References

Froidevaux JSP et al. (2023) EuroBaTrait 1.0: a species-level trait
dataset of bats in Europe and beyond. Scientific Data. figshare
[doi:10.6084/m9.figshare.21777161](https://doi.org/10.6084/m9.figshare.21777161)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Myotis myotis", backbone = "gbif") |>
  add_eurobat()
} # }
```
