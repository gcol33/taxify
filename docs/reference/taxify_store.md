# Builds of a taxify asset held on disk

taxify keeps every build it has downloaded of an enrichment: the active
one under `latest/`, and each build it replaced in a directory named for
that build's content id (the md5 of its `.vtr`, the same string
[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
records). Backbones are listed the same way, though by default only the
active build of a backbone is kept – see `taxify.keep_backbone_versions`
below.

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
`type` (`"backbone"`/`"enrichment"`), `slot` (the store directory –
`"latest"` for the active build, else its content id), `active`,
`version`, `content_id`, `pinned`, `size_mb`, `downloaded_at`.

## Details

Use this to see which pinned builds a lockfile could be restored to
without a download.

## Options

`taxify.keep_enrichment_versions` (default `TRUE`) keeps the build an
enrichment refresh replaces; `taxify.keep_backbone_versions` (default
`FALSE`) does the same for backbones, off because a superseded backbone
is gigabytes. Restoring a pinned build archives the build it replaces
either way.

## See also

[`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md)
to record a build,
[`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
to check or reinstall one,
[`taxify_download_enrichment()`](https://gillescolling.com/taxify/reference/taxify_download_enrichment.md)
to fetch one by content id.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())
head(taxify_store())
options(old)
```
