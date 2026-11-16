# Add reptile ecological traits and distribution (ReptTraits)

Joins species-level reptile traits from ReptTraits (Oskyrko et al. 2024)
to a [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. ReptTraits is built on the Reptile
Database taxonomy, so it joins cleanly against the `reptiledb` backbone
(and any backbone that resolves to Reptile Database accepted names).

## Usage

``` r
add_repttraits(x, cols = NULL, verbose = TRUE)
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

- repttraits_biogeographic_realm:

  Main biogeographic realm (e.g. Neotropic, Palearctic, Afrotropic,
  Australo-Pacific, Marine).

- repttraits_microhabitat:

  Microhabitat (e.g. Terrestrial, Saxicolous, Arboreal).

- repttraits_habitat_type:

  Habitat type(s) (e.g. Forest, Desert, Wetlands).

- repttraits_elevation_min_m:

  Minimum recorded elevation in metres.

- repttraits_elevation_max_m:

  Maximum recorded elevation in metres.

- repttraits_mean_annual_temp_c:

  Mean annual temperature across the range (degrees Celsius).

- repttraits_insular_endemic:

  Whether the species is insular/endemic (`"Yes"`/`"No"`).

- repttraits_body_mass_g:

  Maximum body mass in grams.

- repttraits_svl_mm:

  Maximum snout-vent length (straight carapace length for turtles) in
  mm.

- repttraits_total_length_mm:

  Maximum total length in mm.

- repttraits_longevity_yr:

  Maximum longevity in years.

- repttraits_diet:

  Diet category (e.g. Carnivorous, Herbivorous, Omnivorous).

- repttraits_reproductive_mode:

  Reproductive mode (oviparous/viviparous/...).

- repttraits_clutch_size:

  Mean clutch or litter size.

- repttraits_active_time:

  Activity time (Diurnal/Nocturnal/Cathemeral).

- repttraits_foraging_mode:

  Foraging mode (ACT active / AMB ambush / Mixed).

## Details

The dataset carries a per-species distribution signal (biogeographic
realm, elevation range and mean climate) alongside body-size and
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

taxify("Pogona vitticeps", backbone = "reptiledb") |>
  add_repttraits()
#> Matching 1 names...
#>         input_name     matched_name    accepted_name         taxon_id
#> 1 Pogona vitticeps Pogona vitticeps Pogona vitticeps reptiledb-ex-001
#>        accepted_id    rank   family  genus   epithet authorship
#> 1 reptiledb-ex-001 species Agamidae Pogona vitticeps       <NA>
#>   accepted_authorship is_synonym taxonomic_status is_hybrid match_type
#> 1                <NA>      FALSE         ACCEPTED     FALSE      exact
#>   fuzzy_dist  backbone               backbone_version kingdom_group taxon_group
#> 1         NA reptiledb reptiledb:example (2026-06-24)      animalia      animal
#>   life_form qualifier qualifier_position aggregate_fallback hybrid_type
#> 1    animal      <NA>               <NA>                 NA        <NA>
#>   repttraits_biogeographic_realm repttraits_microhabitat
#> 1    example_biogeographic_realm    example_microhabitat
#>   repttraits_habitat_type repttraits_insular_endemic repttraits_diet
#> 1    example_habitat_type    example_insular_endemic    example_diet
#>   repttraits_reproductive_mode repttraits_active_time repttraits_foraging_mode
#> 1    example_reproductive_mode    example_active_time    example_foraging_mode
#>   repttraits_elevation_min_m repttraits_elevation_max_m
#> 1                         11                         11
#>   repttraits_mean_annual_temp_c repttraits_body_mass_g repttraits_svl_mm
#> 1                            11                     11                11
#>   repttraits_total_length_mm repttraits_longevity_yr repttraits_clutch_size
#> 1                         11                      11                     11
#> Sources: REPTILEDB example, ReptTraits (Oskyrko et al. 2024) example | cite() for full citations

options(old)
```
