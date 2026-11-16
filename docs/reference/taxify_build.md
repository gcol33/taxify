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

Everyday use does not need this:
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
auto-downloads the pre-built `.vtr` on first use, and
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
fetches a pre-built backbone directly without `taxifydb`.

## See also

[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
to fetch a pre-built backbone,
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) which
downloads on first use.

Other Backbone data and cache:
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md),
[`taxify_clean()`](https://gillescolling.com/taxify/reference/taxify_clean.md),
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
if (FALSE) { # \dontrun{
taxify_build("wfo", dest = tempfile("taxify-build-"))
} # }
```
