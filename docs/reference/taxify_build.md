# Build a backbone database from source

Builds the backbone `.vtr` for a backend from its upstream Darwin Core
source, delegating to the sibling `taxifydb` package (which must be
installed). This is the from-source path, for rebuilding a backbone
locally.

## Usage

``` r
taxify_build(backend, dest = NULL, verbose = TRUE, ...)
```

## Arguments

- backend:

  A `taxify_backend` object or a character string (e.g., `"wfo"`).

- dest:

  Character. Destination directory. Defaults to
  [`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md).

- verbose:

  Logical. Print progress messages.

- ...:

  Additional arguments passed to methods.

## Value

The path to the `.vtr` file (invisibly).

## Details

For everyday use you do not need this:
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
auto-downloads the pre-built `.vtr` on first use, and
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
fetches a pre-built backbone directly without `taxifydb`.

## See also

[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
to fetch a pre-built backbone,
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) which
downloads on first use.
