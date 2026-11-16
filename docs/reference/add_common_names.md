# Add common (vernacular) names

Joins vernacular names to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`, filtered by language.

## Usage

``` r
add_common_names(x, lang = "en", cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- lang:

  Character. ISO 639-1 language code (e.g., `"en"`, `"de"`, `"fr"`), or
  `NA` to return names without a language tag (NCBI/OTT sources).
  Default `"en"`. List the languages present with
  `enrichment_groups("common_names")`.

- cols:

  Which columns to attach. `NULL` (the default) attaches the curated
  set; a character vector of column names attaches just those, and
  `"all"` attaches every column the source carries (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with an additional column:

- common_name:

  The vernacular name in the requested language, or `NA` if none is
  available.

## Details

Common names are merged from three sources:

- GBIF backbone vernacular names (CC0), multi-language via ISO 639-1
  codes.

- NCBI Taxonomy common names (public domain), no language tag
  (`lang = NA`).

- Open Tree of Life common names (CC0), no language tag (`lang = NA`).

When multiple common names exist for a species in the requested
language, the first (most commonly used) is returned.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_common_names()
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Skipped (all names matched)
#>   [lcvp] Skipped (all names matched)
#>   [wfo] Skipped (all names matched)
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>      input_name  matched_name accepted_name   taxon_id accepted_id    rank
#> 1 Quercus robur Quercus robur Quercus robur col-ex-001  col-ex-001 species
#>     family   genus epithet authorship accepted_authorship is_synonym
#> 1 Fagaceae Quercus   robur         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      col
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 col:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type         common_name
#> 1               <NA>                 NA        <NA> example_common_name
#> Sources: COL example, vernacular names example | cite() for full citations

taxify("Quercus robur") |>
  add_common_names(lang = "de")
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Skipped (all names matched)
#>   [lcvp] Skipped (all names matched)
#>   [wfo] Skipped (all names matched)
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>      input_name  matched_name accepted_name   taxon_id accepted_id    rank
#> 1 Quercus robur Quercus robur Quercus robur col-ex-001  col-ex-001 species
#>     family   genus epithet authorship accepted_authorship is_synonym
#> 1 Fagaceae Quercus   robur         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      col
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 col:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type         common_name
#> 1               <NA>                 NA        <NA> example_common_name
#> Sources: COL example, vernacular names example | cite() for full citations

options(old)
```
