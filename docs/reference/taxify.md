# Match taxonomic names against local backbone databases

Matches a vector of taxonomic names against locally stored Darwin Core
backbone databases. Returns a data.frame with one row per input name
containing the matched name, accepted name, taxonomic hierarchy, and
match quality information.

## Usage

``` r
taxify(
  x,
  backend = "wfo",
  fuzzy = TRUE,
  fuzzy_threshold = 0.2,
  fuzzy_method = c("dl", "levenshtein", "jw"),
  verbose = TRUE
)
```

## Arguments

- x:

  Character vector of taxonomic names.

- backend:

  Character vector of backend names (e.g., `"wfo"`, `"col"`, `"gbif"`)
  or a single `taxify_backend` object. When multiple backends are given,
  they are tried in order as a fallback chain. Default `"wfo"`.

- fuzzy:

  Logical. Enable fuzzy matching for names that fail exact match.
  Default `TRUE`.

- fuzzy_threshold:

  Numeric. Maximum allowed distance for fuzzy matches. Two modes
  depending on the value:

  - **Fractional** (`0 < fuzzy_threshold < 1`): normalized distance
    (edits / max name length). Default `0.2` is about 1 edit per 5
    characters.

  - **Integer** (`fuzzy_threshold >= 1`): maximum raw edit count, e.g.
    `fuzzy_threshold = 2L` allows at most 2
    insertions/deletions/substitutions regardless of name length. Not
    supported for `fuzzy_method = "jw"`.

- fuzzy_method:

  Character. One of `"dl"` (Damerau-Levenshtein, default),
  `"levenshtein"`, or `"jw"` (Jaro-Winkler).

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

A data.frame with one row per input name and the following columns:

- input_name:

  The original name as provided.

- matched_name:

  Full name in the backbone that matched.

- accepted_name:

  Resolved accepted name (equals `matched_name` if not a synonym).

- taxon_id:

  Backend-specific ID of the matched name.

- accepted_id:

  ID of the accepted name.

- rank:

  Taxonomic rank (species, subspecies, genus, etc.).

- family:

  Family name.

- genus:

  Genus name.

- epithet:

  Specific epithet.

- authorship:

  Authorship of the matched name.

- accepted_authorship:

  Authorship of the accepted name. For a synonym this is the author of
  the resolved accepted name, not the synonym's own author, so
  `accepted_name` and `accepted_authorship` together form the accepted
  name's full citation.

- is_synonym:

  Logical. Was the match a synonym?

- is_hybrid:

  Logical. Was a hybrid marker detected in the input?

- match_type:

  One of `"exact"`, `"exact_ci"`, `"fuzzy"`, `"abbrev"` (an abbreviated
  genus such as `"Q. robur"` resolved via genus initial plus epithet),
  or `"none"`.

- fuzzy_dist:

  Normalized string distance (0–1), `NA` if exact.

- is_ambiguous:

  Logical. `TRUE` when the matched scientificName had multiple synonym
  rows pointing to different accepted taxa at the same priority tier
  (homonym ambiguity). Disambiguated via `nomenclaturalStatus = "Valid"`
  when that column is in the backbone; for irreducible ambiguity, the
  scalar columns hold one candidate.

- ambiguous_targets:

  Character. `|`-joined list of conflicting accepted taxon IDs when
  `is_ambiguous = TRUE`; `NA` otherwise.

- backend:

  Which backend was used (e.g., `"wfo"`, `"col"`, `"gbif"`).

- backbone_version:

  Backend name, version, and download date (e.g.,
  `"wfo:2024-12 (2026-04-01)"`). Useful for reproducibility.

## Details

When multiple backends are specified, names are matched against each
backend in order. Names matched by an earlier backend are not re-matched
by later ones (fallback chain).

## Examples

``` r
# Runs offline against the bundled example database.
old <- options(taxify.data_dir = taxify_example_data())

# Match a few names
taxify(c("Quercus robur", "Pinus sylvestris"))

# Disable fuzzy matching
taxify("Quercus robus", fuzzy = FALSE)

# Fallback chain: try WFO first, then COL for unmatched
taxify(c("Quercus robur", "Panthera leo"),
       backend = c("wfo", "col"))

options(old)
```
