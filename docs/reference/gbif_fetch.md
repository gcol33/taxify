# Fetch the records of a submitted GBIF download

Waits for the download
[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
submitted, retrieves it, imports it and returns the records. A request
too long for one GBIF query is split across several downloads, and all
of them are waited for and stacked, so a sharded request is fetched the
same way as a single one.

## Usage

``` r
gbif_fetch(x, backmatch = TRUE, path = tempdir(), verbose = TRUE)
```

## Arguments

- x:

  What `gbif_request(method = "download")` returned.

- backmatch:

  Logical. Attach the queried names with
  [`gbif_backmatch()`](https://gillescolling.com/taxify/reference/gbif_backmatch.md).
  Default `TRUE`.

- path:

  Directory to download into. Defaults to a session temp directory, so
  nothing is written outside it unless you ask.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame of occurrence records, carrying the same `keys`, `taxa`,
`taxify_meta` and `gbif_download` attributes as `x`, so
[`cite()`](https://gillescolling.com/taxify/reference/cite.md) reports
the backbone and every download DOI.

## See also

[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md),
[`gbif_backmatch()`](https://gillescolling.com/taxify/reference/gbif_backmatch.md),
[`cite()`](https://gillescolling.com/taxify/reference/cite.md).

## Examples

``` r
if (FALSE) { # \dontrun{
dl <- gbif_request(c("Quercus robur", "Bellis perennis"))
recs <- gbif_fetch(dl)
cite(recs)
} # }
```
