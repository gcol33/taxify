# Getting started with taxify

## What taxify solves

Almost every biodiversity dataset starts as a column of names. Before
any analysis, those strings have to resolve to one accepted name per
taxon, and they rarely line up on their own: authorship, field
qualifiers, capitalization, historical synonyms, hybrids, and plain
typos all keep two records of the same species apart. A bare
[`merge()`](https://rdrr.io/r/base/merge.html) on raw strings silently
drops every row that disagrees, so the matching has to come first.

[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) takes
a character vector and returns one standardized table: each name
cleaned, matched against a backbone you keep on disk, synonyms resolved
to the accepted name. Matching runs in C through the
[vectra](https://github.com/gcol33/vectra) engine, so there are no web
services and no rate limits, and the same input gives the same output on
any machine. Nine Darwin Core backbones are available (WFO, COL, GBIF,
ITIS, NCBI, OTT, WoRMS, Species Fungorum, AlgaeBase), all queried
offline.

``` r

library(taxify)
```

The first
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
downloads a backbone once (WFO is about 150 MB) and caches it under
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md).
After that, nothing touches the network.

## One call

Hand [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
a vector of names. The list below is deliberately small and deliberately
messy: every entry takes a different route to its accepted name.

``` r

field_names <- c(
  "Quercus robur L.",        # authorship to strip
  "Quercus robus",           # typo
  "cf. Betula pendula",      # field qualifier
  "FAGUS SYLVATICA",         # caps
  "Quercus pedunculata",     # historical synonym of Q. robur
  "Q. petraea",              # abbreviated genus
  "Pinus abies",             # synonym of Picea abies (a different genus)
  "Festuca rubrra",          # typo
  "Fallopia japonica",       # synonym of Reynoutria japonica (invasive)
  "Taraxacum officinale"
)

res <- taxify(field_names)
res[, c("input_name", "accepted_name", "family",
        "is_synonym", "match_type", "fuzzy_dist")]
```

    #>             input_name        accepted_name       family is_synonym match_type fuzzy_dist
    #> 1     Quercus robur L.        Quercus robur     Fagaceae      FALSE      exact         NA
    #> 2        Quercus robus        Quercus robur     Fagaceae      FALSE      fuzzy      0.077
    #> 3   cf. Betula pendula       Betula pendula   Betulaceae      FALSE      exact         NA
    #> 4      FAGUS SYLVATICA      Fagus sylvatica     Fagaceae      FALSE   exact_ci         NA
    #> 5  Quercus pedunculata        Quercus robur     Fagaceae       TRUE      exact         NA
    #> 6           Q. petraea      Quercus petraea     Fagaceae      FALSE     abbrev         NA
    #> 7          Pinus abies          Picea abies     Pinaceae       TRUE      exact         NA
    #> 8       Festuca rubrra        Festuca rubra      Poaceae      FALSE      fuzzy      0.071
    #> 9    Fallopia japonica  Reynoutria japonica Polygonaceae       TRUE      exact         NA
    #> 10 Taraxacum officinale Taraxacum officinale  Asteraceae      FALSE      exact         NA

Ten names, ten rows, every match readable. Each row also carries genus,
authorship, taxon and accepted IDs, a hybrid flag, the backend, and the
exact backbone version (the full table is wider, the same shape for any
input).

Each name reaches its accepted name a different way. The animation below
walks one name at a time through the pipeline: the clean step strips
authorship, a qualifier, or case; the match step is exact, case-folded,
fuzzy, or abbreviated; the resolve step follows a synonym to the current
name.

`Quercus robur L.` loses its authorship before matching.
`cf. Betula pendula` loses the qualifier. `FAGUS SYLVATICA` matches
after case folding (`exact_ci`). `Q. petraea` resolves on the genus
initial plus epithet (`abbrev`). The three synonyms
(`Quercus pedunculata`, `Pinus abies`, `Fallopia japonica`) resolve to
their accepted names, the last being the current name for a well-known
invader. The two typos go to the fuzzy pass, which is the next thing
worth seeing.

## Why a typo barely costs anything

The fuzzy pass never scores a name against the whole backbone. It blocks
on genus first, so `Quercus robus` is compared only against the other
*Quercus* names. A one-letter slip is found in a handful of comparisons
rather than across every name on disk.

The default threshold allows about one edit per five characters, so
common typos resolve while genuinely different names do not. Fuzzy
matching is controlled by `fuzzy`, `fuzzy_threshold`, and
`fuzzy_method`; the [fuzzy-matching
vignette](https://gillescolling.com/taxify/articles/fuzzy-matching.html)
covers the sub-blocking for very large genera and the genus-typo
fallback in full.

## Check the batch at a glance

[`summary()`](https://rdrr.io/r/base/summary.html) prints a digest, the
fastest way to see whether a run went cleanly.

``` r

summary(res)
```

    #> ── taxify results ──────────────────────────────────────────────────────────
    #>   backend: WFO v2024-12  |  10 names submitted
    #>
    #>   matched        10  (exact: 6, case-insensitive: 1, fuzzy: 2, abbrev: 1)
    #>   ────────────────────────────────────────────────────────────
    #>   taxon groups: angiosperm: 8  gymnosperm: 1  unknown: 1

The digest reports the backend and version, the match-route breakdown
(all ten resolved here, including the abbreviated `Q. petraea`), and the
taxon-group mix. When a name is out of scope (an animal in a plant-only
backbone) or genuinely absent, the digest tallies it and suggests an
alternative backend. The match types and the multi-backend fallback
(`backend = c("wfo", "col", "gbif")`) are covered in the [backends
vignette](https://gillescolling.com/taxify/articles/backends.html).

## Offline, and how much faster

Every match runs against the local snapshot, so a run reproduces exactly
and the `backbone_version` column records the WFO release and download
date for a methods section. On the same task many in this field reach
for, WorldFlora’s `WFO.match`, both run against a local copy and return
the same matches; the difference is where the matching happens. taxify
scores names in C against the compiled backbone, WorldFlora in R. On
1,000 plant names with fuzzy matching on (Windows, R 4.5.2):

Exact matching is close (0.1 s against 1.3 s); the gap opens on fuzzy
matching, where the genus blocking keeps taxify near a second while the
in-R scan grows with the list. The full benchmark and large-batch
strategy are in the [large-scale
vignette](https://gillescolling.com/taxify/articles/large-scale.html).

## Add your own attributes

Once names resolve to an accepted name, any table keyed on species joins
cleanly.
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
takes a data.frame, CSV, XLSX, or SQLite file, runs its species column
through the same backbone, and joins on the accepted name, so a synonym
on either side still lines up.

``` r

my_traits <- data.frame(
  species      = c("Quercus pedunculata",   # synonym of Q. robur
                   "Pinus sylvestris",
                   "Betula pendula"),
  seed_mass_mg = c(3200, 7.5, 0.2)
)

taxify(c("Quercus robur", "Pinus sylvestris", "Betula pendula")) |>
  add_data(my_traits, species_col = "species")
```

    #> add_data: 3 of 3 species matched (100.0%). 0 names in data unmatched.
    #>         input_name    accepted_name seed_mass_mg
    #> 1    Quercus robur    Quercus robur       3200.0
    #> 2 Pinus sylvestris Pinus sylvestris          7.5
    #> 3   Betula pendula   Betula pendula          0.2

The trait table used *Quercus pedunculata* and the result used *Quercus
robur*; a plain [`merge()`](https://rdrr.io/r/base/merge.html) would
have missed that row.
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
joins on the accepted name, so it lines up. Formats, auto-detection, and
strict duplicate handling are in the [custom-data
vignette](https://gillescolling.com/taxify/articles/custom-data.html).

## The enrichment layers

taxify also ships published trait and status layers that attach on the
accepted name. There are over two dozen, across the tree of life and for
the conservation and invasion records this kind of work needs. Each
`add_*()` matches its own source against the backbone and attaches on
the accepted name, so any of them stacks into a pipeline the same way.
Run
[`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md)
for the current set, versions, and coverage.

For invasion work the GloNAF, GRIIS, and alien-first-record layers
attach naturalized status, invasive status, and first-record years on
the same accepted name, so a resolved species list carries its invasion
history without a second join. The full menu and per-layer detail are in
the [enrichments
vignette](https://gillescolling.com/taxify/articles/enrichments.html).

## Stack layers, then test an idea

Field lists run to hundreds of names. Here is a realistic one, about a
hundred European species, matched in one call. Pick any layers and stack
them: woodiness, the EIVE ecological indicator values, and plant height
from the Diaz global trait dataset all attach on the accepted name.

``` r

field <- c(
  "Quercus petraea", "Pinus sylvestris", "Picea abies", "Betula pendula",
  "Acer pseudoplatanus", "Acer platanoides", "Acer campestre", "Corylus avellana",
  "Fraxinus excelsior", "Carpinus betulus", "Sorbus aucuparia", "Tilia cordata",
  "Ulmus glabra", "Alnus glutinosa", "Salix caprea", "Populus tremula",
  "Prunus avium", "Prunus spinosa", "Crataegus monogyna", "Sambucus nigra",
  "Cornus sanguinea", "Viburnum opulus", "Euonymus europaeus", "Ligustrum vulgare",
  "Frangula alnus", "Juniperus communis", "Taxus baccata", "Larix decidua",
  "Abies alba", "Rosa canina", "Rubus idaeus", "Hedera helix",
  "Clematis vitalba", "Berberis vulgaris", "Betula pubescens", "Prunus padus",
  "Rhamnus cathartica", "Lonicera xylosteum", "Trifolium repens", "Trifolium pratense",
  "Festuca ovina", "Dactylis glomerata", "Plantago lanceolata", "Plantago major",
  "Plantago media", "Achillea millefolium", "Ranunculus acris", "Ranunculus repens",
  "Urtica dioica", "Poa pratensis", "Poa annua", "Galium mollugo",
  "Galium aparine", "Bellis perennis", "Cardamine pratensis", "Cirsium arvense",
  "Cirsium vulgare", "Daucus carota", "Heracleum sphondylium", "Anthriscus sylvestris",
  "Lotus corniculatus", "Medicago lupulina", "Vicia cracca", "Lathyrus pratensis",
  "Stellaria media", "Silene dioica", "Silene vulgaris", "Geranium pratense",
  "Geranium robertianum", "Glechoma hederacea", "Lamium album", "Prunella vulgaris",
  "Ajuga reptans", "Veronica chamaedrys", "Rumex acetosa", "Rumex obtusifolius",
  "Chenopodium album", "Capsella bursa-pastoris", "Senecio vulgaris", "Leucanthemum vulgare",
  "Centaurea jacea", "Knautia arvensis", "Campanula rotundifolia", "Primula veris",
  "Anemone nemorosa", "Filipendula ulmaria", "Lythrum salicaria", "Robinia pseudoacacia",
  "Solidago canadensis", "Solidago gigantea", "Impatiens glandulifera",
  "Heracleum mantegazzianum", "Prunus serotina", "Quercus rubra",
  "Quercus robur L.", "FAGUS SYLVATICA", "Quercus robus",
  "cf. Taraxacum officinale", "Quercus pedunculata", "Festuca rubrra"
)

dat <- taxify(field) |>
  add_woodiness() |>
  add_eive() |>
  add_diaz_traits()

head(dat[, c("accepted_name", "woodiness", "eive_light",
             "eive_reaction", "eive_nutrients", "plant_height_m")], 6)
```

    #>         accepted_name woodiness eive_light eive_reaction eive_nutrients plant_height_m
    #> 1     Quercus petraea     woody       5.83          4.79           3.55          31.44
    #> 2    Pinus sylvestris     woody       7.10          5.13           2.69          19.03
    #> 3         Picea abies     woody       4.36          4.24           4.31          40.69
    #> 4      Betula pendula     woody       6.84          4.38           3.64          12.02
    #> 5 Acer pseudoplatanus     woody       3.80          5.92           6.89          24.46
    #> 6    Acer platanoides     woody       3.87          6.34           5.66          21.93

A few species lack an EIVE or a height value, so those cells are `NA`;
R’s statistics functions drop incomplete rows on their own. From here it
is ordinary analysis. Do species on more base-rich soils also sit higher
on the nutrient axis?

``` r

cor.test(dat$eive_reaction, dat$eive_nutrients)
```

    #>  Pearson's product-moment correlation
    #>
    #> data:  dat$eive_reaction and dat$eive_nutrients
    #> t = 3.2378, df = 96, p-value = 0.001654
    #> alternative hypothesis: true correlation is not equal to 0
    #> 95 percent confidence interval:
    #>  0.1230070 0.4821711
    #> sample estimates:
    #>       cor
    #> 0.3137695

Across about a hundred species the correlation is positive and
significant, though modest (r = 0.31, p = 0.002): base-rich soils tend
to carry higher nutrient values. The same three lines work for any
attribute the package can attach.

## Where to go next

This vignette is the fast path. Each step has a dedicated vignette with
the full detail:

- [Backends and multi-backend
  fallback](https://gillescolling.com/taxify/articles/backends.html)

- [Fuzzy
  matching](https://gillescolling.com/taxify/articles/fuzzy-matching.html)

- [Enrichments](https://gillescolling.com/taxify/articles/enrichments.html)

- [Custom
  data](https://gillescolling.com/taxify/articles/custom-data.html)

- [Hybrid
  names](https://gillescolling.com/taxify/articles/hybrid-names.html)

- [Large-scale
  matching](https://gillescolling.com/taxify/articles/large-scale.html)

- [Migrating from taxize and
  WorldFlora](https://gillescolling.com/taxify/articles/migration.html)
  \`\`\`
