# Order match candidates by resolution priority

The single source of truth for the candidate sort: the four concept
scores of
[`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)
in tier order, then the nomenclatural-validity tiebreak, then the lowest
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
