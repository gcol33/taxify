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

A data.frame with columns: `name`, `title` (the source's full name),
`scope`, `n_names`, `size_mb`, `version`, `source_date`, `installed`,
`code`, `source`. `code` is the nomenclature the backbone's names
follow: `"taxon"` for the taxonomic backbones, `"syntaxon"` for a
backbone of vegetation units (`"evc"`, the EuroVegChecklist), which is
matched only when named in `taxify(backbone = )`. `n_names`, `size_mb`,
and `version` are `NA` for any backbone the manifest does not yet
describe or when the manifest cannot be fetched offline.

`version` is the release that packaged the backbone; `source_date` is
the date of the upstream data, which can be much earlier. The GBIF
backbone is the case that matters: GBIF froze it at 2023-08-28 and has
said it will not be updated again, so a current release tag there
carries a treatment three years older than the tag suggests.
`source_date` is an ISO date, or `YYYY-MM` / `YYYY` where the source
dates its release no finer, and `NA` for a backbone whose upstream date
has not been recorded.

## See also

[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md),
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md),
[`taxify_databases()`](https://gillescolling.com/taxify/reference/taxify_databases.md).

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data(),
               taxify.offline = TRUE)
head(list_backbones(verbose = FALSE))
#>    name                                   title                       scope
#> 1   wfo                      World Flora Online             Vascular plants
#> 2   col                       Catalogue of Life                All kingdoms
#> 3 colxr      Catalogue of Life Extended Release                All kingdoms
#> 4  gbif                  GBIF Backbone Taxonomy                All kingdoms
#> 5  itis Integrated Taxonomic Information System US focus, freshwater/marine
#> 6  ncbi                           NCBI Taxonomy                    All life
#>   n_names size_mb version source_date installed  code
#> 1 1664014     120 2026.06  2026-06-21      TRUE taxon
#> 2 5432444     573 2026.09  2026-09-11      TRUE taxon
#> 3 8479599     399 2026.09  2026-09-25     FALSE taxon
#> 4 6404001     461 2023.08  2023-08-28      TRUE taxon
#> 5 1000552      52 2026.09  2026-08-27     FALSE taxon
#> 6 2952424     110 2026.09     2026-09     FALSE taxon
#>                                  source
#> 1     https://www.worldfloraonline.org/
#> 2      https://www.catalogueoflife.org/
#> 3      https://www.catalogueoflife.org/
#> 4                 https://www.gbif.org/
#> 5                  https://www.itis.gov
#> 6 https://www.ncbi.nlm.nih.gov/taxonomy
options(old)
```
