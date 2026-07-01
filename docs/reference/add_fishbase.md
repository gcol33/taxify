# Add fish traits (FishBase)

Joins FishBase morphological and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_fishbase(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- fb_body_length_cm:

  Maximum body length in centimetres.

- fb_body_mass_g:

  Body mass in grams (estimated from length-weight relationships where
  available).

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

## Details

Source: FishBase via rfishbase (Froese & Pauly, CC BY-NC 4.0). Coverage:
~35k fish species. Fishes only.

The build-from-source fallback requires the rfishbase package (available
on CRAN). Pre-built `.vtr` files do not require rfishbase.

## References

Froese R, Pauly D (eds.) (2024) FishBase. World Wide Web electronic
publication, <https://www.fishbase.org>.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Gadus morhua", backend = "gbif") |>
  add_fishbase()

options(old)
```
