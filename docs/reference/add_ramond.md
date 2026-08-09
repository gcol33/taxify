# Add marine protist functional traits (Ramond et al.)

Joins genus-level morphological, behavioural and ecological traits of
marine protists to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `genus`, so any species in a covered genus is
annotated.

## Usage

``` r
add_ramond(x, cols = NULL, verbose = TRUE)
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

- ramond_shape:

  Cell shape (round, elongated, amoeboid, ...).

- ramond_motility:

  Motility mode (swimmer, floater, gliding, ...).

- ramond_ingestion:

  Ingestion / trophic mode (phagotrophic, ...).

- ramond_chloroplast:

  Chloroplast presence (1 = present).

- ramond_symbiontic:

  Symbiotic relationship (parasite, mutualist, ...).

- ramond_colony:

  Colony form.

- ramond_salinity:

  Salinity preference.

- ramond_size_min_um:

  Minimum cell size (micrometres).

- ramond_size_max_um:

  Maximum cell size (micrometres).

With `cols = "all"` the full set of behavioural, ecological and
symbiosis descriptors is attached under their source names.

## Details

Source: Ramond et al. (SEANOE, CC BY 4.0), functional traits of marine
protists. Traits are genus-level; numeric cell size is aggregated by
median, categorical traits by mode.

## References

Ramond P, Siano R, Sourisseau M (2018) Functional traits of marine
protists. SEANOE. [doi:10.17882/51662](https://doi.org/10.17882/51662)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify("Alexandrium", backbone = "gbif") |>
  add_ramond()
} # }
```
