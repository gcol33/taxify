# Add Collembola traits (Data INRAE deposits)

Joins fuzzy-coded springtail functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Output columns are prefixed
`inrae_`.

## Usage

``` r
add_inrae_collembola_traits(x, cols = NULL, verbose = TRUE)
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
seven fuzzy-coded traits: number of ocelli, furca, post-antennal organ,
pigmentation, body shape, scales and reproduction. Each trait is fuzzy
coded, so a species' affinities across the bins of one trait (columns
sharing an `inrae_<trait>__` stem) sum to 100. The source is sparse, so
a trait a species was not scored for is `NA` across its bins. See
[`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md)
for the full column list.

## Details

Source: fuzzy-coded Collembola traits compiled from the BETSI database
(Pey et al. 2014) across two Data INRAE deposits, the datasets behind
Joimel et al. (2021). Coverage: 135 species. The deposits' species codes
carry no published legend and are decoded against a Collembola reference
pool; codes that cannot be resolved are dropped, never guessed. The
fuzzy affinity vectors are not passed to the scalar
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
verb.

## References

Joimel S et al. (2021) Collembola are among the most flexible soil
fauna: a comparison across land uses. Frontiers in Ecology and Evolution
9:630919.
[doi:10.3389/fevo.2021.630919](https://doi.org/10.3389/fevo.2021.630919)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Isotoma viridis", backbone = "gbif") |>
  add_inrae_collembola_traits()
} # }
```
