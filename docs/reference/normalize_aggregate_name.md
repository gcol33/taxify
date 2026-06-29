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
