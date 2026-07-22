# Lowest common taxon of a set of names

Resolves the names and reports the deepest Linnaean rank at which they
all share one classification value – their most recent common ancestor
in the backbone's hierarchy. Two congeners return their shared genus;
two plants in different families return a shared order or class;
unrelated taxa share only a kingdom (or nothing).

## Usage

``` r
lowest_common(x, backbone = NULL, verbose = TRUE)
```

## Arguments

- x:

  Character vector of names (two or more), or a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result.

- backbone:

  Backend passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  when `x` is raw names. `NULL` (default) uses every installed backbone.
  Ignored when `x` is a result.

- verbose:

  Logical. Default `TRUE`.

## Value

A one-row data.frame with columns `rank`, `name` (the shared taxon), and
`n_taxa` (how many resolved names went into the comparison). `rank` and
`name` are `NA` when the taxa share nothing (e.g. different kingdoms, or
only one resolved).

## See also

[`class2tree()`](https://gillescolling.com/taxify/reference/class2tree.md),
[`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md),
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

lowest_common(c("Quercus robur", "Quercus petraea"))

options(old)
```
