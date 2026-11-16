# Resolve backbone IDs to names

Looks up one or more backbone taxon IDs in a backbone and returns the
name, rank, classification, and accepted-name resolution for each. The
inverse of the `taxon_id` / `accepted_id` columns
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
emits.

## Usage

``` r
id2name(id, backbone = NULL, verbose = TRUE)
```

## Arguments

- id:

  A vector of backbone IDs (e.g. GBIF keys, ITIS TSNs, WoRMS AphiaIDs),
  matched as text against the backbone's `taxon_id`. Numeric IDs (as
  read from a CSV) are written out in full, never in scientific
  notation, and must be whole numbers. IDs are backbone-specific, so
  name the `backbone` they came from.

- backbone:

  A single backbone name (e.g. `"col"`, `"gbif"`) or a `taxify_backend`
  object. `NULL` (default) uses the highest-priority installed backbone.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per input ID (in input order), columns:

- id:

  The queried ID.

- name:

  Canonical name for that ID (`NA` if the ID is not in the backbone).

- authorship:

  Authorship of the name.

- rank:

  Taxonomic rank.

- is_synonym:

  Logical. Is this ID a synonym?

- accepted_name:

  The accepted name the ID resolves to (equals `name` when the ID is
  itself accepted).

- family:

  Family.

- genus:

  Genus.

- backbone:

  Backend used.

IDs not found in the backbone yield a row with `NA` name columns, so the
output stays aligned one-to-one with the input.

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) for
name -\> ID,
[`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md),
[`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md).

Other Match and inspect names:
[`cite()`](https://gillescolling.com/taxify/reference/cite.md),
[`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md),
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md),
[`parse_name()`](https://gillescolling.com/taxify/reference/parse_name.md),
[`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md),
[`sci2comm()`](https://gillescolling.com/taxify/reference/sci2comm.md)

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Round-trip: resolve a name, then look its ID back up
r <- taxify("Quercus robur", backbone = "col")
#> Matching 1 names...
id2name(r$taxon_id, backbone = "col")
#>           id          name authorship    rank is_synonym accepted_name   family
#> 1 col-ex-001 Quercus robur         L. SPECIES      FALSE Quercus robur Fagaceae
#>     genus backbone
#> 1 Quercus      col

options(old)
```
