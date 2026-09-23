# Authorship-like column in an enrichment .vtr schema, if any

Grouped enrichments join on a bare accepted-name string (see
`enrich_by_group()`), which collapses distinct homonymous concepts that
happen to share a name. An authorship column is the only signal
available to tell them apart; this picks the first alias present, in
order of how likely it is to be the taxon's own authorship rather than
something else. taxifydb reads the same column at build time, so that
the row it keys under a name is the one this guard will accept.

## Usage

``` r
enrichment_authorship_col(schema_names)
```

## Arguments

- schema_names:

  Character vector of column names in the enrichment `.vtr`.

## Value

The matching column name, or `NULL` if none of the aliases is present.
