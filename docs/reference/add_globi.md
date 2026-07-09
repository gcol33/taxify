# Add biotic interaction degree (GloBI)

Joins per-species biotic interaction breadth from GloBI (Global Biotic
Interactions) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. GloBI's aggregated interaction
records are reduced to per-species counts: how many distinct partner
taxa a species interacts with (undirected), across how many distinct
interaction types, over how many interaction records.

## Usage

``` r
add_globi(x, cols = NULL, verbose = TRUE)
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

- interaction_degree:

  Number of distinct partner taxa recorded interacting with the species
  (both directions).

- n_interaction_types:

  Number of distinct interaction types (eats, pollinates, parasitises,
  ...).

- n_interaction_records:

  Total number of interaction records touching the species.

## Details

Source: GloBI (Poelen et al. 2014), an open index of biotic interactions
aggregated from many contributed datasets. Only derived per-species
counts are distributed here; the underlying interaction records carry
the licenses of their original data contributors, who should be cited in
derivative work. Partner counts are resolved to accepted names before
counting, so synonymous partners are not double-counted.

## References

Poelen JH, Simons JD, Mungall CJ (2014) Global Biotic Interactions: An
open infrastructure to share and analyze species-interaction datasets.
Ecological Informatics 24:148-159. doi:10.1016/j.ecoinf.2014.08.005

## Examples

``` r
# \donttest{
taxify("Apis mellifera", backend = "gbif") |>
  add_globi()
# }
```
