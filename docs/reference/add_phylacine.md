# Add mammal traits including extinct species (PHYLACINE)

Joins PHYLACINE mammal traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. PHYLACINE covers extant plus
recently and prehistorically extinct mammals; it is offered alongside
[`add_pantheria()`](https://gillescolling.com/taxify/reference/add_pantheria.md)
and
[`add_combine()`](https://gillescolling.com/taxify/reference/add_combine.md),
not as a replacement.

## Usage

``` r
add_phylacine(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- phylacine_mass_g:

  Body mass (g).

- phylacine_diet_plant_pct:

  Percent of diet that is plant.

- phylacine_diet_vertebrate_pct:

  Percent of diet that is vertebrate.

- phylacine_diet_invertebrate_pct:

  Percent of diet that is invertebrate.

- phylacine_terrestrial:

  Terrestrial habit (0/1).

- phylacine_marine:

  Marine habit (0/1).

- phylacine_freshwater:

  Freshwater habit (0/1).

- phylacine_aerial:

  Aerial habit (0/1).

- phylacine_island_endemicity:

  Island endemicity class.

- phylacine_iucn_status:

  IUCN status (includes EP = extinct in prehistory, EX, EW).

## Details

Source: PHYLACINE v1.2 (Faurby et al. 2018, Ecology, CC0). Coverage:
~5.8k mammal species including extinct taxa.

## References

Faurby S et al. (2018) PHYLACINE 1.2: The Phylogenetic Atlas of Mammal
Macroecology. Ecology 99:2626.
[doi:10.1002/ecy.2443](https://doi.org/10.1002/ecy.2443)

## Examples

``` r
# \donttest{
taxify("Mammuthus primigenius", backend = "gbif") |>
  add_phylacine()
# }
```
