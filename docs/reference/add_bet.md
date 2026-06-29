# Add bryophyte traits (Bryophytes of Europe Traits)

Joins species-level bryophyte traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_bet(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- bet_growth_form:

  Growth form (acrocarpous/pleurocarpous/thalloid/...).

- bet_life_form:

  Life form (cushion/mat/turf/weft/...).

- bet_life_strategy:

  Life strategy (During).

- bet_sexual_condition:

  Sexual condition (monoicous/dioicous).

- bet_shoot_size_mm:

  Mean shoot size (mm).

- bet_generation_length_y:

  Generation length (years).

- bet_spore_diameter_um:

  Mean spore diameter (micrometres).

- bet_ind_light:

  Ellenberg light indicator value.

- bet_ind_temperature:

  Ellenberg temperature indicator value.

- bet_ind_moisture:

  Ellenberg moisture indicator value.

- bet_ind_reaction_ph:

  Ellenberg reaction (pH) indicator value.

- bet_ind_nitrogen:

  Ellenberg nitrogen indicator value.

- bet_substrate_soil:

  Occurs on soil (0/1).

- bet_substrate_rock:

  Occurs on rock (0/1).

- bet_substrate_bark:

  Occurs on bark (0/1).

- bet_substrate_deadwood:

  Occurs on deadwood (0/1).

- bet_epiphyte:

  Epiphytic (0/1).

- bet_redlist_category:

  IUCN European Red List category.

## Details

Source: Bryophytes of Europe Traits (van Zuijlen et al. 2023, EnviDat,
CC BY-SA 4.0). Coverage: ~1.8k bryophyte species.

## References

van Zuijlen K et al. (2023) Bryophytes of Europe Traits (BET): a
fundamental dataset for European bryophyte ecology. EnviDat.
[doi:10.16904/envidat.348](https://doi.org/10.16904/envidat.348)

## Examples

``` r
# \donttest{
taxify("Abietinella abietina", backend = "gbif") |>
  add_bet()
# }
```
