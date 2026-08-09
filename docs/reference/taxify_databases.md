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
release `version` that packaged it), `installed`, `source`.

## See also

[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md),
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md),
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md).

## Examples

``` r
if (FALSE) { # \dontrun{
taxify_databases()
} # }
```
