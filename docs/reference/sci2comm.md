# Resolve scientific names to common (vernacular) names

The forward direction of
[`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md):
given a scientific name, return the common name(s) it is known by. Reads
the bundled `common_names` enrichment (GBIF, NCBI, and Open Tree
vernaculars) offline; the first call may trigger the one-time download.
Where
[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)
attaches vernaculars to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result as columns, `sci2comm()` takes bare names and returns the long
lookup table – one row per (name, vernacular). A name maps to many
common names (across languages and synonyms), so a query can carry
several rows.

## Usage

``` r
sci2comm(x, lang = NULL, resolve = TRUE, backbone = NULL, verbose = TRUE)
```

## Arguments

- x:

  Character vector of scientific names.

- lang:

  Character. Restrict to one language: an ISO 639-1 code (`"en"`,
  `"de"`, ...) as used by the GBIF source, or `NA` for the untagged
  NCBI/Open Tree names. `NULL` (default) returns every language. List
  the languages present with `enrichment_groups("common_names")`.

- resolve:

  Logical. When `TRUE` (default), each input is run through
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  first so a synonym or misspelling reports its accepted taxon's
  vernaculars. When `FALSE`, the input name is looked up verbatim
  (faster, offline; use when the names are already accepted).

- backbone:

  Passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  when `resolve = TRUE`; `NULL` (default) uses every installed backbone.
  Ignored when `resolve = FALSE`.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per (query, vernacular):

- input_name:

  The scientific name as supplied.

- accepted_name:

  The accepted name looked up (equals `input_name` when
  `resolve = FALSE` or the input_name was already accepted).

- common_name:

  A vernacular name.

- lang:

  Language tag (`NA` for NCBI/Open Tree).

A query with no vernacular contributes no rows.

## See also

[`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md)
for the reverse direction (common -\> scientific),
[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)
to attach vernaculars to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result.

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# The bundled example maps Quercus robur -> "example_common_name" (en + de)
sci2comm("Quercus robur", resolve = FALSE)

options(old)
```
