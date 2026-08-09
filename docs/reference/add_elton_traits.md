# Add diet, foraging, and body mass (EltonTraits 1.0)

Joins EltonTraits 1.0 diet composition, foraging strata, body mass, and
activity data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_elton_traits(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every column the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- diet_inv:

  Percentage of diet: invertebrates.

- diet_vend:

  Percentage of diet: endothermic vertebrates.

- diet_vect:

  Percentage of diet: ectothermic vertebrates.

- diet_vfish:

  Percentage of diet: fish.

- diet_vunk:

  Percentage of diet: unknown vertebrates.

- diet_scav:

  Percentage of diet: scavenging.

- diet_fruit:

  Percentage of diet: fruit.

- diet_nect:

  Percentage of diet: nectar.

- diet_seed:

  Percentage of diet: seeds and nuts.

- diet_plantother:

  Percentage of diet: other plant material.

- foraging_water:

  Percentage of foraging: below water surface.

- foraging_ground:

  Percentage of foraging: on ground.

- foraging_understory:

  Percentage of foraging: in understory.

- foraging_midhigh:

  Percentage of foraging: in mid to high strata.

- foraging_canopy:

  Percentage of foraging: in canopy.

- foraging_aerial:

  Percentage of foraging: aerial.

- elton_body_mass_g:

  Body mass in grams.

- nocturnal:

  Nocturnal activity (0 = diurnal, 1 = nocturnal).

- diet_guild:

  Dominant diet guild derived from the ten diet-fraction columns
  (fractions summed within guild, the guild reaching 50 percent wins,
  otherwise omnivore): carnivore, herbivore, omnivore, invertivore,
  frugivore, granivore, nectarivore, scavenger. Also reachable across
  sources via `add_trait(x, "diet_guild")`.

## Details

Source: EltonTraits 1.0 (Wilman et al. 2014, Figshare, CC0). Coverage:
~15.4k species. Birds and mammals only.

## References

Wilman H et al. (2014) EltonTraits 1.0: Species-level foraging
attributes of the world's birds and mammals. Ecology 95:2027.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Parus major", backbone = "gbif") |>
  add_elton_traits()

options(old)
```
