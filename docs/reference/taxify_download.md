# Download a pre-built taxify backbone

Downloads a pre-built `.vtr` backbone from GitHub Releases using the
taxify manifest. This needs no build tools and does not require
`taxifydb`; it is the fast path
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) uses
internally on first use. Call it directly to pre-fetch backbones before
an offline session. Progress is always shown; no prompts are shown, so
calling this function is consent.

## Usage

``` r
taxify_download(backend = "wfo", version = "latest", verbose = TRUE)

taxify_download_vtr(backend = "wfo", version = "latest", verbose = TRUE)
```

## Arguments

- backend:

  Character. A backend name (e.g. `"wfo"`, `"col"`, `"gbif"`, ...; see
  the backends in
  [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)'s
  companion manifest) or `"register"` for the genus register. Multiple
  backends can be given as a character vector.

- version:

  Character. `"latest"` (default) downloads into
  `<data_dir>/<backend>/latest/` and will be overwritten on future
  updates. A specific version string (e.g., `"2024.01"`) downloads into
  a pinned folder that is never overwritten.

- verbose:

  Logical. Default `TRUE`.

## Value

The path(s) to the downloaded `.vtr` file(s) (invisibly).

## Details

If no pre-built `.vtr` is available for a backend, it falls back to
building from source via
[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md)
(which requires `taxifydb`).

## See also

[`taxify_build()`](https://gillescolling.com/taxify/reference/taxify_build.md)
to build a backbone from source via `taxifydb`,
[`taxify_download_enrichment()`](https://gillescolling.com/taxify/reference/taxify_download_enrichment.md)
for enrichment layers.
