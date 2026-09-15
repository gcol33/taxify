# List all descendants of a taxon down to a target rank

Returns every accepted taxon at `downto` rank that sits beneath `taxon`
– for example every species in an order or family. The parent's rank is
detected from the backbone, then descendants are read from the
denormalized classification the backbone stores.
[`children()`](https://gillescolling.com/taxify/reference/children.md)
is the same query for a genus or family parent.

## Usage

``` r
downstream(
  taxon,
  backbone = NULL,
  downto = "species",
  kingdom = NULL,
  verbose = TRUE
)
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
  `"any"` (or `NULL`) for every accepted taxon beneath `taxon`
  regardless of rank. The parent itself is never returned.

- kingdom:

  Optional kingdom (or kingdoms) the parent belongs to, as in
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  (`"plantae"`, `"animals"`, ...). A name can be used in more than one
  kingdom (*Morus* is both mulberries and gannets); `kingdom` picks one,
  and also decides the parent's rank when the homonyms sit at different
  ranks. Without it such a result mixes the kingdoms, with a warning.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame of accepted descendants, columns: `name`, `authorship`,
`rank`, `kingdom_group` (the coarse kingdom, as in
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
output), `family`, `genus`, `taxon_id`, `parent`, `parent_rank`,
`backbone`. Empty when `taxon` is not found, its rank is one the
backbone does not store as a column (e.g. subfamily, tribe), or it has
no descendants at `downto`.

## See also

[`children()`](https://gillescolling.com/taxify/reference/children.md)
for a genus or family parent,
[`upstream()`](https://gillescolling.com/taxify/reference/upstream.md)
for the ancestors,
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
