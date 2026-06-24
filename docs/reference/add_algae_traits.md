# Add macroalgal functional traits (AlgaeTraits)

Joins AlgaeTraits (Vranken et al. 2023) macroalgal functional traits to
a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. AlgaeTraits provides
morphological, ecological, and life-history traits for European
seaweeds.

## Usage

``` r
add_algae_traits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- algae_body_size_cm:

  Maximum body size in centimetres.

- algae_growth_form:

  Growth form / body shape (e.g., filamentous, foliose, crustose).

- algae_calcification:

  Calcification type (e.g., uncalcified, articulated, encrusting).

- algae_life_span:

  Life span category (annual, perennial, etc.).

- algae_tidal_zone:

  Tidal zonation (e.g., supralittoral, eulittoral, sublittoral).

- algae_wave_exposure:

  Wave exposure tolerance (sheltered, moderately exposed, exposed).

- algae_environment:

  Habitat environment (marine, brackish, freshwater).

- algae_substrate:

  Environmental position / substrate type.

## Details

Source: AlgaeTraits (Vranken et al. 2023, VLIZ Marine Data Archive, CC
BY 4.0). Coverage: ~1,745 European macroalgae species.

## References

Vranken S et al. (2023) AlgaeTraits: a trait database for (European)
seaweeds. Earth System Science Data 15:2711-2754.
doi:10.5194/essd-15-2711-2023

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Fucus vesiculosus", backend = "gbif") |>
  add_algae_traits()

options(old)
```
