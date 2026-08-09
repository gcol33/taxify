# Add Eberswalde long-term carabid monitoring traits and trends

Joins ground-beetle traits and 24-year local population trends to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by accepted name.

## Usage

``` r
add_eberswalde(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) all of them, or a character
  vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with `eberswalde_` columns: numeric
`body_length_mm`, `humidity_pref`, `range_centre_lat`,
`abundance_total`; categorical `wing_morph`, `feeding_guild`,
`abundance_trend`, `drought_effect`.

## Details

Source: Weiss, von Wehrden & Linde (2024), 27 species pitfall-trapped on
13 forest plots near Eberswalde between 1999 and 2022.

`body_length_mm`, `wing_morph` and `range_centre_lat` are carabids.org
(Homburg et al. 2014) verbatim, which the deposit's README states and
the data confirm: over the 19 species shared with
[`add_chowdhury()`](https://gillescolling.com/taxify/reference/add_chowdhury.md)
every size is exactly equal and every wing class agrees. They are
surfaced here because a door should show what its source carries, and
they are kept out of
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
where they would double-count one lineage.

What belongs to this deposit alone is the monitoring result:
`abundance_trend` over the 24 years, `drought_effect` against the
72-month SPEI index, and a `feeding_guild` refined by the authors' field
observations to name the prey. `humidity_pref` is Sustek's (2004) 1-8
scale, 1 dry to 8 humid.

## References

Weiss F, von Wehrden H, Linde A (2024) Eberswalde Carabid Monitoring
1999-2022 - Full Data. PubData Leuphana.
[doi:10.48548/pubdata-46](https://doi.org/10.48548/pubdata-46)

Weiss F, von Wehrden H, Linde A (2024) Long-term drought triggers severe
declines in carabid beetles in a temperate forest. Ecography
2024(4):e07020.
[doi:10.1111/ecog.07020](https://doi.org/10.1111/ecog.07020)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify(c("Carabus coriaceus", "Nebria brevicollis")) |>
  add_eberswalde()
} # }
```
