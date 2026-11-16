# One overview of every database taxify knows about

Stacks the taxonomic backbones (from
[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md))
and the trait/status enrichments (from
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md))
into a single frame with a `type` column, so a new user can see the full
breadth in one call rather than needing to know three separate discovery
verbs. The cross-source trait vocabulary is summarised in the message
footer; browse it with
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md).

## Usage

``` r
taxify_databases(verbose = TRUE)
```

## Arguments

- verbose:

  Logical. When `TRUE` (default), prints a one-line count of backbones,
  enrichments, and registered traits.

## Value

A data.frame with columns: `type` (`"backbone"` or `"enrichment"`),
`name`, `scope` (taxonomic scope for backbones; provided trait columns
for enrichments), `n_rows`, `version`, `source_date` (the date of the
upstream data, where recorded, which can be much earlier than the
release `version` that packaged it), `installed`, `source`. `installed`
is logical for backbone rows and `NA` for enrichment rows. Use
[`taxify_store()`](https://gillescolling.com/taxify/reference/taxify_store.md)
to inspect locally installed enrichments.

## See also

[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md),
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md),
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md).

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data(),
               taxify.offline = TRUE)
head(taxify_databases(verbose = FALSE))
#>       type  name                       scope  n_rows version source_date
#> 1 backbone   wfo             Vascular plants 1664014 2026.06  2026-06-21
#> 2 backbone   col                All kingdoms 5432444 2026.09  2026-09-11
#> 3 backbone colxr                All kingdoms 8479599 2026.09  2026-09-25
#> 4 backbone  gbif                All kingdoms 6404001 2023.08  2023-08-28
#> 5 backbone  itis US focus, freshwater/marine 1000552 2026.09  2026-08-27
#> 6 backbone  ncbi                    All life 2952424 2026.09     2026-09
#>   installed                                source
#> 1      TRUE     https://www.worldfloraonline.org/
#> 2      TRUE      https://www.catalogueoflife.org/
#> 3     FALSE      https://www.catalogueoflife.org/
#> 4      TRUE                 https://www.gbif.org/
#> 5     FALSE                  https://www.itis.gov
#> 6     FALSE https://www.ncbi.nlm.nih.gov/taxonomy
options(old)
```
