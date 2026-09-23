# Request GBIF occurrence data for a matched name list

Takes a list of names, matches it against the GBIF backbone and requests
occurrence data for every accepted taxon key the matches resolve to. A
name GBIF files under more than one key – a homonym published by two
authors, or a name held once as accepted and again as a doubtful record
– contributes all of its keys, so the request covers the whole matched
concept rather than whichever key
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
reported first.

## Usage

``` r
gbif_request(
  x,
  method = c("download", "search"),
  strict = FALSE,
  limit = 500,
  format = "SIMPLE_CSV",
  dry_run = FALSE,
  ...,
  verbose = TRUE
)
```

## Arguments

- x:

  A character vector of names, or a
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result. A character vector is matched against the GBIF backbone first.

- method:

  `"download"` (authenticated, no cap, citable) or `"search"`
  (unauthenticated, capped). See Choosing a method.

- strict:

  Logical, default `FALSE`. By default every accepted key each name
  resolves to is requested. `TRUE` narrows the request to the single key
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  reported, and says how many keys, and how many records, that leaves
  behind.

- limit:

  Records per key for `method = "search"`. Ignored by `"download"`.

- format:

  Download format for `method = "download"`, passed to rgbif. Ignored by
  `"search"`.

- dry_run:

  Logical. If `TRUE`, return the keys without contacting GBIF.

- ...:

  Matching arguments passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  (`fuzzy`, `kingdom`, `region`, ...); only when `x` is a character
  vector, and must be named.

- verbose:

  Logical. Default `TRUE`.

## Value

With `dry_run = TRUE`, an integer vector of GBIF taxon keys. With
`method = "download"`, the object rgbif's `occ_download()` returns (the
download key, to be passed to `occ_download_wait()`). With
`method = "search"`, a data.frame of occurrence records, empty if none
matched. In every case the keys and the
[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
table behind them are attached as the `keys` and `taxa` attributes.

## Details

The keys themselves are read off
[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md),
which resolves each one against the backbone and carries its occurrence
count; call it directly to see what a request would cover before sending
it, or pass `dry_run = TRUE` here for the keys alone.

## Choosing a method

`method = "download"` submits an asynchronous GBIF download. It has no
record cap and yields a citable DOI, which is what GBIF asks for in
published work, and it needs a GBIF account: set `GBIF_USER`, `GBIF_PWD`
and `GBIF_EMAIL` in `~/.Renviron`. The call returns as soon as the
request is queued; wait for it and fetch it with rgbif's
`occ_download_wait()` and `occ_download_get()`.

`method = "search"` sends unauthenticated searches and returns the
records directly. It needs no account, and the GBIF search API caps what
it will page through, so it suits a look at a handful of taxa rather
than a checklist-wide pull.

## See also

[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
for the keys and their occurrence counts,
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) for
the matching itself.

## Examples

``` r
if (FALSE) { # \dontrun{
# A checklist, matched and requested in one call. Needs the full GBIF
# backbone, so it cannot run on a check machine.
spp <- c("Quercus robur", "Bellis perennis", "Morus alba")

# What would be requested, without contacting GBIF:
gbif_request(spp, dry_run = TRUE)

# An unauthenticated search:
recs <- gbif_request(spp, method = "search", limit = 50)

# A citable download (needs GBIF_USER / GBIF_PWD / GBIF_EMAIL):
dl <- gbif_request(spp, method = "download")
rgbif::occ_download_wait(dl)
rgbif::occ_download_get(dl)
} # }
```
