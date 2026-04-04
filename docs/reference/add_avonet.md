# Add bird morphology and migration (AVONET)

Joins AVONET species-level averages for bird morphology, ecology, and
migration to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_avonet(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- beak_length:

  Beak length in mm (culmen, species mean).

- beak_depth:

  Beak depth in mm (species mean).

- wing_length:

  Wing length in mm (species mean).

- tail_length:

  Tail length in mm (species mean).

- tarsus_length:

  Tarsus length in mm (species mean).

- avonet_body_mass_g:

  Body mass in grams (species mean).

- hand_wing_index:

  Hand-wing index (pointedness, species mean).

- habitat:

  Primary habitat classification.

- trophic_level:

  Trophic level classification.

- trophic_niche:

  Trophic niche classification.

- migration:

  Migration strategy: `"sedentary"`, `"partial"`, or `"full"`.

## Details

Source: AVONET (Tobias et al. 2022, Figshare, CC BY 4.0). Coverage: ~11k
bird species. Birds only.

## References

Tobias JA et al. (2022) AVONET: morphological, ecological and
geographical data for all birds. Ecology Letters 25:581-597.

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Parus major") |>
  add_avonet()
} # }
```
