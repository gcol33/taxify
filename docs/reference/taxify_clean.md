# Remove downloaded taxify data

Frees disk space in the data directory
([`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)).
Called with no arguments it removes what taxify no longer reads: builds
replaced by a newer one or kept by version, and files left by an
interrupted download. The active build of every backbone and enrichment
stays, unless `unused_days` is given. Name assets to remove them
completely, or pass `"all"` to delete the data directory.

## Usage

``` r
taxify_clean(
  assets = NULL,
  unused_days = NULL,
  dry_run = FALSE,
  verbose = TRUE
)
```

## Arguments

- assets:

  `NULL` (default) for superseded builds and interrupted downloads, a
  character vector of backbone or enrichment names to remove completely,
  or `"all"` for the whole data directory.

- unused_days:

  Number or `NULL`. With `assets = NULL`, also remove every outdated
  build, the active one included, not read or downloaded for this many
  days.

- dry_run:

  Logical. `FALSE` (default) removes the selected paths. `TRUE` returns
  the removal plan and leaves files in place.

- verbose:

  Logical. `TRUE` (default) reports the space freed or planned.

## Value

Invisibly, a data.frame with one row per path removed (or, with
`dry_run = TRUE`, that would be removed): `component`, `type`
(`"backbone"`/`"enrichment"`/`"directory"`), `reason` (`"superseded"`,
`"unused"`, `"interrupted"`, `"removed"`), `size_mb` and `path`.

## Details

A removed backbone or enrichment downloads again when it is next
installed; a lockfile pin is restored by
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
from the published copy of that build.

## Outdated builds left unused

Every time a session first reads a build, taxify records the time. When
the package is loaded it removes from the data directory every outdated
build that has not been read or downloaded for
`getOption("taxify.max_unused_days")` days (default 90), and the files
of interrupted downloads. A build is outdated when it is stored in the
format used before taxify 0.7.0, or when a newer build of it has been
published. The current build of a backbone or enrichment stays however
long it is left unused, and so does a build pinned by
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md).
Set the option to `Inf` to keep every build.
`taxify_clean(unused_days = )` applies the same rule on demand to the
data directory in use.

## See also

[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)
for the builds on disk,
[`install_backbones()`](https://gillescolling.com/taxify/reference/install_backbones.md).

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md),
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
old <- options(taxify.data_dir = file.path(tempdir(), "taxify_clean_demo"))
taxify_clean(dry_run = TRUE)
#> Would remove 0.0 MB in 0 paths from C:\Users\GILLES~1\AppData\Local\Temp\RtmpCocUuZ/taxify_clean_demo.
taxify_clean(unused_days = 30, dry_run = TRUE)
#> Would remove 0.0 MB in 0 paths from C:\Users\GILLES~1\AppData\Local\Temp\RtmpCocUuZ/taxify_clean_demo.
options(old)
```
