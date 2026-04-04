# Download a backbone database

Downloads the latest Darwin Core snapshot for the specified backend and
converts it to vectra's `.vtr` format for fast repeated queries.

## Usage

``` r
taxify_download(backend, dest = NULL, verbose = TRUE, ...)
```

## Arguments

- backend:

  A `taxify_backend` object or a character string (e.g., `"wfo"`).

- dest:

  Character. Destination directory. Defaults to
  [`taxify_data_dir()`](https://gcol33.github.io/taxify/reference/taxify_data_dir.md).

- verbose:

  Logical. Print progress messages.

- ...:

  Additional arguments passed to methods.

## Value

The path to the `.vtr` file (invisibly).

## Details

Always re-downloads the latest release, overwriting any existing
backbone. Use
[`taxify()`](https://gcol33.github.io/taxify/reference/taxify.md) for
day-to-day matching — it auto-downloads on first use and reuses the
local copy thereafter.
