# Score match candidates by resolution priority

Computes the per-row priority scores used to rank backbone candidates
for a name (smaller is better): smallest fuzzy distance (`dist_score`),
then ACCEPTED over SYNONYM (`status_score`), SPECIES over higher ranks
(`rank_score`), nomenclaturally Valid (`valid_score`), and
epithet-preserving accepted target (`epithet_score`, the homotypic
basionym among same-name homonym synonyms, e.g. `Pinus abies` -\>
`Picea abies`). Used by the matching engine's best-match selection and,
in the `taxifydb` build pipeline, to collapse each backbone key to the
single accepted name
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
resolves it to.

## Usage

``` r
score_candidates(candidates)
```

## Arguments

- candidates:

  A data.frame with `taxonomicStatus` and `taxonRank`, and optionally
  `fuzzy_dist` (fuzzy proximity), `nomenclaturalStatus` (validity), plus
  `matched_name_std` and `accepted_name` (epithet preservation).

## Value

A list with the numeric vector `dist_score`, integer vectors
`status_score`, `rank_score`, `valid_score`, `epithet_score`, and the
character `tier` signature (`"dist/status/rank/valid/epithet"`) per row,
in input order.

## Details

`dist_score` orders first because candidates for a fuzzy query are
different backbone names: the closest one is the best reading of the
input, and the remaining scores then choose among the rows carrying that
name. It is 0 throughout when `fuzzy_dist` is absent, which is every
exact-match path.
