# Story: taxify

## Claim
taxify matches taxonomic names against local copies of published backbones, resolves each to one accepted name, and joins trait and status data on that name, all without a web service.

## Audience
Ecologists, botanists, zoologists and data managers with a species list (a field survey, a trait table, an occurrence download, a checklist) that has to resolve to accepted names before analysis. Many have used taxize, WorldFlora, rWCVP or the GBIF species API; they know what a synonym and an accepted name are, and that names carry authorship and qualifiers. Prerequisites stop there: vectra, the `.vtr` format and how fuzzy matching is blocked are explained where a document uses them.

## Relation
- to: taxize (web-service name resolution) and WorldFlora (matching against a local World Flora Online file); also lcvplants, rWCVP, taxadb, Taxonstand, U.Taxonstand, TNRS, rgbif/worrms/ritis name lookups
- phrase: the name-resolution step of taxize and WorldFlora, run offline against local backbone files
- same: the input (a vector of names) and the answer (matched name, accepted name, IDs, status); with `backbone = "wfo"`, 277 of 300 sampled WFO names get the same accepted name as in WorldFlora (scripts/agreement-worldflora-results.json), though the two may read different WFO releases
- differs: local versioned files instead of web services (no rate limits, the version recorded per row); nineteen taxon backbones and two vegetation-unit backbones behind one call, chained as a fallback; one output schema whatever the backbone; trait and status joins on the accepted name; a different matching engine (C, genus-blocked fuzzy joins)
- status: taxify does not wrap or call any of these packages; a taxize user maps each call through the table in the comparison article. Which package to keep using is the reader's call; the comparison article says where the others are the better choice (live data on the day, a service taxify has no backbone for)
- home: vignettes/migration.Rmd ("Compatibility with taxize and WorldFlora")
- context: sidecars/context.md (standing, debt, discrepancies, evidence scope, framing)

## Arcs

### A1 One accepted name per input
- question: Will my messy list (authors, `cf.`, capitals, typos, old synonyms) come back as one accepted name per row?
- answer: Each name is cleaned, matched exactly, then fuzzily within its genus, and a synonym is followed to its accepted name; every row says how it matched (`match_type`, `fuzzy_dist`) and how many accepted names the spelling could denote (`n_ids`, `accepted_ids`).
- payoff: A reader can join on `accepted_name` and report how each name was resolved.
- evidence: vignettes/taxify.Rmd; vignettes/fuzzy-matching.Rmd; ?taxify (Value); tests/testthat/test-taxify.R
- limits: a fuzzy match is a guess within a threshold; a spelling shared by several taxa (a homonym) is resolved by the backbone's status and the author, and the alternatives stay listed; names no backbone holds come back `match_type = "none"`
- home: vignettes/fuzzy-matching.Rmd ("How names are matched")
- also: DESCRIPTION, README, ?taxify-package, Get started

### A2 Offline and reproducible
- question: Will the same list give the same answer next year, on another machine, and can I say which data produced it?
- answer: Backbones are versioned files downloaded once; every row records the backbone and its version, `taxify_lock()` writes the versions and content hashes to a file, `taxify_restore()` reinstalls the exact builds, and `cite()` prints the references of every source used.
- payoff: A methods section names the backbone versions, and a colleague reruns the analysis on the same data.
- evidence: ?taxify_lock; ?taxify_restore; ?cite; vignettes/backbones.Rmd (Versions and reproducibility)
- limits: the first download needs the network (about 1.1 GB for the default set); a backbone is as current as its release, not the source's live website
- home: vignettes/backbones.Rmd
- also: DESCRIPTION, README, Get started

### A3 The right backbone for the group
- question: Which backbone should I use for plants, fishes, fungi, a mixed list?
- answer: Nineteen taxon backbones (global aggregators and group authorities) and two vegetation-unit checklists share one output schema; naming several forms a fallback chain in which an earlier backbone's exact match beats a later one's fuzzy match; without `backbone`, every installed one is tried in a fixed priority order.
- payoff: A reader picks the authority their field uses and still resolves the names it lacks.
- evidence: ?taxify (`backbone`); ?list_backbones; vignettes/backbones.Rmd; vignettes/articles/databases.Rmd
- limits: the default is a first-match pick, not a vote across backbones; backbones disagree on treatment, and `mode = "wide"` shows the disagreement instead of settling it
- home: vignettes/backbones.Rmd
- also: README, Get started, vignettes/articles/databases.Rmd

### A4 Data joined on the accepted name
- question: How do I get traits, conservation status or my own table onto the matched names when they use other synonyms?
- answer: Each published dataset has its own `add_<source>()` function that joins on the accepted name; `add_trait()` gathers one trait from every source that carries it and harmonizes units; `add_data()` matches the reader's own table through the same backbones before joining.
- payoff: A trait table that writes *Quercus pedunculata* joins onto a list that writes *Quercus robur*.
- evidence: vignettes/enrichments.Rmd; vignettes/custom-data.Rmd; ?add_trait; ?add_data; ?list_enrichments
- limits: an enrichment covers the species its source measured; `add_trait()` registers only sources whose units and definitions could be checked against each other
- home: vignettes/enrichments.Rmd (published data); vignettes/custom-data.Rmd (own data)
- also: DESCRIPTION, README, Get started, vignettes/articles/databases.Rmd

