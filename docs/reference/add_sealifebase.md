# Add aquatic-life traits (SeaLifeBase)

Joins SeaLifeBase morphological and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. SeaLifeBase is the non-fish
companion to FishBase: molluscs, crustaceans, echinoderms, marine
mammals, reptiles and other aquatic organisms. For fishes, use
[`add_fishbase()`](https://gillescolling.com/taxify/reference/add_fishbase.md).

## Usage

``` r
add_sealifebase(x, cols = NULL, verbose = TRUE)
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

- sealifebase_sb_body_length_cm:

  Maximum body length in centimetres.

- sealifebase_sb_body_mass_g:

  Maximum published weight in grams (SeaLifeBase `SPECIES.Weight`). This
  is a record maximum, not a typical or adult-mean mass.

- sealifebase_sb_trophic_level:

  Trophic level.

- sealifebase_sb_depth_min_m:

  Minimum depth in metres.

- sealifebase_sb_depth_max_m:

  Maximum depth in metres.

- sealifebase_sb_vulnerability:

  Vulnerability index (0–100).

- sealifebase_sb_habitat:

  Habitat type (e.g. benthic, pelagic).

- sealifebase_sb_importance:

  Commercial importance category.

- sealifebase_sb_lw_a:

  Coefficient `a` of the length-weight relationship `W = a * L^b`
  (weight in g, length in cm of type `sb_lw_type`), from SeaLifeBase's
  POPLW table.

- sealifebase_sb_lw_b:

  Exponent `b` of the length-weight relationship.

- sealifebase_sb_lw_type:

  Length convention the coefficients were fitted against (`TL` total,
  `SL` standard, `WD` width, ...). Chosen to match the species'
  maximum-length type where recorded, so it applies to
  `sb_body_length_cm`. Applying a coefficient to a different length type
  is a silent error.

- sealifebase_sb_lw_method:

  How the fit was obtained (e.g. "type I linear regression", "single L-W
  pair with b=3").

- sealifebase_sb_lw_sex:

  Sex the fit applies to (unsexed, mixed, female, male, juvenile).

- sealifebase_sb_lw_n:

  Sample size the fit was based on.

- sealifebase_sb_lw_r2:

  Coefficient of determination (`r^2`) of the fit.

## Details

Source: SeaLifeBase via rfishbase (Palomares & Pauly, CC BY-NC 4.0).
Non-fish aquatic life only.

The `sb_lw_*` columns give one representative length-weight fit per
species from the POPLW table, so a length can be converted to a mass
where `sb_body_mass_g` (a record maximum) does not fit the analysis.

The build-from-source fallback requires the rfishbase package (available
on CRAN). Pre-built `.vtr` files do not require rfishbase.

## References

Palomares MLD, Pauly D (eds.) (2024) SeaLifeBase. World Wide Web
electronic publication, <https://www.sealifebase.org>.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Octopus vulgaris", backbone = "gbif") |>
  add_sealifebase()
#> Matching 1 names...
#>         input_name     matched_name    accepted_name    taxon_id accepted_id
#> 1 Octopus vulgaris Octopus vulgaris Octopus vulgaris gbif-ex-015 gbif-ex-015
#>      rank      family   genus  epithet   authorship accepted_authorship
#> 1 species Octopodidae Octopus vulgaris Cuvier, 1797        Cuvier, 1797
#>   is_synonym taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1      FALSE         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type
#> 1               <NA>                 NA        <NA>
#>   sealifebase_sb_body_length_cm sealifebase_sb_body_mass_g
#> 1                            11                         11
#>   sealifebase_sb_trophic_level sealifebase_sb_depth_min_m
#> 1                           11                         11
#>   sealifebase_sb_depth_max_m sealifebase_sb_vulnerability
#> 1                         11                           11
#>   sealifebase_sb_habitat sealifebase_sb_importance sealifebase_sb_lw_a
#> 1        example_habitat        example_importance               0.485
#>   sealifebase_sb_lw_b sealifebase_sb_lw_type sealifebase_sb_lw_method
#> 1               2.908                     ML     nonlinear regression
#>   sealifebase_sb_lw_sex sealifebase_sb_lw_n sealifebase_sb_lw_r2
#> 1               unsexed                 800                0.841
#> Sources: GBIF example, SeaLifeBase example | cite() for full citations

options(old)
```
