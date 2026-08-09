# Add plant traits (BIEN)

Joins BIEN plant functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Values are species-level
aggregates of public-access BIEN records (numeric by median, categorical
by mode).

## Usage

``` r
add_bien(x, cols = NULL, verbose = TRUE)
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

- bien_plant_height_m:

  Whole-plant height (m).

- bien_max_plant_height_m:

  Maximum whole-plant height (m).

- bien_dbh_cm:

  Diameter at breast height (cm).

- bien_sla_mm2_mg:

  Leaf area per leaf dry mass (SLA).

- bien_leaf_area_mm2:

  Leaf area.

- bien_leaf_dry_mass_mg:

  Leaf dry mass.

- bien_leaf_n_per_dry_mass:

  Leaf nitrogen per dry mass.

- bien_leaf_p_per_dry_mass:

  Leaf phosphorus per dry mass.

- bien_leaf_thickness_mm:

  Leaf thickness.

- bien_seed_mass_mg:

  Seed mass.

- bien_wood_density_g_cm3:

  Stem wood density (g/cm3).

- bien_leaf_lifespan:

  Leaf life span.

- bien_growth_form:

  Whole-plant growth form.

- bien_woodiness:

  Whole-plant woodiness.

- bien_dispersal_syndrome:

  Whole-plant dispersal syndrome.

- bien_flower_color:

  Flower colour.

## Details

Source: BIEN (Botanical Information and Ecology Network; Maitner et al.
2018, Methods Ecol Evol, CC BY). Coverage: tens of thousands of vascular
plant species.

## References

Maitner BS et al. (2018) The BIEN R package: A tool to access the
Botanical Information and Ecology Network (BIEN) database. Methods in
Ecology and Evolution 9:373-379.
[doi:10.1111/2041-210X.12861](https://doi.org/10.1111/2041-210X.12861)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus alba", backbone = "gbif") |>
  add_bien()

options(old)
```
