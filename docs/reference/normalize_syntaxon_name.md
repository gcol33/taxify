# Syntaxon name key for lookup across spelling variants

Folds the variation syntaxon names are written with to one key, applied
the same way to the backbone at build time and to the query at match
time: lowercase, diacritics stripped, spaces around hyphens removed, and
the Latin orthographic alternations of
[`normalize_epithets()`](https://gillescolling.com/taxify/reference/normalize_epithets.md)
applied to every word (a syntaxon's first word is a Latin stem as much
as its epithet is), so `Fagion silvaticae` and `Fagion sylvaticae`, or
`Juncion gerardi` and `Juncion gerardii`, share a key.

## Usage

``` r
normalize_syntaxon_name(x)
```

## Arguments

- x:

  Character vector of syntaxon names (no author).

## Value

Character vector of keys; `NA` in, `NA` out.

## Examples

``` r
normalize_syntaxon_name(c("Fagion silvaticae", "Fagion sylvaticae",
                          "Thero - Suaedion"))
```
