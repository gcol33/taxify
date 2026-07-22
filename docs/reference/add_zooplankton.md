# Add marine zooplankton traits

Joins global marine-zooplankton traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name` (species-level summaries).

## Usage

``` r
add_zooplankton(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `zooplankton_` columns: numeric
`body_length_max_mm`, `carbon_weight_mg`, `nitrogen_pdw_pct`;
categorical `vertical_distribution`, `reproduction_mode`,
`trophic_group`, `feeding_mode`, `myelination`, `habitat_association`,
`diel_vertical_migration`, `bioluminescence`.

## Details

Source: Pata & Hunt global marine zooplankton trait database (Zenodo,
CC-BY-SA 4.0).

## References

Pata PR, Hunt BPV (2025) A global trait database for marine zooplankton.
Zenodo.
[doi:10.5281/zenodo.8102913](https://doi.org/10.5281/zenodo.8102913)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Calanus finmarchicus", backbone = "gbif") |>
  add_zooplankton()
} # }
```
