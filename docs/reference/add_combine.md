# Add mammal traits (COMBINE)

The default COMBINE door. Attaches the reported (measured or literature
compiled) trait values and fills each still-missing cell from COMBINE's
phylogenetically imputed table, so a single call reaches the fullest
coverage COMBINE offers. A measurement is never overwritten: the
reported value wins wherever it exists and the imputed model only fills
gaps. Beside every trait sits a `<trait>_src` column recording where
that cell came from – `"reported"`, `"imputed"`, or `NA` when neither
table has it – so a model estimate is always distinguishable from a
measurement.

## Usage

``` r
add_combine(x, cols = NULL, verbose = TRUE)
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

The same data.frame with the `combine_*` trait columns (reported values,
gaps filled from the imputed table) and, beside each, a `combine_*_src`
column tagging that cell as `"reported"`, `"imputed"`, or `NA`. Traits
COMBINE does not impute (for example `combine_biogeographical_realm`)
come out `"reported"` wherever present. If the imputed table is
unavailable, the reported values are returned with every `_src` tag
`"reported"` or `NA`.

## Details

For a single-table view use
[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md)
(measured values only) or
[`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md)
(the imputed table on its own).

## See also

[`add_combine_reported()`](https://gillescolling.com/taxify/reference/add_combine_reported.md),
[`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Coverage-filled values with per-trait provenance:
res <- taxify("Osphranter rufus", backbone = "col") |>
  add_combine()
res[, c("combine_gestation_length_d", "combine_gestation_length_d_src")]
} # }
```
