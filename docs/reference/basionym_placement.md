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
