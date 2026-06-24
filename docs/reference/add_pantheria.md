# Add mammal life-history traits (PanTHERIA)

Joins PanTHERIA mammal life-history and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_pantheria(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- pantheria_body_mass_g:

  Adult body mass in grams.

- longevity_mo:

  Maximum longevity in months.

- litter_size:

  Litter size (mean).

- gestation_d:

  Gestation length in days.

- weaning_d:

  Weaning age in days.

- home_range_km2:

  Home range size in km\\^2\\.

- diet_breadth:

  Diet breadth (number of diet categories).

- habitat_breadth:

  Habitat breadth (number of habitat types).

## Details

Source: PanTHERIA (Jones et al. 2009, Ecological Archives, CC0).
Coverage: ~5.4k mammal species. Mammals only.

## References

Jones KE et al. (2009) PanTHERIA: a species-level database of life
history, ecology, and geography of extant and recently extinct mammals.
Ecology 90:2648.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Vulpes vulpes", backend = "gbif") |>
  add_pantheria()

options(old)
```
