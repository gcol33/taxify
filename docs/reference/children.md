# List the accepted taxa within a genus or family

Returns the accepted taxa a backbone places inside a genus or family, so
you can build a checklist from the backbone rather than only validating
one. The parent is auto-detected: a genus is tried first, then a family.

## Usage

``` r
children(taxon, backend = "wfo", rank = "species", verbose = TRUE)
```

## Arguments

- taxon:

  A single genus or family name.

- backend:

  A single backend name (e.g. `"wfo"`) or a `taxify_backend` object.
  Default `"wfo"`.

- rank:

  Rank of the children to return (`"species"` by default), or `"any"`
  for every rank below the parent.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame of accepted taxa, columns: `name`, `authorship`, `rank`,
`family`, `genus`, `taxon_id`, `parent_rank` (`"genus"` or `"family"`),
`backend`. Empty if the parent is not found.

## See also

[`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md),
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

children("Quercus")

options(old)
```
