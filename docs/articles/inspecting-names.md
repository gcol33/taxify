# Inspecting a name list with inspect()

## The problem

A field list reaches you as a column of strings, and some of those
strings are wrong. A genus is misspelled, an animal is sitting in a list
of plants, a synonym slipped in from an old data sheet, the same species
appears under two spellings.
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) will
resolve what it can and mark the rest, but it returns a row for every
name, matched or not, so the problems are spread through a wide table.
Before committing a list to analysis it helps to see only the names that
look off, each with a short note on why.

[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md) is
that pass. It returns one row per anomalous name, ordered most-notable
first, each labelled with what stands out and, where known, the name to
use instead. Clean names are dropped, so a short report means a clean
list.

``` r

library(taxify)
```

## A first look, without matching

By default
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
does not match anything. On a plain character vector it runs the checks
that need no backbone: it asks the genus register whether each genus is
a real one, and it compares each name against the rest of the batch.
Both are fast and offline.

``` r

names <- c(
  "Quercus robur",
  "Panthera leo",         # an animal among plants
  "Bogusia fakensis",     # not a real genus
  "Festuca rubra",
  "Festuca rubra",
  "Festuca rubraa",       # one stray letter
  "Pinus sylvestris",
  "Pinus abies"           # a synonym of Picea abies
)

inspect(names)
```

    #> ── taxify inspection ──────────────────────────────────────
    #>   8 names inspected  |  3 with anomalies
    #>   backbones: none (register + list checks only)
    #>   unresolved: 1   review: 2
    #>   ────────────────────────────────────────────────────────────
    #>   [unresolved] Bogusia fakensis  ->  ?               genus 'Bogusia' is not in the taxonomic register
    #>   [review    ] Festuca rubraa    ->  Festuca rubra   near-duplicate of more frequent 'Festuca rubra'
    #>   [review    ] Panthera leo      ->  ?               animalia outlier (list is mostly plantae)

Three names surface. *Bogusia fakensis* uses a genus no backbone
recognises, so it reads as not a real name. *Festuca rubraa* is one
letter off a spelling that appears twice in the same list, the mark of a
typo of it. *Panthera leo* is the lone animal in a list of plants, the
pattern a cross-kingdom homonym typo leaves behind.

Two names slip past this first pass. *Quercus robber* needs a backbone
to recognise as a typo of *Quercus robur*, and *Pinus abies* is a
valid-looking binomial whose synonymy only a backbone knows. Those are
the match-based checks, and they are opt-in.

## The labels

Each flagged name carries one or more labels in its `anomalies` column.
The list-only checks need no matching:

| Label | Meaning |
|----|----|
| `unknown` | The genus is not in the register, the union of every backbone’s genera. No backbone recognises it. |
| `near_duplicate` | A near-twin of a more frequent name in the same list, so probably a misspelling of it. Caught from the list alone, even for names no backbone holds. |
| `outlier_group` | The name’s kingdom group is a tiny minority of an otherwise coherent list, typically a cross-kingdom homonym typo. |

The remaining labels read from a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result and only appear once matching has run:

| Label | Meaning |
|----|----|
| `typo` | Resolved only after fuzzy correction. The input most likely contains a spelling error; `suggestion` holds the corrected name. |
| `synonym` | The input is an outdated synonym; `suggestion` holds the current accepted name. |
| `case` | Resolved only after ignoring case. |
| `ambiguous` | A homonym resolving to more than one accepted taxon. |
| `geographic` | The matched species is real but has no record in a declared region (vascular plants, via WCVP). |
| `out_of_range` | No region declared, yet the species’ range falls outside the list’s main continents. |

## Tiers

Every flagged row also gets a `tier`. The tier says what the name needs,
not how serious the problem is:

- `unresolved`: no usable name came back, so the row needs a decision
  before analysis. `unknown` lands here.
- `review`: a name is there, but its identity is uncertain. The identity
  checks (`typo`, `near_duplicate`, `ambiguous`, `geographic`,
  `out_of_range`, `outlier_group`) land here.
- `note`: the name is correct, the change is optional cleanup. `case`
  and `synonym` land here.

An anomaly can be intended. A list may genuinely include one animal
among plants, or deliberately keep a synonym. The tier is a triage hint,
so read it as a place to start rather than a verdict.

## Turning on matching

To pick up typos, synonyms, and ambiguity, let
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
match. The simplest route is `backbones = TRUE`, which runs the names
through every installed backbone and records which ones it used in the
report header.

``` r

inspect(names, backbones = TRUE)
```

    #> ── taxify inspection ──────────────────────────────────────
    #>   8 names inspected  |  4 with anomalies
    #>   backbones: WFO, GBIF
    #>   unresolved: 1   review: 2   note: 1
    #>   ────────────────────────────────────────────────────────────
    #>   [unresolved] Bogusia fakensis  ->  ?              genus 'Bogusia' is not in the taxonomic register
    #>   [review    ] Festuca rubraa    ->  Festuca rubra  likely misspelling; near-duplicate of more frequent 'Festuca rubra'
    #>   [review    ] Panthera leo      ->  Panthera leo   animalia outlier (list is mostly plantae)
    #>   [note      ] Pinus abies       ->  Picea abies    outdated synonym

