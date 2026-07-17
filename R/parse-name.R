# ---- Name parsing: structured decomposition without matching ----
#
# taxify() cleans a name and matches it. parse_name() stops at the cleaning
# step and hands back the parts: genus, specific epithet, infraspecific rank +
# epithet, authorship, hybrid status, and any open-nomenclature qualifier. It is
# the door for callers who want the decomposition itself (the way
# rgbif::name_parse or gnparser do) rather than a backbone match. It reuses the
# same cleaning pipeline the matcher runs, so a name parses the way it matches.


# Infraspecific rank markers: qualifiers that name a rank below species, as
# opposed to the open-nomenclature qualifiers (cf./aff./sp./agg./s.l.). Kept as
# canonical tokens (the form clean_names() records in `qualifier`).
.infra_rank_markers <- c("subsp.", "var.", "f.", "subvar.", "subf.",
                         "convar.", "cv.", "pv.", "f.sp.")


#' Capture the authorship of a taxonomic name (vectorized)
#'
#' Returns the authorship string a name carries -- the part the cleaning
#' pipeline strips before matching. Uses the same parenthesized- and
#' trailing-author patterns as [clean_names()], so what this captures is exactly
#' what matching discards. Qualifiers (including infraspecific rank markers) and
#' hybrid signs are removed first so they are never mistaken for an author.
#'
#' Trailing authorship is captured (`(L.) H.Karst.`); an author interleaved
#' before an infraspecific marker (`Poa pratensis L. subsp. angustifolia`) is
#' not fully separated -- the trailing combination author wins. This is the
#' shape that distinguishes homonyms, which is what the authorship tiebreak in
#' matching needs.
#'
#' @param x Character vector of names.
#' @return Character vector of authorship strings; `NA` where none is present.
#' @noRd
parse_authorship_vec <- function(x) {
  n <- length(x)
  s <- trimws(as.character(x))
  na_in <- is.na(x) | !nzchar(s)

  # Normalize the multiplication-sign mojibake clean_one() also handles, then
  # drop hybrid signs so a nothotaxon marker is never read as an author.
  s <- gsub("\u00c3\u0097", "\u00d7", s, fixed = TRUE)
  s <- gsub("\u00c3\u2014", "\u00d7", s, fixed = TRUE)
  s <- gsub("\u00d7", " ", s, fixed = TRUE)
  s <- gsub("(^|\\s)[xX](\\s|$)", " ", s, perl = TRUE)

  # Leading determination prefix (Cf./Aff.) qualifies the genus, not an author.
  s <- sub("^(cf|aff)\\b\\.?\\s+", "", s, perl = TRUE, ignore.case = TRUE)

  # Strip every qualifier token (open-nomenclature + infraspecific rank
  # markers) so "var."/"subsp." are not seen as authors.
  for (mw in .concept_multiword) {
    s <- gsub(mw$pat, " ", s, perl = TRUE, ignore.case = TRUE)
  }
  s <- gsub(.qualifier_pattern, " ", s, perl = TRUE)
  s <- gsub("\\s+", " ", trimws(s))

  # Authorship is everything from the first token that is not a lowercase Latin
  # epithet: the genus (token 1) is skipped, epithets are all-lowercase, and the
  # first token carrying an uppercase letter, a period, a bracket, or "&" starts
  # the author citation. This captures multi-word and internal-capital authors
  # ("(L.) H.Karst.", "(Siebold & Zucc.) Carriere") that a single trailing-token
  # rule cannot. A trailing author interleaved before an infraspecific marker is
  # the known limit (documented in the roxygen).
  is_epithet <- function(tok) grepl("^[a-z\u00df-\u00ff-]+$", tok)
  out <- vapply(seq_len(n), function(i) {
    if (na_in[i]) return(NA_character_)
    toks <- strsplit(s[i], " ", fixed = TRUE)[[1L]]
    toks <- toks[nzchar(toks)]
    if (length(toks) < 2L) return(NA_character_)
    start <- NA_integer_
    for (j in 2:length(toks)) {
      if (!is_epithet(toks[j])) { start <- j; break }
    }
    if (is.na(start)) return(NA_character_)
    paste(toks[start:length(toks)], collapse = " ")
  }, character(1L))
  out
}


#' Normalize an authorship string for comparison
#'
#' Folds the spelling latitude of author citations to a comparison key:
#' lowercased, diacritics stripped, and spaces / periods removed, so `"L."`,
#' `"L"`, and `"l."` all compare equal, and `"(Siebold & Zucc.) Carriere"`
#' becomes `"(siebold&zucc)carriere"`. Used by the authorship tiebreak.
#'
#' @param x Character vector of authorship strings.
#' @return Character vector of comparison keys (`NA` in, `NA` out).
#' @noRd
normalize_authorship <- function(x) {
  y <- .strip_accents(tolower(trimws(as.character(x))))
  y <- gsub("[. ]", "", y)
  y[is.na(x) | !nzchar(y)] <- NA_character_
  y
}


