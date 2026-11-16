# Add invasive species status (GRIIS)

Joins GRIIS (Global Register of Introduced and Invasive Species) status
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by country. This function is named after its source,
GRIIS; GloNAF
([`add_glonaf()`](https://gillescolling.com/taxify/reference/add_glonaf.md))
carries related naturalized-alien status.

## Usage

``` r
add_griis(x, country, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- country:

  Character. ISO 3166-1 alpha-2 country code(s), or `"all"`.

  - Single code (e.g., `"AT"`): adds `griis_invasive_status` column (no
    suffix).

  - Multiple codes (e.g., `c("AT", "DE")`): adds `invasive_status_AT`,
    `invasive_status_DE`.

  - `"all"`: adds one column per country in the dataset.

  List the codes GRIIS covers with `enrichment_groups("griis")`.

- cols:

  Which columns to attach. `NULL` (the default) attaches the curated
  set; a character vector of column names attaches just those, and
  `"all"` attaches every column the source carries (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional column(s):

- griis_invasive_status:

  One of `"native"`, `"introduced"`, `"invasive"`, or `NA` if not
  recorded for that country.

## Details

Source: GRIIS (Zenodo combined CSV, CC BY 4.0, 196 countries). Coverage:
~23k name x country combinations.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Robinia pseudoacacia") |>
  add_griis(country = "AT")
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
#>   accepted_id    rank   family   genus      epithet authorship
#> 1  wfo-ex-006 species Fabaceae Robinia pseudoacacia         L.
#>   accepted_authorship is_synonym taxonomic_status is_hybrid match_type
#> 1                  L.      FALSE         ACCEPTED     FALSE      exact
#>   fuzzy_dist backbone         backbone_version kingdom_group taxon_group
#> 1         NA      wfo wfo:example (2026-06-24)       plantae        <NA>
#>   life_form qualifier qualifier_position aggregate_fallback hybrid_type
#> 1      <NA>      <NA>               <NA>                 NA        <NA>
#>     griis_invasive_status
#> 1 example_invasive_status
#> Sources: WFO example, GRIIS example | cite() for full citations

taxify("Robinia pseudoacacia") |>
  add_griis(country = c("AT", "DE"))
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
#>   accepted_id    rank   family   genus      epithet authorship
#> 1  wfo-ex-006 species Fabaceae Robinia pseudoacacia         L.
#>   accepted_authorship is_synonym taxonomic_status is_hybrid match_type
#> 1                  L.      FALSE         ACCEPTED     FALSE      exact
#>   fuzzy_dist backbone         backbone_version kingdom_group taxon_group
#> 1         NA      wfo wfo:example (2026-06-24)       plantae        <NA>
#>   life_form qualifier qualifier_position aggregate_fallback hybrid_type
#> 1      <NA>      <NA>               <NA>                 NA        <NA>
#>   griis_invasive_status_AT griis_invasive_status_DE
#> 1  example_invasive_status  example_invasive_status
#> Sources: WFO example, GRIIS example | cite() for full citations

options(old)
```
