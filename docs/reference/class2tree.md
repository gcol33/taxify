# Build a taxonomy tree from resolved names

Resolves the names, attaches their full higher classification, and
assembles a taxonomy tree (kingdom -\> phylum -\> class -\> order -\>
family -\> genus -\> species) from the shared lineages. Returns the tree
as a Newick string and the underlying classification table; when the ape
package is installed, an `ape` `phylo` object is included too.

## Usage

``` r
class2tree(x, backbone = NULL, ..., verbose = TRUE)

# S3 method for class 'taxify_tree'
print(x, ...)
```

## Arguments

- x:

  Character vector of names, or a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result.

- backbone:

  Backend passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  when `x` is raw names. `NULL` (default) uses every installed backbone.
  Ignored when `x` is a result.

- ...:

  Ignored, present for S3 `print` method consistency.

- verbose:

  Logical. Default `TRUE`.

## Value

An object of class `taxify_tree`: a list with

- newick:

  The Newick string (internal nodes labelled by rank value, tips by
  species name). Characters Newick reserves, the space among them, are
  written as `_` (`Quercus_robur`).

- classification:

  The classification data.frame the tree was built from.

- tip_labels:

  The species at the tips, as named in `classification`.

- phylo:

  An ape `phylo` object, or `NULL` if ape is not installed / the string
  could not be parsed. Its `tip.label` and `node.label` carry the names
  themselves, as `tip_labels` does.

## See also

[`lowest_common()`](https://gillescolling.com/taxify/reference/lowest_common.md),
[`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md),
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

Other Explore the backbone:
[`downstream()`](https://gillescolling.com/taxify/reference/downstream.md),
[`lowest_common()`](https://gillescolling.com/taxify/reference/lowest_common.md),
[`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md),
[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md),
[`upstream()`](https://gillescolling.com/taxify/reference/upstream.md)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

tr <- class2tree(c("Quercus robur", "Quercus petraea", "Quercus pyrenaica"))
#> Matching 3 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 3 names...
#>   [wcvp] Matching 2 remaining names...
#>   [lcvp] Matching 2 remaining names...
#>   [wfo] Matching 2 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
tr$newick
#> [1] "(((Quercus_robur,Quercus_petraea,Quercus_pyrenaica)Quercus)Fagaceae)root;"

options(old)
```