### A5 Checking a list before trusting it
- question: Which names in my list need a second look?
- answer: `inspect()` returns only the names that look wrong (typos, synonyms, ambiguous spellings, unknown genera, an animal among plants, a species outside the declared region), each with a suggestion; `region` and `coords` steer fuzzy matches towards species that occur there; `reconcile()` reports how a checklist maps onto a backbone's current treatment.
- payoff: A reader reviews a short list of decisions instead of the whole table.
- evidence: vignettes/inspecting-names.Rmd; vignettes/regions.Rmd; ?inspect; ?reconcile
- limits: region data exist for vascular plants (WCVP) and marine ecoregions; the checks suggest, the reader decides
- home: vignettes/inspecting-names.Rmd (inspect, reconcile); vignettes/regions.Rmd (region)
- also: README

### A6 Reading the backbone the other ways
- question: Can I list the synonyms of a species, the species in a genus, the family of a name, or a tree of my list?
- answer: The same local files answer `synonyms()`, `children()`, `downstream()`, `upstream()`, `add_classification()`, `class2tree()`, `lowest_common()`, `id2name()`, `parse_name()`, `comm2sci()` and `sci2comm()`.
- payoff: taxize's lookup functions have offline counterparts on the backbone the names were matched against.
- evidence: vignettes/exploring.Rmd; the help pages of each verb
- limits: common names come from the vernacular names GBIF, NCBI and OTT publish
- home: vignettes/exploring.Rmd
- also: README

### A7 Lists of any size
- question: Will it run on 100,000 names, or an occurrence download?
- answer: Matching runs in C on columnar files, fuzzy candidates are compared only within a genus, and a list is resolved in seconds to minutes; repeated names are matched once.
- payoff: A whole occurrence download or a national checklist resolves in one call.
- evidence: scripts/benchmark-worldflora.R and its results JSON; vignettes/large-scale.Rmd
- limits: the first load of a backbone costs a few seconds; fuzzy matching dominates the time on lists with many typos
- home: vignettes/large-scale.Rmd; the WorldFlora timings in vignettes/migration.Rmd
- also: DESCRIPTION, README

### A8 Vegetation units
- question: Can I resolve the alliance and association names in a vegetation-plot database?
- answer: Two backbones hold vegetation units (syntaxa): the EuroVegChecklist and the Czech national classification. Naming one switches parsing and matching to the rules of phytosociological nomenclature and returns the unit's class, order, alliance and association.
- payoff: Plot headers in EVA or a national database resolve to current units the way species names do.
- evidence: ?parse_name (`code = "syntaxon"`); vignettes/vegetation-units.Rmd
- limits: a short form naming several units (*Carpinion*) stays unresolved, with the candidates listed
- home: vignettes/vegetation-units.Rmd
- also: README

## Non-goals
- No live web query at match time; data change only when the reader downloads a new release.
- No taxonomic opinion of its own: the accepted name is the backbone's, and backbones that disagree are reported, not reconciled by vote.
- No occurrence cleaning (coordinates, dates); that is OccurrenceCleaner's or CoordinateCleaner's job.
- No building of backbones in the runtime package; taxifydb builds and publishes them.

## Documents
- DESCRIPTION: listing text; the claim, the backbones, A1, A2, A4 in one sentence each
- README / landing: claim, relation, the supports list (A3 A4 A5 A7), install, three-step usage with the first evaluated example, one section each for backbones (A3), data (A4), checking (A5), browsing (A6), vegetation units (A8), Documentation routing, help, support, citation from inst/CITATION
- ?taxify-package: claim, verb map, routing, citation pointer
- taxify.Rmd (Get started): tutorial from a messy list to an accepted-name table with traits attached, with one taste of `inspect()` and the version record
- backbones: how-to choose, chain, download and pin backbones (A2, A3 home)
- fuzzy-matching: explanation of the matching pipeline (A1 home)
- regions: how-to steer matches by region (A5)
- inspecting-names: how-to check a list (A5 home)
- enrichments: how-to attach published data (A4 home)
- custom-data: how-to join one's own table (A4)
- exploring: how-to read the backbone by synonym, rank and lineage (A6 home)
- gbif-requests: how-to turn a matched list into a GBIF occurrence request
- vegetation-units: how-to resolve syntaxon names (A8 home)
- large-scale: how-to resolve large lists (A7 home)
- hybrids-and-aggregates: explanation of hybrid and aggregate names
- articles/databases: reference of every backbone, enrichment and trait
- migration: comparison with taxize, WorldFlora and related packages (relation home)
- help pages: reference

## Open
- The relation phrase is a proposal; the user owns it.
- The WorldFlora benchmark compares taxify on the installed WFO backbone with WorldFlora on the Zenodo file the script downloads, which can be different WFO releases; the script header says one snapshot. Pinning taxify to the same release would make the comparison exact.
- The databases catalogue has no taxon or geographic scope per dataset: the manifest carries none, and 13 datasets store their citation as one string instead of the structured list (taxifydb manifest).
