# Embed accepted taxon info at build time (synonym self-join)

Used by the `taxifydb` build pipeline and by taxify's own test fixtures.
For every synonym row, resolves the accepted taxon and embeds its name,
family, genus, and (when `authorship_col` is supplied) authorship
directly. Handles synonym chains by iterating until stable (max 10
hops).

## Usage

``` r
embed_accepted(
  df,
  id_col,
  acc_id_col,
  name_col,
  family_col,
  genus_col,
  status_col,
  synonym_pattern = "SYNONYM",
  authorship_col = NULL
)
```

## Arguments

- df:

  The full backbone data.frame.

- id_col:

  Name of the taxon ID column.

- acc_id_col:

  Name of the accepted name usage ID column.

- name_col:

  Name of the canonical name column.

- family_col:

  Name of the family column.

- genus_col:

  Name of the genus column.

- status_col:

  Name of the taxonomic status column.

- synonym_pattern:

  Regex pattern to detect synonyms in status column.

- authorship_col:

  Optional name of the authorship column. When supplied, the resolved
  accepted name's authorship is embedded as `accepted_authorship` (so a
  synonym row carries the accepted taxon's author, not its own). When
  `NULL`, `accepted_authorship` is filled with `NA`.

## Value

The data.frame with added columns: accepted_name, accepted_family,
accepted_genus, accepted_taxon_id, accepted_authorship, is_synonym.
