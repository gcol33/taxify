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
add_ecoflora(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional `_uk` columns:

- height_max_mm_uk, height_min_mm_uk:

  Canopy height range (mm).

- leaf_area_uk:

  Leaf area class.

- leaf_longevity_uk:

  Leaf longevity (e.g. evergreen, deciduous).

- root_system_uk:

  Root system type.

- photosynthetic_pathway_uk:

  Photosynthetic pathway (C3/C4/CAM).

- life_form_uk:

  Raunkiaer life form.

- reproduction_uk:

  Reproduction method.

- flower_begin_month_uk, flower_end_month_uk:

  Flowering months (1-12).

- pollination_vector_uk:

  Pollen vector(s).

- seed_weight_mg_uk:

  Seed weight (mg).

- propagule_uk:

  Propagule / dispersule type.

- ell_light_uk, ell_moisture_uk, ell_reaction_uk, ell_nitrogen_uk,
  ell_salt_uk:

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

options(old)
```
