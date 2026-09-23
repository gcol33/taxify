# Score match candidates by resolution priority

Computes the per-row priority scores used to rank backbone candidates
for a name (smaller is better): smallest fuzzy distance (`dist_score`),
then taxonomic status (`status_score`: accepted, then a synonym
homotypic with its accepted name, then a name the backbone keeps but has
not reviewed, then any other synonym, then a misapplication), SPECIES
over higher ranks (`rank_score`), the epithet-preserving accepted target
(`epithet_score`, the homotypic basionym among same-name homonym
synonyms, e.g. `Pinus abies` -\> `Picea abies`), and finally
nomenclatural validity (`valid_score`). Used by the matching engine's
best-match selection and, in the `taxifydb` build pipeline, to collapse
each backbone key to the single accepted name
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
resolves it to.

## Usage

``` r
score_candidates(candidates)
```

## Arguments

- candidates:

  A data.frame with `taxonomicStatus` and `taxonRank`, and optionally
  `is_synonym` (the backbone's normalized synonym flag), `fuzzy_dist`
  (fuzzy proximity), `nomenclaturalStatus` (validity),
  `matched_name_std` and `accepted_name` (epithet preservation), plus
  `authorship` and `accepted_authorship` (homotypy). Two scores read the
  candidate's `n_occurrences` (records filed under its key, a column
  only the GBIF backbone carries), both 0 throughout when the column is
  absent and both outside the tier: which key holds the data is not a
  statement about which taxon the name denotes. `data_score` is 0 for a
  key with at least one record that keeps the name as its own concept
  (accepted, doubtful or unplaced; never a synonym, whose accepted ID is
  another taxon) and 1 otherwise (no records, no count, or a synonym);
  it orders after `dist_score` and before `status_score`. `occ_score` is
  minus the count, `Inf` where it is missing; it orders after
  `epithet_score`, so it only separates keys the concept scores leave
  level. `year_score` is the year the name was published (the `year`
  column, else the first year in `name_published_in`; `Inf` where
  unknown, 0 throughout when both columns are absent); it orders after
  `epithet_score` and before `occ_score`, so the earliest of several
  same-name homonyms wins before the count is read.

## Value

A list with the numeric vectors `dist_score`, `data_score`,
`year_score`, `occ_score` and `status_score`, integer vectors
`rank_score`, `valid_score`, `epithet_score`, and the character `tier`
signature (`"dist/status/rank/epithet"`) per row, in input order.

## Details

`dist_score` orders first because candidates for a fuzzy query are
different backbone names: the closest one is the best reading of the
input, and the remaining scores then choose among the rows carrying that
name. It is 0 throughout when `fuzzy_dist` is absent, which is every
exact-match path.

The returned `tier` covers the four concept scores only. `valid_score`
orders the pick but stays out of the tier: a nomenclaturally valid name
can be a synonym of a different species than an illegitimate one
carrying the same string, so validity must not make that conflict look
resolved. Sort with
[`candidate_order()`](https://gillescolling.com/taxify/reference/candidate_order.md)
rather than re-listing the columns.

A synonym counts as homotypic when its own basionym author is the
accepted name's parenthetical author and the accepted name keeps its
final epithet (`Lycopsis orientalis` L. -\>
`Anchusa arvensis subsp. orientalis` (L.) Nordh.). That outranks a
record the backbone keeps unplaced under the same string, which is a
different type: a homonym, not the name the placed record carries (#81).
