# taxify — Plan

## Goal

Replace taxize with a CRAN-stable, offline-first, multi-backend
taxonomic matching package.

## Design Priorities (in order)

### 1. Output Schema — SETTLED

**Design: core + pipe extensions.**
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
returns a lean, universal schema. Extra detail via `add_*()` pipe
functions.

#### Core columns (returned by `taxify()`)

| Column | Type | Description | Availability |
|----|----|----|----|
| `input_name` | character | Exactly what the user gave us | always |
| `matched_name` | character | Full name in backbone that matched | all backends |
| `accepted_name` | character | Resolved accepted name (= matched_name if not synonym) | all backends |
| `taxon_id` | character | Backend-specific ID (WFO: taxonID, COL: ID, GBIF: id, ITIS: taxonID) | all backends |
| `accepted_id` | character | ID of accepted name | all backends |
| `rank` | character | species, subspecies, genus, variety, form | all backends |
| `family` | character | Family name | all backends (GBIF needs self-join to resolve FK) |
| `genus` | character | Genus | all backends (COL needs Name.tsv join) |
| `epithet` | character | Specific epithet | all backends (COL needs Name.tsv join) |
| `authorship` | character | Of matched name | all backends (COL needs Name.tsv join) |
| `is_synonym` | logical | Was the match a synonym? | all backends |
| `is_hybrid` | logical | Detected from input parsing or backbone flag/× in name | all backends |
| `match_type` | character | “exact”, “fuzzy”, “none” | always |
| `fuzzy_dist` | numeric | Normalized Levenshtein 0–1, NA if exact | always |
| `backend` | character | “wfo”, “col”, “gbif”, “itis” | always |

Notes: - `infrarank` (subsp./var./f.) not a separate column — it’s
encoded in `rank`. The rank column already says “subspecies”, “variety”,
etc. Infraspecific epithet is available via `add_*_info()` if needed. -
No `qualifier` column in core. Qualifiers (cf., aff., s.l., agg.) are
stripped during cleaning. TBD whether to expose them. - No `confidence`
column — `match_type` + `fuzzy_dist` is sufficient. - No diagnostics in
core (squished, brackets detected, etc.) — these are internal.

#### Extension: `add_hybrid_info()`

``` r

taxify(names, backends = "wfo") |>
  add_hybrid_info()
```

Adds columns by parsing hybrid notation from `input_name`:

| Column | Type | Description |
|----|----|----|
| `hybrid_parent_1` | character | First parent (full binomial), NA if not a hybrid formula |
| `hybrid_parent_2` | character | Second parent (full binomial), NA if not a hybrid formula |
| `hybrid_type` | character | “nothogenus”, “nothospecies”, “formula”, NA if not hybrid |

Parsing rules: - `"Quercus pyrenaica × Q. petraea"` → parent_1 =
“Quercus pyrenaica”, parent_2 = “Quercus petraea” (abbreviated genus
expanded) - `"× Festulolium"` → type = “nothogenus”, parents NA (no
formula) - `"Quercus × hispanica"` → type = “nothospecies”, parents NA
(named hybrid, parents not in name) - `"Salix x fragilis"` → type =
“nothospecies”, parents NA

`hybrid_type` from COL `notho` field or GBIF `notho_type` when
available, otherwise inferred from name parsing.

#### Extension: `add_wfo_info()`

``` r

taxify(names, backends = "wfo") |>
  add_wfo_info()
```

Joins extra WFO-specific columns via `taxon_id`: - `scientificNameID`,
`parentNameUsageID`, `namePublishedIn`, `higherClassification`,
`taxonRemarks` - `infraspecificEpithet` (the raw WFO field)

#### Extension: `add_col_info()`

``` r

taxify(names, backends = c("wfo", "col")) |>
  add_col_info()    # enriches only rows where backend == "col"
```

Joins extra COL-specific columns: - `extinct`, `lifezone`,
`temporalRangeStart`, `temporalRangeEnd` - `accordingTo`,
`nameAccordingToID`, `accordingToDate` - `notho` (COL’s 4-level hybrid
classification)

#### Extension: `add_gbif_info()`

Joins extra GBIF-specific columns: - `notho_type`,
`nomenclaturalStatus`, `canonicalName` - `bracket_authorship`, `year`

#### Extension: `add_itis_info()`

Joins extra ITIS-specific columns: - `superfamily`, `verbatimTaxonRank`,
`modified` - `higherClassification`

### 2. API Design

The fundamental interface question: one-at-a-time vs batch.

**WorldFlora approach:** - `WFO.one(name, WFO.data)` — single name,
returns full match details - `WFO.match(names, WFO.data)` — vectorized,
returns data.frame

**What taxify should do:**

``` r

# Option A: single function, vectorized
taxify(names, backends = "wfo", ...)

# Option B: explicit one vs many
taxify_one(name, backends = "wfo", ...)    # detailed single match
taxify(names, backends = "wfo", ...)        # batch, returns data.frame

# Option C: match then resolve as separate steps
matches <- taxify_match(names, backends = "wfo", ...)
resolved <- taxify_resolve(matches)
```

Things to decide: - Does
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
always return one row per input name? Or can it return multiple
candidates? - If multiple candidates, how does the user pick?
Interactive? Score-based? Top-1 with alternatives in a list column? -
Should fuzzy matching be opt-in (`fuzzy = TRUE`) or default? - How does
the user specify the fallback chain? `backends = c("wfo", "col")` tries
WFO first, then COL for unmatched?

### 3. Multi-Backend Architecture

Each backend = one module that implements the same interface. Adding a
new backend should be O(1) effort.

**Query engine: vectra** (dependency, `gcol33/vectra`)

