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

- fb_body_length_cm:

  Maximum body length in centimetres.

- fb_body_mass_g:

  Maximum published weight in grams (FishBase `SPECIES.Weight`). This is
  a record maximum, not a typical or adult-mean mass.

- fb_trophic_level:

  Trophic level.

- fb_depth_min_m:

  Minimum depth in metres.

- fb_depth_max_m:

  Maximum depth in metres.

- fb_vulnerability:

  Vulnerability index (0–100).

- fb_habitat:

  Habitat type (e.g. demersal, pelagic).

- fb_importance:

  Commercial importance category.

- fb_lw_a:

  Coefficient `a` of the length-weight relationship `W = a * L^b`
  (weight in g, length in cm of type `fb_lw_type`), from FishBase's
  POPLW table.

- fb_lw_b:

  Exponent `b` of the length-weight relationship.

- fb_lw_type:

  Length convention the coefficients were fitted against (`TL` total,
  `SL` standard, `FL` fork, `WD` width, ...). Chosen to match the
  species' maximum-length type where recorded, so it applies to
  `fb_body_length_cm`. Applying a coefficient to a different length type
  is a silent error.

- fb_lw_method:

  How the fit was obtained (e.g. "type I linear regression", "single L-W
  pair with b=3").

- fb_lw_sex:

  Sex the fit applies to (unsexed, mixed, female, male, juvenile).

- fb_lw_n:

  Sample size the fit was based on.

- fb_lw_r2:

  Coefficient of determination (`r^2`) of the fit.

## Details

Source: FishBase via rfishbase (Froese & Pauly, CC BY-NC 4.0). Coverage:
~35k fish species. Fishes only.

The `fb_lw_*` columns give one representative length-weight fit per
species from the POPLW table, so a length can be converted to a mass
where `fb_body_mass_g` (a record maximum) is not what you want.
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

options(old)
```
