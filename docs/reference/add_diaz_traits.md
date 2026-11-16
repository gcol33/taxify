# Add seed mass and plant height (Diaz et al. 2022)

Joins species-level mean seed mass and plant height from Diaz et al.
(2022) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_diaz_traits(x, cols = NULL, verbose = TRUE)
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

- diaz_traits_seed_mass_mg:

  Seed mass in milligrams (species-level mean).

- diaz_traits_plant_height_m:

  Plant height in metres (species-level mean).

## Details

Source: Diaz et al. 2022, TRY File Archive (CC BY 3.0). Coverage: ~46k
plant species. Plants only.

## References

Diaz S, Kattge J, Cornelissen JHC, Wright IJ, Lavorel S, Dray S, Reu B,
Kleyer M, Wirth C, Prentice IC, et al. (2022) The global spectrum of
plant form and function: enhanced species-level trait dataset.
Scientific Data 9:755.
[doi:10.1038/s41597-022-01774-9](https://doi.org/10.1038/s41597-022-01774-9)

Diaz S, Kattge J, Cornelissen JHC, Wright IJ, Lavorel S, Dray S, Reu B,
Kleyer M, Wirth C, Prentice IC, et al. (2016) The global spectrum of
plant form and function. Nature 529:167-171.
[doi:10.1038/nature16489](https://doi.org/10.1038/nature16489)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_diaz_traits()
#> Matching 1 names against 8 backbones: col -> wcvp -> lcvp -> wfo -> fishbase -> sealifebase -> reptiledb -> gbif
#>   [col] Matching 1 names...
#>   [wcvp] Skipped (all names matched)
#>   [lcvp] Skipped (all names matched)
#>   [wfo] Skipped (all names matched)
#>   [fishbase] Skipped (all names matched)
#>   [sealifebase] Skipped (all names matched)
#>   [reptiledb] Skipped (all names matched)
#>   [gbif] Skipped (all names matched)
#>      input_name  matched_name accepted_name   taxon_id accepted_id    rank
#> 1 Quercus robur Quercus robur Quercus robur col-ex-001  col-ex-001 species
#>     family   genus epithet authorship accepted_authorship is_synonym
#> 1 Fagaceae Quercus   robur         L.                  L.      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA      col
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 col:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type diaz_traits_seed_mass_mg
#> 1               <NA>                 NA        <NA>                     3000
#>   diaz_traits_plant_height_m
#> 1                         30
#> Sources: COL example, Diaz et al. 2022 example | cite() for full citations

options(old)
```
