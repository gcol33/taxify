# Clear cached backbone paths and matching data

Clears the session's backbone paths, fuzzy-match blocks and temporary
fuzzy files. The next match reads the downloaded backbone files again.

## Usage

``` r
taxify_clear_cache()
```

## Value

`NULL`, invisibly.

## Details

Downloaded builds stay on disk. The genus register, enrichment caches
and manifest cache are separate session state.

## See also

[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md)
to remove downloaded builds,
[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md)
to clear the manifest cache.

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md),
[`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md),
[`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md),
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md),
[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md),
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md),
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md),
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data(),
               taxify.offline = TRUE)
taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
#>      input_name  matched_name accepted_name   taxon_id accepted_id    rank
#> 1 Quercus robur Quercus robur Quercus robur wfo-ex-001  wfo-ex-001 species
#>     family   genus epithet authorship accepted_authorship is_synonym
#> 1 Fagaceae Quercus   robur         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      wfo
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 wfo:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type
#> 1               <NA>                 NA        <NA>
#> Sources: WFO example | cite() for full citations
taxify_clear_cache()
options(old)
```
