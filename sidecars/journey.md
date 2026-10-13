# Journey: taxify

Anchors are `<doc>.<slug>`; the documents carry no `@p:` markers, so entries are matched by order and first words. Articles are mapped per paragraph, code block and section; the opener of each is its own entry. README.md and the shipped vignettes are rendered from README.Rmd and vignettes/*.Rmd.orig by data-raw/precompute_vignettes.R, so the entries describe the sources.

## DESCRIPTION

### desc.claim  [A1 A3]
- idea: matches names against local copies of named backbones, resolves to the accepted name
- job: Names the task, the nineteen backbones and the two vegetation classifications in one sentence.
- leaves: what goes in, what comes out, which data sources

### desc.relation  [A2]
- idea: the name-resolution step of taxize and WorldFlora, run offline
- job: States the relation phrase.
- leaves: where it fits for a user of either package

### desc.pipeline  [A1 A2]
- idea: clean, exact, fuzzy within genus, synonym to accepted; version per row
- job: Says how a name is resolved and that the backbone version is recorded on every row.
- leaves: the mechanism and the reproducibility record

### desc.data  [A4]
- idea: published datasets and the user's table join on the accepted name
- job: States the join.
- leaves: that traits and status come with it

### desc.engine
- idea: vectra
- job: Names the engine.
- leaves: the dependency a CRAN reader sees in Imports

## README

Source is README.Rmd, knitted in the default view (COL, GBIF, ITIS installed).

### readme.breakline
- idea: species names matched to their accepted names, offline
- job: Names the subject in plain words.
- leaves: the domain, before any term

### readme.claim  [A1]
- idea: matches names to the accepted name, with examples of input
- job: Says what the package does in one sentence and defines "accepted name" by its use.
- leaves: the task and its output

### readme.relation  [A1 A2 A3]
- idea: taxize/WorldFlora step offline; what a backbone is; what each row carries; the reader decides
- job: States the relation phrase (one sentence), defines a backbone as a published database downloaded once (one sentence), and says each name comes back with accepted name, match route and version so the reader reviews the uncertain matches and decides (one sentence, ending on the decision).
- leaves: the parent packages, the core term, and the reader's choice

### readme.supports  [A3 A4 A5 A8]  (list)
- idea: backbones for every group · published data on the accepted name · checking a list · vegetation units
- job: Lists four uses, each with its mechanism: the backbone groups and the fallback chain; the datasets joined on the accepted name and `add_trait()`; `inspect()` with its labels; the two vegetation classifications.
- leaves: why a reader would pick the package, each reason backed by a function or a count from the manifest

### readme.trust  [A2]
- idea: the backbone's opinion, disagreement visible, versions, citations, lock
- job: Says the accepted name is the backbone's, `mode = "wide"` shows disagreement, and the version record, `cite()` and `taxify_lock()` make the result citable and rerunnable.
- leaves: what a methods section names, and why the answer can be trusted

### readme.install  (section)
- job: CRAN and development install; the first call downloads COL, GBIF and ITIS (about 4 GB).
- leaves: what the first run costs

### readme.steps  [A1 A4 A5]  (list)
- idea: match, inspect, join
- job: Names the three verbs in the order a user calls them.
- leaves: `taxify()`, `inspect()`, `add_data()` / `add_<source>()`

### readme.example  [A1]  (code)
- idea: smallest call, output shown
- job: Matches four names (one exact, one typo, two synonyms) and prints four columns, with the multiple-ID warning.
- leaves: the call, its input and what comes back

### readme.example-result  [A1]
- idea: what each name went through; the warning
- job: Explains each row by its property and what the warning and `n_ids` / `accepted_ids` mean.
- leaves: how to read `match_type`, `is_synonym` and the warning

### readme.input  [A1 A3]
- idea: what goes in; the default chain
- job: Says the input is a character vector, what cleaning handles, and how the default and named chains work.
- leaves: the minimum input and the `backbone` choice

### readme.inspect  [A5]  (code + paragraph)
- job: Runs `inspect()` on the example and explains the two tiers; routes to Get started.
- leaves: the check step and where the tutorial continues

### readme.joining  [A4]  (section)
- job: `add_data()`, an `add_<source>()` pipe and `add_trait()` in three lines; routes to the enrichments article.
- leaves: the join on the accepted name

### readme.backbones  [A3 A2]  (section)
- job: Downloaded once from taxifydb, pinned by version; the staged fallback chain; `list_backbones()`; routes to the backbones and databases articles.
- leaves: how to choose and chain backbones

### readme.exploring  [A6]  (section)
- job: Five lookup verbs, one line each; routes to the exploring article.
- leaves: the backbone answers more than matching

### readme.scale  [A7]  (section)
- job: vectra and genus blocking; time grows with the list, not the backbone; routes to the large-lists article.
- leaves: that large lists work, with the number at the article

### readme.documentation  (section)
- job: Starting point and every article by its job.

### readme.help, readme.contributing, readme.support, readme.acknowledgements, readme.license, readme.citation  (sections)
- job: Channels, the shared footer, credit to the data providers, MIT, the generated citation.

## ?taxify-package

### pkg.overview  [A1 A2]
- job: Claim, relation phrase, version record.
### pkg.functions  [A1 A4 A5 A6 A2]  (section)
- job: The functions grouped by task.
### pkg.start, pkg.citation  (sections)
- job: Routes to Get started and the site; `citation()` and `cite()`.

## vignettes/taxify.Rmd (Get started)

### vig.taxify.opener  [A1 A4 A2]
- idea: what the article does and where it ends
- job: Says the article resolves a list, joins a trait table and two datasets, and records the versions; assumes basic R; ends with one row per name, accepted name, match route, traits.
- leaves: the destination and the prerequisite

### vig.taxify.steps  (list)
- job: Match, check, join, record, one verb each.

### vig.taxify.install  (section)
- job: CRAN and development install, copied from the README.

### vig.taxify.backbones  [A3 A2]
- idea: what a backbone is; the first-run download
- job: Defines backbone with the three default examples, says the first call downloads them (about 4 GB) and later calls need no network.
- leaves: the term and the cost of the first call

### vig.taxify.match  [A1]  (section, code)
- idea: nine names, each a different route
- job: Introduces each input by its property, then matches them.
- leaves: `res`, one row per input

### vig.taxify.match-result  [A1]  (list)
- job: Defines the output contract (one row per input, input order, `input_name` unchanged) and the four common `match_type` values with their rows.
- leaves: how to read `match_type` and `fuzzy_dist`

### vig.taxify.synonyms  [A1]
- job: The two synonym rows and `is_synonym`.

### vig.taxify.fantasia  [A1 A5]
- job: The invented name reaches a real taxon by fuzzy matching and a synonym; sets up the check.
- leaves: a fuzzy match is a candidate

### vig.taxify.ids  [A1]  (code)
- job: Explains the warning and shows `n_ids` / `accepted_ids` for the row it names.

### vig.taxify.check  [A5]  (section, code)
- job: `summary()` counts and names the version; `inspect()` lists the rows to look at with tiers; the reader drops the rows they reject and keeps `kept`.
- leaves: `kept`, the table most analyses start from

### vig.taxify.own-data  [A4]  (section, code)
- job: A trait table written with a synonym joins through `add_data()`; the report line explained.

### vig.taxify.enrich  [A4]  (section, code)
- job: `add_zanne()` and `add_eive()` join on the accepted name; `cols = "all"`, `list_enrichments()`, `add_trait()` routed.

### vig.taxify.record  [A2]  (section, code)
- job: `backbone_version` on every row; `cite()` for the references; `taxify_lock()` writes the versions and checksums; `taxify_restore()` reinstalls them.

### vig.taxify.errors  (section, code)
- job: A data frame passed instead of its column, and a misspelt backbone name, each with the real error and the corrected call.

### vig.taxify.where-next  (list)
- job: Five articles labelled by job.

## vignettes/backbones.Rmd (Choosing and combining backbones)

### vig.backbones.opener  [A3]
- job: What the article does (how a backbone is chosen, named, compared, downloaded) and where it ends (choices per kind of list).
- leaves: the four steps

### vig.backbones.default  [A3]  (section, code)
- job: `list_backbones()` shows the 21; the default chain is every installed backbone in priority order; first-run set COL, GBIF, ITIS. Eight mixed names all resolve in COL XR; the sources line names only the backbones that matched.
- leaves: `backbone` column, first match decides, no vote

### vig.backbones.naming  [A3]  (section, code)
- job: `c("wfo", "col")`: the progress lines show the chain; *Fucus vesiculosus* is out of scope for both; adding AlgaeBase resolves it.
- leaves: order decides treatment; out_of_scope points to a missing backbone

### vig.backbones.scope  [A3]  (section, code)
- job: `lookup_genus()` and `taxify_register_coverage()` show which backbones hold *Fucus*; `out_of_scope` vs `none`.

### vig.backbones.compare  [A3]  (section, code)
- job: `mode = "wide"` and `"agreement"` on the red kangaroo (GBIF keeps *Macropus*); `accepted_name` stays the chain's pick.

### vig.backbones.extras  [A3]  (section, list, code)
- job: `add_wfo_info()`, `add_col_info()`, `add_gbif_info()`; COL's habitat flags for the shore crab.

### vig.backbones.output  [A3]  (section, list)
- job: How identifiers, authorship and synonyms differ between backbones; links the catalogue.

### vig.backbones.versions  [A2]  (section, code)
- job: Download on first use, `taxify_download()`, the `latest` slot and pinned versions, offline mode, `backbone_version`, `taxify_lock()` / `taxify_restore()`, `taxify_build()`.

### vig.backbones.choosing  [A3]  (section, list)
- job: Backbone choices for plants, European vegetation data, marine, fungi, algae, single animal groups, sequence-linked and phylogenetic lists, unknown composition.

## vignettes/vegetation-units.Rmd (Matching vegetation units)

### vig.vegunits.opener  [A8]
- job: What a syntaxon match does and where it ends (accepted unit plus hierarchy).

### vig.vegunits.names  [A8]  (section, code)
- job: The ICPN name structure (rank suffixes, author with years); `parse_name(code = "syntaxon")` splits name, author, rank, code.

### vig.vegunits.backbones  [A8]  (section, list, code)
- job: `evc` and `vegcz`, with their sources; named only explicitly; never mixed with taxa.

### vig.vegunits.match  [A8]  (section, code, list)
- job: Seven plot-header names, each reaching its unit by a different route (author removed, synonym listed without epithet, i/y spelling, code removed, short name, fuzzy, ambiguous short name); `accepted_ids` of *Carpinion*; author citations choose; fuzzy keeps rank and stems.

### vig.vegunits.hierarchy  [A8]  (section, code)
- job: The `class`, `order`, `alliance`, `association` columns replace the taxon-only ones.

### vig.vegunits.rollup  [A8]  (section, code)
- job: A Czech association resolves to its alliance in `vegcz`, the alliance to its order and class in `evc`; the *Arrhenatheretum* homonym chosen by author; `c("vegcz", "evc")` chain.

### vig.vegunits.mixing  [A8]  (section, code)
- job: The error when taxa and syntaxa backbones are combined.

### vig.vegunits.build  [A8]  (section)
- job: How both backbones were built, the Mucina et al. fill-in, Pladias terms, misapplied names.

## vignettes/fuzzy-matching.Rmd (How names are matched)

### vig.fuzzy.opener  [A1]
- job: The stages from input name to backbone record and the arguments that change them.

### vig.fuzzy.stages  [A1]  (section, list)
- job: Every `match_type` in stage order.

### vig.fuzzy.cleaning  [A1]  (section, code)
- job: Authors, spaces, qualifiers, capitals and an abbreviated genus removed or resolved; Latin spelling variants; infraspecific ranks kept.

### vig.fuzzy.fuzzy  [A1]  (section, code)
- job: Eight typos and how `fuzzy_dist` is computed; fuzzy never replaces an exact match.

### vig.fuzzy.methods  [A1]  (section, list, code)
- job: `"dl"`, `"levenshtein"`, `"jw"` compared on the same names.

### vig.fuzzy.threshold  [A1]  (section, code)
- job: Fractional vs whole-number thresholds on *Poa*.

### vig.fuzzy.genera  [A1]  (section, code)
- job: The two-letter prefix pass for misspelt genera and the case it cannot reach.

### vig.fuzzy.review  [A1 A5]  (section, code)
- job: Two fuzzy matches to the wrong taxon (an invented name, a variety reached before the species fallback); `fuzzy = FALSE`.

### vig.fuzzy.homonyms  [A1]  (section, code)
- job: *Pinus abies* L. vs Thunb.: `n_ids`, `accepted_ids`, the pick order, the author tiebreak; *Prunella* split by `kingdom`.

### vig.fuzzy.synonyms  [A1]  (section, code)
- job: Synonym rows, the homotypic-synonym preference, the basionym stage.

### vig.fuzzy.infra  [A1]  (section, code)
- job: `ssp.` read as `subsp.`; `rank_fallback` for an infraspecific name no backbone holds.

### vig.fuzzy.unmatched  [A1 A3]  (section, code)
- job: `none` vs `out_of_scope` and the genus register that decides between them and fills the register columns.

## vignettes/hybrids-and-aggregates.Rmd (Hybrids and aggregates)

### vig.hybrids.opener  [A1 A4]
- job: How hybrid and aggregate names are matched and receive trait values.

### vig.hybrids.names  [A1]  (section, list, code)
- job: The three hybrid notations; six names matched against WFO; formula rows and their `NA` columns.

### vig.hybrids.parents  [A1]  (section, code)
- job: `add_hybrid_info()` columns; why a nothospecies has no parents; formula notations parsed.

### vig.hybrids.detection  [A1]  (section)
- job: How the marker is found, the encoding repair, the sign-kept and sign-removed forms, whole-formula matching first.

### vig.hybrids.aggregates  [A1]  (section, code)
- job: `agg.` / `s.l.` / `s.str.`; WFO falls back to binomials; Euro+Med holds aggregates; `aggregates = "collapse"`.

### vig.hybrids.traits  [A4]  (section, code)
- job: The trait ladder for formulas and aggregates; a *Salix* cross takes the mean of its parents per dataset, or the one parent with a value; options to turn the fallback off and record its basis.

## vignettes/inspecting-names.Rmd (Checking a name list)

### vig.inspect.opener  [A5]
- job: What `inspect()` finds and that the article ends with `reconcile()`.

### vig.inspect.unmatched  [A5]  (section, code)
- job: The three no-matching checks on a plant list with four problems; why the synonym passes them.

### vig.inspect.matched  [A5]  (section, code)
- job: `backbones = TRUE` in the default chain order adds typo, synonym and ambiguity labels; passing a result.

### vig.inspect.labels  [A5]  (section, list)
- job: Every label and tier, and that a row takes its highest tier.

### vig.inspect.region  [A5]  (section, code)
- job: The region check on *Banksia serrata*; `out_of_range` without a region.

### vig.inspect.report  [A5]  (section, code)
- job: The report as a data frame, `min_tier`, applying suggestions, single-name warning, the `not checked` line.

### vig.inspect.reconcile  [A5]  (section, code)
- job: `reconcile()` statuses and `merged_with` on a five-name checklist.

## vignettes/regions.Rmd (Matching within a region)

### vig.regions.opener  [A5]
- job: Preferring regional candidates in fuzzy matching; WCVP, WGSRPD, WoRMS, MEOW sources.

### vig.regions.example  [A5]  (section, code)
- job: *Cirsium acule* matches a North American thistle without a region and the European one with `region = "Europe"`.

### vig.regions.rules  [A5]  (section, list)
- job: What the filter drops and the three rules that keep candidates.

### vig.regions.naming  [A5]  (section, code)
- job: Names and codes at three levels, `taxify_regions()`, an unknown code dropped with a warning.

### vig.regions.coords  [A5]  (section, code)
- job: Points, spatial objects, the boundary file and the point-in-polygon engine.

### vig.regions.range  [A5]  (section, code)
- job: `range = "native"` / `"introduced"`.

### vig.regions.marine  [A5]  (section, code)
- job: MEOW ecoregions, provinces and realms; points at sea; the precision of WoRMS records.

## vignettes/custom-data.Rmd (Joining your own data)

### vig.customdata.opener  [A4]
- job: Joining a table that writes names differently; ends with `export_data()`.

### vig.customdata.df  [A4]  (section, code)
- job: A trait table with *Fallopia japonica* joins onto *Reynoutria japonica*; names with several accepted taxa routed to the matching article.

### vig.customdata.file  [A4]  (section, code, list)
- job: A CSV with an unnamed species column found automatically; the file types and their arguments.

### vig.customdata.cols  [A4]  (section, code)
- job: `cols` and the `data_` prefix for colliding names.

### vig.customdata.dups  [A4]  (section, code)
- job: Identical repeats merged, differing repeats stop the join, `group_col` keeps groups apart.

### vig.customdata.options  [A4]  (section, code)
- job: `fuzzy` and `fuzzy_threshold` for the table's names; `fuzzy = FALSE` for a checked table.

### vig.customdata.chain  [A4]  (section, code)
- job: `add_data()` and an `add_<source>()` function join on the same accepted taxon, in any order.

### vig.customdata.export  [A4]  (section, code)
- job: `export_data()` writes `.csv`, `.tsv`, `.xlsx` or `.vtr`; a `.vtr` can be joined in another project.

### vig.customdata.how  [A4]  (section, list)
- job: The five steps of the join, keyed on the accepted ID and its backbone.

## vignettes/exploring.Rmd (Exploring the backbone)

### vig.exploring.opener  [A6]
- job: The functions that read the backbone in the other directions; ends with a taxonomy tree.

### vig.exploring.synonyms  [A6]  (section, code)
- job: `synonyms()` of *Picea abies*.

### vig.exploring.below  [A6]  (section, code)
- job: `children()` and `downstream()`.

### vig.exploring.above  [A6]  (section, code)
- job: `upstream()` from a synonym; `add_classification()`.

### vig.exploring.ids  [A6]  (section, code)
- job: `id2name()` and `taxify_ids()` on *Pinus abies*.

### vig.exploring.parse  [A6]  (section, code)
- job: `parse_name()` on four kinds of name.

### vig.exploring.common  [A6]  (section, code)
- job: `sci2comm()` with `name_rank`; `comm2sci()` returns every name that carries a common name, and 27 of 30 matched names resolve to *Picea abies*.

### vig.exploring.compare  [A6]  (section, code)
- job: `lowest_common()` and `class2tree()`, a tree of ranks without branch lengths.

## vignettes/enrichments.Rmd (Attaching published data)

### vig.enrich.opener  [A4]
- job: One dataset, one trait across datasets, datasets by place or language; ends with how values are joined and cited.

### vig.enrich.finding  [A4]  (section, code)
- job: `list_enrichments()` and the help page of each `add_<source>()` function.

### vig.enrich.one  [A4]  (section, code)
- job: `add_zanne()`, the column message, `enrichment_cols()`, `cols = "all"`, chaining.

### vig.enrich.grouped  [A4]  (section, code)
- job: GRIIS by country (an `NA` is no record), `taxify_long()`, WCVP by region, common names by language.

### vig.enrich.trait  [A4]  (section, code)
- job: `list_traits()`, coalesced seed mass in one unit, `trait_info()`, `mode = "wide"`, one vocabulary, the caution rule, `sources` / `priority` / `combine`.

### vig.enrich.refs  [A4 A2]  (section, code)
- job: `provenance = TRUE` and `cite()` of the reference IDs.

### vig.enrich.coverage  [A4]  (section, code)
- job: A mixed list against six datasets; what an `NA` column or cell means; `summary()`.

### vig.enrich.join  [A4]  (section)
- job: Join on the accepted name, the build-time expansion over all backbones, recovery at join time, refused rows, genus-keyed datasets.

### vig.enrich.versions  [A2]  (section, code)
- job: Download on first use, `taxify_download_enrichment()`, fixed vs updated releases, kept builds.

## vignettes/articles/databases.Rmd (The backbones and datasets)

### vig.databases.opener  [A3 A4]
- job: The catalogue, generated from the manifest at build time; links to the how-to articles.

### vig.databases.backbones  [A3]  (section, table)
- job: Every backbone with its full name, scope, size, version, licence where recorded and reference.

### vig.databases.datasets  [A4]  (section, table)
- job: Every dataset with its function, version, release type, rows, licence and reference; datasets without a function feed `add_trait()`.

### vig.databases.traits  [A4]  (section, table)
- job: Every trait `add_trait()` gathers, with its sources.

## vignettes/large-scale.Rmd (Matching large lists)

### vig.scale.opener  [A7]
- job: Timings, memory, and running a list in resumable parts.

### vig.scale.timings  [A7]  (section, table)
- job: Measured times for 1,000 to 100,000 names, clean and with one in ten misspelt, read from `scripts/benchmark-scale-results.json`.

### vig.scale.exact  [A7]  (section, code)
- job: `fuzzy = FALSE` for checked lists; fuzzy matching on the unmatched names only.

### vig.scale.order  [A7 A3]  (section, code)
- job: The first backbone receives every name; the sizes of the backbones.

### vig.scale.parts  [A7]  (section, code)
- job: A resumable loop over parts written with `saveRDS()`.

### vig.scale.memory  [A7]  (section, table)
- job: Memory of a loaded backbone and of exact and fuzzy matching, read from `scripts/benchmark-memory-results.json`; `taxify_clear_cache()`.

### vig.scale.offline  [A2 A7]  (section, code)
- job: Downloading backbones and datasets before a run; offline mode; `taxify_refresh_manifest()`.

### vig.scale.files  [A7]  (section)
- job: `taxify_data_dir()`, the option and environment variable that move it, sharing it between users, `taxify_store()`, deleting a backbone.

## vignettes/gbif-requests.Rmd (Requesting GBIF data for a species list)

### vig.gbif.opener  [A4]
- job: From names to GBIF keys to records and a DOI; what needs rgbif and an account.

### vig.gbif.match  [A4]  (section, code)
- job: Four plants matched to GBIF keys; `n_ids`.

### vig.gbif.keys  [A4 A1]  (section, code)
- job: `taxify_ids()` roles (`pick`, `same_name`, `other_taxon`) and `pick_basis`.

### vig.gbif.dryrun  [A4]  (section, code)
- job: `dry_run = TRUE` and the `keys` choice, with the eleven-record difference.

### vig.gbif.colxr  [A4 A3]  (section, code)
- job: A default-chain result reaches the same keys through COL XR's crosswalk.

### vig.gbif.setup  [A4]  (section, code)
- job: rgbif and the three environment variables.

### vig.gbif.request  [A4]  (section, code)
- job: Download vs search; the 12,000-character query limit and split downloads.

### vig.gbif.backmatch  [A4]  (section, code)
- job: Why records are linked through several key columns; `gbif_backmatch()`.

### vig.gbif.cite  [A2 A4]  (section, code)
- job: `cite()` lists the download DOI.

## vignettes/migration.Rmd (Coming from taxize and WorldFlora)

### vig.migration.opener  [A0]
- job: The relation phrase, the function maps, and the cases for another package.

### vig.migration.differ  [A2]  (section)
- job: Web services vs a file in memory vs files on disk; current treatment vs the version on disk.

### vig.migration.taxize  (section, table)
- job: taxize 0.10.1 functions mapped to taxify.

### vig.migration.worldflora  [A1]  (section, table, code)
- job: WorldFlora 1.14-5 functions mapped; output columns compared; the same four names in taxify.

### vig.migration.timings  [A7]  (section, table)
- job: Times read from `scripts/benchmark-worldflora-results.json`, with versions and date; the two packages return different things.

### vig.migration.others  (section, list)
- job: rgbif, worrms, ritis, taxadb, lcvplants, rWCVP and Taxonstand, with their CRAN status where archived.

### vig.migration.better  (section, list)
- job: Recent names, choosing by hand, distribution queries, phylogenies, occurrence and sequence records.
