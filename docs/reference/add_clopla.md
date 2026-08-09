# Add clonal and bud-bank traits (CLO-PLA)

Joins clonal growth, bud-bank and lifespan traits of the Central
European flora (Klimesova et al. 2017) to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result by looking up `accepted_name`. Source records are collapsed to
the binomial, so infraspecific rows are aggregated to the species
(numeric traits by median, nominal traits by mode).

## Usage

``` r
add_clopla(x, cols = NULL, verbose = TRUE)
```

## Arguments

- x:

  A data.frame returned by
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- cols:

  Which columns to attach: `NULL` (default) the curated set, `"all"`
  every trait the source carries, or a character vector of names. See
  [`enrichment_cols`](https://gillescolling.com/taxify/reference/enrichment_cols.md).

- verbose:

  Logical. Default `TRUE`.

## Value

The same data.frame with additional columns. The default set:

- clopla_clonal:

  Clonal growth present.

- clopla_clonalindex:

  Clonal index.

- clopla_woody, clopla_annual, clopla_monocarpic, clopla_polycarpic:

  Growth-form and life-cycle flags.

- clopla_persistence:

  Persistence of the clonal connection.

- clopla_offspring:

  Offspring produced per parent shoot per year.

- clopla_spread:

  Lateral spread.

- clopla_BBsize, clopla_BBdepth:

  Bud-bank size and depth.

- clopla_finalCGO:

  Final clonal growth organ.

`cols = "all"` attaches every trait the source carries (29 in total: the
remaining bud-bank counts by depth class, root-derived bud banks,
branching, cyclicity and dispersibility), with codes kept verbatim.

## Details

2,909 species of the Central European flora.

This source states no licence – it is an Ecological Society of America
data paper, free to use with citation – so taxify ships no pre-built
copy of it. The first call builds it from the original source on your
own machine, which requires the taxifydb package
(`remotes::install_github("gcol33/taxifydb")`). taxify redistributes
none of the data. Cite Klimesova et al. (2017) when you use it.

## References

Klimesova J, Danihelka J, Chrtek J, de Bello F, Herben T (2017) CLO-PLA:
a database of clonal and bud-bank traits of the Central European flora.
Ecology 98:1179.
[doi:10.1002/ecy.1745](https://doi.org/10.1002/ecy.1745)

## Examples

``` r
if (FALSE) { # \dontrun{
# Builds the enrichment on first use (needs taxifydb).
taxify("Trifolium repens", backbone = "gbif") |>
  add_clopla()
} # }
```
