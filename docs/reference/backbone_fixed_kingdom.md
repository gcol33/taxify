# The single kingdom a backbone's rows always belong to, or NA

A backbone scoped to one kingdom by construction (the vascular-plant
backbones, Species Fungorum) carries no `kingdom` column, since it has
nothing to record there. This names that kingdom, so a row from such a
backbone can still be placed.

## Usage

``` r
backbone_fixed_kingdom(name)
```

## Arguments

- name:

  Character vector of backbone names.

## Value

Character vector of coarse kingdom groups (see
[`normalize_kingdom_group()`](https://gillescolling.com/taxify/reference/normalize_kingdom_group.md)),
`NA` where the backbone spans more than one kingdom or is not a known
backbone.

## Examples

``` r
backbone_fixed_kingdom(c("wfo", "fungorum", "gbif"))
```
