# Add sex-determination traits (Tree of Sex)

Joins sexual-system and sex-determination traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Covers plants, vertebrates and
invertebrates; some traits are group-specific (selfing for plants,
environmental sex determination for vertebrates, haplodiploidy for
invertebrates).

## Usage

``` r
add_tree_of_sex(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- tos_taxon_group:

  Source group (plants/vertebrates/invertebrates).

- tos_sexual_system:

  Sexual system (vocabulary differs by group).

- tos_karyotype:

  Sex-chromosome system (XY/ZW/XO/homomorphic/...).

- tos_genotypic:

  Heterogamety (male/female heterogametic/GSD/...).

- tos_molecular_basis:

  Molecular basis (Y dominant/W dominant/dosage).

- tos_selfing:

  Selfing (plants; self compatible/incompatible).

- tos_environmental_sd:

  Environmental sex determination (vertebrates; TSD/...).

- tos_haplodiploidy:

  Haplodiploidy (invertebrates).

## Details

Source: Tree of Sex (Tree of Sex Consortium 2014, Scientific Data, CC0).
Coverage: ~37.5k species across plants, vertebrates and invertebrates.

## References

The Tree of Sex Consortium (2014) Tree of Sex: a database of sexual
systems. Scientific Data 1:140015.
[doi:10.1038/sdata.2014.15](https://doi.org/10.1038/sdata.2014.15)

## Examples

``` r
# \donttest{
taxify("Silene latifolia", backend = "gbif") |>
  add_tree_of_sex()
# }
```
