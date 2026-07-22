# End-to-end tests

`tests/testthat/` runs offline against `inst/exampledb/` on every check. This
directory is the other half: tests that need a real multi-million-row backbone,
a live download, or restricted data. `tests/testthat.R` is the only file at the
top level of `tests/`, so `R CMD check` copies this directory without executing
it. Nothing here runs unless you run it.

## Accuracy regression against the EVA ground truth

`test-asaas-validation.R` is the package's accuracy claim: 34,589
vegetation-survey names from the European Vegetation Archive, hand-cleaned
during the ASAAS data preparation to a verified WFO target (32,425 of them
carry one). It asserts floors on match rate and on accepted-name, family,
genus and WFO-ID agreement, so a matching regression fails rather than prints.

The corpus is access-restricted vegetation-plot data and is not redistributed
with the package. Point at your own copy:

```r
Sys.setenv(TAXIFY_ASAAS_CORPUS = ".../05_Taxa_WFO/02_eva_one_to_one_wfo_clean.csv")
devtools::load_all()
testthat::test_file("tests/e2e/test-asaas-validation.R")
```

Required columns: `EVA_TAXON`, `WFO_TAXON`, `WFO_TAXON_RANK`, `WFO_GENUS`,
`WFO_FAMILY`, `WFO_ID`. The WFO backbone must be installed. Without the
environment variable every test skips.

The full corpus takes about 25 s per pass; the file runs four passes.

### Baseline

Measured on the full corpus with no sampling, WFO 2026.06:

| mode | match rate | accepted name | family | genus | WFO ID |
|---|---|---|---|---|---|
| exact | 0.9469 | 0.9227 | 0.9574 | 0.9418 | 0.8080 |
| fuzzy | 0.9792 | 0.9152 | 0.9575 | 0.9416 | 0.8031 |

Agreement counts a missing value as a miss rather than dropping it from the
denominator, so coverage loss shows up in the rate.

Fuzzy matching converts about 1,100 unmatched names into matches (+3.2 pp match
rate) and costs about 0.8 pp of accepted-name agreement. Both directions are
asserted, so neither recall nor precision can erode unnoticed.

### Interpreting a disagreement

The corpus was curated against a 2024 WFO snapshot and the package resolves
against whichever WFO release is installed. A divergence is therefore not
automatically a taxify error. The file separates three classes and prints the
counts:

| class | meaning | count at baseline |
|---|---|---|
| drift | same WFO ID, different accepted name -- the backbone renamed the taxon and the corpus predates it | 343 |
| hybrid | the corpus collapses `A x B` to its first parent, taxify expands the formula to both | 265 |
| different genus | taxify landed on another record entirely | 258 |

Only the last class is worth reading as a possible defect, and even there some
are genuine homonyms that taxify flags with `is_ambiguous`. Before changing
matching code to close a gap, establish which class moved.

## Everything else in this directory

The remaining `test-e2e-*.R` files are scripts, not testthat files. They
download real backbones and enrichments and check them with `stopifnot()`.
Run one with:

```
Rscript tests/e2e/test-e2e-wfo.R
```

They need network access and will download multi-gigabyte backbones on first
run.

## CI

`.github/workflows/e2e-accuracy.yml` runs the accuracy regression on manual
dispatch only. It needs a runner that already holds both the installed
backbones and the restricted corpus, so it cannot run on a GitHub-hosted
runner; the workflow takes the runner label as an input and defaults to
`self-hosted`. It is deliberately not scheduled, so it never queues against a
runner that does not exist.
