# List all descendants of a taxon down to a target rank

Returns every accepted taxon at `downto` rank that sits beneath `taxon`
– for example every species in an order or family. The parent's rank is
detected from the backbone, then descendants are read from the
denormalized classification the backbone stores. Where
[`children()`](https://gillescolling.com/taxify/reference/children.md)
gives the immediate contents of a genus or family, `downstream()`
reaches an arbitrary depth.

## Usage

``` r
downstream(taxon, backbone = NULL, downto = "species", verbose = TRUE)
```

## Arguments

- taxon:

  A single higher-taxon name (a genus, family, order, class, phylum, or
  kingdom).

- backbone:

  A single backbone name or a `taxify_backend` object. `NULL` (default)
  uses the highest-priority installed backbone; name one that stores the
  higher ranks (e.g. `"col"`) to reach above genus.

- downto:

  Target rank of the descendants to return (`"species"` by default), or
  `"any"` for every accepted taxon beneath `taxon` regardless of rank.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame of accepted descendants, columns: `name`, `authorship`,
`rank`, `family`, `genus`, `taxon_id`, `parent`, `parent_rank`,
`backbone`. Empty when `taxon` is not found, its rank is one the
backbone does not store as a column (e.g. subfamily, tribe), or it has
no descendants at `downto`.

## See also

[`children()`](https://gillescolling.com/taxify/reference/children.md)
for the immediate level,
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md),
[`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Every species the backbone places in the genus
downstream("Quercus", backbone = "col")

options(old)
```
