# Add butterfly traits (LepTraits)

Joins LepTraits 1.0 butterfly life-history and ecological traits to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`.

## Usage

``` r
add_leptraits(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- wingspan_mm:

  Wingspan in mm (midpoint of lower and upper bounds).

- voltinism:

  Number of generations per year.

- diapause_stage:

  Overwintering/diapause life stage.

- canopy_affinity:

  Canopy association category.

- edge_affinity:

  Edge/gap affinity category.

- moisture_affinity:

  Moisture affinity category.

- disturbance_affinity:

  Disturbance affinity category.

- n_hostplant_families:

  Number of host plant families used.

- flight_months:

  Number of months with adult flight activity.

## Details

Source: LepTraits 1.0 (Shirey et al. 2022, CC0). Coverage: ~12.4k
butterfly species globally (Papilionoidea).

## References

Shirey V et al. (2022) LepTraits 1.0: A globally comprehensive dataset
of butterfly traits. Scientific Data 9:398.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Vanessa cardui", backend = "gbif") |>
  add_leptraits()

options(old)
```
