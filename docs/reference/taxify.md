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
  aggregates = c("preserve", "collapse"),
  region = NULL,
  coords = NULL,
  range = c("present", "native", "introduced"),
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

- aggregates:

  Character. How to treat species aggregates (names with an `agg.` /
  `s.l.` qualifier). `"preserve"` (default) keeps the aggregate as its
  own concept: it matches the backbone's aggregate taxon
  (`"<binomial> aggr."`) where one exists, otherwise falls back to the
  binomial. `"collapse"` strips the marker and matches the binomial
  species, the way any non-aggregate name is matched. Either way the
  qualifier is recorded in the `qualifier` column.

- region:

  TDWG botanical region(s) to constrain fuzzy matching to, or `NULL`
  (default) for no geographic constraint. Accepts Level 3 codes
  (`"BGM"`, `c("BGM", "GER")`) or region names at any level, matched
  case- and accent-insensitively against the bundled WGSRPD crosswalk: a
  Level 3 name (`"Belgium"`), a Level 2 region (`"Middle Europe"`), or a
  Level 1 continent (`"Europe"`, which expands to all its codes). See
  [`taxify_regions()`](https://gillescolling.com/taxify/reference/taxify_regions.md)
  for the full list. When set, **fuzzy** candidates are restricted to
  species with WCVP records in the region(s); exact matches are always
  kept. The filter only narrows genuinely ambiguous fuzzy candidates: a
  candidate is dropped only when the same input name has another
  candidate that is in-region or has no WCVP range data, so non-plant
  matches (no WCVP coverage) are never affected and a name whose only
  candidate is out-of-region is still returned. WCVP is vascular plants
  only, so this disambiguates plant names.

- coords:

  Coordinates to constrain fuzzy matching to, mapped to TDWG regions by
  point-in-polygon and unioned with `region`. A single `c(lon, lat)`
  pair, a matrix/data.frame of longitude/latitude columns (named
  `lon`/`lat` or `x`/`y`, else the first two columns as lon, lat), or a
  point-geometry spatial object (an sf/`sfc` object or a terra
  `SpatVector`, reprojected to longitude/latitude automatically). `NULL`
  (default) for none. The WGSRPD boundary file is downloaded once and
  cached; coordinate lookup needs that download (or a prior cache). The
  point-in- polygon test uses terra or sf when installed, otherwise a
  native fallback; force the engine with
  `options(taxify.pip_engine = "terra" | "sf" | "native")`.

- range:

  Character. Which WCVP statuses count as in-region when `region` or
  `coords` is set. `"present"` (default) accepts any record (native,
  introduced, or extinct) – the right choice for name disambiguation.
  `"native"` accepts only native records, `"introduced"` only introduced
  (alien) records; both fold an ecological filter into matching and are
  for callers who want that. Ignored when no region is set.

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

- qualifier:

  Canonical taxonomic qualifier found in the input name (`"cf."`,
  `"aff."`, `"agg."`, `"s.l."`, `"s.str."`, `"sp."`, ...), or `NA`.
  Spelling variants are folded to one token (`"aggr."`, `"agg"` and
  `"sensu lato"` all map to `"agg."`/`"s.l."`).

- qualifier_position:

  `"genus"` when the qualifier leads the name and qualifies the whole
  name (e.g. `"Cf. Pinus sylvestris"`), `"species"` when it qualifies
  the species (inline `cf.` or trailing `agg.`), `NA` when there is no
  qualifier.

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

# Constrain fuzzy candidates to a geographic region: a TDWG Level 3 code,
# or a region name resolved via the bundled WGSRPD crosswalk
taxify("Quercus robus", region = "EUR")
taxify("Quercus robus", region = "Belgium")

# Constrain by coordinates (downloads WGSRPD boundaries on first use)
if (FALSE) { # \dontrun{
taxify("Quercus robus", coords = c(4.35, 50.85))
} # }

# Fallback chain: try WFO first, then COL for unmatched
taxify(c("Quercus robur", "Panthera leo"),
       backend = c("wfo", "col"))

options(old)
```
