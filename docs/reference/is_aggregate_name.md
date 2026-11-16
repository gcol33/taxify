# Test whether a canonical name carries an aggregate marker

`TRUE` for names ending in any aggregate marker spelling (`agg.`,
`aggr.`, `-agg`, `s.l.`, `sensu lato`, `coll. sp.`). Exported for the
taxifydb build pipeline so it can keep aggregate source rows out of
cross-backbone name expansion (which would otherwise leak an aggregate
trait onto the binomial species key).

## Usage

``` r
is_aggregate_name(x)
```

## Arguments

- x:

  Character vector of canonical names.

## Value

Logical vector; `FALSE` for `NA`.

## See also

Other Low-level building blocks:
[`basionym_placement()`](https://gillescolling.com/taxify/reference/basionym_placement.md),
[`candidate_order()`](https://gillescolling.com/taxify/reference/candidate_order.md),
[`embed_accepted()`](https://gillescolling.com/taxify/reference/embed_accepted.md),
[`enrichment_authorship_col()`](https://gillescolling.com/taxify/reference/enrichment_authorship_col.md),
[`normalize_aggregate_name()`](https://gillescolling.com/taxify/reference/normalize_aggregate_name.md),
[`normalize_epithets()`](https://gillescolling.com/taxify/reference/normalize_epithets.md),
[`precompute_keys()`](https://gillescolling.com/taxify/reference/precompute_keys.md),
[`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)

## Examples

``` r
is_aggregate_name(c("Rubus fruticosus agg.", "Quercus robur", NA))
#> [1]  TRUE FALSE FALSE
```
