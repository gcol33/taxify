# Add EIVE ecological indicator values

Joins EIVE 1.0 (Dengler et al. 2023) ecological indicator values to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. EIVE provides continuous indicator
values for European vascular plants, superseding the original ordinal
Ellenberg values.

## Usage

``` r
add_eive(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- eive_light:

  Light indicator value (continuous).

- eive_temperature:

  Temperature indicator value (continuous).

- eive_moisture:

  Moisture indicator value (continuous).

- eive_reaction:

  Soil reaction (pH) indicator value (continuous).

- eive_nutrients:

  Nutrient indicator value (continuous).

## Details

Source: EIVE 1.0 (Dengler et al. 2023, Zenodo, CC BY 4.0). Coverage:
~14.5k European vascular plant species.

## References

Dengler J et al. (2023) EIVE 1.0 – a standardized set of Ecological
Indicator Values for Europe. Vegetation Classification and Survey
4:7-29. doi:10.3897/VCS.98324

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Arrhenatherum elatius") |>
  add_eive()

options(old)
```
