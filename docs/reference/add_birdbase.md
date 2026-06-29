# Add bird traits (BIRDBASE)

Joins BIRDBASE biogeography, conservation and life-history traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Traits redundant with
[`add_avonet()`](https://gillescolling.com/taxify/reference/add_avonet.md)
morphology are not carried.

## Usage

``` r
add_birdbase(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- birdbase_iucn_status:

  IUCN Red List category.

- birdbase_realm:

  Biogeographic realm.

- birdbase_latitudinal_zone:

  Latitudinal zone (1 tropical to 5).

- birdbase_island_endemic:

  Island-restricted breeding (0/1).

- birdbase_restricted_range:

  Restricted-range species (0/1).

- birdbase_elevation_min_m:

  Lower elevation limit (m).

- birdbase_elevation_max_m:

  Upper elevation limit (m).

- birdbase_elevation_range_m:

  Elevational breadth (m).

- birdbase_primary_habitat:

  Primary habitat.

- birdbase_habitat_breadth:

  Habitat breadth (number of habitats).

- birdbase_primary_diet:

  Primary diet.

- birdbase_diet_breadth:

  Diet breadth (number of food types).

- birdbase_specialization_esi:

  Ecological specialization index.

- birdbase_clutch_min:

  Minimum clutch size (eggs).

- birdbase_clutch_max:

  Maximum clutch size (eggs).

- birdbase_nest_type:

  Nest architecture.

- birdbase_flightlessness:

  Volancy (yes/no/partial).

## Details

Source: BIRDBASE (Sekercioglu et al. 2025, figshare, CC BY 4.0).
Coverage: ~11.6k bird species.

## References

Sekercioglu CH et al. (2025) BIRDBASE: a global database of bird
ecological and life-history traits. Scientific Data.
[doi:10.1038/s41597-025-05615-3](https://doi.org/10.1038/s41597-025-05615-3)

## Examples

``` r
# \donttest{
taxify("Struthio camelus", backend = "gbif") |>
  add_birdbase()
# }
```
