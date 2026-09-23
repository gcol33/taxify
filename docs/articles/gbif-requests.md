# Requesting GBIF data for a species list

You have a list of species names and you want their occurrence records
from GBIF, the Global Biodiversity Information Facility. GBIF does not
serve records by name. It serves them by *taxon key*, an integer
identifying one taxon in the GBIF backbone, so the list has to be
resolved to keys before anything can be requested.

[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
does that in one call: it matches the names against the local GBIF
backbone, collects every accepted key the matches resolve to, and hands
them to [rgbif](https://CRAN.R-project.org/package=rgbif). rgbif is
needed only for the request itself; resolving names and reading off
their keys works offline without it.

``` r

library(taxify)

spp <- c("Quercus robur", "Pinus sylvestris", "Bellis perennis", "Morus alba")

gbif_request(spp, dry_run = TRUE)
#> 11 GBIF key(s) from 4 matched name(s). About 4,090,085 occurrence record(s) across them.
#>  [1] 2878688 7911626 7586523 5285637 7718215 8116613 9079676 8251433 7393648
#> [10] 3117424 5361889
```

Four names, eleven keys.

## Why one name gives several keys

GBIF files a name under more than one key in two situations: a homonym,
where two authors published the same name for different taxa, and a name
held once as an accepted record and again as a doubtful or duplicate
one.
[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
lays those out, one row per name and key, with the occurrence count each
key carries:

``` r

taxify(spp, backbone = "gbif") |>
  taxify_ids()
#>          input_name accepted_id    accepted_name taxonomic_status n_occurrences is_pick
#> 1     Quercus robur     2878688    Quercus robur         ACCEPTED       1725528    TRUE
#> 2     Quercus robur     7911626    Quercus robur         DOUBTFUL             2   FALSE
#> 3     Quercus robur     7586523    Quercus robur         DOUBTFUL             9   FALSE
#> 4  Pinus sylvestris     5285637 Pinus sylvestris         ACCEPTED       1204947    TRUE
#> 5  Pinus sylvestris     7718215 Pinus sylvestris         DOUBTFUL             0   FALSE
#> 6  Pinus sylvestris     8116613 Pinus sylvestris         DOUBTFUL             0   FALSE
#> 7  Pinus sylvestris     9079676 Pinus sylvestris         DOUBTFUL             0   FALSE
#> 8  Pinus sylvestris     8251433 Pinus sylvestris         DOUBTFUL             0   FALSE
#> 9  Pinus sylvestris     7393648 Pinus sylvestris         DOUBTFUL             0   FALSE
#> 10  Bellis perennis     3117424  Bellis perennis         ACCEPTED       1107989    TRUE
#> 11       Morus alba     5361889       Morus alba         ACCEPTED         51610    TRUE
```

`is_pick` marks the key
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
reported in `accepted_id`. The rest are the other records of the same
name. Requesting only the pick would have missed the eleven records
sitting under the two doubtful *Quercus robur* keys.

`n_occurrences` is the count taken when the backbone was built. For an
accepted key it includes the records of that taxon’s synonyms and
descendants, which is what a download by that key returns, so it is a
good guide to the size of a request and not an exact promise.

## Choosing what to request

Every key is requested by default. `strict = TRUE` narrows the request
to the single key
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
reported:

``` r

gbif_request(spp, strict = TRUE, dry_run = TRUE)
#> 4 GBIF key(s) from 4 matched name(s). About 4,090,074 occurrence record(s) across them.
#> [1] 2878688 5285637 3117424 5361889
```

For this list the two choices differ by 11 records out of 4.09 million,
so asking for every key costs almost nothing and picks up records that
would otherwise be dropped. The balance shifts for a list full of
homonyms, which is what
[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
is there to show you.

`dry_run = TRUE` returns the keys and contacts nothing, so it is the way
to see what a request would cover before committing to it.

## Setting up rgbif

Everything so far ran offline against the local backbone. Sending the
request is the part that needs rgbif:

``` r

install.packages("rgbif")
```

`method = "search"` works with nothing further. `method = "download"` is
an authenticated call and needs a GBIF account, which is free: register
at [gbif.org](https://www.gbif.org/).

rgbif reads that account from three environment variables. Its own
documentation recommends keeping them in `.Renviron` rather than passing
them as arguments, which also keeps them out of your scripts:

``` r

usethis::edit_r_environ()
```

Add the three lines, with no quotes and no spaces around the `=`:

    GBIF_USER=yourname
    GBIF_PWD=yourpassword
    GBIF_EMAIL=you@example.org

Save, then restart R so the file is read. rgbif also accepts the
lower-case names `gbif_user`, `gbif_pwd` and `gbif_email` in `.Rprofile`
if you prefer that; see
[`?rgbif::occ_download`](https://docs.ropensci.org/rgbif/reference/occ_download.html).

To confirm GBIF accepts the account, ask it for your own past downloads.
That call is authenticated, so it only succeeds when the credentials are
right:

``` r

rgbif::occ_download_list(limit = 5)
```

If a variable is missing,
[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
stops before contacting GBIF and names which one. If the password is
wrong, GBIF answers 401.

## Sending the request

Two methods, for two situations.

`method = "search"` sends unauthenticated searches and returns the
records directly. It needs no account, and the GBIF search API limits
how deep it will page, so it suits a look at a few taxa:

``` r

recs <- gbif_request(spp, method = "search", strict = TRUE, limit = 50)
nrow(recs)
#> [1] 200
```

The records come back as one data frame with a `taxon_key_requested`
column, so a row can be traced back to the key that asked for it.

`method = "download"` is the default. It submits an asynchronous GBIF
download, which has no record cap and is issued a DOI you can cite. It
needs a GBIF account:

``` r

dl <- gbif_request(spp, method = "download")
rgbif::occ_download_wait(dl)
d <- rgbif::occ_download_get(dl)
recs <- rgbif::occ_download_import(d)
```

All of the keys go into one download, not one download per key: they are
sent as a single `taxonKey IN (...)` predicate, so the whole list comes
back as one dataset under one DOI. A download of four million records is
prepared on GBIF’s servers and takes a while, which is why the call
returns as soon as the request is queued rather than waiting for it.

### Lists too long for one query

GBIF caps a download query at 12,000 characters. A taxonKey predicate
costs about 10 characters per key, so roughly 1,187 keys fit, and a
checklist of a few hundred names can pass that once its homonyms are
counted.

Above the limit
[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
splits the keys into chunks of 1,000 and submits them through rgbif’s
`occ_download_queue()`, which respects GBIF’s rule of three concurrent
downloads per user:

``` r

dl <- gbif_request(long_species_list, method = "download")
#> 2,431 keys exceed GBIF's query limit; splitting into 3 downloads of up to
#> 1000 keys. Each gets its own DOI.
```

`dl` is then a vector of download keys rather than one. Fetch and stack
them, and [`cite()`](https://gillescolling.com/taxify/reference/cite.md)
reports every DOI:

``` r

recs <- do.call(rbind, lapply(dl, function(k) {
  rgbif::occ_download_wait(k)
  rgbif::occ_download_import(rgbif::occ_download_get(k))
}))

recs <- gbif_backmatch(recs, dl)
```

The record count itself is not a limit. GBIF prepares downloads of tens
of millions of records server-side; only the query naming the keys is
capped.

## Linking the records back to your names

The records come back keyed by GBIF taxon, not by the name you asked
for, so they have to be traced back before you can count or group by
species.
[`gbif_backmatch()`](https://gillescolling.com/taxify/reference/gbif_backmatch.md)
does that, adding `requested_key`, `input_name` and `accepted_name`:

``` r

recs <- gbif_request(spp, method = "search", limit = 100)
recs <- gbif_backmatch(recs, recs)

table(recs$input_name, useNA = "ifany")
```

It takes the object
[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
returned, which carries the key table as an attribute. A
[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
table or a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result works too, which is what you need after importing a download:

``` r

matched <- taxify(spp, backbone = "gbif")

recs <- rgbif::occ_download_import(d)
recs <- gbif_backmatch(recs, matched)
```

### Why not just join on taxonKey

Because it loses records without saying so. GBIF returns the records of
a key’s descendants along with its own, and a record identified below
species level carries its own key. Requesting *Pinus nigra* (5284809)
returns records whose `taxonKey` is 5686674, *P. nigra* subsp.
*salzmannii*; those rows carry the requested key in `speciesKey` and
nowhere else.

In a 300-record sample of that request, 50 rows are identified to a
subspecies. Joining on `taxonKey` matches 250 of 300.
[`gbif_backmatch()`](https://gillescolling.com/taxify/reference/gbif_backmatch.md)
matches all 300, because it tries the record’s keys from the most
specific outwards and takes the first that is one of the keys you
requested.

Rows matching no requested key keep `NA` in the three added columns and
are counted in a message rather than dropped.

## Citing the download

A GBIF download gets a DOI once it is ready, and citing it is what lets
someone else retrieve the same records. The download key travels with
the records, so
[`cite()`](https://gillescolling.com/taxify/reference/cite.md) reports
the DOI next to the backbone the names were matched against:

``` r

recs <- gbif_backmatch(rgbif::occ_download_import(d), dl)

cite(recs)
#> ── taxify citations ────────────────────────────────────────────────
#>   [1] Colling G (2026). taxify: Offline Taxonomic Name Matching (version 0.6.0).
#>   [2] GBIF Secretariat (2024). GBIF Backbone Taxonomy. doi:10.15468/39omei
#>   [3] GBIF.org (2026-09-23) GBIF Occurrence Download https://doi.org/10.15468/dl.ckzs32
#>   ────────────────────────────────────────────────────────────
```

The DOI is read from GBIF when you call
[`cite()`](https://gillescolling.com/taxify/reference/cite.md), not
stored when the request was made, because GBIF issues it only once the
download has finished preparing. A download still running is reported as
having no DOI yet.

`cite(recs, file = "refs.bib")` writes the same entries as BibTeX, the
download included.

## Starting from an already matched list

[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
takes a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result as well as a character vector, so matching arguments and any
filtering belong in the
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call:

``` r

matched <- taxify(spp, backbone = "gbif", fuzzy = TRUE, kingdom = "Plantae")

matched |>
  gbif_request(method = "search", limit = 100)
```

Rows matched by another backbone are dropped with a message, because
their IDs are not GBIF keys. If nothing in the result came from GBIF,
[`gbif_request()`](https://gillescolling.com/taxify/reference/gbif_request.md)
stops and says to match against `backbone = "gbif"`.

## See also

- [`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
  for the keys and their occurrence counts on their own.

- [`vignette("large-scale")`](https://gillescolling.com/taxify/articles/large-scale.md)
  for matching lists too large to hold in memory.

- [`vignette("quickstart")`](https://gillescolling.com/taxify/articles/quickstart.md)
  for the matching itself.
