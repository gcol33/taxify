# Check an install against a lockfile

Reads a lockfile written by
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
and reports, for each backbone and enrichment it pins, whether the
currently installed asset matches – by version and byte-identity
(content id) – or has drifted, or is missing. taxify serves only the
latest version of each asset, so `taxify_restore()` verifies and reports
rather than force-installing a historical version; a drift row tells you
the recorded run cannot be reproduced byte-for-byte with the current
downloads.

## Usage

``` r
taxify_restore(file, verbose = TRUE)
```

## Arguments

- file:

  Path to a lockfile written by
  [`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md),
  or the lock list it returned.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per pinned asset, columns: `component`, `type`
(`"backbone"`/`"enrichment"`), `locked_version`, `installed_version`,
`locked_content_id` and `installed_content_id` (short), and `status`
(`"ok"`, `"version_drift"`, `"content_drift"`, `"missing"`, or
`"unverified"` when neither a version nor a content id could be
compared).

## See also

[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

res  <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
lock <- taxify_lock(res)
taxify_restore(lock, verbose = FALSE)

options(old)
```
