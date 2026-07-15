# Add plant chromosome numbers (Chromosome Counts Database)

Joins somatic chromosome numbers from the Chromosome Counts Database
(Rice et al. 2015) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. CCDB aggregates published counts
per taxon; records are collapsed to the binomial and reduced to a
per-species median with its observed range.

## Usage

``` r
add_ccdb(x, cols = NULL, verbose = TRUE)
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

- ccdb_chromosome_2n:

  Median somatic chromosome number (2n).

- ccdb_chromosome_2n_min:

  Lowest 2n reported for the species.

- ccdb_chromosome_2n_max:

  Highest 2n reported for the species.

## Details

Source: CCDB (ccdb.tau.ac.il), citation requested, no explicit licence,
so taxify publishes no pre-built copy. The data is built on your machine
from the original source, which needs taxifydb installed:
`remotes::install_github("gcol33/taxifydb")`.

CCDB's service reports gametic numbers, which taxifydb doubles to the
somatic 2n reported here. The spread between `min` and `max` is real
ploidy variation among a species' cytotypes rather than measurement
error, so a polyploid complex legitimately spans a wide range (*Sedum
acre* runs 2n = 40 to 120). Where a species is covered by both, this and
the CC BY
[`add_kew_cvalues()`](https://gillescolling.com/taxify/reference/add_kew_cvalues.md)
chromosome column agree exactly for 85% of the 7133 species they share;
the rest are compilations differing over which cytotype is typical.

## References

Rice A, Glick L, Abadi S, Einhorn M, Kopelman NM, Salman-Minkov A,
Mayzel J, Chay O, Mayrose I (2015) The Chromosome Counts Database
(CCDB) - a community resource of plant chromosome numbers. New
Phytologist 206:19-26.

## See also

[`add_kew_cvalues()`](https://gillescolling.com/taxify/reference/add_kew_cvalues.md)
for genome size and a CC BY chromosome number.

## Examples

``` r
if (FALSE) { # \dontrun{
# Builds the enrichment on first use (requires taxifydb).
taxify("Zea mays", backend = "gbif") |>
  add_ccdb()
} # }
```
