# Build the genus register from source

Rebuilds `genus_register.vtr` and `backend_coverage.vtr` locally instead
of downloading the published pair. The build itself lives in `taxifydb`,
which resolves every backbone in the register's fixed backbone set and
can take well over an hour; the download takes seconds and yields the
same file, so this is an escape hatch rather than the normal route.

## Usage

``` r
taxify_build_register(verbose = TRUE)
```

## Arguments

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

Path to `genus_register.vtr` (invisibly).

## Details

`taxify_download("register")` fetches the published pair.

## See also

[`taxify_load_register()`](https://gillescolling.com/taxify/reference/taxify_load_register.md)
to load it into memory,
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md)
to query backbone coverage for a genus.
