# Get the taxify data directory

Returns the directory where taxify stores downloaded backbone and
enrichment `.vtr` files. By default this is the platform-appropriate
per-user cache returned by
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html) (available
since R 4.0).

## Usage

``` r
taxify_data_dir()
```

## Value

Character string. Path to the data directory.

## Details

The location can be overridden, in order of precedence, by the
`taxify.data_dir` option (`getOption("taxify.data_dir")`) or the
`TAXIFY_DATA_DIR` environment variable. This is useful to point taxify
at a shared cache, or at the small bundled example database returned by
[`taxify_example_data()`](https://gillescolling.com/taxify/reference/taxify_example_data.md).
