# Link GBIF occurrence records back to the names they were requested for

A request built from
[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
covers several keys per name, so the records that come back have to be
traced to the name that asked for them before they can be counted or
grouped.

## Usage

``` r
gbif_backmatch(records, x, verbose = TRUE)
```

## Arguments

- records:

  A data.frame of occurrence records: what
  `gbif_request(method = "search")` returns, or a download imported with
  rgbif's `occ_download_import()`.

- x:

  What the keys came from: the object
  [`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
  returned, a
  [`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
  table, or a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result.

- verbose:

  Logical. Default `TRUE`.

## Value

`records` with three columns added: `requested_key` (the key that
matched), `input_name` (the name as queried) and `accepted_name`.
Records matching no requested key keep `NA` in all three. The provenance
on `x` travels with them, so
[`cite()`](https://gillescolling.com/taxify/reference/cite.md) on the
result reports the backbone and, for a download, its DOI.

## Details

Joining on `taxonKey` alone loses records, silently. GBIF returns the
records of a key's descendants as well as its own, and a record
identified to a subspecies carries the subspecies key: requesting *Pinus
nigra* (5284809) returns records whose `taxonKey` is 5686674, *P. nigra*
subsp. *salzmannii*. Those rows match on `speciesKey` and on nothing
else. This function therefore tries the record's keys from the most
specific outwards and takes the first that is one of the requested keys.

## See also

[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md),
[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md).

## Examples

``` r
if (FALSE) { # \dontrun{
spp <- c("Pinus nigra", "Quercus robur")
recs <- gbif_request(spp, method = "search", limit = 100)

recs <- gbif_backmatch(recs, recs)
table(recs$input_name, useNA = "ifany")
} # }
```
