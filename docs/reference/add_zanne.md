# Add woodiness (Zanne et al. 2014)

Joins the woody / herbaceous classification of Zanne et al. (2014) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. This is the source-named door for
the Zanne Global Woodiness Database; for woodiness reconciled across
every source that carries it (Zanne, GIFT), use
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
with `"woodiness"`.

## Usage

``` r
add_zanne(x, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with an additional column:

- woodiness:

  One of `"woody"`, `"herbaceous"`, `"variable"`, or `NA` if not in the
  dataset.

## Details

Source: Zanne et al. 2014, Nature (Dryad, CC0). Coverage: ~50k plant
species. Plants only.

## References

Zanne AE et al. (2014) Three keys to the radiation of angiosperms into
freezing environments. Nature 506:89-92.

## See also

[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
for woodiness harmonized across sources.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

taxify("Quercus robur") |>
  add_zanne()

options(old)
```
