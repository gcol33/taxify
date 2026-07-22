# Accuracy regression: taxify against the curated EVA-to-WFO ground truth.
#
# The corpus is the hand-cleaned one-to-one EVA/ASAAS species mapping produced
# during the ASAAS data preparation (34,589 vegetation-survey names, 32,425 of
# them carrying a verified WFO target). It is access-restricted vegetation-plot
# data and is not redistributed with the package.
#
# Point at it with the corpus CSV path:
#
#   Sys.setenv(TAXIFY_ASAAS_CORPUS = ".../02_eva_one_to_one_wfo_clean.csv")
#   testthat::test_file("tests/e2e/test-asaas-validation.R")
#
# Required columns: EVA_TAXON, WFO_TAXON, WFO_TAXON_RANK, WFO_GENUS, WFO_FAMILY,
# WFO_ID.
#
# Reading the numbers
# -------------------
# The corpus was curated against a 2024 WFO snapshot; the package resolves
# against whichever WFO release is installed (2026.06 at the time these
# thresholds were set). A name the corpus maps to one accepted name and taxify
# maps to another is therefore not automatically a taxify error -- WFO itself
# re-circumscribes genera between releases. Three divergence classes are
# separated below and only the aggregate floors are asserted:
#
#   drift    the same WFO ID under a different accepted name. The backbone
#            renamed the taxon; taxify followed it and the corpus did not.
#   hybrid   the corpus collapses "A x B" to its first parent; taxify expands
#            the formula to both parents. A convention difference.
#   genuine  a different WFO ID, i.e. taxify landed on another record.
#
# A failure here means the accuracy floor was breached, not that taxify must be
# made to agree with the corpus. Before changing matching code to close a gap,
# establish which class moved.
#
# Baseline measured on the full corpus, WFO 2026.06, no sampling:
#
#             match_rate  name   family  genus  wfo_id
#   exact       0.9469   0.9227  0.9574  0.9418  0.8080
#   fuzzy       0.9783   0.9172  0.9574  0.9413  0.8050
#
# Fuzzy trades accuracy for recall: it converts ~1,080 unmatched names into
# matches (+3.1 pp match rate) at a cost of ~0.55 pp accepted-name agreement.
# Both sides of that trade are asserted so neither can silently erode.

library(testthat)

corpus_path <- Sys.getenv("TAXIFY_ASAAS_CORPUS", unset = "")

skip_if_no_corpus <- function() {
  if (!nzchar(corpus_path)) {
    skip("Set TAXIFY_ASAAS_CORPUS to the EVA-to-WFO ground-truth CSV.")
  }
  if (!file.exists(corpus_path)) {
    skip(paste0("TAXIFY_ASAAS_CORPUS does not exist: ", corpus_path))
  }
  if (!"wfo" %in% installed_backbones()) {
    skip("The WFO backbone is not installed.")
  }
}

required_cols <- c("EVA_TAXON", "WFO_TAXON", "WFO_TAXON_RANK", "WFO_GENUS",
                   "WFO_FAMILY", "WFO_ID")

load_corpus <- function() {
  truth <- utils::read.csv(corpus_path, stringsAsFactors = FALSE)
  missing <- setdiff(required_cols, names(truth))
  if (length(missing)) {
    stop("Corpus is missing required column(s): ",
         paste(missing, collapse = ", "), call. = FALSE)
  }
  truth
}

# Agreement over the rows where taxify matched and the corpus carries a target.
# A missing value counts against the rate rather than leaving the denominator:
# a match that returns no family has failed to deliver the family, and dropping
# those rows would report accuracy on a set that shrinks as coverage worsens.
agreement <- function(got, want, comparable) {
  n <- sum(comparable)
  if (n == 0L) return(NA_real_)
  sum(got[comparable] == want[comparable], na.rm = TRUE) / n
}

run_corpus <- function(truth, fuzzy) {
  res <- taxify(truth$EVA_TAXON, backbone = "wfo", fuzzy = fuzzy, verbose = FALSE)
  has_truth  <- !is.na(truth$WFO_TAXON) & nzchar(truth$WFO_TAXON)
  matched    <- !is.na(res$match_type) & res$match_type != "none"
  comparable <- matched & has_truth
  list(
    res          = res,
    matched      = matched,
    comparable   = comparable,
    match_rate   = mean(matched),
    n_comparable = sum(comparable),
    name_agree   = agreement(res$accepted_name, truth$WFO_TAXON,  comparable),
    family_agree = agreement(res$family,        truth$WFO_FAMILY, comparable),
    genus_agree  = agreement(res$genus,         truth$WFO_GENUS,  comparable),
    id_agree     = agreement(res$taxon_id,      truth$WFO_ID,     comparable)
  )
}

