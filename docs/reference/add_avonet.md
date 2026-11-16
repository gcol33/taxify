# Add bird morphology and migration (AVONET)

Joins AVONET species-level averages for bird morphology, ecology, and
migration to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_avonet(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach. `NULL` (the default) attaches the curated
  set; a character vector of column names attaches just those, and
  `"all"` attaches every column the source carries (see
  [`enrichment_cols()`](https://gillescolling.com/taxify/reference/enrichment_cols.md)).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- avonet_beak_length:

  Beak length in mm (culmen, species mean).

- avonet_beak_depth:

  Beak depth in mm (species mean).

- avonet_wing_length:

  Wing length in mm (species mean).

- avonet_tail_length:

  Tail length in mm (species mean).

- avonet_tarsus_length:

  Tarsus length in mm (species mean).

- avonet_body_mass_g:

  Body mass in grams (species mean).

- avonet_hand_wing_index:

  Hand-wing index (pointedness, species mean).

- avonet_habitat:

  Primary avonet_habitat classification.

- avonet_trophic_level:

  Trophic level classification.

- avonet_trophic_niche:

  Trophic niche classification.

- avonet_migration:

  Migration strategy: `"sedentary"`, `"partial"`, or `"full"`.

## Details

Source: AVONET (Tobias et al. 2022, Figshare, CC BY 4.0). Coverage: ~11k
bird species. Birds only.

## References

Tobias JA et al. (2022) AVONET: morphological, ecological and
geographical data for all birds. Ecology Letters 25:581-597.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Parus major", backbone = "gbif") |>
  add_avonet()
#> Matching 1 names...
#>    input_name matched_name accepted_name    taxon_id accepted_id    rank
#> 1 Parus major  Parus major   Parus major gbif-ex-002 gbif-ex-002 species
#>    family genus epithet     authorship accepted_authorship is_synonym
#> 1 Paridae Parus   major Linnaeus, 1758      Linnaeus, 1758      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type avonet_beak_length
#> 1               <NA>                 NA        <NA>                 11
#>   avonet_beak_depth avonet_wing_length avonet_tail_length avonet_tarsus_length
#> 1                11                 11                 11                   11
#>   avonet_body_mass_g avonet_hand_wing_index  avonet_habitat
#> 1                 11                     11 example_habitat
#>   avonet_trophic_level  avonet_trophic_niche  avonet_migration
#> 1                   11 example_trophic_niche example_migration
#> Sources: GBIF example, AVONET example | cite() for full citations

options(old)
```
