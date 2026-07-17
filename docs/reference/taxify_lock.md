# Record the exact backbone and enrichment versions behind a result

Writes a machine-readable lockfile pinning which backbone and enrichment
assets – name, version, and byte-identity (content id) – produced a
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
  result (its resolved backbones and any `add_*()` enrichment layers are
  locked), or `NULL` (default) to snapshot every installed backbone.

- file:

  Optional path to write the lockfile to (JSON). When `NULL` (default)
  nothing is written and the lock is only returned.

- verbose:

  Logical. Default `TRUE`.

## Value

A lock list (invisibly when `file` is written), with elements
`taxify_version`, `created`, `r_version`, `backends`, and `enrichments`.

## See also

[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
to check an install against a lockfile,
[`cite()`](https://gillescolling.com/taxify/reference/cite.md) for prose
citations.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

res  <- taxify("Quercus robur", backend = "wfo", verbose = FALSE)
lock <- taxify_lock(res)
lock$backends[[1]]$name

options(old)
```
