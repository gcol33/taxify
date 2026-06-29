# Inspect a name list for probable typos and other anomalies

A quality-control pass over a name list. By default `inspect()` does not
match names against backbones: on a plain character vector it runs the
checks that need no matching – the genus register and the rest of the
batch – and is fast and offline. To also surface the match-based
anomalies (`typo`, `synonym`, `ambiguous`, `geographic`), either set
`backbones = TRUE` (matches against every installed backbone, listed in
the report) or match yourself first and inspect the result
(`taxify(x) |> inspect()`). Either way it returns only the rows that
look anomalous, each labelled with what stands out and, where known, the
name to use instead.

## Usage

``` r
inspect(
  x,
  backbones = FALSE,
  region = NULL,
  coords = NULL,
  range = c("present", "native", "introduced"),
  min_tier = c("note", "review", "unresolved"),
  verbose = TRUE
)
```

## Arguments

- x:

  A character vector of names, or a `taxify_result` from
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- backbones:

  Logical. When `x` is a character vector, `TRUE` matches it against
  every installed backbone (via
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)) so
  the match-based labels are available; `FALSE` (default) runs the
  register and list checks only, with no matching. The backbones used
  are printed in the report header. Ignored when `x` is already a
  `taxify_result` (it was matched already).

- region, coords, range:

  Geographic constraint for the `geographic` / `out_of_range` checks, as
  in [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).
  These act on a `taxify_result` (which carries the accepted names they
  need); on a character vector there is nothing matched to place, so
  they have no effect.

- min_tier:

  Lowest tier to report: `"note"` (default, everything), `"review"`, or
  `"unresolved"`.

- verbose:

  Logical. Print progress messages. Default `TRUE`.

## Value

A `taxify_inspection` data.frame (one row per anomalous name, ordered
most-notable first) with columns `input_name`, `suggestion` (the name to
use instead, or `NA`), `anomalies` (`|`-joined labels), `tier` (ordered
factor `note` \< `review` \< `unresolved`), `reason`, `fuzzy_dist`, and
`backend`. Zero rows means nothing stood out.

## Details

Checks that need no matching (run on a character vector or a result):

- `unknown`:

  The genus is not in the genus register – the union of all 13
  backbones' genera – so no backbone recognises it. The strong "probably
  not a real name" signal.

- `near_duplicate`:

  A near-twin of a more frequent name in the same list (small edit
  distance), so probably a misspelling of it. Computed from the list
  alone, so it catches typos in names no backbone contains.

- `outlier_group`:

  The name's kingdom group (from the register) is a tiny minority of an
  otherwise group-coherent list – the lone animal or fungus among
  plants, typically a cross-kingdom homonym typo.

Checks read from a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result (only present when you inspect one):

- `typo`:

  Resolved only after fuzzy correction (`match_type = "fuzzy"`): the
  input most likely contains a spelling error; `suggestion` is the name.

- `ambiguous`:

  A homonym resolving to more than one accepted taxon.

- `geographic`:

  The matched species is real but has no WCVP record in the declared
  `region` / `coords` (vascular plants only).

- `out_of_range`:

  No region declared, yet the matched species' range falls outside the
  list's main TDWG continents (skipped for globally spread lists).

- `case`:

  Resolved only after ignoring case (`match_type = "exact_ci"`).

- `synonym`:

  The input is an outdated synonym; `suggestion` is the current accepted
  name.

Rows with no anomaly are dropped.

Each row gets a `tier` describing what it needs, not how bad it is:
`unresolved` (no usable name – act on it), `review` (a name is there but
its identity is uncertain – verify it), or `note` (correct, optional
cleanup). `unknown` is `unresolved`; the identity-uncertain labels are
`review`; `case` and `synonym` are `note`. An anomaly may be intended,
so the tier is a triage hint, not a verdict.

The list-context labels (`near_duplicate`, `out_of_range`,
`outlier_group`) judge a name against the rest of the batch, so they
cannot apply to a single name: `inspect()` on one name warns and reports
only the per-name labels. The register checks (`unknown`, and the
register-derived `outlier_group`) need the genus register installed;
without it they are skipped (with a message at `verbose`).

## See also

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md),
[`taxify_regions()`](https://gillescolling.com/taxify/reference/taxify_regions.md)

## Examples

``` r
old <- options(taxify.data_dir = taxify_example_data())

# On raw names: register + list checks (no matching)
inspect(c("Quercus robur", "Bogusus fakus", "Carexus mysteriosa",
          "Carexus mysteriosa", "Carexus mysteryosa"))

# Opt in to matching to also get typos, synonyms, ambiguity
inspect(c("Quercus robur", "Quercus robus"), backbones = TRUE)

# Or match yourself and inspect the result
taxify(c("Quercus robur", "Quercus robus")) |> inspect()

options(old)
```
