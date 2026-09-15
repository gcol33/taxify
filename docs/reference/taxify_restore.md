# Check an install against a lockfile, and optionally reinstall what drifted

Reads a lockfile written by
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
and reports, for each backbone and enrichment it pins, whether the
currently installed asset matches – by version and byte-identity
(content id) – or has drifted, or is missing.

## Usage

``` r
taxify_restore(file, install = FALSE, verbose = TRUE)
```

## Arguments

- file:

  Path to a lockfile written by
  [`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md),
  or the lock list it returned.

- install:

  Logical. `FALSE` (default) verifies and reports only. `TRUE` downloads
  and activates the pinned build of every asset that does not already
  match.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per pinned asset, columns: `component`, `type`
(`"backbone"`/`"enrichment"`), `locked_version`, `installed_version`,
`locked_content_id` and `installed_content_id` (short), and `status`
(`"ok"`, `"version_drift"`, `"content_drift"`, `"missing"`, or
`"unverified"` when what the lock pinned cannot be compared against this
install). With `install = TRUE` the statuses describe the install
afterwards, a `restored` column records which rows were fetched, and a
`pinned` column which rows are now pinned (every row whose status is
`"ok"`).

## Details

With `install = TRUE` it also fetches the exact build each row pins,
from the immutable copy published beside the rolling asset, and makes it
the active one: the recorded run is put back in place in a single call.
The build each pinned build replaces is kept on disk under its own
content id, so restoring a lockfile is reversible. Every build that
matches the lock afterwards is pinned, including one that already
matched and needed no download, so the next session's version check does
not refresh it away from the lock. Release a pin with
[`taxify_pin()`](https://gillescolling.com/taxify/reference/taxify_pin.md).

A build published before taxifydb began uploading an immutable copy
cannot be recovered – the re-cut replaced it in place – and its row
keeps reporting drift after the install pass.

## See also

[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md),
[`taxify_pin()`](https://gillescolling.com/taxify/reference/taxify_pin.md)
to pin or release an installed build without a lockfile,
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)
for the builds on disk,
[`taxify_download_enrichment()`](https://gillescolling.com/taxify/reference/taxify_download_enrichment.md)
to fetch a single build by content id.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

res  <- taxify("Quercus robur", backbone = "wfo", verbose = FALSE)
lock <- taxify_lock(res)
taxify_restore(lock, verbose = FALSE)

options(old)
```
