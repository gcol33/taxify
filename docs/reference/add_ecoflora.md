# Add British plant traits from Ecoflora

Joins traits from the Ecological Flora of the British Isles (Fitter &
Peat 1994) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Ecoflora covers the vascular flora
of the British Isles, providing canopy height, leaf traits, life form,
flowering phenology, pollination and reproduction, seed weight, and
British-calibrated Ellenberg indicator values. Every column carries a
`_uk` suffix to mark the British-flora calibration and to avoid
collisions when chained with other plant-trait enrichments (e.g.
[`add_baseflor()`](https://gillescolling.com/taxify/reference/add_baseflor.md)
for France,
[`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md)
for Germany).

## Usage

``` r
add_ecoflora(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional `_uk` columns:

- ecoflora_height_max_mm_uk, ecoflora_height_min_mm_uk:

  Typical maximum and minimum plant height (mm; Ecoflora records cm).

- ecoflora_leaf_area_uk:

  Leaf area class (cm\\^2\\).

- ecoflora_leaf_longevity_uk:

  Leaf longevity (e.g. evergreen, deciduous).

- ecoflora_root_system_uk:

  Root system type.

- ecoflora_photosynthetic_pathway_uk:

  Photosynthetic pathway (C3/C4/CAM).

- ecoflora_life_form_uk:

  Raunkiaer life form.

- ecoflora_reproduction_uk:

  Reproduction method.

- ecoflora_flower_begin_month_uk, ecoflora_flower_end_month_uk:

  Flowering months (1-12).

- ecoflora_pollination_vector_uk:

  Pollen vector(s).

- ecoflora_seed_weight_mg_uk:

  Seed weight (mg).

- ecoflora_propagule_uk:

  Propagule / dispersule type.

- ecoflora_ell_light_uk, ecoflora_ell_moisture_uk,
  ecoflora_ell_reaction_uk, ecoflora_ell_nitrogen_uk, ell_salt_uk:

  Ellenberg indicator values calibrated for the British flora (light,
  moisture, reaction, nitrogen, salt).

## Details

Source: Ecoflora (Ecological Flora of the British Isles). Ecoflora has
no bulk download or API; the bundled dataset was collected one species
at a time and is redistributed under the source licence (CC BY-NC-SA
4.0). The `.vtr` is downloaded from the taxify release on first use and
cached.

For French-flora traits see
[`add_baseflor()`](https://gillescolling.com/taxify/reference/add_baseflor.md);
for German-flora traits see
[`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md);
for European-calibration indicator values see
[`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md).

## References

Fitter AH, Peat HJ (1994) The Ecological Flora Database. Journal of
Ecology 82:415-425.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Bellis perennis") |>
  add_ecoflora()
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Matching 1 remaining names...
#>   [lcvp] Matching 1 remaining names...
#>   [wfo] Matching 1 remaining names...
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>        input_name    matched_name   accepted_name   taxon_id accepted_id
#> 1 Bellis perennis Bellis perennis Bellis perennis wfo-ex-009  wfo-ex-009
#>      rank     family  genus  epithet authorship accepted_authorship is_synonym
#> 1 species Asteraceae Bellis perennis         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      wfo
#>           backbone_version kingdom_group taxon_group life_form qualifier
#> 1 wfo:example (2026-06-24)       plantae     unknown   unknown      <NA>
#>   qualifier_position aggregate_fallback hybrid_type ecoflora_height_max_mm_uk
#> 1               <NA>                 NA        <NA>  example_height_max_mm_uk
#>   ecoflora_height_min_mm_uk ecoflora_leaf_area_uk ecoflora_leaf_longevity_uk
#> 1  example_height_min_mm_uk  example_leaf_area_uk  example_leaf_longevity_uk
#>   ecoflora_root_system_uk ecoflora_photosynthetic_pathway_uk
#> 1  example_root_system_uk  example_photosynthetic_pathway_uk
#>   ecoflora_life_form_uk ecoflora_reproduction_uk ecoflora_flower_begin_month_uk
#> 1  example_life_form_uk  example_reproduction_uk  example_flower_begin_month_uk
#>   ecoflora_flower_end_month_uk ecoflora_pollination_vector_uk
#> 1  example_flower_end_month_uk  example_pollination_vector_uk
#>   ecoflora_seed_weight_mg_uk ecoflora_propagule_uk ecoflora_ell_light_uk
#> 1  example_seed_weight_mg_uk  example_propagule_uk  example_ell_light_uk
#>   ecoflora_ell_moisture_uk ecoflora_ell_reaction_uk ecoflora_ell_nitrogen_uk
#> 1  example_ell_moisture_uk  example_ell_reaction_uk  example_ell_nitrogen_uk
#>   ecoflora_ell_salt_uk
#> 1  example_ell_salt_uk
#> Sources: WFO example, Ecoflora (Ecological Flora of the British Isles) example | cite() for full citations

options(old)
```
