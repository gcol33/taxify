# Add reptile ecological traits and distribution (ReptTraits)

Joins species-level reptile traits from ReptTraits (Oskyrko et al. 2024)
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. ReptTraits is built on the Reptile
Database taxonomy, so it joins cleanly against the `reptiledb` backbone
(and any backbone that resolves to Reptile Database accepted names).

## Usage

``` r
add_repttraits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- biogeographic_realm:

  Main biogeographic realm (e.g. Neotropic, Palearctic, Afrotropic,
  Australo-Pacific, Marine).

- microhabitat:

  Microhabitat (e.g. Terrestrial, Saxicolous, Arboreal).

- habitat_type:

  Habitat type(s) (e.g. Forest, Desert, Wetlands).

- elevation_min_m:

  Minimum recorded elevation in metres.

- elevation_max_m:

  Maximum recorded elevation in metres.

- mean_annual_temp_c:

  Mean annual temperature across the range (degrees Celsius).

- insular_endemic:

  Whether the species is insular/endemic (`"Yes"`/`"No"`).

- body_mass_g:

  Maximum body mass in grams.

- svl_mm:

  Maximum snout-vent length (straight carapace length for turtles) in
  mm.

- total_length_mm:

  Maximum total length in mm.

- longevity_yr:

  Maximum longevity in years.

- diet:

  Diet category (e.g. Carnivorous, Herbivorous, Omnivorous).

- reproductive_mode:

  Reproductive mode (oviparous/viviparous/...).

- clutch_size:

  Mean clutch or litter size.

- active_time:

  Activity time (Diurnal/Nocturnal/Cathemeral).

- foraging_mode:

  Foraging mode (ACT active / AMB ambush / Mixed).

## Details

The layer carries a per-species distribution signal – biogeographic
realm, elevation range and mean climate – alongside body-size and
life-history traits, across all reptiles (snakes, lizards,
amphisbaenians, turtles, crocodiles and the tuatara), not lizards only.

Source: ReptTraits v1.2 (Oskyrko et al. 2024, Scientific Data, CC BY
4.0). Coverage: 12,060 reptile species. The biogeographic realm and
climate fields give a coarse, realm-level range signal; they are not a
fine-grained (TDWG-level) range like the plant ranges used by the
`region` constraint.

## References

Oskyrko O, Mi C, Meiri S, Du W (2024) ReptTraits: a comprehensive
dataset of ecological traits in reptiles. Scientific Data 11:243.
[doi:10.1038/s41597-024-03079-5](https://doi.org/10.1038/s41597-024-03079-5)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Pogona vitticeps", backend = "reptiledb") |>
  add_repttraits()

options(old)
```
