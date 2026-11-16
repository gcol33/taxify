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
  family_col = NULL,
  genus_col = NULL,
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

  Name of the family column, or `NULL` for a backbone without one (a
  syntaxon backbone); `accepted_family` is then not added.

- genus_col:

  Name of the genus column, or `NULL` likewise.

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

## See also

Other Low-level building blocks:
[`basionym_placement()`](https://gillescolling.com/taxify/reference/basionym_placement.md),
[`candidate_order()`](https://gillescolling.com/taxify/reference/candidate_order.md),
[`enrichment_authorship_col()`](https://gillescolling.com/taxify/reference/enrichment_authorship_col.md),
[`is_aggregate_name()`](https://gillescolling.com/taxify/reference/is_aggregate_name.md),
[`normalize_aggregate_name()`](https://gillescolling.com/taxify/reference/normalize_aggregate_name.md),
[`normalize_epithets()`](https://gillescolling.com/taxify/reference/normalize_epithets.md),
[`precompute_keys()`](https://gillescolling.com/taxify/reference/precompute_keys.md),
[`score_candidates()`](https://gillescolling.com/taxify/reference/score_candidates.md)

## Examples

``` r
df <- data.frame(id = c("1", "2"), accepted = c("1", "1"),
                 name = c("Picea abies", "Pinus abies"),
                 status = c("ACCEPTED", "SYNONYM"))
embed_accepted(df, "id", "accepted", "name", status_col = "status")
#>   id accepted        name   status accepted_name accepted_taxon_id
#> 1  1        1 Picea abies ACCEPTED   Picea abies                 1
#> 2  2        1 Pinus abies  SYNONYM   Picea abies                 1
#>   accepted_authorship is_synonym
#> 1                <NA>      FALSE
#> 2                <NA>       TRUE
```
