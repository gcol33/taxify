# Score match candidates by resolution priority

Computes the per-row priority scores used to rank backbone candidates
for a name (smaller is better): ACCEPTED over SYNONYM (`status_score`),
SPECIES over higher ranks (`rank_score`), nomenclaturally Valid
(`valid_score`), and epithet-preserving accepted target
(`epithet_score`, the homotypic basionym among same-name homonym
synonyms, e.g. `Pinus abies` -\> `Picea abies`). Used by the matching
engine's best-match selection and, in the `taxifydb` build pipeline, to
collapse each backbone key to the single accepted name
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
resolves it to.

## Usage

``` r
score_candidates(candidates)
```

## Arguments

- candidates:

  A data.frame with `taxonomicStatus` and `taxonRank`, and optionally
  `nomenclaturalStatus` (validity), plus `matched_name_std` and
  `accepted_name` (epithet preservation).

## Value

A list with integer vectors `status_score`, `rank_score`, `valid_score`,
`epithet_score`, and the character `tier` signature
(`"status/rank/valid/epithet"`) per row, in input order.
