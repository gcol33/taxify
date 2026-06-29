# Add aquatic-life traits (SeaLifeBase)

Joins SeaLifeBase morphological and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. SeaLifeBase is the non-fish
companion to FishBase: molluscs, crustaceans, echinoderms, marine
mammals, reptiles and other aquatic organisms. For fishes, use
[`add_fishbase()`](https://gillescolling.com/taxify/reference/add_fishbase.md).

## Usage

``` r
add_sealifebase(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- sb_body_length_cm:

  Maximum body length in centimetres.

- sb_body_mass_g:

  Body mass in grams where available.

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

## Details

Source: SeaLifeBase via rfishbase (Palomares & Pauly, CC BY-NC 3.0).
Non-fish aquatic life only.

The build-from-source fallback requires the rfishbase package (available
on CRAN). Pre-built `.vtr` files do not require rfishbase.

## References

Palomares MLD, Pauly D (eds.) (2024) SeaLifeBase. World Wide Web
electronic publication, <https://www.sealifebase.org>.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Octopus vulgaris", backend = "gbif") |>
  add_sealifebase()

options(old)
```
