# Add Collembola ecomorphosis (Bonfanti et al. 2022)

Joins the ecomorphosis record of a springtail species to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Ecomorphosis is a seasonal,
reversible change of form some Collembola undergo; this marks the
species known to display it.

## Usage

``` r
add_ecomorphosis(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) all, or a character vector
  of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns:

- ecomorphosis:

  Whether the species is known to display ecomorphosis.

- ecomorphosis_area:

  The morphological area affected.

- ecomorphosis_reference:

  The literature record establishing it.

## Details

Source: extended species list of Collembola known to display
ecomorphosis, Bonfanti (2022), Zenodo, CC BY 4.0. Coverage: 43 species,
each carrying the literature record for its ecomorphic form. It is a
presence list: a species not listed is not evidence of absence.

## References

Bonfanti J, Krogh PH, Hedde M, Cortet J (2022) Ecomorphosis in European
Collembola: a review in the context of trait-based ecology. Applied Soil
Ecology.
[doi:10.1016/j.apsoil.2022.104692](https://doi.org/10.1016/j.apsoil.2022.104692)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Hypogastrura vesiculosa", backbone = "gbif") |>
  add_ecomorphosis()
} # }
```
