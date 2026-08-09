# Expand ambiguous matches into their candidate taxa

Where [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
meets an irreducible homonym – a name whose synonyms point to several
accepted taxa at the same priority tier – it records one candidate in
the scalar columns, sets `is_ambiguous = TRUE`, and lists the
conflicting accepted taxon IDs in `ambiguous_targets`. This verb expands
those rows into one row per candidate, resolved to full names against
the backbone, so you can choose the right taxon yourself instead of
relying on the automatic tiebreak.

## Usage

``` r
taxify_candidates(x, verbose = TRUE)
```

## Arguments

- x:

  A [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  result.

- verbose:

  Logical. Default `TRUE`.

## Value

A data.frame with one row per (ambiguous input, candidate taxon):

- input_name:

  The queried name.

- chosen:

  The accepted name
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  picked for that row.

- candidate:

  A candidate accepted name.

- authorship:

  Authorship of the candidate.

- rank:

  Rank of the candidate.

- family:

  Family of the candidate.

- genus:

  Genus of the candidate.

- taxon_id:

  Backend ID of the candidate.

- backbone:

  Backend used.

Empty when no rows were ambiguous.

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md),
[`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Homonyms are rare; on an unambiguous result this is an empty frame.
taxify("Quercus robur") |>
  taxify_candidates()

options(old)
```
