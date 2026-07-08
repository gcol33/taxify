# Per-door integration coverage, offline against the bundled example database.
# For each bundled single-source enrichment, this probes a species the .vtr
# actually covers, calls its add_*() door, and asserts the door attaches columns
# and recovers at least one value. This catches a door wired to the wrong
# enrichment key or a col_map whose source columns are misspelled (which would
# silently attach an all-NA column). The heavier real-backbone joins live in
# tests/e2e/, which need full backbones and network and are not run here.

# Bundled single-source doors whose function is add_<key> and which take only
# (x, [cols], verbose). Group-filtered doors (griis, glonaf, wcvp,
# alien_first_records, common_names) need a group argument and are covered
# elsewhere.
.simple_bundled_doors <- c(
  "zanne", "iucn", "diaz_traits", "leda", "gift", "eive", "avonet",
  "pantheria", "amphibio", "anage", "animaltraits", "arthropod_traits",
  "austraits", "baseflor", "bien", "ecoflora", "elton_traits", "fishbase",
  "fishmorph", "floraweb", "funguild", "groot", "kew_sid",
  "leptraits", "repttraits", "sealifebase", "algae_traits"
)
# Genus-keyed doors (fungal_traits, fungalroot) use a different join and are
# covered by test-fungalroot.R and test-trait-genus-join.R.

# A species the enrichment .vtr covers with at least one non-NA trait value, or
# NULL when the enrichment is not bundled in the example database.
door_probe_species <- function(key) {
  p <- file.path(taxify_example_data(), "enrichment", key, "latest",
                 paste0(key, ".vtr"))
  if (!file.exists(p)) return(NULL)
  d <- tryCatch(vectra::collect(utils::head(vectra::tbl(p), 8L)),
                error = function(e) NULL)
  if (is.null(d) || !"canonical_name" %in% names(d) || nrow(d) == 0L) {
    return(NULL)
  }
  trait_cols <- setdiff(names(d), c("canonical_name", "accepted_name", "genus"))
  for (i in seq_len(nrow(d))) {
    if (length(trait_cols) &&
        any(!is.na(unlist(d[i, trait_cols, drop = FALSE])))) {
      return(d$canonical_name[i])
    }
  }
  d$canonical_name[1L]
}

test_that("each bundled door attaches columns and recovers a value", {
  old <- options(taxify.data_dir = taxify_example_data())
  on.exit(options(old), add = TRUE)

  tested <- 0L
  for (key in .simple_bundled_doors) {
    sp <- door_probe_species(key)
    if (is.null(sp)) next
    fn <- get(paste0("add_", key), envir = asNamespace("taxify"))
    # Provide genus too, so genus-keyed doors (fungal_traits) can join.
    x  <- data.frame(accepted_name = sp, genus = sub(" .*", "", sp),
                     stringsAsFactors = FALSE)
    out <- fn(x, verbose = FALSE)

    expect_s3_class(out, "data.frame")
    expect_true(ncol(out) > 2L, info = paste0(key, ": attaches columns"))
    added <- setdiff(names(out), c("accepted_name", "genus"))
    recovered <- any(vapply(added, function(cc) any(!is.na(out[[cc]])),
                            logical(1L)))
    expect_true(recovered, info = paste0(key, ": recovers a value for ", sp))
    tested <- tested + 1L
  }
  # Guard against the probe silently testing nothing (wrong example-db path).
  skip_if(tested == 0L, "no bundled enrichments found")
  expect_gt(tested, 5L)
})
