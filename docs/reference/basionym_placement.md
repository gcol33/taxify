# Find the placed basionym of each unplaced backbone record

The one definition of when a basionym places a record, shared by the
matching engine and taxifydb's name-lookup build. A record qualifies
when the backbone keeps it unplaced (the status grade of
`.status_unplaced`) and its `original_name_usage_id` names another
record that the backbone places: accepted, or a plain synonym, with an
accepted taxon other than the record itself. A basionym that is itself
unplaced, misapplied or absent settles nothing.

## Usage

``` r
basionym_placement(records, basionyms)
```

## Arguments

- records:

  Backbone rows (unified schema) with `taxon_id`, `taxonomic_status`,
  `original_name_usage_id` and optionally `is_synonym`.

- basionyms:

  Backbone rows to find the basionyms among, with `taxon_id`,
  `taxonomic_status`, `accepted_taxon_id` and optionally `is_synonym`.

## Value

Integer vector along `records`: the row of `basionyms` whose accepted
taxon the record belongs to, or `NA`.

## See also

Other Low-level building blocks:
[`candidate_order()`](https://gillescolling.com/taxify/reference/candidate_order.md),
[`embed_accepted()`](https://gillescolling.com/taxify/reference/embed_accepted.md),
[`enrichment_authorship_col()`](https://gillescolling.com/taxify/reference/enrichment_authorship_col.md),
[`is_aggregate_name()`](https://gillescolling.com/taxify/reference/is_aggregate_name.md),
[`normalize_aggregate_name()`](https://gillescolling.com/taxify/reference/normalize_aggregate_name.md),
[`normalize_epithets()`](https://gillescolling.com/taxify/reference/normalize_epithets.md),
[`precompute_keys()`](https://gillescolling.com/taxify/reference/precompute_keys.md),
[`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)

## Examples

``` r
records <- data.frame(taxon_id = "2", taxonomic_status = "UNPLACED",
                      original_name_usage_id = "1", is_synonym = FALSE)
basionyms <- data.frame(taxon_id = "1", taxonomic_status = "ACCEPTED",
                       accepted_taxon_id = "1", is_synonym = FALSE)
basionym_placement(records, basionyms)
#> [1] 1
```
