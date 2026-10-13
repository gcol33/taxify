# Checking a name list

This article shows how to find the names in a list that need a decision
before analysis: a genus no backbone knows, a misspelling, a species
from another kingdom, a synonym, a species outside the study region.
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
returns one row per such name, with a label for what stands out and,
where it can, the name to use instead. At the end the article compares a
whole checklist with a backbone’s current treatment using
[`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md).
Installation is covered in [Get
started](https://gillescolling.com/taxify/articles/taxify.md).

1.  **Screen** the raw names with
    [`inspect()`](https://gillescolling.com/taxify/reference/inspect.md),
    which needs no matching.

2.  **Match** them as well, with `backbones = TRUE` or by passing a
    [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
    result, to find misspellings, synonyms and names with several
    accepted taxa.

3.  **Place** the matched species against a `region`.

4.  **Filter** the report with `min_tier`, and apply its suggestions.

5.  **Compare** a checklist with a backbone’s treatment with
    [`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md).

``` r

library(taxify)
```

## Checks without matching

The list below is a plant list with four problems: an animal, a genus
that does not exist, a name written with one extra letter, and an old
synonym.

``` r

plants <- c(
  "Quercus robur", "Panthera leo", "Xyzzia fakensis", "Festuca rubra",
  "Festuca rubra", "Festuca rubraa", "Pinus sylvestris", "Pinus abies"
)
inspect(plants)
#> ── taxify inspection ──────────────────────────────────────────
#>   8 names inspected  |  3 with anomalies
#>   backbones: none (register + list checks only)
#>   unresolved: 1   review: 2
#>   ────────────────────────────────────────────────────────────
#>   [unresolved] Xyzzia fakensis  ->  ?              genus 'Xyzzia' is not in the taxonomic register
#>   [review    ] Festuca rubraa   ->  Festuca rubra  near-duplicate of more frequent 'Festuca rubra'
#>   [review    ] Panthera leo     ->  ?              animalia outlier (list is mostly plantae)
```

Without matching,
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
runs the checks that need only the genus register, an index of the
genera of every backbone, and the list itself. Three names stand out.
*Xyzzia* is in no backbone. *Festuca rubraa* is one letter from *Festuca
rubra*, which appears twice in the list, so it is likely a slip of that
name. *Panthera leo* is the only animal in a list of plants. *Pinus
abies* is a well-formed name of a real genus and passes these checks;
its synonymy shows only when it is matched.

## Checks on matched names

`backbones = TRUE` matches the names against every installed backbone,
in the order of the default fallback chain of
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md), and
adds the checks that read the match:

``` r

report <- inspect(plants, backbones = TRUE, verbose = FALSE)
report
#> ── taxify inspection ──────────────────────────────────────────
#>   8 names inspected  |  4 with anomalies
#>   backbones: colxr, col, worms, wcvp, euromed, lcvp, wfo, fungorum, algaebase, fishbase, sealifebase, reptiledb, mdd, avilist, lpsn, gbif, itis, ncbi, ott
#>   unresolved: 1   review: 3
#>   ────────────────────────────────────────────────────────────
#>   [unresolved] Xyzzia fakensis  ->  ?              genus 'Xyzzia' is not in the taxonomic register
#>   [review    ] Festuca rubraa   ->  Festuca rubra  likely misspelling; near-duplicate of more frequent 'Festuca rubra'
#>   [review    ] Panthera leo     ->  Panthera leo   animalia outlier (list is mostly plantae)
#>   [review    ] Pinus abies      ->  Picea abies    ambiguous (targets: 4HPZF|4HQ46|8K9Y|6BRMR|4HQ4F|4HQ48); outdated synonym
```

*Pinus abies* is now recognised as a synonym of *Picea abies*, and as a
name with more than one accepted taxon behind it. *Festuca rubraa*
carries the label of the fuzzy match as well as the list check.
*Panthera leo* matches a backbone, so it is reported only as the animal
in a plant list. The header names the backbones used.

A list that is already matched is passed to
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
directly, which keeps the backbones and options of that call:

``` r

taxify(plants, backbone = c("col", "gbif")) |>
  inspect()
```

## Labels and tiers

Each row has one or more labels in `anomalies`. Three need no matching:

- `unknown`: the genus is in no backbone.

- `near_duplicate`: a near-identical spelling of a name that occurs more
  often in the same list.

- `outlier_group`: the name’s kingdom is a small minority in a list that
  is otherwise of one kingdom.

The others read the match:

- `typo`: resolved only by fuzzy matching; `suggestion` holds the
  corrected name.

- `synonym`: an outdated synonym, or an unplaced name whose basionym the
  backbone places; `suggestion` holds the accepted name.

- `case`: resolved only after capitals were ignored.

- `rank_fallback`: an infraspecific name no backbone holds, resolved to
  its species.

- `ambiguous`: a name with more than one accepted taxon, which is not
  itself the accepted name.

- `geographic`: the species has no record in the declared region.

- `out_of_range`: without a declared region, the species occurs on none
  of the continents that hold most of the list.

