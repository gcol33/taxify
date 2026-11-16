# Describe a trait's sources and units

Prints the kind, canonical unit, and (for categorical traits) the shared
vocabulary of a trait, and returns a data.frame of the sources
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
draws from: one row per source, with its enrichment, source column,
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
`column`, `citation`, `note` (unit or vocabulary harmonization), and
`caution` (a method or definition difference from the reference source,
or `NA`). The header line (label, kind, unit, default priority,
vocabulary) is printed as a message.

## See also

[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md)

Other Traits across sources:
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
[`list_traits()`](https://gillescolling.com/taxify/reference/list_traits.md)

## Examples

``` r
trait_info("woodiness")
#> Woodiness (categorical)  |  default priority: zanne > gift > austraits > bien
#> vocabulary: woody, non-woody, variable
#>      source enrichment           column                        citation
#> 1     zanne      zanne        woodiness               Zanne et al. 2014
#> 2      gift       gift gift_woodiness_1      GIFT (Weigelt et al. 2020)
#> 3 austraits  austraits        woodiness AusTraits (Falster et al. 2021)
#> 4      bien       bien        woodiness      BIEN (Maitner et al. 2018)
#>                                                                           note
#> 1                            Zanne 'herbaceous' maps to canonical 'non-woody'.
#> 2                                                GIFT woodiness used verbatim.
#> 3 Pure 'woody'/'herbaceous' mapped; mixed or semi-woody entries -> 'variable'.
#> 4                                       BIEN 'herbaceous' maps to 'non-woody'.
#>   caution
#> 1    <NA>
#> 2    <NA>
#> 3    <NA>
#> 4    <NA>
```
