# Add NZ marine benthos traits (NZTD)

Joins New Zealand marine benthic-invertebrate functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`. Each fuzzy-coded trait is reduced to its
dominant modality.

## Usage

``` r
add_nztd(x, cols = NULL, verbose = TRUE)
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

The same data.frame with categorical `nztd_` columns:
`nztd_bioturbation`, `nztd_body_size`, `nztd_degree_of_attachment`,
`nztd_feeding_mode`, `nztd_living_habit`, `nztd_mobility`,
`nztd_morphology`, `nztd_movement_method`, `nztd_rigidity`.

## Details

Source: NZTD (Lam-Gordillo et al. 2023, figshare, CC-BY 4.0).

## References

Lam-Gordillo O et al. (2023) New Zealand Trait Database (NZTD) for
marine benthic invertebrates. figshare.
[doi:10.6084/m9.figshare.21939647](https://doi.org/10.6084/m9.figshare.21939647)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Macomona liliana", backbone = "gbif") |>
  add_nztd()
} # }
```