The `tier` names the action a row needs. `unresolved` means no usable
name came back (`unknown`). `review` means a name is there but its
identity is uncertain (`typo`, `near_duplicate`, `rank_fallback`,
`ambiguous`, `geographic`, `out_of_range`, `outlier_group`). `note`
means the name is correct and the change is optional (`case`,
`synonym`). A row takes the highest tier of its labels, so *Pinus abies*
is `review` because it is also `ambiguous`. A label can describe
something intended, such as one animal kept on purpose in a plant list.

## Checks against a region

A species far from the study region is worth a second look even when its
name is correct. With a declared `region`,
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
reports matched species with no record there in the World Checklist of
Vascular Plants (WCVP):

``` r

alpine <- c("Gentiana lutea", "Primula veris", "Banksia serrata")
taxify(alpine, backbone = "wcvp", verbose = FALSE) |>
  inspect(region = "Europe")
#> ── taxify inspection ──────────────────────────────────────────
#>   3 names inspected  |  1 with anomalies
#>   backbones: wcvp
#>   review: 1
#>   ────────────────────────────────────────────────────────────
#>   [review] Banksia serrata  ->  Banksia serrata  outside region per WCVP
```

*Banksia serrata* is an Australian shrub. Its name is correct, so only
the region check reports it. `coords` and `range` work as in
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md),
described in [Matching within a
region](https://gillescolling.com/taxify/articles/regions.md). Both
geographic checks cover vascular plants only, since they read WCVP.

Without a declared region, `out_of_range` compares each species with the
rest of the list: it finds the continents that hold most of the matched
species and reports a species found on none of them. A list spread over
many continents has no such core, and the check reports nothing.

## Using the report

The report is a data frame with the columns `input_name`, `suggestion`,
`anomalies`, `tier`, `reason`, `fuzzy_dist` and `backbone`. `min_tier`
drops the lower tiers:

``` r

inspect(plants, backbones = TRUE, min_tier = "review", verbose = FALSE)
#> ── taxify inspection ──────────────────────────────────────────
#>   8 names inspected  |  4 with anomalies
#>   backbones: colxr, col, worms, wcvp, euromed, lcvp, wfo, fungorum, algaebase, fishbase, sealifebase, reptiledb, mdd, avilist, lpsn, gbif, itis, ncbi, ott
#>   unresolved: 1   review: 3
#>   ────────────────────────────────────────────────────────────
#>   [unresolved] Xyzzia fakensis  ->  ?              genus 'Xyzzia' is not in the taxonomic register
#>   [review    ] Festuca rubraa   ->  Festuca rubra  likely misspelling; near-duplicate of more frequent 'Festuca rubra'
#>   [review    ] Panthera leo     ->  Panthera leo   animalia outlier (list is mostly plantae)
#>   [review    ] Pinus abies      ->  Picea abies    ambiguous (targets: 4HPZF|4HQ46|8K9Y|6BRMR|4HQ4F|4HQ48); outdated synonym
```

`tier` is an ordered factor, so `report[report$tier >= "review", ]`
selects the same rows from an existing report. The suggestions can
replace the input names before the list is matched again:

``` r

fixes <- report[!is.na(report$suggestion), c("input_name", "suggestion")]
fixes
#>       input_name    suggestion
#> 2 Festuca rubraa Festuca rubra
#> 3   Panthera leo  Panthera leo
#> 4    Pinus abies   Picea abies
```

The checks that compare a name with the rest of the list need more than
one name;
[`inspect()`](https://gillescolling.com/taxify/reference/inspect.md) on
a single name warns and runs only the others. A check that could not
run, such as the region check without the WCVP range data, is named on a
`not checked` line in the header, so an empty report always means that
the checks that ran found nothing.

## Comparing a checklist with a backbone

A checklist compiled years ago follows an older treatment.
[`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md)
reports for each name whether the backbone still accepts it, and which
names now fall together:

``` r

checklist <- c(
  "Quercus robur", "Pinus abies", "Picea abies", "Festuca rubraa",
  "Prunella"
)
rec <- reconcile(checklist, backbone = "col")
#> Matching 5 names...
#>   Fuzzy matching 1 unmatched...
rec[, c("input_name", "accepted_name", "status", "merged_with")]
#>       input_name accepted_name      status merged_with
#> 1  Quercus robur Quercus robur   unchanged        <NA>
#> 2    Pinus abies   Picea abies   ambiguous Picea abies
#> 3    Picea abies   Picea abies   unchanged Pinus abies
#> 4 Festuca rubraa Festuca rubra misspelling        <NA>
#> 5       Prunella      Prunella   unchanged        <NA>
```

`status` is `unchanged` for a name the backbone accepts, `synonym` for
one it treats as a synonym, `misspelling` for one matched by fuzzy
matching, `ambiguous` for a synonym with more than one accepted taxon,
and `unresolved` for a name with no match. *Pinus abies* and *Picea
abies* now name the same species, so each lists the other in
`merged_with`. *Prunella* is the accepted name of two genera and stays
`unchanged`; `n_ids` (not shown) counts them.

## Where next

- [How names are
  matched](https://gillescolling.com/taxify/articles/fuzzy-matching.md):
  how the fuzzy matches behind `typo` are made.

- [Matching within a
  region](https://gillescolling.com/taxify/articles/regions.md): the
  `region`, `coords` and `range` arguments.
