# Add root-nodule nitrogen fixation (NodDB)

Joins the nodulation status of a plant genus to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result. NodDB records nodulation per genus, so the join is on `genus`,
the same grain as
[`add_fungalroot()`](https://gillescolling.com/taxify/reference/add_fungalroot.md).

## Usage

``` r
add_noddb(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `noddb_` columns: `nodulation_consensus`,
`nodulation_type`, `nodulation_clade`, `nodulation_family`,
`spp_recognized`, `spp_studied`, `positive_reports`, `negative_reports`.

## Details

Source: Tedersoo et al. (2018), 824 plant genera. CC BY-SA 4.0.

`nodulation_consensus` is the authors' verdict verbatim, which
distinguishes a confirmed record from a phylogenetic inference
(`Rhizobia` against `likely_Rhizobia`) and carries their negative calls
as `unlikely_Rhizobia` and `unlikely_Frankia`. `nodulation_type`
collapses that to the symbiont involved – `rhizobia`, `frankia`,
`nostocaceae`, `present`, `none` – reading both `unlikely_` verdicts as
`none`.

`positive_reports` and `negative_reports` are the counts of published
observations behind the verdict, so a thinly evidenced call is visible.

## References

Tedersoo L, Laanisto L, Rahimlou S, Toussaint A, Hallikma T, Partel M
(2018) Global database of plants with root-symbiotic nitrogen fixation:
NodDB. Journal of Vegetation Science 29:560-568.
[doi:10.1111/jvs.12627](https://doi.org/10.1111/jvs.12627)

Data: [doi:10.15156/BIO/587469](https://doi.org/10.15156/BIO/587469)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify(c("Pisum sativum", "Alnus glutinosa", "Quercus robur")) |>
  add_noddb()
} # }
```
