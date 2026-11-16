# Builds of a taxify asset held on disk

Lists each backbone and enrichment build in the data directory: the
active one under `latest/`, and any other build in a directory named for
its content id (the md5 of its `.vtr`, the same string
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
records). By default a refresh replaces a build in place, so an asset
has one build; the others come from restoring a pinned build or from the
`taxify.keep_*_versions` options below.
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md)
removes them.

## Usage

``` r
taxify_store(asset = NULL)
```

## Arguments

- asset:

  Character. One or more backbone or enrichment names to list. `NULL`
  (default) lists every asset in the data directory.

## Value

A data.frame with one row per build on disk, columns: `component`,
`type` (`"backbone"`/`"enrichment"`), `slot` (the store directory:
`"latest"` for the active build, else its content id), `active`,
`version`, `content_id`, `pinned`, `size_mb`, `downloaded_at`.

## Details

Use this to see which pinned builds a lockfile could be restored to
without a download, and how much disk each asset takes.

## Options

`taxify.keep_enrichment_versions` and `taxify.keep_backbone_versions`
(both default `FALSE`) keep the build a refresh replaces, under its
content id. Restoring a pinned build archives the build it replaces
either way.

## See also

[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
to record a build,
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
to check or reinstall one,
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
to fetch one by content id,
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md)
to remove builds.

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
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md),
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())
head(taxify_store())
#>          component     type   slot active version
#> 1 backend_coverage backbone latest   TRUE 2026.07
#> 2              col backbone latest   TRUE example
#> 3              evc backbone latest   TRUE example
#> 4         fishbase backbone latest   TRUE example
#> 5             gbif backbone latest   TRUE example
#> 6   genus_register backbone latest   TRUE 2026.07
#>                         content_id pinned size_mb downloaded_at
#> 1 c9be15f2051c6bb97a6df86662a1e1b0  FALSE     0.0    2026-07-22
#> 2                             <NA>  FALSE     0.0          <NA>
#> 3                             <NA>  FALSE     0.2          <NA>
#> 4                             <NA>  FALSE     0.0          <NA>
#> 5                             <NA>  FALSE     0.0          <NA>
#> 6 a80a3d2999770a4e73191aa8be7faa85  FALSE     0.0    2026-07-22
options(old)
```
