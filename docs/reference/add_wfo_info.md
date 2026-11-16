# Add WFO-specific columns

Joins extra World Flora Online columns to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `taxon_id` in the WFO backbone.

## Usage

``` r
add_wfo_info(x)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  with `backbone == "wfo"`.

## Value

The same data.frame with additional columns:

- scientificNameID:

  WFO scientificNameID.

- parentNameUsageID:

  WFO parentNameUsageID.

- name_published_in:

  Publication reference, under the name every backbone's `.vtr` and
  [`add_gbif_info()`](https://gillescolling.com/taxify/reference/add_gbif_info.md)
  use.

- higherClassification:

  Higher classification string.

- taxonRemarks:

  Taxonomic remarks.

- infraspecificEpithet:

  Infraspecific epithet (for subspecies, varieties, forms).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_wfo_info()
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
#>   qualifier_position aggregate_fallback hybrid_type scientificNameID
#> 1               <NA>                 NA        <NA>             <NA>
#>   parentNameUsageID name_published_in higherClassification taxonRemarks
#> 1              <NA>              <NA>                 <NA>         <NA>
#>   infraspecificEpithet
#> 1                 <NA>
#> Sources: COL example | cite() for full citations

options(old)
```
