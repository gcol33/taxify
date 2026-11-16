# Show backbone coverage for a genus

Queries `backend_coverage.vtr` to determine which backbones contain the
given genus, along with the backbone version at time of indexing.

## Usage

``` r
taxify_register_coverage(genus)
```

## Arguments

- genus:

  Character scalar. The genus name to query.

## Value

A data.frame with columns `genus`, `backbone`, `version`, `date_added`.
Returns a zero-row data.frame if the genus is not found in any backbone.
`version` and `date_added` describe the indexed backbone when the
coverage table was built; they do not report the locally installed
build.

## See also

[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md),
[`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md)

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md),
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md),
[`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md),
[`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md),
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md),
[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md),
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md),
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data(),
               taxify.offline = TRUE)
taxify_register_coverage("Quercus")
#>     genus backbone version date_added
#> 1 Quercus      wfo 2026.06 2026-07-22
#> 2 Quercus     wcvp 2026.06 2026-07-22
#> 3 Quercus      ott   3.7.3 2026-07-22
#> 4 Quercus     ncbi 2026.06 2026-07-22
#> 5 Quercus     lcvp   3.0.1 2026-07-22
#> 6 Quercus     itis 2026.06 2026-07-22
#> 7 Quercus     gbif current 2026-06-25
#> 8 Quercus  euromed 2026.07 2026-07-11
#> 9 Quercus      col 2026.06 2026-07-22
options(old)
```
