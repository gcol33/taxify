# Resolve common (vernacular) names to scientific names

The reverse of
[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md):
given a common name, return the accepted scientific name(s) it refers
to. Reads the bundled `common_names` enrichment (GBIF, NCBI, and Open
Tree vernaculars) offline; the first call may trigger the one-time
download. A common name is frequently ambiguous (several species share
"bluebell", "robin"), so the result can carry more than one row per
query.

## Usage

``` r
comm2sci(
  x,
  lang = NULL,
  output = c("lookup", "result"),
  backbone = NULL,
  ...,
  verbose = TRUE
)
```

## Arguments

- x:

  Character vector of common names.

- lang:

  Character. Restrict to one language: an ISO 639-1 code (`"en"`,
  `"de"`, ...) as used by the GBIF source, or `NA` for the untagged
  NCBI/Open Tree names. `NULL` (default) searches every language. List
  the languages present with `enrichment_groups("common_names")`.

- output:

  What to return. `"lookup"` (default): the lookup table (common name
  -\> scientific name). `"result"`: the matched scientific names run
  through
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md), as
  a `taxify_result` (with a leading `query_common` column), so the
  result pipes straight into the `add_*()` enrichments.

- backbone:

  Passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  when `output = "result"`; `NULL` (default) uses every installed
  backbone. Ignored for `"lookup"`.

- ...:

  Matching arguments passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  when `output = "result"` (e.g. `fuzzy`, `fuzzy_threshold`, `kingdom`,
  `region`). Must be named.

- verbose:

  Logical. Default `TRUE`.

## Value

For `output = "lookup"`, a data.frame with one row per (query,
scientific match, language):

- input_name:

  The common name as supplied.

- common_name:

  The vernacular name as stored in the source (its casing, which may
  differ from `input_name`).

- accepted_name:

  The accepted scientific name.

- lang:

  Language tag of the vernacular name (`NA` for NCBI/Open Tree).

A query with no match contributes no rows. For `output = "result"`, a
`taxify_result` with one row per (query, distinct scientific match),
with `query_common` prepended.

## See also

[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)
for the forward direction (scientific -\> common),
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

Other Match and inspect names:
[`cite()`](https://gillescolling.com/taxify/reference/cite.md),
[`id2name()`](https://gillescolling.com/taxify/reference/id2name.md),
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md),
[`parse_name()`](https://gillescolling.com/taxify/reference/parse_name.md),
[`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md),
[`sci2comm()`](https://gillescolling.com/taxify/reference/sci2comm.md)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# The bundled example database maps "example_common_name" to Quercus robur;
# against the full download this is where "pedunculate oak" would resolve.
comm2sci("example_common_name")
#>            input_name         common_name accepted_name lang
#> 1 example_common_name example_common_name Quercus robur   de
#> 2 example_common_name example_common_name Quercus robur   en

# Resolve straight to a taxify_result, ready for add_*() functions
comm2sci("example_common_name", output = "result", backbone = "wfo")
#> Matching 1 names...
#>          query_common    input_name  matched_name accepted_name   taxon_id
#> 1 example_common_name Quercus robur Quercus robur Quercus robur wfo-ex-001
#>   accepted_id    rank   family   genus epithet authorship accepted_authorship
#> 1  wfo-ex-001 species Fagaceae Quercus   robur         L.                  L.
#>   is_synonym taxonomic_status is_hybrid match_type fuzzy_dist backbone
#> 1      FALSE         ACCEPTED     FALSE      exact         NA      wfo
#>           backbone_version kingdom_group taxon_group  life_form qualifier
#> 1 wfo:example (2026-06-24)       plantae  angiosperm angiosperm      <NA>
#>   qualifier_position aggregate_fallback hybrid_type
#> 1               <NA>                 NA        <NA>
#> Sources: WFO example | cite() for full citations

options(old)
```
