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

- sb_body_length_cm:

  Maximum body length in centimetres.

- sb_body_mass_g:

  Maximum published weight in grams (SeaLifeBase `SPECIES.Weight`). This
  is a record maximum, not a typical or adult-mean mass.

- sb_trophic_level:

  Trophic level.

- sb_depth_min_m:

  Minimum depth in metres.

- sb_depth_max_m:

  Maximum depth in metres.

- sb_vulnerability:

  Vulnerability index (0–100).

- sb_habitat:

  Habitat type (e.g. benthic, pelagic).

- sb_importance:

  Commercial importance category.

- sb_lw_a:

  Coefficient `a` of the length-weight relationship `W = a * L^b`
  (weight in g, length in cm of type `sb_lw_type`), from SeaLifeBase's
  POPLW table.

- sb_lw_b:

  Exponent `b` of the length-weight relationship.

- sb_lw_type:

  Length convention the coefficients were fitted against (`TL` total,
  `SL` standard, `WD` width, ...). Chosen to match the species'
  maximum-length type where recorded, so it applies to
  `sb_body_length_cm`. Applying a coefficient to a different length type
  is a silent error.

- sb_lw_method:

  How the fit was obtained (e.g. "type I linear regression", "single L-W
  pair with b=3").

- sb_lw_sex:

  Sex the fit applies to (unsexed, mixed, female, male, juvenile).

- sb_lw_n:

  Sample size the fit was based on.

- sb_lw_r2:

  Coefficient of determination (`r^2`) of the fit.

## Details

Source: SeaLifeBase via rfishbase (Palomares & Pauly, CC BY-NC 4.0).
Non-fish aquatic life only.

The `sb_lw_*` columns give one representative length-weight fit per
species from the POPLW table, so a length can be converted to a mass
where `sb_body_mass_g` (a record maximum) is not what you want.

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

options(old)
```
