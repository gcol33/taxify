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

- elton_traits_diet_inv:

  Percentage of diet: invertebrates.

- elton_traits_diet_vend:

  Percentage of diet: endothermic vertebrates.

- elton_traits_diet_vect:

  Percentage of diet: ectothermic vertebrates.

- elton_traits_diet_vfish:

  Percentage of diet: fish.

- elton_traits_diet_vunk:

  Percentage of diet: unknown vertebrates.

- elton_traits_diet_scav:

  Percentage of diet: scavenging.

- elton_traits_diet_fruit:

  Percentage of diet: fruit.

- elton_traits_diet_nect:

  Percentage of diet: nectar.

- elton_traits_diet_seed:

  Percentage of diet: seeds and nuts.

- elton_traits_diet_plantother:

  Percentage of diet: other plant material.

- elton_traits_foraging_water:

  Percentage of foraging: below water surface.

- elton_traits_foraging_ground:

  Percentage of foraging: on ground.

- elton_traits_foraging_understory:

  Percentage of foraging: in understory.

- elton_traits_foraging_midhigh:

  Percentage of foraging: in mid to high strata.

- elton_traits_foraging_canopy:

  Percentage of foraging: in canopy.

- elton_traits_foraging_aerial:

  Percentage of foraging: aerial.

- elton_traits_elton_body_mass_g:

  Body mass in grams.

- elton_traits_nocturnal:

  Nocturnal activity (0 = diurnal, 1 = elton_traits_nocturnal).

- elton_traits_diet_guild:

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
#> Matching 1 names...
#>    input_name matched_name accepted_name    taxon_id accepted_id    rank
#> 1 Parus major  Parus major   Parus major gbif-ex-002 gbif-ex-002 species
#>    family genus epithet     authorship accepted_authorship is_synonym
#> 1 Paridae Parus   major Linnaeus, 1758      Linnaeus, 1758      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type elton_traits_diet_inv
#> 1               <NA>                 NA        <NA>      example_diet_inv
#>   elton_traits_diet_vend elton_traits_diet_vect elton_traits_diet_vfish
#> 1      example_diet_vend      example_diet_vect      example_diet_vfish
#>   elton_traits_diet_vunk elton_traits_diet_scav elton_traits_diet_fruit
#> 1      example_diet_vunk      example_diet_scav      example_diet_fruit
#>   elton_traits_diet_nect elton_traits_diet_seed elton_traits_diet_plantother
#> 1      example_diet_nect      example_diet_seed      example_diet_plantother
#>   elton_traits_foraging_water elton_traits_foraging_ground
#> 1      example_foraging_water      example_foraging_ground
#>   elton_traits_foraging_understory elton_traits_foraging_midhigh
#> 1      example_foraging_understory      example_foraging_midhigh
#>   elton_traits_foraging_canopy elton_traits_foraging_aerial
#> 1      example_foraging_canopy      example_foraging_aerial
#>   elton_traits_elton_body_mass_g elton_traits_nocturnal elton_traits_diet_guild
#> 1                             11      example_nocturnal                omnivore
#> Sources: GBIF example, EltonTraits 1.0 example | cite() for full citations

options(old)
```
