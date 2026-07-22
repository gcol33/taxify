# Add benthic invertebrate traits (Cefas)

Joins biological traits of North-West European continental-shelf benthic
macrofauna from the Cefas biological-traits database to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `genus`. The source fuzzy-codes traits at genus
level, and each trait is reduced to its highest-scoring modality, so the
join is on `genus` rather than `accepted_name`: every species in a coded
genus is annotated.

## Usage

``` r
add_cefas_btrait(x, cols = NULL, verbose = TRUE)
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

- cefas_body_size:

  Maximum body-size class.

- cefas_morphology:

  Body morphology.

- cefas_lifespan:

  Life-span class.

- cefas_living_habit:

  Living habit.

- cefas_feeding_mode:

  Feeding mode.

- cefas_mobility:

  Mobility.

- cefas_bioturbation:

  Bioturbation mode.

`cols = "all"` also attaches egg and larval development and sediment
position.

## Details

Source: North-West European continental-shelf benthos biological-traits
database, Cefas Data Hub
([doi:10.14466/CefasDataHub.123](https://doi.org/10.14466/CefasDataHub.123)
), Open Government Licence v3.0.

## References

Centre for Environment, Fisheries and Aquaculture Science (2022)
North-West European continental-shelf benthos biological-traits
database.
[doi:10.14466/CefasDataHub.123](https://doi.org/10.14466/CefasDataHub.123)

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloads the enrichment on first use.
taxify("Abra alba", backbone = "gbif") |>
  add_cefas_btrait()
} # }
```
