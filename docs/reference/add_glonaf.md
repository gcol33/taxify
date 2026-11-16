# Add naturalized alien flora status (GloNAF)

Joins GloNAF (Global Naturalized Alien Flora) data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, filtered by region.

## Usage

``` r
add_glonaf(x, region, verbose = TRUE, cols = NULL)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- region:

  Character. GloNAF region identifier(s), or `"all"`. Regions are ISO
  3166 alpha-3 country codes extended with dot notation for sub-national
  units (e.g., `"DEU"` for Germany, `"USA.CA"` for California). List
  them with `enrichment_groups("glonaf")`.

  - Single region: adds `glonaf_naturalized` column (no suffix).

  - Multiple regions: adds `glonaf_naturalized_<region>` columns.

  - `"all"`: adds one column per region in the dataset.

- verbose:

  Logical. Default `TRUE`.

- cols:

  Which columns to attach. `NULL` (the default) attaches the curated
  set; a character vector of column names attaches just those, and
  `"all"` attaches every column the source carries (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)).

## Value

The same data.frame with additional column(s):

- glonaf_naturalized:

  `1` if the species is recorded as naturalized in that region, `NA`
  otherwise.

## Details

Source: GloNAF v2.0 (van Kleunen et al. 2019, Davis et al. 2025, CC BY
4.0). Coverage: ~16k alien plant taxa across ~1,300 regions. Plants
only.

## References

van Kleunen M et al. (2019) The Global Naturalized Alien Flora (GloNAF)
database. Ecology 100:e02542.
[doi:10.1002/ecy.2542](https://doi.org/10.1002/ecy.2542)

Davis AJS et al. (2025) The updated Global Naturalized Alien Flora
(GloNAF 2.0) database. Ecology 106:e70245.
[doi:10.1002/ecy.70245](https://doi.org/10.1002/ecy.70245)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Robinia pseudoacacia") |>
  add_glonaf(region = "DEU")
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
#>   glonaf_naturalized
#> 1                  1
#> Sources: WFO example, GloNAF example | cite() for full citations

taxify("Robinia pseudoacacia") |>
  add_glonaf(region = c("DEU", "AUT"))
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
#>   glonaf_naturalized_DEU glonaf_naturalized_AUT
#> 1                      1                      1
#> Sources: WFO example, GloNAF example | cite() for full citations

options(old)
```
