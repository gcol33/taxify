# Build a taxonomy tree from resolved names

Resolves the names, attaches their full higher classification, and
assembles a taxonomy tree (kingdom -\> phylum -\> class -\> order -\>
family -\> genus -\> species) from the shared lineages. Returns the tree
as a Newick string and the underlying classification table; when the ape
package is installed, an `ape` `phylo` object is included too.

## Usage

``` r
class2tree(x, backend = NULL, verbose = TRUE)
```

## Arguments

- x:

  Character vector of names, or a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result.

- backend:

  Backend passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  when `x` is raw names. `NULL` (default) uses every installed backbone.
  Ignored when `x` is a result.

- verbose:

  Logical. Default `TRUE`.

## Value

An object of class `taxify_tree`: a list with

- newick:

  The Newick string (internal nodes labelled by rank value, tips by
  species name).

- classification:

  The classification data.frame the tree was built from.

- tip_labels:

  The species at the tips.

- phylo:

  An ape `phylo` object, or `NULL` if ape is not installed / the string
  could not be parsed.

## See also

[`lowest_common()`](https://gillescolling.com/taxify/reference/lowest_common.md),
[`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md),
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

tr <- class2tree(c("Quercus robur", "Quercus petraea", "Quercus pyrenaica"))
tr$newick

options(old)
```
