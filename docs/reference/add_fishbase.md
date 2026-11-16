# Add fish traits (FishBase)

Joins FishBase morphological and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_fishbase(x, cols = NULL, verbose = TRUE)
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

- fishbase_fb_body_length_cm:

  Maximum body length in centimetres.

- fishbase_fb_body_mass_g:

  Maximum published weight in grams (FishBase `SPECIES.Weight`). This is
  a record maximum, not a typical or adult-mean mass.

- fishbase_fb_trophic_level:

  Trophic level.

- fishbase_fb_depth_min_m:

  Minimum depth in metres.

- fishbase_fb_depth_max_m:

  Maximum depth in metres.

- fishbase_fb_vulnerability:

  Vulnerability index (0–100).

- fishbase_fb_habitat:

  Habitat type (e.g. demersal, pelagic).

- fishbase_fb_importance:

  Commercial importance category.

- fishbase_fb_lw_a:

  Coefficient `a` of the length-weight relationship `W = a * L^b`
  (weight in g, length in cm of type `fb_lw_type`), from FishBase's
  POPLW table.

- fishbase_fb_lw_b:

  Exponent `b` of the length-weight relationship.

- fishbase_fb_lw_type:

  Length convention the coefficients were fitted against (`TL` total,
  `SL` standard, `FL` fork, `WD` width, ...). Chosen to match the
  species' maximum-length type where recorded, so it applies to
  `fb_body_length_cm`. Applying a coefficient to a different length type
  is a silent error.

- fishbase_fb_lw_method:

  How the fit was obtained (e.g. "type I linear regression", "single L-W
  pair with b=3").

- fishbase_fb_lw_sex:

  Sex the fit applies to (unsexed, mixed, female, male, juvenile).

- fishbase_fb_lw_n:

  Sample size the fit was based on.

- fishbase_fb_lw_r2:

  Coefficient of determination (`r^2`) of the fit.

## Details

Source: FishBase via rfishbase (Froese & Pauly, CC BY-NC 4.0). Coverage:
~35k fish species. Fishes only.

The `fb_lw_*` columns give one representative length-weight fit per
species from the POPLW table, so a length can be converted to a mass
where `fb_body_mass_g` (a record maximum) does not fit the analysis.
FishBase's Bayesian congeneric estimates are not included; `fb_lw_*` are
measured fits.

The build-from-source fallback requires the rfishbase package (available
on CRAN). Pre-built `.vtr` files do not require rfishbase.

## References

Froese R, Pauly D (eds.) (2024) FishBase. World Wide Web electronic
publication, <https://www.fishbase.org>.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Gadus morhua", backbone = "gbif") |>
  add_fishbase()
#> Matching 1 names...
#>     input_name matched_name accepted_name    taxon_id accepted_id    rank
#> 1 Gadus morhua Gadus morhua  Gadus morhua gbif-ex-010 gbif-ex-010 species
#>    family genus epithet     authorship accepted_authorship is_synonym
#> 1 Gadidae Gadus  morhua Linnaeus, 1758      Linnaeus, 1758      FALSE
#>   taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1         ACCEPTED     FALSE      exact         NA     gbif
#>            backbone_version kingdom_group taxon_group life_form qualifier
#> 1 gbif:example (2026-06-24)      animalia      animal    animal      <NA>
#>   qualifier_position aggregate_fallback hybrid_type fishbase_fb_body_length_cm
#> 1               <NA>                 NA        <NA>                         11
#>   fishbase_fb_body_mass_g fishbase_fb_trophic_level fishbase_fb_depth_min_m
#> 1                      11                        11                      11
#>   fishbase_fb_depth_max_m fishbase_fb_vulnerability fishbase_fb_habitat
#> 1                      11                        11     example_habitat
#>   fishbase_fb_importance fishbase_fb_lw_a fishbase_fb_lw_b fishbase_fb_lw_type
#> 1     example_importance           0.0065           3.0982                  TL
#>      fishbase_fb_lw_method fishbase_fb_lw_sex fishbase_fb_lw_n
#> 1 type I linear regression            unsexed            16665
#>   fishbase_fb_lw_r2
#> 1            0.9929
#> Sources: GBIF example, FishBase example | cite() for full citations

options(old)
```
