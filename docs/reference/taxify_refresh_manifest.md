# Invalidate the session manifest cache

Clears the in-memory catalogue of published builds. The next catalogue
request loads it again, using local metadata when offline mode is
active. Existing assets and their session version-check flags are
unchanged.

## Usage

``` r
taxify_refresh_manifest()
```

## Value

`NULL`, invisibly.

## See also

[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md),
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md)

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
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md),
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md),
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)

## Examples

``` r
old <- options(taxify.offline = TRUE)
taxify_refresh_manifest()
head(list_backbones(verbose = FALSE)[, c("name", "version")])
#>    name version
#> 1   wfo 2026.06
#> 2   col 2026.09
#> 3 colxr 2026.09
#> 4  gbif 2023.08
#> 5  itis 2026.09
#> 6  ncbi 2026.09
options(old)
```
