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
`version`, `source_date`, `installed`, `source`. `n_names`, `size_mb`,
and `version` are `NA` for any backbone the manifest does not yet
describe or when the manifest cannot be fetched offline.

`version` is the release that packaged the backbone; `source_date` is
the date of the upstream data, which can be much earlier. The GBIF
backbone is the case that matters: GBIF froze it at 2023-08-28 and has
said it will not be updated again, so a current release tag there
carries a treatment three years older than the tag suggests.
`source_date` is `NA` for a backbone whose upstream date has not been
recorded.

## See also

[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md),
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md),
[`taxify_databases()`](https://gillescolling.com/taxify/reference/taxify_databases.md).

## Examples

``` r
if (FALSE) { # \dontrun{
list_backbones()
} # }
```
