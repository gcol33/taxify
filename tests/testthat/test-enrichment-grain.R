# Join grain of the enrichment doors.
#
# An enrichment .vtr is keyed at the resolution its source records: most at
# species, some at genus, one at a mix of both. A door that joins a genus-keyed
# source on the accepted_name default matches nothing and attaches an all-NA
# column -- no error, no warning. The door tests stage species-keyed fixtures, so
# a grain mismatch is invisible to them; these guards read the grain each door
# declares.

# Join arguments declared by each exported source door.
door_join_arguments <- function() {
  doors <- grep("^add_", getNamespaceExports("taxify"), value = TRUE)
  declarations <- lapply(doors, function(door) {
    args <- taxify:::.door_declaration(substring(door, 5L))
    if (is.null(args) || !is.null(args$group_col) || !is.null(args$db)) return(NULL)
    list(door = door, args = args)
  })
  Filter(Negate(is.null), declarations)
}

test_that("genus-keyed and mixed-grain enrichments are joined at their own grain", {
  genus_keyed <- genus_keyed_enrichments()
  mixed_grain <- mixed_grain_enrichments()

  calls <- door_join_arguments()
  expect_gt(length(calls), 0L)

  seen <- character(0L)
  for (cl in calls) {
    en <- cl$args$enrichment_name
    if (!is.character(en) || length(en) != 1L) next
    seen <- c(seen, en)
    if (en %in% genus_keyed) {
      expect_identical(
        cl$args$join_col, "genus",
        info = sprintf("%s() joins genus-keyed '%s' -- needs join_col = \"genus\"",
                       cl$door, en)
      )
    }
    if (en %in% mixed_grain) {
      expect_true(
        isTRUE(cl$args$genus_fallback),
        info = sprintf("%s() joins mixed-grain '%s' -- needs genus_fallback = TRUE",
                       cl$door, en)
      )
    }
  }

  expect_true(all(c(genus_keyed, mixed_grain) %in% seen))
})

test_that("species-keyed enrichments are not joined on genus", {
  # The mirror failure: a species-keyed source joined on genus silently collapses
  # every species of a genus onto one row of trait values.
  genus_keyed <- genus_keyed_enrichments()
  for (cl in door_join_arguments()) {
    en <- cl$args$enrichment_name
    if (!is.character(en) || length(en) != 1L) next
    if (en %in% genus_keyed) next
    expect_false(
      identical(cl$args$join_col, "genus"),
      info = sprintf("%s() joins species-keyed '%s' on genus", cl$door, en)
    )
  }
})

test_that("build-only enrichments are absent from the bundled manifest", {
  # These sources are built locally by taxifydb and never redistributed, so a
  # manifest entry (which exists to point at a published asset) would be wrong.
  mf <- jsonlite::read_json(
    system.file("manifest_v3.json", package = "taxify"), simplifyVector = TRUE
  )
  for (nm in taxify:::.build_only_enrichments()) {
    expect_false(nm %in% names(mf$enrichments),
                 info = sprintf("build-only '%s' has a manifest entry", nm))
  }
})

test_that("build-only enrichments never report a version to download", {
  # check_enrichment_version() must short-circuit: with no manifest entry the
  # download path would error, and ensure_enrichment() would warn on every call.
  for (nm in taxify:::.build_only_enrichments()) {
    expect_false(taxify:::check_enrichment_version(nm))
  }
})


test_that("every grouped enrichment declares its group column in the manifest", {
  # enrichment_groups() and the grouped join need the group column name. It is
  # copied into meta.json at download time, so a manifest entry without it
  # leaves a freshly downloaded enrichment unable to report its own groups.
  # The set is taxifydb's build registry: the entries built with a group_col.
  grouped <- c(
    griis               = "country_code",
    gidias              = "affected_taxon",
    alien_first_records = "location",
    wcvp                = "tdwg_code",
    marine_distribution = "region_code",
    common_names        = "lang",
    glonaf              = "region_id"
  )

  mf <- jsonlite::read_json(
    system.file("manifest_v3.json", package = "taxify"), simplifyVector = TRUE
  )
  for (nm in names(grouped)) {
    entry <- mf$enrichments[[nm]]
    expect_false(is.null(entry),
                 info = sprintf("grouped enrichment '%s' has no manifest entry", nm))
    expect_identical(entry$group_col, unname(grouped[[nm]]),
                     info = sprintf("manifest group_col for '%s'", nm))
  }
})


test_that("enrichment_groups() recovers the group column from the manifest", {
  # An enrichment installed before the describing fields were copied into
  # meta.json has no local group_col. The manifest carries it, so the groups
  # must still resolve rather than reporting the enrichment as ungrouped.
  df <- data.frame(
    canonical_name = c("Acacia dealbata", "Acacia dealbata", "Pinus radiata"),
    country_code   = c("PT", "ZA", "PT"),
    is_invasive    = c(TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )
  install_mock_enrichment("griis", df)

  # Seed the session manifest cache from the bundled copy so the fallback is
  # exercised against known content rather than whatever GitHub is serving.
  env  <- taxify:::.taxify_env
  prev <- env$manifest
  env$manifest <- taxify:::local_manifest()
  withr::defer(env$manifest <- prev)

  groups <- enrichment_groups("griis", verbose = FALSE)

  expect_type(groups, "character")
  expect_true(length(groups) > 0L)
  expect_true(all(c("PT", "ZA") %in% groups))
})
