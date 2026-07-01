# Describe a trait's sources and units

Prints the kind, canonical unit, and (for categorical traits) the shared
vocabulary of a trait, and returns a data.frame of the sources
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
draws from – one row per source, with its enrichment, source column,
citation, and the harmonization note (unit conversion or vocabulary
mapping).

## Usage

``` r
trait_info(trait)
```

## Arguments

- trait:

  Character. A single trait name; see
  [`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md).

## Value

A data.frame (invisibly-friendly) with columns `source`, `enrichment`,
`column`, `citation`, `note`. The header line (label, kind, unit,
default priority, vocabulary) is printed as a message.

## See also

[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md)

## Examples

``` r
trait_info("woodiness")
```
