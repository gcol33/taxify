# List the traits available to add_trait()

Returns the traits that
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
can attach across sources, with their kind, canonical unit, and the
number and names of contributing sources.

## Usage

``` r
list_traits()
```

## Value

A data.frame with one row per trait:

- trait:

  The trait name to pass to
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md).

- label:

  Human-readable label.

- kind:

  `"numeric"` or `"categorical"`.

- unit:

  Canonical unit for numeric traits, `NA` for categorical.

- n_sources:

  Number of sources providing the trait.

- sources:

  Comma-separated source names.

## See also

[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)

## Examples

``` r
list_traits()
```
