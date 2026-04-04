# Getting started with taxify

## Why taxify

Biodiversity data analysis almost always starts with a name-matching
step. Field records, herbarium labels, and literature extractions use
different spellings, outdated synonyms, and informal qualifiers. Before
any statistical work can begin, those raw strings need to be resolved to
a single accepted name per taxon.

The R ecosystem used to handle this through taxize, which queried online
APIs (GBIF, ITIS, NCBI, and others) in real time. taxize was removed
from CRAN in 2024, and even before that, the API-dependent design had
practical limits: rate-limited requests, unstable upstream endpoints,
and unreproducible results when a backbone updated between runs.
WorldFlora offered a local alternative for plants, but it supports only
the World Flora Online backbone and lacks fuzzy matching, synonym
chaining, and any concept of enrichment.

taxify takes a different approach. It downloads Darwin Core backbone
snapshots to disk once, converts them to a compressed columnar format
(.vtr files powered by the vectra engine), and runs all matching offline
against those local copies. Nine backbones are available: WFO (plants),
COL (all-kingdom catalogue), GBIF (all kingdoms, largest), ITIS (North
American focus), NCBI Taxonomy (molecular/genomic), Open Tree of Life
(synthetic tree), WoRMS (marine taxa), Species Fungorum (fungi), and
AlgaeBase (algae). A single function call matches names, resolves
synonyms, and returns a uniform 16-column data.frame regardless of which
backbone was used.

The choice of backbone matters. WFO is maintained by the World Flora
Online consortium and represents the most authoritative source for
vascular plants, bryophytes, and ferns. COL (the Catalogue of Life)
covers all kingdoms but with less taxonomic depth per group; it is a
good second choice when a dataset mixes plants with fungi or animals.
GBIF has the widest raw coverage because it aggregates multiple source
taxonomies, but its synonym handling is coarser. For marine taxa, WoRMS
is the standard. For molecular work, NCBI Taxonomy aligns with GenBank
accession metadata. The remaining backbones serve more specialized
needs: ITIS for North American regulatory contexts, OTT for phylogenetic
placement, Species Fungorum for fungal nomenclature, and AlgaeBase for
algal taxonomy.

This vignette walks through the core workflow: installing a backbone,
matching names, reading the output, and layering on enrichment data. The
code chunks are not evaluated here because the backbone files are too
large for CRAN build infrastructure, but every example uses real species
names and realistic outputs.

``` r

library(taxify)
```

## Installing a backbone

The first call to
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
auto-downloads the WFO backbone if no local copy exists. For a more
deliberate setup, or to pre-install several backbones before an analysis
session, use
[`taxify_download_vtr()`](https://gillescolling.com/taxify/reference/taxify_download_vtr.md).

``` r

# Download the WFO backbone (~150 MB)
taxify_download_vtr("wfo")
```

    #> i WFO backbone not found locally. Downloading v2024-12...
    #> v WFO backbone ready (v2024-12, 148 MB).

The file lands in a platform-appropriate data directory. On Linux that
is typically `~/.local/share/R/taxify/wfo/latest/wfo.vtr`; on macOS,
`~/Library/Application Support/R/taxify/wfo/latest/wfo.vtr`; on Windows,
`%LOCALAPPDATA%/R/data/R/taxify/wfo/latest/wfo.vtr`.

``` r

taxify_data_dir()
```

    #> [1] "/home/user/.local/share/R/taxify"

Multiple backbones can be installed in one call. Each backbone is
independent and occupies its own subdirectory.

``` r

taxify_download_vtr(c("wfo", "col", "gbif"))
```

taxify checks backbone versions once per R session. If a newer release
appears on Zenodo, the next
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
downloads the update automatically. Pinned versions (useful for
reproducibility) are also supported:
`taxify_download_vtr("wfo", version = "2024.06")` downloads into a
separate directory that is never overwritten. This distinction matters
for long-running projects. The “latest” directory always tracks the most
recent release, while a pinned directory preserves an exact snapshot. If
a collaborator needs to reproduce your results six months later, the
pinned version guarantees that the same backbone rows are used even if
WFO has published a new release in the interim.

## Basic matching

The core function is
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md). It
accepts a character vector of taxonomic names and returns a data.frame
with one row per input name.

``` r

result <- taxify(c(
  "Quercus robur",
  "Pinus sylvestris",
  "Betula pendula",
  "Fagus sylvatica",
  "Acer pseudoplatanus"
))
```

    #> Matching 5 names...

The result is a standard data.frame. Every column is character or
logical, so it plays well with dplyr, data.table, or base R subsetting
without type coercion surprises.

``` r

result[, c("input_name", "accepted_name", "family", "match_type")]
```

    #>              input_name       accepted_name    family match_type
    #> 1        Quercus robur       Quercus robur   Fagaceae      exact
    #> 2     Pinus sylvestris    Pinus sylvestris   Pinaceae      exact
    #> 3       Betula pendula      Betula pendula Betulaceae      exact
    #> 4      Fagus sylvatica     Fagus sylvatica   Fagaceae      exact
    #> 5 Acer pseudoplatanus Acer pseudoplatanus Sapindaceae      exact

All five names matched exactly. The `family` column comes from the
backbone, not from a separate taxonomy lookup, so it is always
consistent with the accepted name.

## Understanding the output

