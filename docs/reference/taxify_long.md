# Reshape grouped enrichment columns to long format

Converts wide-format columns produced by grouped enrichments (e.g.,
`griis_invasive_status_AT`, `griis_invasive_status_DE`) back to long
format with one row per species x group combination.

## Usage

``` r
taxify_long(x, cols = NULL, group_col = NULL, drop_na = FALSE)
```

## Arguments

- x:

  A data.frame, typically a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result after applying a grouped enrichment like
  [`add_griis()`](https://gillescolling.com/taxify/reference/add_griis.md),
  [`add_alien_first_records()`](https://gillescolling.com/taxify/reference/add_alien_first_records.md),
  or
  [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md).

- cols:

  Character vector of base column names to reshape. These are the column
  names without the group suffix (e.g., `"griis_invasive_status"`, not
  `"griis_invasive_status_AT"`). If omitted, auto-detected from the
  enrichment metadata stamped by the `add_*()` functions.

- group_col:

  Character. Name for the output group column. If omitted, auto-detected
  from enrichment metadata (e.g., `"country_code"` for invasive status,
  `"location"` for alien first records).

- drop_na:

  Logical. If `TRUE`, drop rows where all value columns are `NA`.
  Default `FALSE`.

## Value

A data.frame in long format. All columns from `x` that are not part of
the reshape are preserved. The reshaped columns use their base names
(without suffix), and a new `group_col` column contains the group code
extracted from the suffix.

## Details

When `cols` and `group_col` are omitted, `taxify_long()` reads the
reshape metadata attached by grouped enrichment functions
([`add_griis()`](https://gillescolling.com/taxify/reference/add_griis.md),
[`add_alien_first_records()`](https://gillescolling.com/taxify/reference/add_alien_first_records.md),
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md),
[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)).
If multiple grouped enrichments were applied, all are reshaped together
(they must share the same group column).

Column matching uses the explicit base names in `cols` to avoid
ambiguity. For example, given
`cols = c("alien_first_record", "alien_first_record_source")`, the
column `alien_first_record_source_AT` is correctly matched to base
`alien_first_record_source` (not `alien_first_record` with suffix
`source_AT`), because longer base names are matched first.

If the columns in `x` exactly match `cols` (no suffixed variants), the
data is already in single-group format. In this case, the data.frame is
returned unchanged with `group_col` set to `NA`.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Auto-detected: no cols or group_col needed
taxify("Robinia pseudoacacia") |>
  add_alien_first_records(location = c("AT", "DE")) |>
  taxify_long()
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>             input_name         matched_name        accepted_name   taxon_id
#> 1 Robinia pseudoacacia Robinia pseudoacacia Robinia pseudoacacia wfo-ex-006
#> 2 Robinia pseudoacacia Robinia pseudoacacia Robinia pseudoacacia wfo-ex-006
#>   accepted_id    rank   family   genus      epithet authorship
#> 1  wfo-ex-006 species Fabaceae Robinia pseudoacacia         L.
#> 2  wfo-ex-006 species Fabaceae Robinia pseudoacacia         L.
#>   accepted_authorship is_synonym taxonomic_status is_hybrid match_type
#> 1                  L.      FALSE         ACCEPTED     FALSE      exact
#> 2                  L.      FALSE         ACCEPTED     FALSE      exact
#>   fuzzy_dist backbone         backbone_version kingdom_group taxon_group
#> 1         NA      wfo wfo:example (2026-06-24)       plantae        <NA>
#> 2         NA      wfo wfo:example (2026-06-24)       plantae        <NA>
#>   life_form qualifier qualifier_position aggregate_fallback hybrid_type
#> 1      <NA>      <NA>               <NA>                 NA        <NA>
#> 2      <NA>      <NA>               <NA>                 NA        <NA>
#>   location        alien_first_records_reference
#> 1       AT example_alien_first_record_reference
#> 2       DE example_alien_first_record_reference
#>          alien_first_records_source alien_first_records_year
#> 1 example_alien_first_record_source                       11
#> 2 example_alien_first_record_source                       12
#> Sources: WFO example, Alien first records (Seebens et al.) example | cite() for full citations

# Explicit: override auto-detection
taxify("Robinia pseudoacacia") |>
  add_griis(country = c("AT", "DE")) |>
  taxify_long(cols = "griis_invasive_status", group_col = "country")
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>             input_name         matched_name        accepted_name   taxon_id
#> 1 Robinia pseudoacacia Robinia pseudoacacia Robinia pseudoacacia wfo-ex-006
#> 2 Robinia pseudoacacia Robinia pseudoacacia Robinia pseudoacacia wfo-ex-006
#>   accepted_id    rank   family   genus      epithet authorship
#> 1  wfo-ex-006 species Fabaceae Robinia pseudoacacia         L.
#> 2  wfo-ex-006 species Fabaceae Robinia pseudoacacia         L.
#>   accepted_authorship is_synonym taxonomic_status is_hybrid match_type
#> 1                  L.      FALSE         ACCEPTED     FALSE      exact
#> 2                  L.      FALSE         ACCEPTED     FALSE      exact
#>   fuzzy_dist backbone         backbone_version kingdom_group taxon_group
#> 1         NA      wfo wfo:example (2026-06-24)       plantae        <NA>
#> 2         NA      wfo wfo:example (2026-06-24)       plantae        <NA>
#>   life_form qualifier qualifier_position aggregate_fallback hybrid_type country
#> 1      <NA>      <NA>               <NA>                 NA        <NA>      AT
#> 2      <NA>      <NA>               <NA>                 NA        <NA>      DE
#>     griis_invasive_status
#> 1 example_invasive_status
#> 2 example_invasive_status
#> Sources: WFO example, GRIIS example | cite() for full citations

options(old)
```
