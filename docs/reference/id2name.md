# Resolve backend IDs to names

Looks up one or more backend taxon IDs in a backbone and returns the
name, rank, classification, and accepted-name resolution for each. The
inverse of the `taxon_id` / `accepted_id` columns
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
emits.

## Usage

``` r
id2name(id, backend = "col", verbose = TRUE)
```

## Arguments

- id:

  A vector of backend IDs (e.g. GBIF keys, ITIS TSNs, WoRMS AphiaIDs).
  Coerced to character, matched against the backbone's `taxon_id`.

- backend:

  A single backend name (e.g. `"col"`, `"gbif"`) or a `taxify_backend`
  object. Default `"col"`.

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

- backend:

  Backend used.

IDs not found in the backbone yield a row with `NA` name columns, so the
output stays aligned one-to-one with the input.

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) for
name -\> ID,
[`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md),
[`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Round-trip: resolve a name, then look its ID back up
r <- taxify("Quercus robur", backend = "col")
id2name(r$taxon_id, backend = "col")

options(old)
```