report <- function(label, m) {
  cat(sprintf(
    "\n%s: match %.4f | name %.4f | family %.4f | genus %.4f | wfo_id %.4f (n=%d)\n",
    label, m$match_rate, m$name_agree, m$family_agree, m$genus_agree,
    m$id_agree, m$n_comparable))
}


test_that("the corpus is the expected shape", {
  skip_if_no_corpus()
  truth <- load_corpus()

  expect_true(all(required_cols %in% names(truth)))
  # Guards against being pointed at a truncated or sampled file: the accuracy
  # floors below are only meaningful over the whole corpus.
  expect_gte(nrow(truth), 30000L)
  expect_gte(sum(!is.na(truth$WFO_TAXON) & nzchar(truth$WFO_TAXON)), 28000L)
})


test_that("exact matching holds its accuracy floor on the full corpus", {
  skip_if_no_corpus()
  truth <- load_corpus()
  m <- run_corpus(truth, fuzzy = FALSE)
  report("exact", m)

  expect_gte(m$match_rate,   0.94)
  expect_gte(m$name_agree,   0.91)
  expect_gte(m$family_agree, 0.95)
  expect_gte(m$genus_agree,  0.93)
  expect_gte(m$id_agree,     0.79)
})


test_that("fuzzy matching raises recall without eroding accuracy", {
  skip_if_no_corpus()
  truth <- load_corpus()
  exact <- run_corpus(truth, fuzzy = FALSE)
  fuzzy <- run_corpus(truth, fuzzy = TRUE)
  report("fuzzy", fuzzy)

  # Recall: fuzzy exists to resolve names exact matching leaves unmatched.
  expect_gte(fuzzy$match_rate, 0.97)
  expect_gt(fuzzy$match_rate, exact$match_rate)

  # Accuracy: the extra recall must not be bought with wrong answers.
  expect_gte(fuzzy$name_agree,   0.90)
  expect_gte(fuzzy$family_agree, 0.95)
  expect_gte(fuzzy$genus_agree,  0.93)

  # The cost of fuzzy over exact is bounded. A widening gap means fuzzy is
  # resolving names it should be declining.
  expect_lt(exact$name_agree - fuzzy$name_agree, 0.02)
})


test_that("divergence stays dominated by backbone drift and known conventions", {
  skip_if_no_corpus()
  truth <- load_corpus()
  m <- run_corpus(truth, fuzzy = FALSE)
  res <- m$res

  disagree <- which(m$comparable & res$accepted_name != truth$WFO_TAXON)
  expect_gt(length(disagree), 0L)

  exp_id <- truth$WFO_ID[disagree]
  got_id <- res$taxon_id[disagree]
  drift  <- !is.na(exp_id) & !is.na(got_id) & exp_id == got_id

  hybrid <- res$match_type[disagree] == "hybrid_formula"

  genus_of <- function(x) sub(" .*$", "", x)
  same_genus <- genus_of(truth$WFO_TAXON[disagree]) == genus_of(res$accepted_name[disagree])
  hard <- !drift & !hybrid & !same_genus & !is.na(same_genus)

  cat(sprintf(
    "\ndivergence: %d total | drift %d | hybrid convention %d | different genus %d\n",
    length(disagree), sum(drift), sum(hybrid), sum(hard)))

  # A hard miss is a different genus that is neither a rename nor a hybrid
  # formula. These are the ones worth reading; cap the share so a matching
  # regression that scatters names across genera fails here.
  expect_lt(sum(hard) / m$n_comparable, 0.015)
})


test_that("unauthored homonyms are flagged rather than silently resolved", {
  skip_if_no_corpus()

  # WFO carries two Schedonorus arundinaceus records under different authors,
  # a synonym of Scolochloa festucacea (Roem. & Schult.) and one of Lolium
  # arundinaceum ((Schreb.) Dumort.). With no authorship in the query neither
  # can be preferred, so the result must carry the ambiguity flag.
  res <- taxify("Schedonorus arundinaceus", backbone = "wfo", fuzzy = FALSE,
                verbose = FALSE)

  expect_equal(res$match_type, "exact")
  expect_true(res$is_ambiguous)
  expect_true(res$accepted_name %in% c("Scolochloa festucacea",
                                       "Lolium arundinaceum"))
})


test_that("hybrid formulae expand to both parents", {
  skip_if_no_corpus()

  # The corpus records the first parent only; taxify resolves both. Pinned so
  # the expansion is not quietly dropped to match the corpus convention.
  res <- taxify("Cirsium pannonicum \u00d7 erisithales", backbone = "wfo",
                fuzzy = FALSE, verbose = FALSE)

  expect_equal(res$match_type, "hybrid_formula")
  expect_match(res$accepted_name, "Cirsium pannonicum")
  expect_match(res$accepted_name, "erisithales")
})
