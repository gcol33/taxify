# Add Mediterranean plant traits (BROT 2.0)

Joins Mediterranean-Basin plant fire-response, regeneration and
functional traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by `accepted_name`.

## Usage

``` r
add_brot(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `brot_` columns: numeric `brot_seed_mass_mg`,
`brot_sla_mm2_mg`, `brot_height_m`, `brot_leaf_area_mm2`; categorical
`brot_resp_fire`, `brot_growth_form`, `brot_disp_mode`,
`brot_fruit_type`, `brot_soil_seed_bank`, `brot_seedling_emergence`.

## Details

Source: BROT 2.0 (Tavsanoglu & Pausas 2018, Scientific Data, CC-BY 4.0).

## References

Tavsanoglu C, Pausas JG (2018) A functional trait database for
Mediterranean Basin plants (BROT 2.0). Scientific Data 5:180135.
[doi:10.6084/m9.figshare.c.3843841](https://doi.org/10.6084/m9.figshare.c.3843841)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus coccifera", backbone = "gbif") |>
  add_brot()
#> Matching 1 names...
#>   Fuzzy matching 1 unmatched...
#> add_brot(): attaching 10 of 20 columns. Pass cols = "all" for all, or see enrichment_cols("brot").
#>          input_name matched_name accepted_name taxon_id accepted_id rank family
#> 1 Quercus coccifera         <NA>          <NA>     <NA>        <NA> <NA>   <NA>
#>   genus epithet authorship accepted_authorship is_synonym taxonomic_status
#> 1  <NA>    <NA>       <NA>                <NA>         NA             <NA>
#>   is_hybrid match_type fuzzy_dist backbone backbone_version kingdom_group
#> 1     FALSE       none         NA     <NA>             <NA>       plantae
#>   taxon_group  life_form qualifier qualifier_position aggregate_fallback
#> 1  angiosperm angiosperm      <NA>               <NA>                 NA
#>   hybrid_type brot_seed_mass_mg brot_sla_mm2_mg brot_height_m
#> 1        <NA>                NA              NA            NA
#>   brot_leaf_area_mm2 brot_resp_fire brot_growth_form brot_disp_mode
#> 1                 NA           <NA>             <NA>           <NA>
#>   brot_fruit_type brot_soil_seed_bank brot_seedling_emergence
#> 1            <NA>                <NA>                    <NA>

options(old)
```
