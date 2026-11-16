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

  Leaf area per leaf dry mass (SLA, mm2/mg).

- bien_leaf_area_mm2:

  Leaf area (mm2).

- bien_leaf_dry_mass_mg:

  Leaf dry mass (mg; BIEN records g).

- bien_leaf_n_per_dry_mass:

  Leaf nitrogen per dry mass (mg/g).

- bien_leaf_p_per_dry_mass:

  Leaf phosphorus per dry mass (mg/g).

- bien_leaf_thickness_mm:

  Leaf thickness (mm).

- bien_seed_mass_mg:

  Seed mass (mg).

- bien_wood_density_g_cm3:

  Stem wood density (g/cm3).

- bien_leaf_lifespan:

  Leaf life span (months).

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
#> Matching 1 names...
#>   Fuzzy matching 1 unmatched...
#>     input_name matched_name accepted_name taxon_id accepted_id rank family
#> 1 Quercus alba         <NA>          <NA>     <NA>        <NA> <NA>   <NA>
#>   genus epithet authorship accepted_authorship is_synonym taxonomic_status
#> 1  <NA>    <NA>       <NA>                <NA>         NA             <NA>
#>   is_hybrid match_type fuzzy_dist backbone backbone_version kingdom_group
#> 1     FALSE       none         NA     <NA>             <NA>       plantae
#>   taxon_group  life_form qualifier qualifier_position aggregate_fallback
#> 1  angiosperm angiosperm      <NA>               <NA>                 NA
#>   hybrid_type bien_plant_height_m bien_max_plant_height_m bien_dbh_cm
#> 1        <NA>                  NA                      NA          NA
#>   bien_sla_mm2_mg bien_leaf_area_mm2 bien_leaf_dry_mass_mg
#> 1              NA                 NA                    NA
#>   bien_leaf_n_per_dry_mass bien_leaf_p_per_dry_mass bien_leaf_thickness_mm
#> 1                       NA                       NA                     NA
#>   bien_seed_mass_mg bien_wood_density_g_cm3 bien_leaf_lifespan bien_growth_form
#> 1                NA                      NA                 NA             <NA>
#>   bien_woodiness bien_dispersal_syndrome bien_flower_color
#> 1           <NA>                    <NA>              <NA>

options(old)
```
