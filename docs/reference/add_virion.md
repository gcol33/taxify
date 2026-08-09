# Add host-virus association breadth (VIRION)

Joins per-host counts of recorded virus associations to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result.

## Usage

``` r
add_virion(x, cols = NULL, verbose = TRUE)
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

The same data.frame with `virion_` columns: `virus_richness`,
`virus_family_count`, `virus_record_count`, `host_class`.

## Details

Source: Carlson et al. (2022), 4223 vertebrate hosts and 9833 viruses.
ODbL-1.0. As with
[`add_globi()`](https://gillescolling.com/taxify/reference/add_globi.md)
and
[`add_invacost()`](https://gillescolling.com/taxify/reference/add_invacost.md),
only the derived per-host counts are redistributed, not the association
records.

These counts measure how much a host has been looked at as much as what
infects it. *Homo sapiens* leads with 936 distinct viruses across
633,053 records, and the ordering below it tracks livestock and
laboratory species. `virus_record_count` travels alongside so the effort
behind a richness is visible; treat richness as association breadth as
recorded, not as a biological property of the host.

## References

Carlson CJ, Gibb RJ, Albery GF, et al. (2022) The Global Virome in One
Network (VIRION): an atlas of vertebrate-virus associations. mBio
13:e0298521.
[doi:10.1128/mbio.02985-21](https://doi.org/10.1128/mbio.02985-21)

## Examples

``` r
if (FALSE) { # \dontrun{
taxify(c("Sus scrofa", "Myotis lucifugus")) |>
  add_virion()
} # }
```
