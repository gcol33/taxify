# Add earthworm traits (Pelosi et al. 2014)

Joins fuzzy-coded earthworm functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Output columns are prefixed
`betsi_ew_`.

## Usage

``` r
add_betsi_earthworm_traits(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) all, or a character vector
  of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns, one per modality bin of
seven fuzzy-coded traits: body length, body mass to length ratio, cocoon
diameter, epithelium, typhlosolis, soil carbon preference and vertical
distribution. Each trait is fuzzy coded, so a species' affinities across
the bins of one trait (columns sharing a `betsi_ew_<trait>__` stem) sum
to 100. See
[`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md)
for the full column list.

## Details

Source: earthworm functional traits compiled from the BETSI database
(Biological and Ecological Traits of Soil Invertebrates) and published
in Pelosi et al. (2014), Appendix 1. Coverage: 11 species. Earthworm
body length and soil carbon preference are given as fuzzy affinity
vectors rather than a single value, so they are not passed to the scalar
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
verb.

## References

Pelosi C, Pey B, Hedde M, et al. (2014) Reducing tillage in cultivated
fields increases earthworm functional diversity. Applied Soil Ecology
83:79-87.
[doi:10.1016/j.apsoil.2013.10.005](https://doi.org/10.1016/j.apsoil.2013.10.005)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Lumbricus terrestris", backbone = "gbif") |>
  add_betsi_earthworm_traits()
} # }
```