Every [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
call returns the same 16 columns, regardless of which backbone produced
the match. This uniformity means downstream code never needs to branch
on backend type.

| Column | Type | Description |
|:---|:---|:---|
| `input_name` | character | The original string as submitted |
| `matched_name` | character | The backbone entry that matched |
| `accepted_name` | character | The currently accepted name (equals `matched_name` when the match is not a synonym) |
| `taxon_id` | character | Backend-specific ID of the matched name |
| `accepted_id` | character | ID of the accepted name |
| `rank` | character | Taxonomic rank: species, subspecies, genus, family, etc. |
| `family` | character | Family of the accepted name |
| `genus` | character | Genus of the accepted name |
| `epithet` | character | Specific epithet |
| `authorship` | character | Taxonomic authority string |
| `is_synonym` | logical | TRUE if the matched name is a synonym |
| `is_hybrid` | logical | TRUE if a hybrid marker was detected in the input |
| `match_type` | character | One of `exact`, `exact_ci`, `fuzzy`, `out_of_scope`, or `none` |
| `fuzzy_dist` | numeric | Normalized edit distance (0–1), NA for exact matches |
| `backend` | character | Which backbone was used (e.g., `wfo`, `col`, `gbif`) |
| `backbone_version` | character | Backend name, version, and download date for reproducibility |

To see what a single row looks like in practice, consider the synonym
“Pinus abies” matched against WFO.

``` r

row <- taxify("Pinus abies")
t(row)
```

    #>                  [,1]
    #> input_name       "Pinus abies"
    #> matched_name     "Pinus abies"
    #> accepted_name    "Picea abies"
    #> taxon_id         "wfo-0000483065"
    #> accepted_id      "wfo-0000471692"
    #> rank             "species"
    #> family           "Pinaceae"
    #> genus            "Picea"
    #> epithet          "abies"
    #> authorship       "L."
    #> is_synonym       "TRUE"
    #> is_hybrid        "FALSE"
    #> match_type       "exact"
    #> fuzzy_dist       NA
    #> backend          "wfo"
    #> backbone_version "wfo:2024-12 (2026-04-01)"

Several things stand out. The `taxon_id` is the WFO identifier of the
row that actually matched (“Pinus abies”), while `accepted_id` points to
the currently accepted taxon (“Picea abies”). These two IDs differ
whenever a synonym is involved. The `genus` and `family` columns always
reflect the accepted name, not the matched synonym, so downstream joins
on genus or family work correctly even for synonym inputs. The
`backbone_version` string encodes both the WFO release version and the
date the backbone was downloaded. This is useful for methods sections:
“We matched names against WFO v2024-12, downloaded 2026-04-01.”

When a name is not a synonym, `taxon_id` and `accepted_id` are
identical, `matched_name` and `accepted_name` are identical, and
`is_synonym` is FALSE. The `fuzzy_dist` column holds NA for all exact
and case-insensitive matches; it only gets a numeric value for fuzzy
matches. This makes it straightforward to filter for uncertain matches
with `result[!is.na(result$fuzzy_dist), ]`.

The `rank` column deserves a brief note. Most matched names will have
rank “species”, but taxify also matches genus-level names (rank
“genus”), infraspecific names (rank “subspecies”, “variety”, “form”),
and higher-rank names (rank “family”, “order”, etc.) when they appear in
the backbone. If you submit “Quercus” without an epithet, taxify matches
the genus-level entry and returns rank “genus”. If you submit “Pinus
sylvestris var. hamata” and the variety exists in the backbone, you get
rank “variety”; if it does not exist, taxify falls back to the
species-level match and returns rank “species”.

The `authorship` column contains the taxonomic authority as recorded in
the backbone. For WFO this is typically the standard abbreviation (“L.”,
“Sm.”, “(Aiton) Sm.”), while COL and GBIF may include the full
unabbreviated author name. Note that this is the authorship of the
*matched* name, not necessarily of the accepted name. When a synonym is
matched, the authorship reflects the synonym’s authority. This can be
useful for disambiguating homonyms (different species that share the
same binomial but differ in authorship).

## Name cleaning

taxify cleans input names before matching, so messy real-world data
works without manual preprocessing. The cleaning pipeline runs entirely
on the user’s input vector (which is small); the backbone is already
clean. The following transformations happen in order:

1.  **Qualifier stripping.** Prefixes and infixes like `cf.`, `aff.`,
    `s.l.`, `s.str.`, `sp.`, `spp.`, `subsp.`, `var.`, `f.`, `auct.`,
    `sensu`, `agg.` are removed. The qualifier is recorded separately
    and can be retrieved later with
    [`add_qualifier_info()`](https://gillescolling.com/taxify/reference/add_qualifier_info.md).

2.  **Authorship removal.** Parenthesized authorship strings like “(L.)”
    or “(Aiton) Sm.” are stripped first, then trailing authorship
    patterns like “L.” or “ex DC.” are removed. The backbone’s own
    `authorship` column still carries the authority for the matched
    name.

3.  **Whitespace and case normalization.** Multiple spaces collapse to
    one. Everything except the genus initial is lowercased. “ACER
    PSEUDOPLATANUS” becomes “Acer pseudoplatanus”.

4.  **Hybrid marker detection.** The multiplication sign, the letter “x”
    between genus and epithet, or “x” between two binomials are
    recognized as hybrid markers. The `is_hybrid` flag is set, and the
    marker is stripped for matching purposes.

5.  **Latin orthographic normalization.** Common epithet spelling
    alternations are reduced to a canonical form. Pairs like
    “hirtaeformis”/“hirtiformis”, “caeruleum”/“ceruleum”, and
    “phyllum”/“fillum” all normalize to the same key. This catches
    mismatches that are really just alternative transliterations, not
    typos.

Here are those transformations in action.

``` r

messy_result <- taxify(c(
  "Quercus robur L.",              # trailing authorship
  "cf. Betula pendula",            # qualifier prefix
  "Pinus sylvestris var. hamata",  # infraspecific qualifier
  "  Fagus   sylvatica  ",         # extra whitespace
  "ACER PSEUDOPLATANUS"            # all caps
))

messy_result[, c("input_name", "accepted_name", "match_type")]
```

    #>                        input_name       accepted_name match_type
    #> 1              Quercus robur L.        Quercus robur      exact
    #> 2            cf. Betula pendula       Betula pendula      exact
    #> 3 Pinus sylvestris var. hamata    Pinus sylvestris      exact
    #> 4           Fagus   sylvatica      Fagus sylvatica      exact
    #> 5         ACER PSEUDOPLATANUS  Acer pseudoplatanus   exact_ci

The authorship “L.” after “Quercus robur” was removed before matching.
The “cf.” prefix on “Betula pendula” was stripped (the qualifier itself
is recorded internally and can be retrieved with
[`add_qualifier_info()`](https://gillescolling.com/taxify/reference/add_qualifier_info.md)).
“Pinus sylvestris var. hamata” did not match at the variety rank, so
taxify fell back to matching “Pinus sylvestris” at species rank and
reported it as an exact match. The all-caps version of Acer
pseudoplatanus matched after case folding, so it received match type
`exact_ci`.

Latin orthographic normalization is grouped under `exact_ci` as well,
since no edit distance algorithm is involved. The normalizer handles six
common alternation patterns in Latin epithets: `ae`/`i` (as in
caeruleum/ceruleum), `oe`/`i`, terminal `ii`/`i`, `y`/`i`, `ph`/`f`
(phyllum/fillum), `rh`/`r`, and `th`/`t`. These transformations are
applied only to the epithet, never to the genus, and only during the
normalization matching pass. They catch a class of discrepancies that
would otherwise require fuzzy matching and consume edit-distance budget
that might be needed for genuine typos.

The cleaning pipeline is conservative by design. It strips known
qualifiers and authorship patterns but preserves the core binomial. It
does not attempt to correct obvious misspellings (that is the fuzzy
matcher’s job), and it does not guess at abbreviated genus names. The
goal is to remove noise while leaving the signal intact for the matching
engine to handle.

## Synonym resolution

Synonyms are resolved transparently. When a submitted name matches a
synonym in the backbone, `matched_name` shows what was found and
`accepted_name` shows what it resolves to. The `is_synonym` flag marks
these rows.

``` r

syn_result <- taxify(c(
  "Picea abies",
  "Pinus abies",       # basionym / synonym of Picea abies
  "Quercus robur",
  "Quercus pedunculata" # synonym of Quercus robur
))

syn_result[, c("input_name", "matched_name", "accepted_name", "is_synonym")]
```

    #>            input_name       matched_name  accepted_name is_synonym
    #> 1         Picea abies        Picea abies    Picea abies      FALSE
    #> 2         Pinus abies        Pinus abies    Picea abies       TRUE
    #> 3       Quercus robur      Quercus robur  Quercus robur      FALSE
    #> 4 Quercus pedunculata Quercus pedunculata Quercus robur       TRUE

Both “Pinus abies” and “Picea abies” resolve to the same
`accepted_name`, and both share the same `accepted_id`. This is the key
that enrichment joins and
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
use, so trait data attached via accepted ID propagates correctly
regardless of which synonym the user submitted.

Some species accumulate many synonyms over their taxonomic history. The
common Norway spruce has been described under at least four different
genera: *Pinus abies* L. (the Linnaean basionym), *Abies picea* Mill.,
*Picea excelsa* (Lam.) Link, and the accepted *Picea abies* (L.)
H.Karst. All four names are present in the WFO backbone as synonyms
pointing to the same accepted taxon ID. Submitting any of them to taxify
returns the same `accepted_name` and `accepted_id`.

``` r

spruce <- taxify(c(
  "Picea abies",       # accepted name
  "Pinus abies",       # Linnaean basionym
  "Abies picea",       # Miller's combination
  "Picea excelsa"      # Link's combination
))

spruce[, c("input_name", "accepted_name", "accepted_id", "is_synonym")]
```

    #>       input_name accepted_name     accepted_id is_synonym
    #> 1    Picea abies   Picea abies wfo-0000471692      FALSE
    #> 2    Pinus abies   Picea abies wfo-0000471692       TRUE
    #> 3    Abies picea   Picea abies wfo-0000471692       TRUE
    #> 4  Picea excelsa   Picea abies wfo-0000471692       TRUE

The identical `accepted_id` across all four rows means any downstream
operation that groups or joins on accepted ID treats them as the same
species. This is the entire point of synonym resolution: it collapses
the many-to-one relationship between historical names and the current
consensus.

Taxonomic synonyms come in two flavours. A *homotypic synonym* (also
called a nomenclatural synonym) is based on the same type specimen as
the accepted name; the species was simply moved to a different genus.
“Pinus abies” is a homotypic synonym of “Picea abies” because both are
based on the same Linnaean type. A *heterotypic synonym* (also called a
taxonomic synonym) is based on a different type specimen but was later
judged to represent the same species. taxify does not distinguish
between the two in the output: the `is_synonym` column is TRUE for both.
Some backbones (GBIF, COL) do record whether a synonym is homotypic or
heterotypic, and that information is available via
[`add_gbif_info()`](https://gillescolling.com/taxify/reference/add_gbif_info.md)
or
[`add_col_info()`](https://gillescolling.com/taxify/reference/add_col_info.md),
but for most workflows the simple TRUE/FALSE flag is sufficient.

Synonym resolution handles chains. If synonym A points to synonym B,
which points to accepted name C, taxify follows the chain (up to 10
hops) and returns C. This matters for backbones like COL and GBIF where
synonym chains of length two or three are common.

## Match types

taxify classifies every match into one of five categories. Each category
reflects a different level of confidence in the result.

**exact**: The cleaned input matches a backbone entry character for
character. This is the fastest path and the most reliable. In practice,
the majority of well-formatted species names fall into this category.

``` r

taxify("Quercus robur")[, c("input_name", "match_type", "fuzzy_dist")]
```

    #>     input_name match_type fuzzy_dist
    #> 1 Quercus robur      exact         NA

**exact_ci**: The input matches after case folding or after Latin
orthographic normalization. No edit distance is involved. This category
catches two distinct classes of mismatch: pure capitalization
differences, and Latin spelling alternations.

``` r

taxify("quercus robur")[, c("input_name", "match_type", "fuzzy_dist")]
```

    #>     input_name match_type fuzzy_dist
    #> 1 quercus robur   exact_ci         NA

The name “quercus robur” (all lowercase) does not match “Quercus robur”
character-for-character, but it does match after case folding. The match
type is `exact_ci` and `fuzzy_dist` remains NA because no edit distance
algorithm was needed.

**fuzzy**: The input does not match exactly but falls within the allowed
edit distance of a backbone entry. The default threshold is 0.2
(normalized Damerau-Levenshtein), which allows roughly one edit per five
characters. Fuzzy matching is genus-blocked: “Quercus robor” will only
be compared against other *Quercus* entries, not the entire backbone.

``` r

taxify("Quercus robor")[, c("input_name", "accepted_name",
                            "match_type", "fuzzy_dist")]
```

    #>     input_name accepted_name match_type fuzzy_dist
    #> 1 Quercus robor Quercus robur      fuzzy 0.07142857

The typo “robor” (missing the “u”) was corrected to “Quercus robur” with
a normalized edit distance of about 0.07. The `fuzzy_dist` column always
holds the normalized distance, so values are comparable across names of
different lengths.

**out_of_scope**: The genus is recognized in the genus register but is
not covered by the requested backbone. Submitting “Panthera leo” to the
WFO backbone (plants only) produces this classification, because taxify
knows *Panthera* is a real genus that belongs to a different backbone.

``` r

taxify("Panthera leo")[, c("input_name", "match_type", "life_form")]
```

    #>    input_name   match_type life_form
    #> 1 Panthera leo out_of_scope    animal

The `life_form` column (populated from the genus register) shows
“animal”, which explains why the name is out of scope for a plant-only
backbone. The summary method uses this information to suggest
alternative backends.

**none**: No match was found and the genus is either unknown or also
covered by the requested backend. This means the name is genuinely
absent from the backbone, not merely scoped to a different one.

``` r

taxify("Fakegenus fakus")[, c("input_name", "match_type")]
```

    #>       input_name match_type
    #> 1 Fakegenus fakus       none

“Fakegenus fakus” is not recognized by any backbone, so it receives
`none`. There is no genus register entry for “Fakegenus”, no alternative
backend to suggest. In real-world datasets, `none` typically indicates a
garbled name, a common name that was not converted to Latin, or an
organism described in a publication that predates the backbone’s
coverage.

The five categories together give a complete picture of match quality. A
quick diagnostic pass over the output might look like this:

``` r

types_result <- taxify(c(
  "Quercus robur",      # exact
  "quercus robur",      # exact_ci (case folding)
  "Quercus robor",      # fuzzy (one-char typo)
  "Panthera leo",       # out_of_scope (animal in WFO)
  "Fakegenus fakus"     # none
))

table(types_result$match_type)
```

    #>       exact    exact_ci       fuzzy        none out_of_scope
    #>           1           1           1           1            1

Fuzzy matching is controlled by three arguments. `fuzzy = FALSE`
disables it entirely. `fuzzy_threshold` sets the maximum normalized
distance (default 0.2) or, when \>= 1, a raw edit count (e.g.,
`fuzzy_threshold = 2L` allows at most 2 edits regardless of name
length). `fuzzy_method` selects the algorithm: `"dl"`
(Damerau-Levenshtein, default), `"levenshtein"`, or `"jw"`
(Jaro-Winkler).

``` r

# Strict: only allow 1 edit total, regardless of name length
taxify("Quercus robor", fuzzy_threshold = 1L)

# Jaro-Winkler instead of Damerau-Levenshtein
taxify("Quercus robor", fuzzy_method = "jw")

# No fuzzy matching at all
taxify("Quercus robor", fuzzy = FALSE)
```

## The summary method

Calling [`summary()`](https://rdrr.io/r/base/summary.html) on a taxify
result prints a compact digest of match quality. This is the fastest way
to assess whether a run went well or whether something needs attention
upstream.

``` r

mixed <- taxify(c(
  "Quercus robur", "Pinus sylvestris", "Betula pendula",
  "Picea abies", "Pinus abies",
  "Quercus robor",       # typo
  "Panthera leo",         # animal in WFO
  "Felis catus",          # animal in WFO
  "Fakus invalidus"       # genuinely absent
))

summary(mixed)
```

    #> -- taxify results ------------------------------------------------------------
    #>   backend: WFO v2024-12  |  9 names submitted
    #>
    #>   matched         6  (exact: 4, case-insensitive: 0, fuzzy: 1)
    #>   out of scope    2  (animal: 2 -- not in WFO, try backend = "col", "gbif")
    #>   unmatched       1  (taxon_group: unknown: 1)
    #>   ------------------------------------------------------------
    #>   taxon groups: vascular plant: 6  animal: 2  unknown: 1

The first line identifies the backend and version, and the total number
of names submitted. The “matched” line breaks down by match type so we
can immediately see that four names matched exactly, zero needed case
folding, and one required fuzzy correction. The “out of scope” line
reports two animal names that have no business being in a plant
backbone, and helpfully suggests `"col"` or `"gbif"` as alternatives.
The “unmatched” line tallies genuinely absent names, broken down by
taxon group from the genus register. The taxon-groups summary at the
bottom shows the life-form composition of the full input. If a dataset
that should be all plants shows 50 animals, something went wrong
upstream.

When enrichments have been applied, the summary includes them as well.
Each enrichment layer gets its own line showing the source, version, and
how many species received data.

``` r

enriched <- mixed |>
  add_conservation_status() |>
  add_woodiness()

summary(enriched)
```

    #> -- taxify results ------------------------------------------------------------
    #>   backend: WFO v2024-12  |  9 names submitted
    #>
    #>   matched         6  (exact: 4, case-insensitive: 0, fuzzy: 1)
    #>   out of scope    2  (animal: 2 -- not in WFO, try backend = "col", "gbif")
    #>   unmatched       1  (taxon_group: unknown: 1)
    #>   ------------------------------------------------------------
    #>   taxon groups: vascular plant: 6  animal: 2  unknown: 1
    #>
    #>   enrichments:
    #>     conservation_status  (IUCN Red List 2024.12) -- 4 of 9 matched
    #>     woodiness            (Zanne et al. 2014 2024.12) -- 5 of 9 matched

The enrichment lines show that 4 of the 9 input names received an IUCN
conservation status, and 5 received woodiness data. The difference is
expected: the two animal names and the unmatched name have no records in
either enrichment, and not every plant species has been assessed by
IUCN.

## Multi-backend fallback

A single backbone rarely covers everything in a mixed-kingdom dataset.
Passing multiple backend names creates a fallback chain: names matched
by an earlier backend are not re-matched by later ones.

``` r

multi <- taxify(
  c("Quercus robur", "Panthera leo", "Amanita muscaria",
    "Escherichia coli", "Salmo trutta"),
  backend = c("wfo", "col", "gbif")
)
```

    #> Matching 5 names against 3 backends: wfo -> col -> gbif
    #>   [wfo] Matching 5 names...
    #>   [col] Matching 3 remaining names...
    #>   [gbif] Matching 1 remaining names...

The progress messages tell the story. WFO receives all 5 names. It
matches “Quercus robur” (a plant) and fails on the other four. COL then
receives the 3 remaining names and matches “Panthera leo” (a mammal),
“Amanita muscaria” (a fungus), and “Salmo trutta” (a fish). That leaves
only “Escherichia coli” (a bacterium) for GBIF.

``` r

multi[, c("input_name", "accepted_name", "backend")]
```

    #>         input_name      accepted_name backend
    #> 1    Quercus robur      Quercus robur     wfo
    #> 2     Panthera leo       Panthera leo     col
    #> 3 Amanita muscaria  Amanita muscaria     col
    #> 4 Escherichia coli  Escherichia coli    gbif
    #> 5     Salmo trutta      Salmo trutta     col

The `backend` column records which backbone resolved each name. This
column is essential for reproducibility: it tells a reviewer (or your
future self) that Quercus robur was resolved using WFO while Panthera
leo used COL.

The fallback order matters. WFO is the most authoritative source for
plants, so putting it first ensures plant names get WFO-quality synonym
resolution. COL covers all kingdoms but with less taxonomic depth per
group. GBIF has the widest coverage but coarser synonym handling. A
sensible default for mixed-kingdom work is
`backend = c("wfo", "col", "gbif")`.

A subtle point: once a name matches in an earlier backend, it is removed
from the pool sent to subsequent backends. This means the COL and GBIF
backends never see “Quercus robur” at all, which both speeds up matching
and avoids conflicting results for names that exist in multiple
backbones. If Quercus robur had been sent to all three backbones, it
would match in each, potentially returning different taxon IDs and
slightly different synonym chains. The fallback design avoids this
ambiguity by construction.

One practical consequence: the `accepted_id` values in a multi-backend
result are not globally unique across backends. A WFO ID like
“wfo-0000306015” and a COL ID like “9TQBG” are both valid identifiers
but belong to different namespaces. Downstream joins that combine
results from different taxify runs should join on `accepted_name` (which
is a real taxonomic name) rather than `accepted_id` (which is
backend-specific).

The summary for a multi-backend run aggregates across all backends but
preserves the per-backend breakdown in the out-of-scope tally. It also
shows the backend names in the header line, making it clear that
multiple sources contributed to the result.

## Enrichments

taxify ships with 12 enrichment layers that join external trait and
status data to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result. Each enrichment is a separate .vtr file downloaded on first use
and cached locally. The join key is `accepted_name`, so synonyms in the
original input resolve correctly.

``` r

list_enrichments()
```

    #>                name   version   nrow static                                  trait_cols                                  source_url
    #> 1  conservation_status 2024.12 166342   TRUE                         conservation_status    https://doi.org/10.15468/39omei
    #> 2             griis    2024.12  25918   TRUE                          invasive_status  https://doi.org/10.15468/6jbdk3
    #> 3              wcvp    2024.12 356224   TRUE                            native_status      https://doi.org/10.34885/gah...
    #> 4              eive    2024.12   6937   TRUE   light, temperature, moisture, reaction  https://doi.org/10.1111/jvs.13031
    #> 5       elton_traits   2024.12   9994   TRUE         diet_inv, diet_vend, ..., body...      https://doi.org/10.1890/13-1917.1
    #> 6            avonet    2024.12  11009   TRUE        beak_length, wing_length, migrat...    https://doi.org/10.1111/ele.13898
    #> 7          pantheria   2024.12   5416   TRUE   longevity_mo, litter_size, gestation...   https://doi.org/10.1890/08-1494.1
    #> 8          amphibio    2024.12   6776   TRUE  body_size_mm, age_maturity_d, reproduc...   https://doi.org/10.1038/sdata.2017.123
    #> 9      common_names    2024.12 982445  FALSE                             common_name     https://doi.org/10.15468/39omei
    #> 10        woodiness    2024.12  47898   TRUE                               woodiness        https://doi.org/10.1038/nature12872
    #> 11      diaz_traits   2024.12   7381   TRUE              seed_mass_mg, plant_height_m  https://doi.org/10.1038/s41586-015-...
    #> 12             leda    2024.12   3625   TRUE   raunkiaer_life_form, dispersal_type, ...  https://doi.org/10.1111/j.1365-...

Each `add_*()` function appends one or more columns to the result. The
functions download their .vtr on first use, so no separate installation
step is needed. The `static` column in the listing above indicates
whether the dataset is version-locked (TRUE means it will never change;
FALSE means taxify checks for updates once per session).

The enrichment join key is `accepted_name`, not `input_name`. This is a
deliberate choice. If two rows in the taxify result were submitted as
“Pinus abies” (a synonym) and “Picea abies” (the accepted name), both
resolve to the same `accepted_name` and therefore receive the same trait
values from the enrichment layer. The enrichment .vtr files are built
with cross-backbone name resolution, meaning a species name is resolved
against all seven backbones during the enrichment build pipeline, and
the union of all resulting accepted names is stored. This ensures that
[`add_woodiness()`](https://gillescolling.com/taxify/reference/add_woodiness.md)
works correctly regardless of whether the user matched against WFO, COL,
or GBIF.

Some enrichments are kingdom-specific. Woodiness, EIVE, WCVP, Diaz
traits, and LEDA cover plants only. EltonTraits covers birds and
mammals. AVONET is bird-only. PanTHERIA is mammal-only. AmphiBIO is
amphibian-only. Conservation status and common names are cross-kingdom.
When an enrichment does not cover a particular taxon group, those rows
simply receive NA. The summary method reports how many rows received
data, so the coverage gap is immediately visible.

### Conservation status

[`add_conservation_status()`](https://gillescolling.com/taxify/reference/add_conservation_status.md)
joins IUCN Red List categories. Coverage is global across all taxonomic
groups, approximately 166,000 species.

``` r

conservation <- taxify(c(
  "Panthera tigris",
  "Quercus robur",
  "Ailuropoda melanoleuca",
  "Pinus sylvestris",
  "Spheniscus demersus"
), backend = c("wfo", "col")) |>
  add_conservation_status()

conservation[, c("input_name", "accepted_name", "conservation_status")]
```

    #>              input_name          accepted_name conservation_status
    #> 1       Panthera tigris        Panthera tigris                  EN
    #> 2         Quercus robur          Quercus robur                  LC
    #> 3 Ailuropoda melanoleuca Ailuropoda melanoleuca                 VU
    #> 4      Pinus sylvestris       Pinus sylvestris                  LC
    #> 5    Spheniscus demersus    Spheniscus demersus                 EN

The IUCN abbreviations are standard: LC (Least Concern), NT (Near
Threatened), VU (Vulnerable), EN (Endangered), CR (Critically
Endangered), EW (Extinct in the Wild), EX (Extinct). Species not yet
assessed by the IUCN receive NA. The Sumatran tiger and African penguin
both show EN; Quercus robur and Pinus sylvestris are LC.

### Common names

[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md)
joins GBIF vernacular names filtered by ISO 639-1 language code. The
default is English.

``` r

common <- taxify(c(
  "Quercus robur",
  "Pinus sylvestris",
  "Betula pendula"
)) |>
  add_common_names()

common[, c("input_name", "common_name")]
```

    #>        input_name   common_name
    #> 1   Quercus robur   Pedunculate Oak
    #> 2 Pinus sylvestris  Scots Pine
    #> 3   Betula pendula  Silver Birch

Other languages work the same way. German names for the same species:

``` r

common_de <- taxify(c(
  "Quercus robur",
  "Pinus sylvestris",
  "Betula pendula"
)) |>
  add_common_names(lang = "de")

common_de[, c("input_name", "common_name")]
```

    #>        input_name common_name
    #> 1   Quercus robur  Stieleiche
    #> 2 Pinus sylvestris Waldkiefer
    #> 3   Betula pendula  Hängebirke

When multiple vernacular names exist for a species in the requested
language, the most commonly used one is returned.

### Woodiness

[`add_woodiness()`](https://gillescolling.com/taxify/reference/add_woodiness.md)
joins the Zanne et al. (2014) woodiness classification. Coverage is
about 48,000 plant species, each labelled as “woody”, “herbaceous”, or
“variable” (species that can be either depending on growth conditions).

``` r

woody <- taxify(c(
  "Quercus robur",
  "Trifolium repens",
  "Salix caprea",
  "Plantago lanceolata"
)) |>
  add_woodiness()

woody[, c("input_name", "accepted_name", "woodiness")]
```

    #>           input_name       accepted_name woodiness
    #> 1      Quercus robur       Quercus robur     woody
    #> 2  Trifolium repens    Trifolium repens herbaceous
    #> 3      Salix caprea        Salix caprea     woody
    #> 4 Plantago lanceolata Plantago lanceolata herbaceous

Enrichments stack naturally in a pipe. The columns added by each
`add_*()` function are independent, so the order of application does not
matter.

``` r

stacked <- taxify(c(
  "Quercus robur",
  "Betula pendula",
  "Pinus sylvestris"
)) |>
  add_conservation_status() |>
  add_woodiness() |>
  add_common_names()

stacked[, c("accepted_name", "conservation_status",
            "woodiness", "common_name")]
```

    #>      accepted_name conservation_status woodiness    common_name
    #> 1    Quercus robur                  LC     woody Pedunculate Oak
    #> 2   Betula pendula                  LC     woody    Silver Birch
    #> 3 Pinus sylvestris                  LC     woody     Scots Pine

## Custom data

[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
joins any external dataset to a taxify result through backbone matching.
The external data’s species names are run through the same backbone(s)
that produced the original result, and the join is performed on
`accepted_id`. This means synonyms in either the user’s data or the
external dataset resolve to the same key.

### From a data.frame

``` r

traits <- data.frame(
  species = c("Quercus robur", "Quercus pedunculata",
              "Pinus sylvestris", "Betula pendula"),
  max_height_m = c(40, 40, 35, 25),
  shade_tolerance = c("moderate", "moderate", "intolerant", "intolerant"),
  stringsAsFactors = FALSE
)

result <- taxify(c("Quercus robur", "Pinus sylvestris", "Betula pendula"))

enriched <- result |>
  add_data(traits, species_col = "species")
```

    #> Matching 4 names from 'species' through WFO backbone...
    #> Matching 4 names...
    #> add_data: 3 of 3 species matched (100.0%). 0 names in data unmatched.

``` r

enriched[, c("input_name", "accepted_name", "max_height_m", "shade_tolerance")]
```

    #>        input_name     accepted_name max_height_m shade_tolerance
    #> 1   Quercus robur     Quercus robur           40        moderate
    #> 2 Pinus sylvestris  Pinus sylvestris           35      intolerant
    #> 3   Betula pendula    Betula pendula           25      intolerant

The traits data.frame contained both “Quercus robur” and “Quercus
pedunculata” (a synonym). Because both resolve to the same accepted ID,
the join works correctly without deduplication on the user’s side. If
the two rows had different trait values for the same accepted species,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
would raise an error rather than silently picking one.

### From a CSV file

``` r

enriched <- result |>
  add_data("my_field_traits.csv")
```

When `species_col` is not specified,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
auto-detects it by probing the first 10 rows of each character column
against the backbone. The column with the highest match rate wins. If no
column reaches 50% match rate, an error asks the user to specify
`species_col` explicitly. The auto-detection runs a small
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
internally, so it adds a brief delay on first use, but it saves time in
exploratory workflows where the column name varies across datasets
(“species”, “taxon”, “scientific_name”, “Taxon.name”, and so on).

The join itself is performed on `accepted_id`, not on the raw species
name. This is the key difference from a naive
[`merge()`](https://rdrr.io/r/base/merge.html). If the user’s CSV
contains “Quercus pedunculata” (a synonym) and the taxify result
contains “Quercus robur” (the accepted name), a raw string merge would
miss the connection. The
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
join resolves both names through the backbone, discovers that they share
the same accepted ID, and links them correctly. Duplicate handling is
strict: if two rows in the external data resolve to the same accepted ID
with different trait values,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
raises an error rather than silently picking one row.

### Supported file formats

[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
reads `.csv`, `.csv.gz`, `.xlsx` (requires the openxlsx2 package),
`.sqlite`/`.db` (requires DBI and RSQLite), and `.vtr` files natively.
For SQLite files, specify the table name with the `table` argument. Any
other format can be read into a data.frame first and passed directly.

``` r

# SQLite
result |> add_data("ecology_db.sqlite", table = "plant_traits")

# XLSX
result |> add_data("supplementary_table_S1.xlsx", species_col = "Taxon")

# Subset columns
result |> add_data(traits, species_col = "species", cols = "max_height_m")
```

## Hybrid names

taxify detects hybrid markers in input names (the multiplication sign,
the letter x between genus and epithet, or between two binomials) and
sets `is_hybrid = TRUE` in the output.
[`add_hybrid_info()`](https://gillescolling.com/taxify/reference/add_hybrid_info.md)
goes further, parsing hybrid formulas to extract parent names and
classify the hybrid type.

``` r

hybrids <- taxify(c(
  "Quercus x rosacea",                  # nothospecies
  "Quercus pyrenaica x Q. petraea",     # hybrid formula
  "x Cuprocyparis leylandii",           # nothogenus
  "Betula pendula"                       # not a hybrid
)) |>
  add_hybrid_info()

hybrids[, c("input_name", "is_hybrid", "hybrid_type",
            "hybrid_parent_1", "hybrid_parent_2")]
```

    #>                          input_name is_hybrid hybrid_type hybrid_parent_1 hybrid_parent_2
    #> 1              Quercus x rosacea      TRUE nothospecies            <NA>            <NA>
    #> 2 Quercus pyrenaica x Q. petraea      TRUE      formula Quercus pyrenaica Quercus petraea
    #> 3    x Cuprocyparis leylandii        TRUE   nothogenus            <NA>            <NA>
    #> 4                  Betula pendula     FALSE         <NA>            <NA>            <NA>

Three hybrid types are recognized. “nothospecies” is a named hybrid
species (the multiplication sign appears between genus and epithet).
“formula” is a hybrid cross written as “A x B”, where the parser expands
abbreviated genera (the “Q.” in “Q. petraea” is expanded to “Quercus”
based on the first parent). “nothogenus” is a hybrid genus (the
multiplication sign precedes the genus name).

For formulas, the extracted parent names are full binomials that can be
submitted to
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
themselves for further resolution. A common workflow for hybrid-heavy
datasets (e.g., ornamental horticulture records) is to run
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) on
the full list, then pipe through
[`add_hybrid_info()`](https://gillescolling.com/taxify/reference/add_hybrid_info.md),
and finally re-run
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) on
the extracted parent names to obtain their full taxonomic resolution.
The hybrid detection runs on the raw input before any cleaning, so it
correctly handles both the Unicode multiplication sign and the ASCII “x”
notation.

## Genus register

taxify maintains a unified genus register built from all installed
backbones. It maps each genus to its family, higher classification, and
a broad life-form category.
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md)
queries this register.

``` r

lookup_genus("Quercus")
```

    #>     genus kingdom phylum class     order   family kingdom_group  taxon_group      life_form
    #> 1 Quercus Plantae   <NA> Magnoliopsida Fagales Fagaceae       plantae vascular plant vascular plant

``` r

lookup_genus("Panthera")
```

    #>      genus  kingdom   phylum    class    order   family kingdom_group taxon_group life_form
    #> 1 Panthera Animalia Chordata Mammalia Carnivora Felidae      animalia      animal    animal

The register is what powers the `out_of_scope` classification and the
taxon-group breakdown in
[`summary()`](https://rdrr.io/r/base/summary.html). It is built once
from the union of WFO, COL, and GBIF genera, with classification
conflicts resolved by priority (COL \> GBIF \> WFO for higher taxonomy,
since COL and GBIF carry kingdom through order while WFO only has
family).

[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md)
shows which backbones contain a given genus, which helps decide which
backend to use for a particular taxonomic group.

``` r

taxify_register_coverage("Quercus")
```

    #>     genus backend  version  date_added
    #> 1 Quercus     wfo 2024-12  2026-04-01
    #> 2 Quercus     col 2024.4   2026-04-01
    #> 3 Quercus    gbif 2024-08  2026-04-01

``` r

taxify_register_coverage("Panthera")
```

    #>      genus backend  version  date_added
    #> 1 Panthera     col 2024.4   2026-04-01
    #> 2 Panthera    gbif 2024-08  2026-04-01

Quercus appears in all three major backbones. Panthera is absent from
WFO (plants only) but present in COL and GBIF. This information is used
automatically during matching, but it is also useful when planning which
backends to install for a particular project. If your dataset is
entirely marine invertebrates, you might check a few representative
genera with
[`taxify_register_coverage()`](https://gillescolling.com/taxify/reference/taxify_register_coverage.md)
and discover that WoRMS is the only backend that covers them, saving the
time of downloading WFO and COL.

The register currently contains approximately 100,000 genera drawn from
the union of WFO, COL, and GBIF. It is rebuilt whenever
`build_unified_register()` runs (typically after installing or updating
a backbone). The register is small enough to fit comfortably in memory
and is cached for the duration of the R session, so
[`lookup_genus()`](https://gillescolling.com/taxify/reference/lookup_genus.md)
calls are effectively instant.

## Cache management

Backbone .vtr files, enrichment .vtr files, and the genus register all
live under
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md).
During an R session, taxify caches file paths in memory so that repeated
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) calls
do not re-scan the file system.

[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md)
drops these in-memory handles. The next
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
will re-load from disk. This is rarely needed, but it can help after
manually moving or deleting .vtr files.

``` r

taxify_clear_cache()
```

To force a fresh manifest fetch (e.g., after the maintainer publishes a
new backbone version mid-session), use
[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md).

``` r

taxify_refresh_manifest()
```

The on-disk files themselves are never deleted by taxify. To reclaim
disk space, delete the contents of
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)
manually.

``` r

# See where everything lives
taxify_data_dir()

# To remove all taxify data (backbones, enrichments, register):
# unlink(taxify_data_dir(), recursive = TRUE)
```

The total disk footprint depends on how many backbones and enrichments
are installed. WFO alone is about 150 MB; all nine backbones plus all 12
enrichments total roughly 2.5 GB.

## The full pipeline

We will close with an end-to-end worked example. The input is a
realistic list of 22 species names from a hypothetical European
biodiversity survey. It includes six clean accepted plant names, three
historical synonyms (Pinus abies, Quercus pedunculata, Picea excelsa),
two typos (Quercus robor, Fagus sylvatyca), four messy field annotations
(qualifier, trailing authorship, infraspecific rank, excess whitespace),
one hybrid, four animal names that do not belong in a plant backbone,
and two entirely fictitious names. We will match against WFO and COL,
inspect the summary, and layer on three enrichments.

``` r

survey_names <- c(
  "Quercus robur", "Fagus sylvatica", "Betula pendula",
  "Pinus sylvestris", "Alnus glutinosa", "Fraxinus excelsior",
  "Pinus abies", "Quercus pedunculata", "Picea excelsa",
  "Quercus robor", "Fagus sylvatyca",
  "cf. Sorbus aucuparia", "Acer pseudoplatanus L.",
  "Pinus sylvestris var. hamata", "  Tilia   cordata  ",
  "Quercus x rosacea",
  "Panthera leo", "Salmo trutta", "Cervus elaphus", "Parus major",
  "Notareal plantus", "Randomus specius"
)
```

There are 22 names in total. We match against WFO first (best for
plants), with COL as a fallback for the animal names.

``` r

result <- taxify(survey_names, backend = c("wfo", "col"))
```

    #> Matching 22 names against 2 backends: wfo -> col
    #>   [wfo] Matching 22 names...
    #>   [wfo] Fuzzy matching 6 unmatched...
    #>   [col] Matching 4 remaining names...

WFO handled the plant names (exact, fuzzy, synonym, and all). The 4
animal names did not match in WFO and were forwarded to COL, which
resolved all four. Let us look at the summary first.

``` r

summary(result)
```

    #> -- taxify results ------------------------------------------------------------
    #>   backend: WFO + COL  |  22 names submitted
    #>
    #>   matched        18  (exact: 13, case-insensitive: 0, fuzzy: 2)
    #>   out of scope    0
    #>   unmatched       2  (taxon_group: unknown: 2)
    #>   ------------------------------------------------------------
    #>   taxon groups: vascular plant: 16  animal: 4  unknown: 2

Eighteen of 22 names matched. The two unknowns are “Notareal plantus”
and “Randomus specius”, which do not exist in any backbone. The animal
names are not out of scope this time because COL covers them.

Now we layer on three enrichments: conservation status, woodiness, and
common names.

``` r

result <- result |>
  add_conservation_status() |>
  add_woodiness() |>
  add_common_names()
```

The summary now reflects the enrichment coverage.

``` r

summary(result)
```

    #> -- taxify results ------------------------------------------------------------
    #>   backend: WFO + COL  |  22 names submitted
    #>
    #>   matched        18  (exact: 13, case-insensitive: 0, fuzzy: 2)
    #>   out of scope    0
    #>   unmatched       2  (taxon_group: unknown: 2)
    #>   ------------------------------------------------------------
    #>   taxon groups: vascular plant: 16  animal: 4  unknown: 2
    #>
    #>   enrichments:
    #>     conservation_status  (IUCN Red List 2024.12)      -- 12 of 22 matched
    #>     woodiness            (Zanne et al. 2014 2024.12)  -- 14 of 22 matched
    #>     common_names         (GBIF vernacular names 2024.12) -- 16 of 22 matched

Conservation status matched 12 of 22 names, woodiness matched 14, and
common names matched 16. These numbers make sense. Conservation status
has gaps because not every species has been assessed by IUCN; the common
European trees are assessed (mostly LC), but some of the less prominent
species may not be. Woodiness covers about 48,000 species from the Zanne
et al. dataset, so most temperate trees are included. Common names have
the widest coverage because the GBIF vernacular names dataset is very
large, though it still misses some species in less commonly documented
languages.

We can now pull out the columns we care about for downstream analysis.
The result is a plain data.frame, so standard R subsetting, dplyr verbs,
or data.table operations all work without special handling.

``` r

analysis <- result[, c("input_name", "accepted_name", "family",
                        "match_type", "is_synonym", "backend",
                        "conservation_status", "woodiness",
                        "common_name")]
```

A few diagnostic queries round out the workflow. These are patterns that
come up in nearly every biodiversity data cleaning session.

``` r

# Which names were synonyms?
result[result$is_synonym == TRUE,
       c("input_name", "accepted_name", "accepted_id")]
```

    #>            input_name  accepted_name       accepted_id
    #> 7         Pinus abies    Picea abies  wfo-0000471692
    #> 8  Quercus pedunculata Quercus robur  wfo-0000306015
    #> 9     Picea excelsa      Picea abies  wfo-0000471692

Three synonyms were submitted. “Pinus abies” and “Picea excelsa” both
resolve to the same accepted species, Picea abies, with the same
accepted ID. “Quercus pedunculata” resolves to Quercus robur. Because
these synonyms share accepted IDs with other rows in the result, the
enrichment columns carry the same trait values as their accepted-name
counterparts. This is a common pattern in biodiversity databases: the
same physical species appears under different names in different
records, and the synonym resolution step collapses those variants so
that trait lookups and species counts are correct. Without this step, a
species count would overcount Picea abies (listing it three times under
three different names) and a trait join would miss the synonym rows
entirely.

``` r

# Which names needed fuzzy correction?
result[result$match_type == "fuzzy",
       c("input_name", "accepted_name", "fuzzy_dist")]
```

    #>        input_name  accepted_name fuzzy_dist
    #> 10  Quercus robor  Quercus robur 0.07142857
    #> 11 Fagus sylvatyca Fagus sylvatica 0.06666667

Both typos were corrected with very low edit distances. The “y” in
“sylvatyca” was caught by Damerau-Levenshtein, and the missing “u” in
“robor” was caught the same way.

``` r

# Threatened species in the survey
result[!is.na(result$conservation_status) &
       result$conservation_status %in% c("VU", "EN", "CR"),
       c("accepted_name", "conservation_status", "common_name")]
```

    #>     accepted_name conservation_status common_name
    #> 17  Panthera leo                  VU        Lion

Only one species in this survey carries a threatened IUCN status. The
rest are either Least Concern or not yet assessed. For a European forest
plot this is unsurprising. A tropical or marine dataset would likely
show more threatened species. The conservation status enrichment is
cross-kingdom, so it works for the animal names as well (Panthera leo is
VU globally).

``` r

# Woody vs. herbaceous breakdown
table(result$woodiness, useNA = "ifany")
```

    #> herbaceous      woody       <NA>
    #>          0         14          8

All matched plants in this survey are woody, which makes sense for a
European forest plot. The 8 NAs correspond to the 4 animal names
(woodiness is a plant-only enrichment), the 2 unknown names, and 2
plants that happen to fall outside the Zanne et al. dataset coverage.

The entire pipeline ran offline after the initial backbone download.
There are no API rate limits, no network dependency during analysis, and
the `backbone_version` column in the output ensures full
reproducibility.

A few closing notes on performance. taxify uses vectra’s columnar engine
for all backbone queries. Exact matching is index-accelerated (hash
indexes on the name and genus columns), so even against the GBIF
backbone (over 7 million rows) a batch of 10,000 names typically
completes in a few seconds. Fuzzy matching is slower because it involves
string distance computation, but it is genus-blocked: each input name is
only compared against backbone entries in the same genus, which reduces
the search space by several orders of magnitude. For very large batches
(100,000+ names), the main bottleneck is fuzzy matching of names with
misspelled genera, where the genus blocking cannot help. In that case,
consider running a first pass with `fuzzy = FALSE` to pick off the easy
matches, then re-running only the unmatched names with fuzzy enabled.

The enrichment joins are also fast. Each `add_*()` call performs a
single vectra inner join on `accepted_name`, which is O(n) in the size
of the taxify result. Stacking multiple enrichments in a pipe adds
columns incrementally without re-reading the backbone.
