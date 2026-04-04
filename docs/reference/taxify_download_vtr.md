# Download a taxify backbone

Downloads a pre-built `.vtr` backbone from Zenodo using the taxify
manifest. Progress is always shown. No prompts are shown — calling this
function is consent.

## Usage

``` r
taxify_download_vtr(backend = "wfo", version = "latest", verbose = TRUE)
```

## Arguments

- backend:

  Character. One of `"wfo"`, `"col"`, `"gbif"`, or `"register"`.
  Multiple backends can be specified as a character vector.

- version:

  Character. `"latest"` (default) downloads into
  `<data_dir>/<backend>/latest/` and will be overwritten on future
  updates. A specific version string (e.g., `"2024.01"`) downloads into
  a pinned folder that is never overwritten.

- verbose:

  Logical. Default `TRUE`.

## Value

The path(s) to the downloaded `.vtr` file(s) (invisibly).
