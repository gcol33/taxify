# Normalize aggregate markers on canonical names (build-time)

Folds every aggregate marker a backbone or enrichment source may use to
one canonical form, `"<binomial> aggr."`, so taxify's matching engine
and enrichment join recognize aggregates uniformly regardless of source
spelling. Two cases are handled:

- a name already carrying a marker (`agg.`, `aggr.`, `-agg`, `s.l.`,
  `sensu lato`, `coll. sp.`) is rewritten to `"<binomial> aggr."`;

- a name at an aggregate *rank* (`taxon_rank` such as
  `"SPECIES AGGREGATE"`, `"AGGR."`, `"COLL. SP."`) that carries no
  marker gets `" aggr."` appended.

Exported for the taxifydb build pipeline so the build and runtime sides
share one definition.

## Usage

``` r
normalize_aggregate_name(name, rank = NULL)
```

## Arguments

- name:

  Character vector of canonical names.

- rank:

  Optional character vector of taxon ranks, the same length as `name`.
  When supplied, aggregate-rank rows without a marker are suffixed.

## Value

`name` with aggregate markers normalized to `" aggr."`.

## See also

Other Low-level building blocks:
[`basionym_placement()`](https://gillescolling.com/taxify/reference/basionym_placement.md),
[`candidate_order()`](https://gillescolling.com/taxify/reference/candidate_order.md),
[`embed_accepted()`](https://gillescolling.com/taxify/reference/embed_accepted.md),
[`enrichment_authorship_col()`](https://gillescolling.com/taxify/reference/enrichment_authorship_col.md),
[`is_aggregate_name()`](https://gillescolling.com/taxify/reference/is_aggregate_name.md),
[`normalize_epithets()`](https://gillescolling.com/taxify/reference/normalize_epithets.md),
[`precompute_keys()`](https://gillescolling.com/taxify/reference/precompute_keys.md),
[`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)

## Examples

``` r
normalize_aggregate_name(c("Rubus fruticosus agg.", "Quercus robur"))
#> [1] "Rubus fruticosus aggr." "Quercus robur"         
```
