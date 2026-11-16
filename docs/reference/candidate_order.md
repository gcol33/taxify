# Order match candidates by resolution priority

The single source of truth for the candidate sort: the fuzzy distance,
whether the key has occurrence records, the remaining concept scores of
[`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)
in tier order, publication priority where applicable, the occurrence
count, then the nomenclatural-validity tiebreak, then the lowest
`taxonID`. Pass `group_col` to sort within groups first, so the first
row of each group is that group's best candidate.

## Usage

``` r
candidate_order(candidates, scores = NULL, group_col = NULL)
```

## Arguments

- candidates:

  A data.frame accepted by
  [`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md),
  carrying a `taxonID` column and, when `group_col` is given, that
  column too.

- scores:

  The
  [`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)
  output for `candidates`, when it has already been computed; recomputed
  when `NULL`.

- group_col:

  Character or `NULL`. Column to sort by ahead of the scores.

## Value

An integer permutation of `seq_len(nrow(candidates))`.

## See also

Other Low-level building blocks:
[`basionym_placement()`](https://gillescolling.com/taxify/reference/basionym_placement.md),
[`embed_accepted()`](https://gillescolling.com/taxify/reference/embed_accepted.md),
[`enrichment_authorship_col()`](https://gillescolling.com/taxify/reference/enrichment_authorship_col.md),
[`is_aggregate_name()`](https://gillescolling.com/taxify/reference/is_aggregate_name.md),
[`normalize_aggregate_name()`](https://gillescolling.com/taxify/reference/normalize_aggregate_name.md),
[`normalize_epithets()`](https://gillescolling.com/taxify/reference/normalize_epithets.md),
[`precompute_keys()`](https://gillescolling.com/taxify/reference/precompute_keys.md),
[`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)

## Examples

``` r
candidates <- data.frame(
  taxonID = c("2", "1"), taxonomicStatus = c("SYNONYM", "ACCEPTED"),
  taxonRank = "SPECIES", is_synonym = c(TRUE, FALSE)
)
candidates[candidate_order(candidates), ]
#>   taxonID taxonomicStatus taxonRank is_synonym
#> 2       1        ACCEPTED   SPECIES      FALSE
#> 1       2         SYNONYM   SPECIES       TRUE
```