Now *Pinus abies* is recognised as a synonym and resolved to *Picea
abies*, and *Festuca rubraa* carries both its list-context label and the
fuzzy `typo` label that confirms it. *Panthera leo* now matches in GBIF,
so it is no longer a candidate typo, but it remains a kingdom-group
outlier in a plant list.

If you have already matched the list, inspect the result instead of
asking
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md) to
match again. This reuses the exact backend, region, and options of your
original call.

``` r

taxify(names, backend = c("wfo", "gbif")) |>
  inspect()
```

The two routes return the same kind of report. Pass `backbones = TRUE`
when you want a quick standalone check; pipe a result in when matching
is already part of the workflow.

## Geographic checks

When a list is regionally coherent, a species whose range sits elsewhere
is worth a second look. With a declared `region`,
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
flags matched species that WCVP does not record there.

``` r

alpine <- taxify(c("Gentiana lutea", "Primula veris", "Banksia serrata")) |>
  inspect(region = "Europe")
```

    #> ── taxify inspection ──────────────────────────────────────
    #>   3 names inspected  |  1 with anomalies
    #>   backbones: WFO
    #>   review: 1
    #>   ────────────────────────────────────────────────────────────
    #>   [review] Banksia serrata  ->  Banksia serrata  outside region per WCVP

*Banksia serrata* is a real, well-matched name, so nothing else flags
it. It is the geographic context that makes it stand out: an Australian
shrub in a European list. The same check accepts `coords` instead of a
region name, and a `range` argument to count only native or only
introduced records. The [geographic constraints
vignette](https://gillescolling.com/taxify/articles/regions.html) covers
those inputs in full.

Without a declared region, the `out_of_range` check does the comparison
from the list itself: it finds the continents that hold the bulk of the
matched species and flags any species occurring on none of them. A
globally spread list needs too many continents to reach that bulk, fails
the coherence test, and flags nothing, so the check stays quiet unless
the list is regionally tight. Both geographic checks use WCVP, which
covers vascular plants only.

## Reporting fewer rows

On a long list even the `note` rows add up. `min_tier` raises the floor
so the report keeps only what needs action.

``` r

# only names that need a decision or a second look
inspect(names, backbones = TRUE, min_tier = "review")
```

    #> ── taxify inspection ──────────────────────────────────────
    #>   8 names inspected  |  3 with anomalies
    #>   backbones: WFO, GBIF
    #>   unresolved: 1   review: 2
    #>   ────────────────────────────────────────────────────────────
    #>   [unresolved] Bogusia fakensis  ->  ?              genus 'Bogusia' is not in the taxonomic register
    #>   [review    ] Festuca rubraa    ->  Festuca rubra  likely misspelling; near-duplicate of more frequent 'Festuca rubra'
    #>   [review    ] Panthera leo      ->  Panthera leo   animalia outlier (list is mostly plantae)

`min_tier = "review"` drops the `note`-tier synonym;
`min_tier = "unresolved"` would leave only the unknown name.

## What needs a batch, and what needs the register

The list-context labels (`near_duplicate`, `outlier_group`,
`out_of_range`) weigh a name against the rest of the batch, so they
cannot apply to a single name.
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md) on
one name warns and reports only the per-name labels.

``` r

inspect("Quercus robber", backbones = TRUE)
#> Warning: list-context anomaly checks need a batch of names; with a single
#> name only the per-name checks run.
```

The register checks (`unknown`, and the register-derived
`outlier_group`) need the genus register installed. Without it they are
skipped, with a message at `verbose = TRUE`, and the rest of the checks
still run.

## The report is a data.frame

Printing is a convenience. The object underneath is an ordinary
data.frame with columns `input_name`, `suggestion`, `anomalies`, `tier`,
`reason`, `fuzzy_dist`, and `backend`, so the report drops straight into
a cleaning script.

``` r

report <- inspect(names, backbones = TRUE)

# the names that came back with a confident replacement
fixes <- report[!is.na(report$suggestion), c("input_name", "suggestion")]
fixes
```

    #>      input_name    suggestion
    #> 1 Festuca rubraa Festuca rubra
    #> 2    Pinus abies   Picea abies

`tier` is an ordered factor (`note` \< `review` \< `unresolved`), so
`report[report$tier >= "review", ]` keeps the rows worth a person’s
time. A typical loop is to run
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md),
apply the confident `suggestion`s, decide the handful of `unresolved`
names by hand, then re-run
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) on
the corrected list.

## Where to go next

- [Geographic
  constraints](https://gillescolling.com/taxify/articles/regions.html)
  for the `region`, `coords`, and `range` arguments the geographic
  checks share with
  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md).

- [Fuzzy
  matching](https://gillescolling.com/taxify/articles/fuzzy-matching.html)
  for how the `typo` label is produced and tuned.

- [Getting
  started](https://gillescolling.com/taxify/articles/quickstart.html)
  for the matching pipeline
  [`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
  sits on top of. \`\`\`
