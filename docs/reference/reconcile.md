# Reconcile a checklist against a backbone's current treatment

Classifies each name in a list against what a backbone currently
accepts, so a checklist assembled at one time can be checked against the
taxonomy as it stands now. Where
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
returns the resolved match per name, `reconcile()` adds the editorial
verdict – unchanged, now a synonym, a misspelling, ambiguous, or
unresolved – and flags names that merge onto a single accepted taxon.

## Usage

``` r
reconcile(x, backbone = NULL, ..., verbose = TRUE)
```

## Arguments

- x:

  Character vector of names (a checklist).

- backbone:

  Character vector of backbone names or a `taxify_backend` object,
  passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).
  `NULL` (default) uses every installed backbone.

- ...:

  Matching arguments passed to
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  (e.g. `fuzzy`, `fuzzy_threshold`, `kingdom`, `region`). Must be named.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per input name, columns:

- input_name:

  The name as supplied.

- accepted_name:

  The name it resolves to now (`NA` if unresolved).

- status:

  One of: `"unchanged"` (resolves to itself, still accepted),
  `"synonym"` (now a synonym of a different accepted name, including a
  name the backbone keeps unplaced but resolves through its basionym),
  `"misspelling"` (resolved by fuzzy/abbrev match to a corrected
  spelling), `"rank_fallback"` (an infraspecific name the backbone does
  not carry; `accepted_name` is the accepted name of its species),
  `"ambiguous"` (a name the backbone files under several accepted taxa,
  `n_ids > 1`, that does not resolve to itself as accepted;
  `accepted_name` is the one it picked, and
  [`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
  lists the others), `"unresolved"` (no match).

- is_synonym:

  Logical, from
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- match_type:

  The [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  match type.

- n_ids:

  Distinct accepted taxa the backbone files the name under, from
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).
  Above 1 on an `"unchanged"` row, the name is accepted under its own
  spelling and a homonym record also exists.

- merged:

  Logical. `TRUE` when two or more input names resolve to this same
  accepted name (a many-to-one collapse).

- merged_with:

  `|`-joined other input names sharing this accepted name, or `NA`.

- backbone:

  Backend that matched (`NA` if unresolved).

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md),
[`taxify_ids()`](https://gillescolling.com/taxify/reference/taxify_ids.md)
to expand the ambiguous rows,
[`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Quercus pedunculata is now a synonym of Quercus robur; "Quercus robus" is a
# misspelling of it; a bad name is unresolved.
reconcile(c("Quercus robur", "Quercus pedunculata", "Quercus robus",
            "Notagenus imaginus"),
          backbone = "wfo", verbose = FALSE)

options(old)
```
