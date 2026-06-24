# List available enrichments

Returns a summary of all enrichment layers available in the taxify
manifest, including version, row count, whether the dataset is static,
and which trait columns are provided.

## Usage

``` r
list_enrichments(verbose = TRUE)
```

## Arguments

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with columns: `name`, `version`, `nrow`, `static`,
`trait_cols` (comma-separated), and `source_url`.

## Examples

``` r
# \donttest{
list_enrichments()
# }
```
