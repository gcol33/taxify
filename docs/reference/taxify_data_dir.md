# Get the taxify data directory

Returns the directory where taxify stores downloaded backbone and
enrichment `.vtr` files. By default this is the platform-appropriate
per-user data directory returned by
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

## Usage

``` r
taxify_data_dir()
```

## Value

Character string. Path to the data directory.

## Details

The location can be overridden, in order of precedence, by the
`taxify.data_dir` option (`getOption("taxify.data_dir")`) or the
`TAXIFY_DATA_DIR` environment variable. This is useful to point taxify
at a shared cache, or at the small bundled example database returned by
[`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md).

## See also

[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)
to inspect builds,
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md)
to remove them.

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md),
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
identical(taxify_data_dir(), taxify_example_data())
#> [1] TRUE
options(old)
```
