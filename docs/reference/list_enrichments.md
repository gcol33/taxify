# List available enrichments

Returns a summary of all published datasets available in the taxify
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

## See also

Other Browse and discover:
[`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md),
[`enrichment_groups()`](https://gillescolling.com/taxify/reference/enrichment_groups.md)

## Examples

``` r
if (FALSE) { # \dontrun{
list_enrichments()
} # }
```
