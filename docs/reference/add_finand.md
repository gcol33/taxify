# Add Helsinki urban-forest carabid traits (Finand & Kotze)

Joins ground-beetle traits measured from Helsinki specimens to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by accepted name.

## Usage

``` r
add_finand(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `finand_` columns: numeric `body_length_mm`;
categorical `wing_morph`, `feeding_type`, `habitat_pref`,
`moisture_pref`.

## Details

Source: Finand & Kotze (2025), 34 species from 25 remnant urban forests
in Helsinki.

Small, and carried for a reason no larger source can supply. Every other
reachable carabid trait table traces its body sizes and wing classes
back to carabids.org (Homburg et al. 2014), so agreement between them is
not corroboration. These body lengths were measured from the beetles the
authors caught, which makes them the one independent check: they run at
a median ratio of 0.9946 against the NW European arthropod compilation
over 28 shared species, with only 7.1 percent exactly equal.

`body_length_mm` is a whole-body length despite the source column being
terse about it; elytra length would sit near 0.6 of these values.

`wing_morph` records the morph of the beetles caught in Helsinki, so it
can name a definite morph where a species-level source calls the species
dimorphic. Compare
[`add_chowdhury()`](https://gillescolling.com/taxify/reference/add_chowdhury.md),
which states the species' capacity.

## References

Finand B, Kotze DJ (2025) Habitat specialisation and dispersal capacity
drive rapid carabid beetle responses to urban forest fragmentation.
Zenodo.
[doi:10.5281/zenodo.17184995](https://doi.org/10.5281/zenodo.17184995)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify(c("Carabus glabratus", "Cychrus caraboides")) |>
  add_finand()
} # }
```
