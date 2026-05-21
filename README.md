# taxify

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Offline Taxonomic Name Matching Against Local Darwin Core Snapshots**

Match taxonomic names against locally stored backbone databases, resolve synonyms, and enrich results with trait and status data from published datasets. No API calls, no internet dependency, no rate limits.

## Quick Start

```r
install.packages("pak")
pak::pak("gcol33/taxify")

library(taxify)

# Match names against WFO (downloads backbone on first use, ~120 MB)
result <- taxify(c(
  "Quercus robur",
  "Pinus abies",            # synonym → resolved to Picea abies
  "Quercus robus",          # typo → fuzzy-corrected to Q. robur
  "Taraxacum officinale"
))

# Enrich with conservation status and plant traits
result |>
  add_conservation_status() |>
  add_woodiness() |>
  add_eive()

# Join your own data (auto-detects the species column)
result |> add_data("my_traits.csv")
```

## What taxify does

taxify resolves taxonomic names offline against ten backbone databases covering all kingdoms of life, then optionally enriches the results with trait and status data from over twenty published datasets. The matching engine is written in C (via the [vectra](https://github.com/gcol33/vectra) columnar engine), so large species lists resolve in seconds.

The core workflow is: clean input names, match against a backbone, resolve synonyms to accepted names, and return a standardized 16-column data.frame. Every step runs locally against versioned backbone snapshots, so results are fully reproducible.

### Related packages

The R ecosystem has a rich set of taxonomic tools, each with its own focus. The summary below describes what each one does so you can pick the right tool for your workflow.

| Package | Source data | Coverage | Access |
|---|---|---|---|
| [taxize](https://docs.ropensci.org/taxize/) | ~20 web services (NCBI, ITIS, GBIF, EOL, IUCN, WoRMS, Tropicos, ...) | All kingdoms | Live API |
| [WorldFlora](https://cran.r-project.org/package=WorldFlora) | World Flora Online classification (`WFO.match`) | Land plants (vascular + bryophytes) | Local file |
| [lcvplants](https://cran.r-project.org/package=lcvplants) | Leipzig Catalogue of Vascular Plants | Vascular plants | Bundled in package |
| [rWCVP](https://matildabrown.github.io/rWCVP/) | World Checklist of Vascular Plants (Kew) | Vascular plants | Local snapshot |
| [taxadb](https://docs.ropensci.org/taxadb/) | GBIF, ITIS, COL, NCBI, OTT, WFO snapshots | All kingdoms | Local DuckDB / MonetDB |
| [Taxonstand](https://cran.r-project.org/package=Taxonstand) | The Plant List (legacy, retired by Kew in 2013) | Vascular plants | Bundled in package |
| [U.Taxonstand](https://github.com/ecoinfor/U.Taxonstand) | User-supplied or bundled checklists | Configurable | Local |
| [bdc](https://brunobrr.github.io/bdc/) | taxadb + GNR for the taxonomic step inside a wider data-cleaning workflow | All kingdoms | Local + API |
| [TNRS](https://cran.r-project.org/package=TNRS) | TNRS web service (BIEN / iDigBio) | Plants | Live API |
| [rgbif](https://docs.ropensci.org/rgbif/) | GBIF backbone | All kingdoms | Live API |
| [worrms](https://docs.ropensci.org/worrms/) | WoRMS | Marine taxa | Live API |
| [ritis](https://docs.ropensci.org/ritis/) | ITIS | Mostly North American taxa | Live API |

taxify ships ten backbones (WFO, COL, GBIF, ITIS, NCBI, OTT, WoRMS, Euro+Med, Species Fungorum, AlgaeBase) as pre-built local snapshots, runs exact, case-insensitive, and genus-blocked fuzzy matching against any of them in C, resolves synonyms to accepted names in the same call, and arbitrates across backbones via a single fallback chain. The result pipes directly into the trait and status enrichments listed below. The closest functional analogue is [taxadb](https://docs.ropensci.org/taxadb/), which also stores backbone snapshots locally; the migration vignette walks through the differences in matching strategy, output schema, and enrichment integration.

### Speed

All matching in taxify is vectorized at the C level with genus-blocked joins. Before matching, input names are cleaned automatically:

```r
# What you provide:              What taxify matches against the backbone:
"Quercus robur L."            →  "Quercus robur"        # authorship stripped
"Pinus cf. sylvestris"        →  "Pinus sylvestris"      # qualifier removed
"Nothofagus × alpina"         →  "Nothofagus alpina"     # hybrid marker normalized
"Oenothera"                   →  "Oenothera"             # ae/oe alternation handled
"Betula pendula (Roth) Doll"  →  "Betula pendula"        # parenthesized author stripped
```

This means the fuzzy pass only runs on names that genuinely differ from the backbone, not on names that just carry extra authorship or qualifiers.

Benchmark on the same WFO backbone, same 5,000 plant names (Windows, R 4.5.2):

| | taxify | WorldFlora |
|---|---|---|
| Exact match (1,000 names) | 0.1 s | 1.3 s |
| Fuzzy match (1,000 names) | 1.0 s | 1,862 s (31 min) |
| Fuzzy match (5,000 names) | 1.1 s | ~83 min (extrapolated) |
| Backbone load | ~3 s (first call) | 33 s (CSV into RAM) |

taxify's throughput increases with batch size because the C engine amortizes setup costs across the full input vector.

## Output

`taxify()` returns a data.frame with one row per input name and 16 columns:

| Column | Description |
|--------|-------------|
| `input_name` | Original name as provided |
| `matched_name` | Name in the backbone that matched |
| `accepted_name` | Accepted name after synonym resolution |
| `taxon_id` | Backend-specific ID of the matched name |
| `accepted_id` | ID of the accepted name |
| `rank` | Taxonomic rank (species, subspecies, genus, ...) |
| `family` | Family |
| `genus` | Genus |
| `epithet` | Specific epithet |
| `authorship` | Authorship string |
| `is_synonym` | Was the match a synonym? |
| `is_hybrid` | Was a hybrid marker detected? |
| `match_type` | `exact`, `exact_ci`, `fuzzy`, or `none` |
| `fuzzy_dist` | Normalized string distance (0–1), NA if exact |
| `backend` | Which backbone was used |
| `backbone_version` | Backend, version, and download date |

`summary()` prints a compact digest:

```r
summary(result)
#> ── taxify results ────────────────────────────────────────────────────
#>   backend: WFO  |  4 names submitted
#>
#>   matched         4  (exact: 2, case-insensitive: 0, fuzzy: 2)
#>   unmatched       0
#>   ────────────────────────────────────────────────────────────────────
#>   taxon groups: plant: 4
```

## Features

### Matching

- Exact match (case-insensitive)
- Fuzzy match with configurable algorithm (Damerau-Levenshtein, Levenshtein, Jaro-Winkler) and threshold
- Automatic name cleaning before matching (authorship, qualifiers, hybrid markers, orthography)
- Synonym resolution to accepted names
- Best-match selection (ACCEPTED > SYNONYM, SPECIES > higher ranks)
- Multi-backend fallback chains: `taxify(names, backend = c("wfo", "col", "gbif"))`

### Backends

Ten backbone databases, downloaded once and stored locally as compressed `.vtr` files:

| Backend | Scope | Approx. names |
|---------|-------|---------------|
| [WFO](https://www.worldfloraonline.org/) | Vascular plants | ~400k |
| [COL](https://www.catalogueoflife.org/) | All kingdoms | ~4.5M |
| [GBIF](https://www.gbif.org/) | All kingdoms | ~10M |
| [ITIS](https://www.itis.gov/) | US focus, freshwater/marine | ~900k |
| [NCBI Taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy) | All life | ~2.5M |
| [Open Tree of Life](https://opentreeoflife.github.io/) | All life (synthetic) | ~4M |
| [WoRMS](https://www.marinespecies.org/) | Marine/aquatic | ~600k |
| [Euro+Med](https://europlusmed.org/) | European/Mediterranean plants | ~132k |
| [Species Fungorum](https://www.speciesfungorum.org/) | Fungi | ~329k |
| [AlgaeBase](https://www.algaebase.org/) | Algae | ~172k |

### Enrichments

Twenty-two enrichment layers join published trait and status data to your results via backbone-resolved accepted names:

```r
# Plants
taxify(plant_names) |>
  add_conservation_status() |>   # IUCN Red List
  add_invasive_status("AT") |>   # GRIIS invasive status
  add_woodiness() |>             # Zanne et al.
  add_eive()                     # EIVE indicator values

# Fish
taxify(fish_names, backend = "col") |>
  add_fishbase() |>              # FishBase morphology & ecology
  add_fish_traits()              # FISHMORPH functional traits
```

| Enrichment | Source | Reference | Taxa |
|------------|--------|-----------|------|
| `add_conservation_status()` | [IUCN Red List](https://www.iucnredlist.org/) | IUCN (2024) | All |
| `add_invasive_status()` | [GRIIS](https://griis.org/) | Pagad et al. (2018) | All |
| `add_alien_first_records()` | [Seebens et al.](https://doi.org/10.6084/m9.figshare.c.3924424.v3) | Seebens et al. (2017) | All |
| `add_common_names()` | [GBIF](https://www.gbif.org/) | GBIF (2024) | All |
| `add_wcvp()` | [WCVP](https://powo.science.kew.org/) | Govaerts et al. (2021) | Plants |
| `add_woodiness()` | [Zanne et al.](https://datadryad.org/stash/dataset/doi:10.5061/dryad.63q27) | Zanne et al. (2014) | Plants |
| `add_eive()` | [EIVE 1.0](https://doi.org/10.5281/zenodo.7534792) | Dengler et al. (2023) | European plants |
| `add_diaz_traits()` | [Diaz et al.](https://doi.org/10.1038/s41586-022-05606-z) | Diaz et al. (2022) | Plants |
| `add_leda()` | [LEDA Traitbase](https://uol.de/en/landeco/research/leda) | Kleyer et al. (2008) | NW European plants |
| `add_fungal_traits()` | [FungalTraits](https://doi.org/10.1007/s13225-020-00466-2) | Polme et al. (2020) | Fungi |
| `add_funguild()` | [FUNGuild](https://github.com/UMNFuN/FUNGuild) | Nguyen et al. (2016) | Fungi |
| `add_algae_traits()` | [AlgaeTraits](https://doi.org/10.14284/574) | Vranken et al. (2023) | Macroalgae |
| `add_elton_traits()` | [EltonTraits 1.0](https://doi.org/10.6084/m9.figshare.c.3306933) | Wilman et al. (2014) | Birds, mammals |
| `add_avonet()` | [AVONET](https://doi.org/10.6084/m9.figshare.16586228) | Tobias et al. (2022) | Birds |
| `add_pantheria()` | [PanTHERIA](https://esapubs.org/archive/ecol/E090/184/) | Jones et al. (2009) | Mammals |
| `add_amphibio()` | [AmphiBIO](https://doi.org/10.6084/m9.figshare.4644424) | Oliveira et al. (2017) | Amphibians |
| `add_fish_traits()` | [FISHMORPH](https://doi.org/10.6084/m9.figshare.14891412) | Brosse et al. (2021) | Freshwater fish |
| `add_fishbase()` | [FishBase](https://www.fishbase.org/) | Froese & Pauly (2024) | All fish |
| `add_lizard_traits()` | [Meiri lizards](https://doi.org/10.6084/m9.figshare.5765553) | Meiri (2018) | Lizards |
| `add_anage()` | [AnAge](https://genomics.senescence.info/) | Tacutu et al. (2018) | Vertebrates |
| `add_glonaf()` | [GloNAF](https://glonaf.org/) | van Kleunen et al. (2019) | Plants (by region) |
| `add_leptraits()` | [LepTraits 1.0](https://doi.org/10.6084/m9.figshare.c.5899187) | Shirey et al. (2022) | Butterflies |
| `add_animaltraits()` | [AnimalTraits](https://animaltraits.org/) | Hebert et al. (2022) | Cross-taxon |
| `add_arthropod_traits()` | [NW Euro Arthropods](https://doi.org/10.3897/BDJ.13.e146785) | Logghe et al. (2025) | Arthropods (NW European) |

### Keeping enrichments up to date

Pre-built enrichment files are updated roughly every six months, but you can always rebuild from source to get the latest upstream data. The build pipeline handles all processing steps (cleaning, deduplication, country mapping, etc.):

```r
# Rebuild from the default upstream source
build_enrichment_from_source("conservation_status")

# Point at a newer release URL (same format, newer data)
build_enrichment_from_source(
  "alien_first_records",
  url = "https://figshare.com/ndownloader/articles/6192923/versions/4"
)
```

Alternatively, if you have your own version of a dataset (e.g., a newer IUCN export, a regional checklist), use `add_data()` to join it directly:

### Custom data

`add_data()` joins any external dataset to your taxify results. It auto-detects which column contains species names, matches them through the same backbone(s) used in your original `taxify()` call (so synonyms in either dataset resolve to the same key), and left-joins the result. Accepts data.frames, CSV, CSV.GZ, XLSX, SQLite, and .vtr files.

```r
# Just point it at a file — species column and backbone are detected automatically
result |> add_data("TRY_traits.csv")

# Pick specific columns
result |> add_data("TRY_traits.csv", cols = c("LeafArea", "SLA", "PlantHeight"))

# Grouped data (species x country) — pivots to wide format
result |> add_data(
  "my_first_records.csv",
  group_col = "country_code",
  groups = c("AT", "DE")
)
```

### Reshaping to long format

Group-based enrichments (invasive status, alien first records, native range, common names) produce wide output with one column per country/region. `taxify_long()` reshapes these to long format for modelling, mapping, or invasion timelines:

```r
taxify(species) |>
  add_alien_first_records(country = c("AT", "DE", "CH")) |>
  taxify_long()
```

Multiple enrichments with different country sets are combined automatically, with `NA` padding where a group is missing:

```r
taxify(species) |>
  add_invasive_status(country = c("AT", "DE")) |>
  add_alien_first_records(country = c("AT", "DE", "CH")) |>
  taxify_long()
# invasive_status is NA for CH rows
```

### Name Cleaning

Input names are automatically cleaned before matching:

- Authorship stripping (parenthesized and trailing)
- Qualifier detection and removal (cf., aff., s.l., s.str., agg.)
- Hybrid marker normalization (×, x, X)
- Latin orthographic normalization (ae/oe alternations)
- Bracket, number, and whitespace cleanup

### Genus Register

```r
lookup_genus("Quercus")
#>     genus   kingdom       family life_form
#> 1 Quercus Plantae   Fagaceae     plant

taxify_register_coverage("Quercus")
#>     genus backend version
#> 1 Quercus     wfo 2024.12
#> 2 Quercus     col 2024-12
#> 3 Quercus    gbif 2024-08
```

## Installation

```r
# Install from GitHub (vectra is installed automatically)
install.packages("pak")
pak::pak("gcol33/taxify")
```

## Usage

```r
library(taxify)

# Single backend (WFO for plants)
result <- taxify(c("Quercus robur", "Pinus sylvestris"))

# Multi-backend fallback (tries WFO first, then COL, then GBIF)
result <- taxify(
  c("Quercus robur", "Gadus morhua", "Agaricus bisporus"),
  backend = c("wfo", "col", "gbif")
)

# Disable fuzzy matching for clean lists
result <- taxify(names, fuzzy = FALSE)

# Tune fuzzy matching
result <- taxify(names, fuzzy_method = "jw", fuzzy_threshold = 0.15)

# Enrich with traits
result <- taxify(plant_names) |>
  add_conservation_status() |>
  add_woodiness() |>
  add_eive()

# Join external trait data (species column auto-detected, matched through same backbone)
result |> add_data("TRY_traits.csv")

# Check the result
summary(result)
```

## Citation and licensing

taxify itself is MIT-licensed. However, the backbone databases and enrichment datasets have their own licenses and citation requirements. When you publish results, please cite:

1. **The backbone(s) you used** — each backbone has its own citation. Run `taxify()` and check the `backbone_version` column for which version you matched against.
2. **The enrichment datasets you used** — the enrichment table above links to each source. Most are CC BY or CC BY-NC licensed and require citation of the original publication.
3. **taxify** (optional but appreciated).

The [enrichments vignette](https://gillescolling.com/taxify/articles/enrichments.html) lists full citations for each dataset.

## Documentation

- [Getting started](https://gillescolling.com/taxify/articles/quickstart.html)
- [Choosing and combining backends](https://gillescolling.com/taxify/articles/backends.html)
- [Fuzzy matching](https://gillescolling.com/taxify/articles/fuzzy-matching.html)
- [Enrichments](https://gillescolling.com/taxify/articles/enrichments.html)
- [Custom data](https://gillescolling.com/taxify/articles/custom-data.html)
- [Hybrid names](https://gillescolling.com/taxify/articles/hybrid-names.html)
- [Migrating from taxize, WorldFlora, and related tools](https://gillescolling.com/taxify/articles/migration.html)
- [Large-scale workflows](https://gillescolling.com/taxify/articles/large-scale.html)

## Support

> "Software is like sex: it's better when it's free." — Linus Torvalds

I'm a PhD student who builds R packages in my free time because I believe good tools should be free and open. I started these projects for my own work and figured others might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to say thanks. It helps with my coffee addiction.

[![Buy Me A Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## License

MIT (see the LICENSE.md file)