All backbone querying goes through vectra’s columnar engine: -
`tbl_csv()` / `tbl()` to stream Darwin Core files larger than RAM -
Exact matching via `inner_join()` on canonical name (hash join,
streaming) - Fuzzy matching via `levenshtein()` / `levenshtein_norm()`
C-level expressions (implemented in vectra — stays in engine, no
collect-to-R roundtrip) - Candidate pre-filtering by genus before fuzzy
step (selection vectors, zero-copy) - Cleaning pipeline:
[`tolower()`](https://rdrr.io/r/base/chartr.html),
[`trimws()`](https://rdrr.io/r/base/trimws.html),
[`gsub()`](https://rdrr.io/r/base/grep.html) all in vectra’s C engine

This means: - No data.table dependency — vectra handles the heavy
lifting - No manual batch splitting — vectra streams row groups
automatically - Fuzzy matching on 40k names against a genus-filtered
backbone is fast because Levenshtein runs in C on a pre-filtered
candidate set

Backbone storage: `.vtr` (vectra native format) after first download.
First
[`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md)
fetches Darwin Core CSV, converts to `.vtr` for fast repeated queries.

Backends to support: - **WFO** — World Flora Online (plants, offline
Darwin Core snapshot from Zenodo) - **COL** — Catalogue of Life (all
kingdoms, annual checklist export) - **GBIF** — GBIF backbone taxonomy
(all kingdoms, downloadable — note: being deprecated in favor of COL)

Each backend needs: - `download()` — fetch Darwin Core archive and
convert to `.vtr` - [`load()`](https://rdrr.io/r/base/load.html) — open
via
[`vectra::tbl()`](https://gillescolling.com/vectra/reference/tbl.html)
(lazy, no RAM cost) - [`match()`](https://rdrr.io/r/base/match.html) —
exact join + fuzzy via vectra expressions - `resolve()` — synonym →
accepted name via join on `acceptedNameUsageID`

### 4. Hybrid Detection

This is a cross-cutting concern that touches parsing, matching, and
output.

**The `x` problem:** - `×` (Unicode multiplication sign) — unambiguous
hybrid marker - `x` (lowercase letter x) — ambiguous. Could be hybrid,
could be part of a name, could be a typo. - Need a strategy: trust `×`
always, trust `x` only in specific positions (between genus and epithet,
between two binomials), confirm against backbone?

**Hybrid types:** 1. **Named hybrids / nothogenera:** `× Festulolium` —
a named hybrid genus, treated as a single taxon in backbones 2.
**Nothospecies:** `Quercus × hispanica` — a named hybrid species 3.
**Hybrid formulas:** `Quercus pyrenaica × Q. petraea` — two parents, may
not exist as a named entity in any backbone 4. **Ambiguous:**
`Salix x fragilis` — is this a hybrid or bad formatting?

**Strategy options:** - A) Parse hybrid notation, set
`is_hybrid = TRUE`, try to match the full hybrid name in backbone. If it
exists, done. If not, split and match parents separately. - B) Always
try to match the name as-is first. Only parse as hybrid if the initial
match fails. - C) Parse hybrids upfront, match both the hybrid name and
the parents, return whichever gives the best match.

## Pain Points from ASAAS Pipeline (reference)

These are the specific problems the package must solve — drawn from
`/j/Phd Local/Gilles_paper2/Data/ASAAS/Data prep/05_Taxa_WFO/`:

1.  Hybrid `×` spacing breaks WFO.prepare() — needed gsub pre/post hacks
2.  Mojibake encoding (`á` instead of `subsp.`) — needed manual CSV
    chunking
3.  WFO.prepare() extracts bogus authorships — needed manual correction
    rounds
4.  WFO alone misses 5-10% — needed hand-wired GBIF fallback via
    taxize::name_suggest()
5.  WFO.match() chokes on 40k+ names — needed manual batch splitting
    into 7 chunks
6.  Different output formats between WFO and GBIF results — manual
    column harmonization

## Design Decisions (settled)

**Query engine:** vectra (C11 columnar engine, streaming) — no
data.table dependency

**String distance in vectra:** Levenshtein, Damerau-Levenshtein,
Jaro-Winkler — all implemented in C, column-vs-literal and
column-vs-column, with max_dist early termination

**Backbone storage:** Download Darwin Core CSV → convert to `.vtr` for
fast repeated queries

**Local files, no API deps:** All backends are offline Darwin Core
snapshots. No rgbif/ritis/taxizedb dependency.

**Output schema:** Core 15 columns (universal across backends) + pipe
extensions
([`add_hybrid_info()`](https://gillescolling.com/taxify/reference/add_hybrid_info.md),
[`add_wfo_info()`](https://gillescolling.com/taxify/reference/add_wfo_info.md),
[`add_col_info()`](https://gillescolling.com/taxify/reference/add_col_info.md),
[`add_gbif_info()`](https://gillescolling.com/taxify/reference/add_gbif_info.md),
`add_itis_info()`)

**Hybrid in core:** `is_hybrid` logical only. Parent parsing and hybrid
type via
[`add_hybrid_info()`](https://gillescolling.com/taxify/reference/add_hybrid_info.md).

## Open Questions

API: one function or split match/resolve?

One row per input always, or allow multiple candidates?

Default fuzzy on or off?

Which fuzzy algorithm as default? Levenshtein, Damerau-Levenshtein, or
Jaro-Winkler?

How to handle the ambiguous `x` — parser-level or backend-confirmed?

Scope: plants only (M1) then expand? Or design for all kingdoms from the
start?

S3 or R6 for backend interface?

`qualifier` column (cf., aff., s.l.) — expose in core, in an extension,
or just strip silently?
