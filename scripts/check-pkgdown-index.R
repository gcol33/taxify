# Every documented topic is listed in the _pkgdown.yml reference index.
#
# pkgdown builds the reference index from the `reference:` block, and a topic
# absent from it aborts the whole site build. Nothing else notices: R CMD check
# does not read _pkgdown.yml, so a new exported function documents and tests
# clean and only fails months later, whenever the site is next built. That has
# happened twice, at ten and eight missing doors.
#
# `pkgdown::check_pkgdown()` is the same check the build runs, so this stays
# correct as pkgdown's rules change instead of restating them here.
#
# Usage (from the repository root):
#   Rscript scripts/check-pkgdown-index.R

if (!dir.exists("R")) stop("run this from the repository root", call. = FALSE)

pkgdown::check_pkgdown(".")
message("reference index is complete")
