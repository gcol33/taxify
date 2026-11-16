# Record the exact backbone and enrichment versions behind a result

Writes a machine-readable lockfile pinning which backbone and enrichment
assets (name, version, and byte-identity, the content id) produced a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result. Where
[`cite()`](https://gillescolling.com/taxify/reference/cite.md) prints
prose citations, `taxify_lock()` records the reproducible counterpart,
so a manuscript's Methods can state exactly what was matched against and
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
can later verify an install still matches.

## Usage

``` r
taxify_lock(x = NULL, file = NULL, verbose = TRUE)
```

## Arguments

- x:

  A [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result (its resolved backbones and any `add_*()` published datasets
  are locked), or `NULL` (default) to snapshot every installed backbone.

- file:

  Optional path to write the lockfile to (JSON). When `NULL` (default)
  nothing is written and the lock is only returned.

- verbose:

  Logical. Default `TRUE`.

## Value

A lock list (invisibly when `file` is written), with elements
`taxify_version`, `created`, `r_version`, `backbones`, and
`enrichments`. Each backbone entry contains `name`, `version`,
`content_id`, `downloaded_at` and `installed`; enrichment entries also
contain `source` and `license`. Only enrichments that supplied values
are included.

## Details

Create the lock immediately after matching and enrichment. Backbone
identities are read from the active installation when the lock is made.
Writing a lock leaves refresh settings unchanged;
[`taxify_pin()`](https://gillescolling.com/taxify/reference/taxify_pin.md)
or `taxify_restore(install = TRUE)` pins installed builds.

The lock records backbone and contributing enrichment assets. Save the
input names, matching arguments and R package environment with your
script; the lock does not record those or the register and
region-boundary assets.

## See also

[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
to check an install against a lockfile,
[`cite()`](https://gillescolling.com/taxify/reference/cite.md) for prose
citations.

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md),
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md),
[`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md),
[`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md),
[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md),
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md),
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md),
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

res  <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
lock <- taxify_lock(res)
lock$backbones[[1]]$name
#> [1] "wfo"

options(old)
```
