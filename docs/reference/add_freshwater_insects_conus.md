# Add freshwater-insect genus traits (Freshwater Insects CONUS)

Joins genus-level ecological and life-history trait modalities of North
American freshwater insects to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `genus`, so any species in a covered genus is
annotated. The modalities are the source's own abbreviation codes, kept
verbatim.

## Usage

``` r
add_freshwater_insects_conus(x, cols = NULL, verbose = TRUE)
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

The same data.frame with additional columns. The curated set:

- fwinsect_thermal_pref:

  Thermal preference class.

- fwinsect_feed_prim:

  Primary functional feeding group code.

- fwinsect_habit_prim:

  Primary habit (swimmer, clinger, burrower, ...).

- fwinsect_rheophily:

  Rheophily (current preference) code.

- fwinsect_voltinism:

  Voltinism (generations per year) code.

- fwinsect_max_body_size:

  Maximum body size class.

With `cols = "all"` the remaining trait groups (emergence, dispersal,
respiration, ...) are attached under their source names.

## Details

Source: Twardochleb et al. (2021, Environmental Data Initiative, CC BY
4.0), the Freshwater Insects CONUS genus trait table. Traits are
genus-level categorical modalities.

## References

Twardochleb LA et al. (2021) Freshwater insect occurrences and traits
for the contiguous United States, 2001-2018. Environmental Data
Initiative.
[doi:10.6073/pasta/8238ea9bc15840844b3a023b6b6ed158](https://doi.org/10.6073/pasta/8238ea9bc15840844b3a023b6b6ed158)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Baetis", backbone = "gbif") |>
  add_freshwater_insects_conus()
} # }
```
