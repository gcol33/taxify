# List the higher classification (ancestors) of a taxon

Returns the lineage above `taxon` – its genus, family, order, class,
phylum, and kingdom, for whichever of those ranks the backbone stores –
as a tidy frame with one row per ancestor rank. Where
[`downstream()`](https://gillescolling.com/taxify/reference/downstream.md)
reaches down to descendants, `upstream()` reaches up to ancestors; where
[`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md)
attaches the ranks to an existing
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result, `upstream()` takes a bare name. A synonym or misspelling is
resolved to its accepted taxon first, so the lineage returned is the
accepted taxon's.

## Usage

``` r
upstream(taxon, backbone = NULL, to = NULL, verbose = TRUE)
```

## Arguments

- taxon:

  A single taxonomic name (a species, genus, or higher taxon; synonyms
  and typos are resolved first).

- backbone:

  A single backbone name or a `taxify_backend` object. `NULL` (default)
  uses the highest-priority installed backbone; name one that stores the
  higher ranks (e.g. `"col"`) for a full lineage.

- to:

  Optional rank (or ranks) to restrict the output to – e.g.
  `to = "family"` answers "what family is this in?" with a single row.
  `NULL` (default) returns the whole lineage.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per ancestor rank, columns: `input_name` (the
name as supplied), `accepted_name` (what it resolved to), `rank`,
`name`, `backbone`, ordered kingdom -\> genus. Empty when `taxon` does
not resolve or the backbone stores no ranks above it.

## See also

[`downstream()`](https://gillescolling.com/taxify/reference/downstream.md)
for descendants,
[`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md)
to attach the ranks to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result,
[`lowest_common()`](https://gillescolling.com/taxify/reference/lowest_common.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# The lineage above a species (reptiledb carries the full higher hierarchy)
upstream("Naja naja", backbone = "reptiledb")

# Just the family
upstream("Naja naja", backbone = "reptiledb", to = "family")

options(old)
```
