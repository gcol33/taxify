# List supported taxonomic backbones

Returns every taxonomic backbone
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) can
match against, its taxonomic scope, and (once the manifest is reachable)
its current version, name count, download size, and whether it is
already installed locally. The counterpart to
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)
for the backbone side.

## Usage

``` r
list_backbones(verbose = TRUE)
```

## Arguments

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with columns: `name`, `scope`, `n_names`, `size_mb`,
`version`, `installed`, `source`. `n_names`, `size_mb`, and `version`
are `NA` for any backbone the manifest does not yet describe or when the
manifest cannot be fetched offline.

## See also

[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md),
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md),
[`taxify_databases()`](https://gillescolling.com/taxify/reference/taxify_databases.md).

## Examples

``` r
# \donttest{
list_backbones()
# }
```
