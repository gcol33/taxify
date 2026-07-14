# Add copepod traits (Brun et al. 2017)

Joins marine-copepod traits from the trait database of Brun et al.
(2017) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Records are reduced to per-species
values (numeric by median, categorical by mode).

## Usage

``` r
add_copepod_traits(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns. The default set:

- cop_body_length_mm:

  Body length (mm).

- cop_egg_diameter_um:

  Egg outer diameter (micrometres).

- cop_clutch_size:

  Clutch size.

- cop_feeding_mode:

  Feeding mode.

- cop_spawning_strategy:

  Spawning strategy.

`cols = "all"` also attaches feeder type, myelination, resting-egg
presence, and the per-species min/max/n spread of the numeric values.

## Details

Source: A trait database for marine copepods (Brun et al. 2017),
PANGAEA, CC BY 3.0.

## References

Brun P, Payne MR, Kiorboe T (2017) A trait database for marine copepods.
Earth System Science Data 9:99-113.
[doi:10.5194/essd-9-99-2017](https://doi.org/10.5194/essd-9-99-2017)

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloads the enrichment on first use.
taxify("Calanus finmarchicus", backend = "gbif") |>
  add_copepod_traits()
} # }
```
