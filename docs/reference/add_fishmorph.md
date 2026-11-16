# Add freshwater fish morphological traits (FISHMORPH)

Joins FISHMORPH morphological trait data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. This function is named after its
source, FISHMORPH; for the fish reference database FishBase see
[`add_fishbase()`](https://gillescolling.com/taxify/reference/add_fishbase.md).

## Usage

``` r
add_fishmorph(x, cols = NULL, verbose = TRUE)
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

- fishmorph_fish_max_body_length:

  Maximum body length (cm).

- fishmorph_fish_body_elongation:

  Body elongation (body length / body depth).

- fishmorph_fish_vertical_eye_position:

  Vertical eye position (eye position / head depth).

- fishmorph_fish_relative_eye_size:

  Relative eye size (eye diameter / head length).

- fishmorph_fish_oral_gape_position:

  Oral gape position (mouth position: 0 = inferior, 0.5 = terminal, 1 =
  superior).

- fishmorph_fish_relative_maxillary_length:

  Relative maxillary length (maxillary length / head length).

- fishmorph_fish_body_lateral_shape:

  Body lateral shape (body depth / caudal peduncle depth).

- fishmorph_fish_pectoral_fin_position:

  Pectoral fin vertical position (fin insertion depth / body depth).

- fishmorph_fish_pectoral_fin_size:

  Pectoral fin size (fin length / body length).

- fishmorph_fish_caudal_peduncle_throttling:

  Caudal peduncle throttling (caudal peduncle depth / caudal fin depth).

## Details

Source: FISHMORPH (Brosse et al. 2021, Figshare, CC BY 4.0). Coverage:
~9k freshwater fish species.

## References

Brosse S, Charpin N, Su G, Toussaint A, Herrera-R GA, Tedesco PA,
Villegé r S (2021) FISHMORPH: A global database on morphological traits
of freshwater fishes. Global Ecology and Biogeography 30:2330-2336.
[doi:10.1111/geb.13395](https://doi.org/10.1111/geb.13395)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Salmo trutta", backbone = "gbif") |>
  add_fishmorph()
#> Matching 1 names...
#>     input_name matched_name accepted_name    taxon_id accepted_id    rank
#> 1 Salmo trutta Salmo trutta  Salmo trutta gbif-ex-009 gbif-ex-009 species
#>       family genus epithet     authorship accepted_authorship is_synonym
#> 1 Salmonidae Salmo  trutta Linnaeus, 1758      Linnaeus, 1758      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type
#> 1               <NA>                 NA        <NA>
#>   fishmorph_fish_max_body_length fishmorph_fish_body_elongation
#> 1        example_max_body_length        example_body_elongation
#>   fishmorph_fish_vertical_eye_position fishmorph_fish_relative_eye_size
#> 1        example_vertical_eye_position        example_relative_eye_size
#>   fishmorph_fish_oral_gape_position fishmorph_fish_relative_maxillary_length
#> 1        example_oral_gape_position        example_relative_maxillary_length
#>   fishmorph_fish_body_lateral_shape fishmorph_fish_pectoral_fin_position
#> 1        example_body_lateral_shape        example_pectoral_fin_position
#>   fishmorph_fish_pectoral_fin_size fishmorph_fish_caudal_peduncle_throttling
#> 1        example_pectoral_fin_size        example_caudal_peduncle_throttling
#> Sources: GBIF example, FISHMORPH example | cite() for full citations

options(old)
```