#' Parse taxonomic names into their structural parts
#'
#' Decomposes each name into genus, specific epithet, infraspecific rank and
#' epithet, authorship, hybrid status, and any open-nomenclature qualifier,
#' without matching against a backbone. Where [taxify()] cleans a name and then
#' resolves it, `parse_name()` returns the cleaning step itself -- the parts of
#' the name -- for callers who need the decomposition rather than a match (the
#' role `rgbif::name_parse()` or gnparser fill). The same cleaning pipeline the
#' matcher uses drives the parse, so a name breaks apart the way it matches.
#'
#' @param x Character vector of taxonomic names.
#'
#' @return A data.frame with one row per input name and columns:
#' \describe{
#'   \item{input}{The original name as supplied.}
#'   \item{genus}{The genus (first token), or a single-letter initial for an
#'     abbreviated genus (`"Q. robur"`). `NA` for an unresolvable hybrid
#'     formula.}
#'   \item{specific_epithet}{The specific epithet, or `NA` for a bare genus.}
#'   \item{infrasp_rank}{The infraspecific rank marker (`"subsp."`, `"var."`,
#'     `"f."`, ...) when the name has one, else `NA`.}
#'   \item{infrasp_epithet}{The infraspecific epithet, else `NA`.}
#'   \item{authorship}{The authorship the name carries (trailing form, e.g.
#'     `"(L.) H.Karst."`), or `NA`.}
#'   \item{qualifier}{Any open-nomenclature / uncertainty qualifier (`"cf."`,
#'     `"aff."`, `"sp."`, `"agg."`, `"s.l."`, ...), canonicalized, or `NA`.
#'     Infraspecific rank markers are reported in `infrasp_rank`, not here.}
#'   \item{is_hybrid}{Logical. Was a hybrid marker detected?}
#'   \item{hybrid_type}{`"nothogenus"`, `"nothospecies"`, `"formula"`, or `NA`.}
#'   \item{rank}{`"genus"`, `"species"`, `"infraspecies"`, `"hybrid_formula"`,
#'     or `NA` for an empty input.}
#'   \item{canonical}{The cleaned name used for matching (genus plus epithets,
#'     qualifiers and authorship removed, hybrid sign dropped). `NA` for a
#'     hybrid formula, which is not a single taxon.}
#' }
#'
#' @seealso [taxify()] to match a name; `parse_name()` exposes the same internal
#'   cleaning pipeline the matcher runs.
#'
#' @examples
#' parse_name(c("Quercus robur L.",
#'              "Poa annua var. annua",
#'              "Q. robur",
#'              "Pinus cf. sylvestris",
#'              "Salix alba x Salix fragilis"))
#'
#' @export
parse_name <- function(x) {
  if (!is.character(x)) {
    stop("x must be a character vector.", call. = FALSE)
  }
  n <- length(x)
  empty <- data.frame(
    input = character(0L), genus = character(0L),
    specific_epithet = character(0L), infrasp_rank = character(0L),
    infrasp_epithet = character(0L), authorship = character(0L),
    qualifier = character(0L), is_hybrid = logical(0L),
    hybrid_type = character(0L), rank = character(0L),
    canonical = character(0L), stringsAsFactors = FALSE
  )
  if (n == 0L) return(empty)

  cl   <- clean_names(x)
  auth <- parse_authorship_vec(x)
  canon <- cl$cleaned

  is_infra <- !is.na(cl$qualifier) & cl$qualifier %in% .infra_rank_markers

  # Token split of the canonical (matching) form.
  tok  <- strsplit(ifelse(is.na(canon), "", canon), " ", fixed = TRUE)
  ntok <- lengths(tok)
  pick <- function(k) vapply(tok, function(t)
    if (length(t) >= k && nzchar(t[k])) t[k] else NA_character_, character(1L))
  genus <- pick(1L)
  tok2  <- pick(2L)
  tok3  <- pick(3L)

  specific_epithet <- ifelse(ntok >= 2L, tok2, NA_character_)
  infrasp_epithet  <- ifelse(is_infra & ntok >= 3L, tok3, NA_character_)
  infrasp_rank     <- ifelse(is_infra, cl$qualifier, NA_character_)
  # Open-nomenclature qualifier is everything that is not a rank marker.
  qualifier <- ifelse(is_infra, NA_character_, cl$qualifier)

  is_formula <- !is.na(cl$hybrid_type) & cl$hybrid_type == "formula"
  # A two-parent cross is not a single taxon; its author "citation" is spurious.
  auth[is_formula] <- NA_character_
  rank <- rep(NA_character_, n)
  rank[!is.na(canon) & ntok == 1L] <- "genus"
  rank[!is.na(canon) & ntok >= 2L & !is_infra] <- "species"
  rank[is_infra] <- "infraspecies"
  rank[is_formula] <- "hybrid_formula"
  # A genus-only qualifier collapse (e.g. "Quercus sp.") is a genus.
  rank[cl$genus_only] <- "genus"

  data.frame(
    input            = x,
    genus            = genus,
    specific_epithet = specific_epithet,
    infrasp_rank     = infrasp_rank,
    infrasp_epithet  = infrasp_epithet,
    authorship       = auth,
    qualifier        = qualifier,
    is_hybrid        = cl$is_hybrid,
    hybrid_type      = cl$hybrid_type,
    rank             = rank,
    canonical        = canon,
    stringsAsFactors = FALSE
  )
}
