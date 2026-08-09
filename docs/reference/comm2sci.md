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
comm2sci(x, lang = NULL, resolve = FALSE, backbone = NULL, verbose = TRUE)
```

## Arguments

- x:

  Character vector of common names.

- lang:

  Character. Restrict to one language: an ISO 639-1 code (`"en"`,
  `"de"`, ...) as used by the GBIF source, or `NA` for the untagged
  NCBI/Open Tree names. `NULL` (default) searches every language. List
  the languages present with `enrichment_groups("common_names")`.

- resolve:

  Logical. When `FALSE` (default), return the lookup table (common name
  -\> scientific name). When `TRUE`, run the matched scientific names
  through
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) and
  return a `taxify_result` (with a leading `query_common` column), so
  the result pipes straight into the `add_*()` enrichments.

- backbone:

  Passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  when `resolve = TRUE`; `NULL` (default) uses every installed backbone.
  Ignored when `resolve = FALSE`.

- verbose:

  Logical. Default `TRUE`.

## Value

When `resolve = FALSE`, a data.frame with one row per (query, scientific
match):

- input_name:

  The common name as supplied.

- common_name:

  The vernacular name as stored in the source (its casing, which may
  differ from `input_name`).

- accepted_name:

  The accepted scientific name.

- lang:

  Language tag of the vernacular name (`NA` for NCBI/Open Tree).

A query with no match contributes no rows. When `resolve = TRUE`, a
`taxify_result` for the distinct matched scientific names, with
`query_common` prepended.

## See also

[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)
for the forward direction (scientific -\> common),
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# The bundled example database maps "example_common_name" to Quercus robur;
# against the full download this is where "pedunculate oak" would resolve.
comm2sci("example_common_name")

# Resolve straight to a taxify_result you can enrich
comm2sci("example_common_name", resolve = TRUE, backbone = "wfo")

options(old)
```
