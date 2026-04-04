# Migrating from taxize and WorldFlora

## Why migrate

The R ecosystem has two well-established packages for taxonomic name
resolution: [taxize](https://docs.ropensci.org/taxize/) for
multi-database API lookups, and
[WorldFlora](https://cran.r-project.org/package=WorldFlora) for offline
matching against the WFO backbone. Both work. If your workflow already
uses one of them and you are happy with it, there is no urgent reason to
switch.

That said, there are situations where taxify offers a better fit:

- **Multiple backbones.** taxize queries APIs one at a time; WorldFlora
  supports WFO only. taxify matches against nine backbones offline and
  can chain them in a single call:
  `taxify(names, backend = c("wfo", "col", "gbif"))`.
- **Speed at scale.** taxify’s matching engine is written in C with
  genus-blocked fuzzy joins. Ten thousand names resolve in seconds, not
  minutes.
- **Enrichments.** taxify pipes results directly into twelve published
  trait and status datasets (IUCN, GRIIS, WCVP, EIVE, EltonTraits, etc.)
  with a single `|>` chain.
- **Reproducibility.** Backbones are versioned files on disk. The
  `backbone_version` column records exactly which snapshot was used.

This vignette maps the old APIs to their taxify equivalents, walks
through three side-by-side examples, and is honest about what taxify
does not cover.

## Function mapping: taxize to taxify

The table below lists the taxize functions that taxify replaces, along
with functions that have no direct equivalent.

| taxize function | taxify equivalent | Notes |
|----|----|----|
| `gnr_resolve()` | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | Any backend; returns best match per name |
| `get_tsn()` | `taxify(backend = "itis")` | `taxon_id` column holds the TSN |
| `get_uid()` | `taxify(backend = "ncbi")` | `taxon_id` column holds the UID |
| `get_gbifid()` | `taxify(backend = "gbif")` | `taxon_id` column holds the GBIF usage key |
| `get_wormsid()` | `taxify(backend = "worms")` | `taxon_id` column holds the AphiaID |
| `classification()` | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | Returns `family`, `genus`, `rank` directly; [`add_col_info()`](https://gillescolling.com/taxify/reference/add_col_info.md) for full hierarchy |
| `synonyms()` | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | `is_synonym` + `accepted_name` columns in the output |
| `tax_name()` | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | `family`, `genus`, `rank` columns |
| `itis_acceptname()` | `taxify(backend = "itis")` | `accepted_name` column |
| `sci2comm()` | [`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md) | Pipe enrichment; GBIF vernacular names by language |
| `get_nativecountry()` | [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md) | WCVP native range by TDWG region (plants) |
| `comm2sci()` | *no equivalent* | taxify matches scientific names, not common names |
| `downstream()` | *no equivalent* | Use rotl or rgbif for child taxa |
| phylogenetic tree functions | *no equivalent* | Use rotl for synthetic trees |
| occurrence data functions | *no equivalent* | Use rgbif or spocc |
| sequence retrieval | *no equivalent* | Use rentrez |

The key structural difference is that taxize returned results in varied
formats: `get_tsn()` returned a character vector with attributes,
`classification()` returned a nested list of data.frames, `synonyms()`
returned another nested list. taxify returns the same 16-column
data.frame from every call. Synonym status, taxonomic hierarchy, and
match quality are columns, not separate API calls.

## Function mapping: WorldFlora to taxify

| WorldFlora function | taxify equivalent | Notes |
|----|----|----|
| [`WFO.match()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html) | `taxify(backend = "wfo")` | Exact + fuzzy in one call |
| [`WFO.one()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html) | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | Best-match selection is automatic |
| [`WFO.match.fuzzyjoin()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match2.html) | `taxify(fuzzy = TRUE)` | Enabled by default; genus-blocked Damerau-Levenshtein |
| [`WFO.synonyms()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html) | [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) | `is_synonym`, `accepted_name`, `accepted_id` in output |

WorldFlora returns a wide data.frame with WFO-specific column names
(`scientificName`, `taxonID`, `taxonomicStatus`, `acceptedNameUsageID`,
plus the full authorship and bibliographic fields). taxify normalizes
these into a backend-agnostic schema: `matched_name`, `taxon_id`,
`accepted_name`, `accepted_id`, and so on. The WFO-specific columns are
still accessible via
[`add_wfo_info()`](https://gillescolling.com/taxify/reference/add_wfo_info.md)
when needed, but the default output is the same 16 columns whether the
backend is WFO, COL, or GBIF.

WorldFlora also requires the user to download `classification.txt`
manually and pass the file path or a pre-loaded data.frame to every
call. taxify handles backbone management automatically: the first
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
downloads and converts the backbone, subsequent calls reuse the local
copy, and a once-per-session version check keeps it current.

## Example 1: Basic name resolution (taxize vs. taxify)

A typical taxize workflow resolved names through `gnr_resolve()`, then
pulled classification and synonyms with separate calls. Each step hit a
different API.

``` r

# --- taxize (no longer on CRAN) ---
library(taxize)

names <- c("Quercus robur", "Pinus sylvestris", "Betula pendula",
           "Panthera leo", "Salmo trutta")

# Step 1: resolve names via Global Names Resolver
resolved <- gnr_resolve(names, best_match_only = TRUE)

# Step 2: get GBIF IDs (separate API call)
gbif_ids <- get_gbifid(names)

# Step 3: get classification (yet another API call, per name)
class_list <- classification(gbif_ids, db = "gbif")

# Step 4: check synonyms (another round of API calls)
syn_list <- synonyms(gbif_ids, db = "gbif")
```

Each of those four steps makes network requests. If the GBIF API is slow
or rate-limiting, the whole pipeline stalls. The results come back in
different shapes: `resolved` is a data.frame, `gbif_ids` is a character
vector with class attributes, `class_list` is a list of data.frames (one
per name), and `syn_list` is another list of data.frames.

The taxify equivalent is one function call. Name resolution, synonym
resolution, and classification are handled together.

``` r

# --- taxify ---
library(taxify)

names <- c("Quercus robur", "Pinus sylvestris", "Betula pendula",
           "Panthera leo", "Salmo trutta")

# One call: resolve, classify, and check synonyms
result <- taxify(names, backend = "gbif")

# Everything is in the result data.frame:
result$accepted_name
result$family
result$genus
result$is_synonym
result$taxon_id        # GBIF usage key
```

The output is a data.frame with 16 columns and one row per input name.
No nested lists, no per-name API calls, no internet connection required
after the first run.

## Example 2: WFO matching with fuzzy + synonyms (WorldFlora vs. taxify)

WorldFlora’s standard workflow loads the classification file, runs exact
matching, then applies fuzzy matching to unresolved names in a second
pass.

``` r

# --- WorldFlora ---
library(WorldFlora)

# User must download classification.txt manually (~400 MB)
wfo_data <- read.delim("classification.txt")

# Exact match first
names <- c("Quercus robur", "Quercus pedonculata",
           "Pinus silvestris", "Rosa canina")
exact <- WFO.match(names, WFO.data = wfo_data)

# Fuzzy match for unmatched (separate call, requires fuzzyjoin)
fuzzy <- WFO.match.fuzzyjoin(names, WFO.data = wfo_data)

# Pick best match per name
best <- WFO.one(fuzzy)

# Check synonym resolution
best$taxonomicStatus
best$acceptedNameUsageID
```

The output is a wide data.frame with all WFO columns
(`scientificNameAuthorship`, `namePublishedIn`, `references`,
`acceptedNameUsageID`, and more). The user has to look at
`taxonomicStatus` to tell accepted names from synonyms, and
cross-reference `acceptedNameUsageID` against `taxonID` to find the
accepted name string.

taxify folds exact matching, fuzzy matching, and synonym resolution into
a single call. Fuzzy matching is on by default and uses
Damerau-Levenshtein distance with genus blocking, which is faster and
more accurate than a full-table string distance computation.

``` r

# --- taxify ---
library(taxify)

# No manual download needed (automatic on first use)
names <- c("Quercus robur", "Quercus pedonculata",
           "Pinus silvestris", "Rosa canina")

result <- taxify(names, backend = "wfo")

# Misspellings are caught by fuzzy matching:
result[, c("input_name", "matched_name", "match_type", "fuzzy_dist")]
#   input_name           matched_name        match_type fuzzy_dist
# 1 Quercus robur        Quercus robur       exact              NA
# 2 Quercus pedonculata  Quercus pedunculata fuzzy           0.053
# 3 Pinus silvestris     Pinus sylvestris    fuzzy           0.063
# 4 Rosa canina          Rosa canina         exact              NA

# Synonyms resolved automatically:
result[, c("input_name", "is_synonym", "accepted_name")]
```

`Quercus pedonculata` is both a misspelling and a synonym. taxify
handles both in one pass: the fuzzy matcher corrects the spelling to
`Quercus pedunculata`, and the synonym resolver maps it to
`Quercus robur` (the accepted name). WorldFlora requires the user to
chain
[`WFO.match.fuzzyjoin()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match2.html)
and then manually trace the `acceptedNameUsageID`.

## Example 3: Multi-backend fallback with enrichments

This workflow has no taxize or WorldFlora equivalent. taxize could query
multiple databases, but each was a separate API call returning a
different format. WorldFlora was WFO-only. taxify runs a fallback chain
where unmatched names cascade to the next backbone automatically.

``` r

# --- taxify only (no taxize/WorldFlora equivalent) ---
library(taxify)

# Mixed kingdom input: plants, animals, fungi
names <- c(
  "Quercus robur",         # plant (WFO primary)
  "Panthera leo",          # animal (not in WFO, picked up by GBIF)
  "Amanita muscaria",      # fungus (not in WFO, picked up by GBIF)
  "Salmo trutta",          # fish (not in WFO, picked up by GBIF)
  "Arabidopsis thaliana"   # plant (in both WFO and GBIF)
)

# WFO first (best for plants), GBIF as fallback (all kingdoms)
result <- taxify(names, backend = c("wfo", "gbif"))

# The backend column shows which database matched each name:
result[, c("input_name", "backend", "family")]
#   input_name            backend family
# 1 Quercus robur         wfo     Fagaceae
# 2 Panthera leo          gbif    Felidae
# 3 Amanita muscaria      gbif    Amanitaceae
# 4 Salmo trutta          gbif    Salmonidae
# 5 Arabidopsis thaliana  wfo     Brassicaceae

# Layer on enrichments via the pipe:
result |>
  add_conservation_status() |>
  add_common_names(lang = "en")

# Or join custom data:
my_traits <- data.frame(
  species = c("Quercus robur", "Panthera leo"),
  max_height_m = c(35, NA),
  body_mass_kg = c(NA, 190)
)
result |> add_data(my_traits, species_col = "species")
```

The fallback chain resolves plants through WFO (where nomenclatural
coverage for vascular plants is strongest) and passes animals, fungi,
and anything else WFO does not cover to GBIF. The user sees one
data.frame. The `backend` column records provenance.

Enrichments attach additional data columns through the pipe. Each
`add_*()` function downloads its dataset on first use (the same
download-once pattern as backbones) and joins on `accepted_name`.
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
handles arbitrary external datasets: pass a CSV path, an XLSX file, a
SQLite database, or a plain data.frame, and taxify matches the species
names through the same backbone(s) before joining.

## Key differences at a glance

**Online vs. offline.** taxize sent HTTP requests for every name. taxify
downloads backbone files once and matches locally. After the initial
download (typically 50–300 MB depending on the backbone), no internet
connection is needed. Queries against the local backbone run in
milliseconds per name.

**Single database vs. multi-backend.** taxize could query multiple
databases, but each was a separate function call with a different return
type. WorldFlora supported only WFO. taxify supports nine backbones
through a single function, with optional fallback chains that cascade
unmatched names automatically.

**Output format.** taxize returned different types depending on the
function: character vectors (`get_tsn()`), lists of data.frames
(`classification()`), nested lists (`synonyms()`). WorldFlora returned
wide data.frames with all WFO columns. taxify always returns a
data.frame with 16 standardized columns, regardless of the backend. The
columns are:

| Column | Type | Content |
|----|----|----|
| `input_name` | character | Original name as submitted |
| `matched_name` | character | Closest match in the backbone |
| `accepted_name` | character | Accepted name after synonym resolution |
| `taxon_id` | character | Backend-specific ID of the matched name |
| `accepted_id` | character | ID of the accepted name |
| `rank` | character | Taxonomic rank (species, genus, family, etc.) |
| `family` | character | Family name |
| `genus` | character | Genus name |
| `epithet` | character | Specific epithet |
| `authorship` | character | Taxonomic authority |
| `is_synonym` | logical | Was the matched name a synonym? |
| `is_hybrid` | logical | Hybrid marker detected in the input? |
| `match_type` | character | `"exact"`, `"exact_ci"`, `"fuzzy"`, or `"none"` |
| `fuzzy_dist` | numeric | Normalized edit distance (NA if exact) |
| `backend` | character | Which backend matched this name |
| `backbone_version` | character | Backend name, version, and download date |

**Speed.** taxize was limited by network latency and API rate limits.
WorldFlora’s
[`WFO.match()`](https://rdrr.io/pkg/WorldFlora/man/WFO.match.html)
processes names sequentially against a loaded data.frame. taxify uses
vectra’s C-level join engine with hash indexes and genus-blocked fuzzy
joins, processing thousands of names per second on a single core. Fuzzy
matching runs in parallel across four threads by default.

**Reproducibility.** taxize results changed whenever an upstream
database updated. taxify pins backbone versions locally and records the
version string in the `backbone_version` column of every result. The
same backbone file produces the same output indefinitely. Version
pinning is also available:
`taxify_download_vtr("wfo", version = "2024.06")` downloads a specific
release that will never be overwritten.

## What taxify does not do

taxify is a name matcher. It resolves scientific names to accepted
names, returns classification metadata, and joins enrichment layers.
Several things that taxize or other packages handle are outside its
scope.

**Common-to-scientific name lookup.** taxize had `comm2sci()` to go from
“European robin” to *Erithacus rubecula*. taxify works in the opposite
direction: it matches scientific names and can attach common names via
[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md),
but it cannot start from a vernacular name.

**Downstream taxa.** taxize’s `downstream()` returned all children of a
higher taxon (e.g., all species in a genus). taxify does not enumerate
children. For tree-based queries, the rotl package provides access to
the Open Tree of Life synthetic tree, and rgbif’s `name_usage()` can
list children of a GBIF usage key.

**Phylogenetic trees.** taxize had convenience wrappers for tree
retrieval. For phylogenetic data, use rotl (Open Tree of Life) or
phylomatic.

**Occurrence data.** taxize could fetch occurrence records from GBIF.
For occurrence data, rgbif and spocc are the standard tools.

**Sequence data.** taxize integrated with NCBI for sequence retrieval.
The rentrez package handles GenBank/NCBI queries directly.

**Real-time API lookups.** By design, taxify queries local files. If a
name was added to a backbone yesterday and taxify’s local copy is from
last month, taxify will not find it until the backbone is updated. For
research workflows where last-week freshness matters more than
reproducibility, a direct API client (rgbif, worrms, ritis) may be the
better fit.

## When not to switch

taxify is not a universal replacement for every taxize use case. A few
situations where the old tools or their successors may be more
appropriate:

- **Common-to-scientific lookups** (`comm2sci()`). If the starting point
  is vernacular names, taxify cannot help. The GBIF API
  ([`rgbif::name_suggest()`](https://docs.ropensci.org/rgbif/reference/name_suggest.html))
  accepts common names and returns scientific name candidates.

- **Downstream taxa enumeration.** If the goal is to list all species in
  a family or all subspecies of a species, taxify does not provide that
  query. Use `rgbif::name_usage(key, data = "children")` or
  `rotl::tol_subtree()`.

- **Interactive, per-name resolution with manual disambiguation.**
  taxize had interactive modes where the user could pick among multiple
  candidates. taxify picks the best match automatically (accepted name
  over synonym, species rank over higher ranks, lowest ID as
  tiebreaker). If manual control over ambiguous matches is needed, the
  taxize fork maintained on GitHub or direct API calls may be
  preferable.

- **Data freshness over reproducibility.** taxify’s strength is
  reproducible, versioned, offline matching. If the priority is to
  always use the very latest backbone update (published hours ago),
  querying the API directly via rgbif, worrms, or ritis avoids the delay
  between upstream publication and taxify’s next backbone release.

For most biodiversity data analysis workflows, taxify covers the core
need: take a list of names, resolve them to accepted names against an
authoritative backbone, and move on to the analysis. The migration is
straightforward, and the output format is designed to fit directly into
downstream data pipelines without reshaping.

## Discovering available enrichments

taxify bundles 12 enrichment datasets that cover conservation status,
invasive species, functional traits, morphological measurements, and
vernacular names. These are joined to the taxify result by piping
through `add_*()` functions.

``` r

# See all available enrichments and their metadata
list_enrichments()
```

Each enrichment downloads automatically on first use and is cached
locally, following the same pattern as backbones. The full list:
[`add_conservation_status()`](https://gillescolling.com/taxify/reference/add_conservation_status.md),
[`add_invasive_status()`](https://gillescolling.com/taxify/reference/add_invasive_status.md),
[`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md),
[`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md),
[`add_elton_traits()`](https://gillescolling.com/taxify/reference/add_elton_traits.md),
[`add_avonet()`](https://gillescolling.com/taxify/reference/add_avonet.md),
[`add_pantheria()`](https://gillescolling.com/taxify/reference/add_pantheria.md),
[`add_amphibio()`](https://gillescolling.com/taxify/reference/add_amphibio.md),
[`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md),
[`add_woodiness()`](https://gillescolling.com/taxify/reference/add_woodiness.md),
[`add_diaz_traits()`](https://gillescolling.com/taxify/reference/add_diaz_traits.md),
and
[`add_leda()`](https://gillescolling.com/taxify/reference/add_leda.md).

## Summary

The migration path from taxize or WorldFlora to taxify is a structural
simplification. Multiple API calls or manual file management collapse
into [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
plus optional `add_*()` pipes. The output is a flat data.frame, not
nested lists. Matching runs offline against versioned backbone files, so
results do not change between sessions unless the user explicitly
updates the backbone.

For functions that taxify does not replace (downstream taxa, occurrence
data, phylogenetic trees, sequence retrieval), the specialized packages
(rotl, rgbif, spocc, rentrez) remain the right tools. taxify handles the
name-matching step that comes before all of those.
