# ---- Syntaxon names (phytosociological nomenclature) ----
#
# A syntaxon is a vegetation unit: a class (Molinio-Arrhenatheretea), order
# (Arrhenatheretalia elatioris), alliance (Arrhenatherion elatioris),
# suballiance, association or subassociation. Its name is governed by the
# International Code of Phytosociological Nomenclature (ICPN; Theurillat et al.
# 2021), not by the botanical code: it is built from one or two plant names in
# the genitive, the last carrying a rank suffix (-etea, -etalia, -ion, -etum,
# ...), and it has no genus/epithet structure. Its author citation carries a
# year and its own vocabulary (`(Neuhausl 1959) Oberd. et al. 1967`,
# `Tx. 1937 corr. Gutermann et Mucina 1993`, `nom. inval. (3b)`).
#
# This file holds the syntaxon side of the name pipeline: the parse that splits
# a written syntaxon into name, author citation and annotations, the
# normalization key the matcher looks names up by, and the rank a name's suffix
# denotes. The matching engine itself is shared with taxon names
# (R/backend.R); R/nomenclature-codes.R decides which pipeline a backbone uses.


# Rank suffixes of the ICPN (Art. 10 and Appendix I), longest first so
# "-etalia" is tested before "-etea" could match it and "-enion" before "-ion".
.syntaxon_rank_suffixes <- c(
  enalia = "suborder",
  etalia = "order",
  enea   = "subclass",
  etea   = "class",
  enion  = "suballiance",
  ion    = "alliance",
  etum   = "association"
)

# Ranks of the hierarchy, broadest first. A syntaxon backbone carries one
# column per rank it covers, holding the accepted unit's ancestor at that rank.
.syntaxon_ranks <- c("class", "subclass", "order", "suborder", "alliance",
                     "suballiance", "association", "subassociation")

# Lowercase words that start an author citation rather than continue a name:
# name particles (de Foucault, di Pietro, van der Maarel), the connecting words
# of a citation (et, ex, in, apud, em.), and the nomenclatural vocabulary
# (nom. inval., corr., mut., ined., auct., sensu). A syntaxon name never
# contains one of them as a whole word.
.syntaxon_author_particles <- c(
  "de", "del", "della", "delle", "dei", "degli", "di", "da", "do", "dos",
  "das", "du", "des", "la", "le", "lo", "van", "von", "der", "den", "ten",
  "ter", "zu", "zur", "y", "e", "et", "ex", "in", "ap", "apud", "em", "emend",
  "corr", "mut", "nom", "prov", "ined", "nud", "inval", "illeg", "auct",
  "non", "nec", "sensu", "pro", "fide", "sec", "sub", "ad", "and", "al", "ms",
  "mscr", "ass", "all", "ord", "cl", "comb", "stat", "nov", "orig"
)

# A word that can continue a syntaxon name after its first word: a lowercase
# Latin word (the genitive epithet, "sylvaticae"), possibly hyphenated into the
# next plant-name stem ("rupestris-Kobresietea", "non-scripti-Fagion"). No
# period, digit or bracket, which mark an author citation.
.syntaxon_name_word <- paste0(
  "^[a-z\u00df-\u00ff][a-z\u00df-\u00ff']*",
  "(-[A-Za-z\u00c0-\u00ff][a-z\u00df-\u00ff']*)*$")

# The first word of a syntaxon name: letters joined by hyphens
# ("Molinio-Arrhenatheretea", "Eu-Fagion").
.syntaxon_first_word <- "^[A-Za-z\u00c0-\u00ff][A-Za-z\u00c0-\u00ff']*(-[A-Za-z\u00c0-\u00ff']+)*$"

# Nomenclatural annotations a source appends after the author citation. They
# say something about the name's standing, not who published it, so they are
# reported apart from `authorship`. Matched at the end of the citation,
# repeatedly, so "Golub et al. 2003 nom. inval. (5a)" leaves the author only.
.syntaxon_status_patterns <- c(
  "nom\\.\\s*(inval|illeg|nud|ambig|dub|rej|rejic|cons|superfl|conserv)\\.?(\\s*propos\\.?)?",
  "nom\\.\\s*(corr|mut)\\.",
  "\\((syntax\\.\\s*syn|phantom|fantom|pseudonym|nom\\.[^)]*|nomen [a-z]+|[0-9]+[a-z]?(\\s*,\\s*[0-9]+[a-z]?)*)\\.?\\)",
  "\\(\\s*(\u00a7|par\\.)[^)]*\\)",
  "\\((Ordo|Order|Class|Classis|Cl\\.|All\\.|Alliance|Association|Ass\\.|Regionalverband|Zentralverband)\\)",
  "ined\\.", "prov\\.", "p\\.\\s*p\\.",
  "(sensu\\s+)?auct\\.(\\s+[a-z]+\\.)*(\\s+non\\b.*)?"
)


#' Rank a syntaxon name's suffix denotes
#'
#' Reads the rank from the last plant-name stem of the name (the stem after the
#' last hyphen of the last capitalized word segment: `Fagion` in
#' `Endymio non-scripti-Fagion`, `Kobresietea` in `Carici rupestris-Kobresietea
#' bellardii`). A trailing lowercase word ending in `-etosum` makes the name a
#' subassociation.
#'
#' @param name Character vector of syntaxon names (no author).
#' @return Character vector of ranks (`"class"`, `"order"`, `"alliance"`, ...),
#'   `NA` where no suffix is recognised.
#' @noRd
syntaxon_rank_of <- function(name) {
  out <- rep(NA_character_, length(name))
  ok <- !is.na(name) & nzchar(name)
  if (!any(ok)) return(out)
  out[ok] <- vapply(name[ok], function(nm) {
    words <- strsplit(nm, " ", fixed = TRUE)[[1L]]
    if (length(words) > 1L &&
        grepl("etosum$", words[length(words)], ignore.case = TRUE) &&
        !grepl("^[A-Z]", words[length(words)])) {
      return("subassociation")
    }
    segs <- unlist(strsplit(words, "-", fixed = TRUE), use.names = FALSE)
    stems <- segs[grepl("^[A-Z\u00c0-\u00de]", segs)]
    if (length(stems) == 0L) stems <- segs[1L]
    stem <- tolower(stems[length(stems)])
    for (suf in names(.syntaxon_rank_suffixes)) {
      if (endsWith(stem, suf) && nchar(stem) > nchar(suf) + 1L) {
        return(unname(.syntaxon_rank_suffixes[[suf]]))
      }
    }
    NA_character_
  }, character(1L), USE.NAMES = FALSE)
  out
}


#' Title-case a syntaxon name written in capitals
#'
#' `AVENULO-AMPELODESMION MAURITANICI` -> `Avenulo-Ampelodesmion mauritanici`:
#' the first word capitalized at each hyphen-joined stem, the rest lowercase.
#' @noRd
title_case_syntaxon <- function(words) {
  w <- tolower(words)
  first <- strsplit(w[1L], "-", fixed = TRUE)[[1L]]
  w[1L] <- paste0(toupper(substr(first, 1L, 1L)), substring(first, 2L),
                  collapse = "-")
  w
}


# Rank labels a record writes in front of a unit ("all. Xanthorion parietinae",
# "Ord. Leucodontetalia", "suball. Aceri tatarici-Carpinenion"), mapped to
# the rank they name.
.syntaxon_rank_labels <- c(
  cl = "class", class = "class", classis = "class",
  ord = "order", orde = "order", order = "order", ordo = "order",
  all = "alliance", alliance = "alliance",
  suball = "suballiance", suballiance = "suballiance",
  ass = "association", association = "association"
)

# A rank label as its own token, followed by a capitalized name.
.syntaxon_label_pattern <- paste0(
  "(?i)(?:^|[,;]?\\s+)(", paste(names(.syntaxon_rank_labels), collapse = "|"),
  ")\\.?:?\\s+(?=[A-Z\u00c0-\u00de])")

# Windows-1252 renderings of CP850 letters: a record written in a DOS code
# page and read as Windows-1252 (Turboveg exports: "Iso\u2030tion" for
# Isoetion with a diaeresis, "G\u201ahu" for Gehu with an acute). Only the
# glyphs that never occur in a syntaxon name or an author citation are mapped;
# the others of the C1 range are letters and punctuation in their own right
# (the oe ligature of Boeuf, the S caron of Smarda, quotation marks).
.cp850_via_cp1252 <- c(
  "\u201a" = "\u00e9", "\u0192" = "\u00e2", "\u201e" = "\u00e4",
  "\u2026" = "\u00e0", "\u2020" = "\u00e5", "\u2021" = "\u00e7",
  "\u02c6" = "\u00ea", "\u2030" = "\u00eb", "\u2039" = "\u00ef",
  "\u203a" = "\u00f8", "\u02dc" = "\u00ff", "\u2122" = "\u00d6"
)

#' Undo a DOS code page read as Windows-1252 in a syntaxon record
#' @noRd
repair_cp850 <- function(s) {
  if (is.na(s)) return(s)
  for (g in names(.cp850_via_cp1252)) {
    if (grepl(g, s, fixed = TRUE)) {
      s <- gsub(g, .cp850_via_cp1252[[g]], s, fixed = TRUE)
    }
  }
  s
}

#' Split a record naming several units into its labelled parts
#'
#' "all. Caloplacion pyraceae, ord. Xeroverrucarietalia, cl. Epipetretea
#' lichenosa" names a unit at each rank; the most specific one is the record's
#' assignment (the broader ones follow from it). Returns the chosen part, or
#' the string unchanged when it carries no rank label.
#' @noRd
pick_labelled_unit <- function(s) {
  starts <- gregexpr(.syntaxon_label_pattern, s, perl = TRUE)[[1L]]
  if (starts[1L] == -1L) return(s)
  cs <- attr(starts, "capture.start")[, 1L]
  cl <- attr(starts, "capture.length")[, 1L]
  labels <- tolower(substring(s, cs, cs + cl - 1L))
  ends <- c(starts[-1L] - 1L, nchar(s))
  bodies <- trimws(substring(s, starts + attr(starts, "match.length"), ends))
  bodies <- sub("[,;]\\s*$", "", bodies)
  ranks <- unname(.syntaxon_rank_labels[labels])
  # Text before the first label is a unit too ("Epiphytetea, ord. ...").
  if (starts[1L] > 1L) {
    lead <- sub("[,;]\\s*$", "", trimws(substring(s, 1L, starts[1L] - 1L)))
    if (nzchar(lead)) {
      bodies <- c(lead, bodies)
      ranks <- c(NA_character_, ranks)
    }
  }
  ranks[is.na(ranks)] <- syntaxon_rank_of(sub(" .*$", "", bodies[is.na(ranks)]))
  depth <- match(ranks, .syntaxon_ranks)
  if (all(is.na(depth))) return(bodies[1L])
  bodies[which.max(replace(depth, is.na(depth), 0L))]
}


#' Parse one written syntaxon into name, author citation and annotations
#'
#' @param s A single, already trimmed string.
#' @return A list of `code`, `name`, `authorship`, `qualifier`, `name_status`.
#' @noRd
parse_syntaxon_one <- function(s) {
  out <- list(code = NA_character_, name = NA_character_,
              authorship = NA_character_, qualifier = NA_character_,
              name_status = NA_character_)
  if (is.na(s) || !nzchar(s) ||
      toupper(s) %in% c("NA", "N/A", "[NA]", "-", ".", "?")) return(out)
  s <- repair_cp850(s)

  # A national code in front of the name: "25   - Molinio-Arrhenatheretea",
  # "TDA - Arrhenatherion elatioris", "41BB03 - Tilio-Carpinetum",
  # "3.4.1. Fagion". The prefix is a code when it carries a digit or is a short
  # all-capital token; "Thero - Suaedion" is a name written with a spaced
  # hyphen and keeps its first word.
  m <- regmatches(s, regexec("^(\\S+(?: \\S{1,3})?)\\s+-\\s+(.+)$", s))[[1L]]
  if (length(m) == 3L &&
      (grepl("[0-9]", m[2L]) || grepl("^[A-Z]{1,5}$", m[2L]))) {
    out$code <- m[2L]
    s <- m[3L]
  } else if (grepl("^[0-9][0-9.]*\\.?\\s+\\S", s)) {
    out$code <- sub("\\s.*$", "", s)
    s <- sub("^\\S+\\s+", "", s)
  }

  # Several units in one record: labelled by rank, the most specific; written
  # side by side ("X-Fagion sylvaticae / Y-Fagenion sylvaticae", "Fagion;
  # Luzulo-Fagion"), the first one, which the record is filed under.
  s <- pick_labelled_unit(s)
  s <- sub("\\s+/\\s+.*$", "", s)
  s <- sub("\\s*;.*$", "", s)

  # A suffix variant written into the word: "Quercetalia(-etea) ilicis".
  s <- gsub("([a-z])\\(-?[a-z]{1,8}\\)", "\\1", s)
  # The infraspecific epithet of the plant a stem is named after is not part
  # of the syntaxon name: "Molinio caeruleae subsp. caeruleae-Rhynchosporion
  # albae" is Molinio caeruleae-Rhynchosporion albae.
  s <- gsub("\\s(subsp|ssp|var)\\.?\\s[a-z]+(?=-[A-Z]|\\s|$)", "", s,
            perl = TRUE)

  # Leading determination prefix.
  if (grepl("^(cf|aff)\\.?\\s+", s, ignore.case = TRUE)) {
    out$qualifier <- canon_qualifier(sub("^(\\S+).*$", "\\1", s))
    s <- sub("^\\S+\\s+", "", s)
  }

  # A spaced hyphen joins two stems of one name ("Thero - Suaedion",
  # "Rhinantho rumelici -Festucetum").
  s <- gsub("\\s*-\\s*", "-", s)
  s <- gsub("\\s+", " ", trimws(s))

  # A question mark records doubt about the assignment, not part of the name.
  if (grepl("?", s, fixed = TRUE)) {
    out$qualifier <- out$qualifier %|na|% "?"
    s <- trimws(gsub("?", "", s, fixed = TRUE))
  }

  toks <- strsplit(s, " ", fixed = TRUE)[[1L]]
  toks <- toks[nzchar(toks)]
  if (length(toks) == 0L) return(out)

  # All-capital names: lowercase the leading capitalized words so the
  # name/author boundary below reads them by their case like any other name.
  caps <- grepl("^[A-Z\u00c0-\u00de][A-Z\u00c0-\u00de'-]+$", toks)
  if (caps[1L] && nchar(gsub("-", "", toks[1L])) >= 3L) {
    k <- 1L
    while (k < length(toks) && caps[k + 1L]) k <- k + 1L
    toks[seq_len(k)] <- title_case_syntaxon(toks[seq_len(k)])
  }

  # The name runs to the first word that cannot continue it. A comma straight
  # after a name word ends a list of units ("Saxifrago-Fagenion,
  # Aremonio-Fagion"), so the name stops there and the rest is dropped.
  first <- toks[1L]
  listed <- grepl(",$", first)
  first <- sub(",$", "", first)
  if (!grepl(.syntaxon_first_word, first, perl = TRUE)) return(out)
  substr(first, 1L, 1L) <- toupper(substr(first, 1L, 1L))
  k <- 1L
  while (!listed && k < length(toks)) {
    nxt <- toks[k + 1L]
    bare <- sub(",$", "", nxt)
    if (!grepl(.syntaxon_name_word, bare, perl = TRUE) ||
        tolower(bare) %in% .syntaxon_author_particles) break
    k <- k + 1L
    if (bare != nxt) {
      toks[k] <- bare
      listed <- TRUE
    }
  }
  words <- c(first, toks[seq_len(k)[-1L]])
  # A last stem written apart and in lowercase ("Luzulo fagion") is the
  # rank-bearing part of the first word.
  nw <- length(words)
  if (nw >= 2L && is.na(syntaxon_rank_of(words[1L])) &&
      !is.na(syntaxon_rank_of(words[nw])) && grepl("^[a-z]", words[nw]) &&
      !grepl("-", words[nw], fixed = TRUE)) {
    stem <- words[nw]
    substr(stem, 1L, 1L) <- toupper(substr(stem, 1L, 1L))
    words <- c(words[seq_len(nw - 2L)], paste0(words[nw - 1L], "-", stem))
  }
  out$name <- paste(words, collapse = " ")
  if (listed) return(out)

  if (k < length(toks)) {
    auth <- paste(toks[(k + 1L):length(toks)], collapse = " ")
    status <- character(0L)
    repeat {
      hit <- FALSE
      for (p in .syntaxon_status_patterns) {
        re <- paste0("\\s*,?\\s*(", p, ")\\s*$")
        mm <- regmatches(auth, regexec(re, auth, perl = TRUE))[[1L]]
        if (length(mm) && nzchar(mm[1L])) {
          status <- c(trimws(mm[2L]), status)
          auth <- trimws(substr(auth, 1L, nchar(auth) - nchar(mm[1L])))
          hit <- TRUE
          break
        }
      }
      if (!hit || !nzchar(auth)) break
    }
    # Sensu lato / stricto are qualifiers on the concept.
    for (mw in .concept_multiword[1:2]) {
      if (grepl(mw$pat, auth, perl = TRUE, ignore.case = TRUE)) {
        out$qualifier <- out$qualifier %|na|% mw$canon
        auth <- trimws(gsub(mw$pat, "", auth, perl = TRUE, ignore.case = TRUE))
      }
    }
    auth <- sub("[,;]+$", "", trimws(auth))
    # A parenthesis the citation closes or opens without its partner is left
    # over from the source's own punctuation around the name.
    open_n  <- lengths(regmatches(auth, gregexpr("(", auth, fixed = TRUE)))
    close_n <- lengths(regmatches(auth, gregexpr(")", auth, fixed = TRUE)))
    if (close_n > open_n) auth <- trimws(sub("^\\)\\s*|\\)$", "", auth))
    if (open_n > close_n) auth <- trimws(sub("\\($", "", auth))
    if (nzchar(auth)) out$authorship <- auth
    if (length(status)) out$name_status <- paste(status, collapse = " ")
  }
  out
}


# `a` unless it is NA, else `b`.
`%|na|%` <- function(a, b) if (is.na(a)) b else a


#' Syntaxon name key for lookup across spelling variants
#'
#' Folds the variation syntaxon names are written with to one key, applied the
#' same way to the backbone at build time and to the query at match time:
#' lowercase, diacritics stripped, spaces around hyphens removed, and the Latin
#' orthographic alternations of [normalize_epithets()] applied to every word
#' (a syntaxon's first word is a Latin stem as much as its epithet is), so
#' `Fagion silvaticae` and `Fagion sylvaticae`, or `Juncion gerardi` and
#' `Juncion gerardii`, share a key.
#'
#' @param x Character vector of syntaxon names (no author).
#' @return Character vector of keys; `NA` in, `NA` out.
#' @keywords internal
#' @export
#' @examples
#' normalize_syntaxon_name(c("Fagion silvaticae", "Fagion sylvaticae",
#'                           "Thero - Suaedion"))
normalize_syntaxon_name <- function(x) {
  y <- .strip_accents(tolower(as.character(x)))
  y <- gsub("\\s*-\\s*", "-", y)
  y <- gsub("\\s+", " ", trimws(y))
  y <- latin_orthography(y)
  y[is.na(x)] <- NA_character_
  y
}


#' Clean syntaxon names for matching
#'
#' The syntaxon counterpart of `clean_names()`: one row per input with the
#' columns the shared matching engine reads. The taxon-only flags (hybrid,
#' aggregate, genus-only, abbreviated genus) are constant, since a syntaxon has
#' none of that structure; the parse adds `authorship` (read by the authorship
#' tiebreak) and `syntaxon_rank` (read by the fuzzy rank filter).
#'
#' @param x Character vector of syntaxon names as written.
#' @return A data.frame in the `clean_names()` shape plus `authorship` and
#'   `syntaxon_rank`.
#' @noRd
clean_syntaxon_names <- function(x) {
  p <- parse_syntaxon(x)
  n <- length(x)
  data.frame(
    original           = x,
    cleaned            = p$name,
    is_hybrid          = rep(FALSE, n),
    hybrid_type        = rep(NA_character_, n),
    qualifier          = p$qualifier,
    qualifier_position = ifelse(is.na(p$qualifier), NA_character_, "name"),
    infra_rank         = rep(NA_character_, n),
    is_aggregate       = rep(FALSE, n),
    genus_only         = rep(FALSE, n),
    hybrid_name        = rep(NA_character_, n),
    genus_abbrev       = rep(FALSE, n),
    authorship         = p$authorship,
    syntaxon_rank      = p$rank,
    stringsAsFactors   = FALSE
  )
}


#' Parse syntaxon names (phytosociological nomenclature)
#'
#' The syntaxon branch of [parse_name()]: splits each written vegetation-unit
#' name into the name itself, its author citation and the annotations a source
#' appends, and reads the rank from the name's suffix.
#'
#' @param x Character vector of syntaxon names.
#' @return A data.frame; see [parse_name()].
#' @noRd
parse_syntaxon <- function(x) {
  parts <- lapply(trimws(as.character(x)), parse_syntaxon_one)
  pick <- function(f) vapply(parts, function(p) p[[f]], character(1L))
  name <- pick("name")
  data.frame(
    input_name  = x,
    code        = pick("code"),
    name        = name,
    authorship  = pick("authorship"),
    rank        = syntaxon_rank_of(name),
    qualifier   = pick("qualifier"),
    name_status = pick("name_status"),
    stringsAsFactors = FALSE
  )
}


# ---- Syntaxon structure: stems and epithets ----
#
# A syntaxon name is a sequence of plant-name stems, each optionally followed
# by the epithet of that plant: "Carici rupestris-Kobresietea bellardii" is
# Carici (rupestris) + Kobresietea (bellardii); "Asparago albi-Rhamnion
# oleoidis" is Asparago (albi) + Rhamnion (oleoidis). The stems carry the
# identity of the unit, the epithets narrow the plant names, and writing a
# unit without its epithets ("Cynosurion" for Cynosurion cristati) is the
# standard short form.

#' Split syntaxon names into their stems and epithets
#'
#' @param name Character vector of syntaxon names (no author).
#' @return A list, one element per name: a list of `stems` (character) and
#'   `epithets` (character, the same length, `NA` where a stem has none).
#' @noRd
syntaxon_groups <- function(name) {
  lapply(name, function(nm) {
    if (is.na(nm) || !nzchar(nm)) return(list(stems = character(0L),
                                             epithets = character(0L)))
    segs <- unlist(strsplit(strsplit(nm, " ", fixed = TRUE)[[1L]], "-",
                            fixed = TRUE), use.names = FALSE)
    segs <- segs[nzchar(segs)]
    stem <- grepl("^[A-Z\u00c0-\u00de]", segs)
    stem[1L] <- TRUE
    grp <- cumsum(stem)
    stems <- segs[stem]
    epithets <- vapply(seq_along(stems), function(g) {
      e <- segs[grp == g & !stem]
      if (length(e)) paste(e, collapse = " ") else NA_character_
    }, character(1L))
    list(stems = stems, epithets = epithets)
  })
}


#' Key of a syntaxon name's stems, epithets dropped
#'
#' The stems normalized and joined without separator, so the short form
#' (`Cynosurion`), the full name (`Cynosurion cristati`) and a spelling that
#' joins or splits a stem (`Magno-Caricion`, `Magnocaricion`) share a key.
#'
#' @param name Character vector of syntaxon names.
#' @return Character vector of keys, `NA` where the name is missing.
#' @noRd
syntaxon_stem_key <- function(name) {
  vapply(syntaxon_groups(name), function(g) {
    if (!length(g$stems)) return(NA_character_)
    normalize_syntaxon_name(paste(g$stems, collapse = ""))
  }, character(1L))
}


#' Whether two syntaxon names agree on their epithets
#'
#' Positionally, stem by stem. Two written epithets agree when their
#' normalized forms are equal, or, with `max_dist`, when they are close
#' (`parts_close()`). Where a name omits an epithet, `omit` says which side
#' may do so: `"either"`, `"a"` (`a` writes no epithet `b` lacks) or `"b"`.
#'
#' @param a,b Character vectors of syntaxon names, parallel.
#' @param max_dist `NULL` for equality, else the largest normalized distance.
#' @param omit Which name may omit an epithet the other writes.
#' @return Logical vector.
#' @noRd
syntaxon_epithets_agree <- function(a, b, max_dist = NULL,
                                    omit = c("either", "a", "b")) {
  omit <- match.arg(omit)
  ga <- syntaxon_groups(a)
  gb <- syntaxon_groups(b)
  vapply(seq_along(ga), function(i) {
    ea <- ga[[i]]$epithets
    eb <- gb[[i]]$epithets
    if (length(ea) != length(eb)) {
      # Stems joined on one side only: only the last stem's epithets line up.
      ea <- utils::tail(ea, 1L)
      eb <- utils::tail(eb, 1L)
    }
    if (omit == "a" && any(!is.na(ea) & is.na(eb))) return(FALSE)
    if (omit == "b" && any(is.na(ea) & !is.na(eb))) return(FALSE)
    both <- !is.na(ea) & !is.na(eb)
    if (!any(both)) return(TRUE)
    x <- normalize_syntaxon_name(ea[both])
    y <- normalize_syntaxon_name(eb[both])
    if (is.null(max_dist)) return(all(x == y))
    all(parts_close(x, y, max_dist))
  }, logical(1L))
}


#' Whether two name parts are one part misspelt, element-wise
#'
#' Within `max_dist`, and either a single edit apart or starting with the
#' same three letters. The prefix is what separates a misspelling from a
#' different plant once two letters differ: a misspelt stem or epithet keeps
#' its opening (`Puccinelion`, `cerris` for cerridis), while two species of
#' one genus can be as few edits apart and differ there (`callosae` and
#' `camposii`, two letters in seven; the stems `Piceion` and `Pinion`). One
#' edit is a typo wherever it falls (`narturtii` for nasturtii).
#'
#' @param x,y Normalized parts, parallel.
#' @param max_dist Largest normalized edit distance.
#' @return Logical vector.
#' @noRd
parts_close <- function(x, y, max_dist) {
  edits <- vapply(seq_along(x), function(i) {
    as.numeric(utils::adist(x[i], y[i]))
  }, numeric(1L))
  edits / pmax(nchar(x), nchar(y), 1L) <= max_dist &
    (edits <= 1 | substr(x, 1L, 3L) == substr(y, 1L, 3L))
}


#' Edit distance divided by the longer string's length, element-wise
#' @noRd
normalized_edit_distance <- function(x, y) {
  d <- vapply(seq_along(x), function(i) {
    as.numeric(utils::adist(x[i], y[i]))
  }, numeric(1L))
  d / pmax(nchar(x), nchar(y), 1L)
}


# Largest normalized edit distance between two corresponding stems, or two
# corresponding epithets, in a fuzzy syntaxon match. A misspelt stem stays
# within it (Phyteumo- for Phyteumato-, Puccinelion for Puccinellion); a
# different plant (Vaccinio-Piceion vs Vaccinio-Pinion, Erico- vs
# Eriophoro-) does not.
.syntaxon_part_max_dist <- 0.25
.syntaxon_epithet_max_dist <- 0.3


#' Keep fuzzy candidates that are the query's unit misspelt
#'
#' Two filters, both drawn from a syntaxon's structure. The rank is written
#' into the suffix, so a candidate at another rank is dropped: `Caricenion
#' gracilis` (a suballiance) is two edits from `Caricion gracilis` (an
#' alliance), and a cross-rank match would silently roll a unit up or down
#' the hierarchy. And a whole-name distance lets a long name absorb a
#' different plant stem (`Vaccinio-Piceion` is two edits from
#' `Vaccinio-Pinion`, a different alliance), so every stem, and every epithet
#' both names write, must also be close to its counterpart. Where the query's
#' rank is unknown the rank filter keeps the candidate. Where the query's
#' suffix gives a rank, a candidate whose name carries no rank suffix is
#' dropped: `Deschampsietum caespitosae` (an association) is two edits from
#' `Deschampsiosum cespitosae`, a name not built on any rank suffix.
#'
#' @param matches `fuzzy_join()` output with `row_idx` and the backbone name.
#' @param names_df The cleaned-names frame (carries `syntaxon_rank`).
#' @param name_col The backbone name column.
#' @return `matches` without the ruled-out candidates.
#' @noRd
filter_fuzzy_syntaxon <- function(matches, names_df, name_col) {
  if (nrow(matches) == 0L) return(matches)
  query <- names_df$cleaned[matches$row_idx]
  cand  <- matches[[name_col]]

  q <- names_df$syntaxon_rank %||% rep(NA_character_, nrow(names_df))
  q <- q[matches$row_idx]
  b <- syntaxon_rank_of(cand)
  keep <- is.na(q) | (!is.na(b) & q == b)

  gq <- syntaxon_groups(query)
  gc <- syntaxon_groups(cand)
  stems_close <- vapply(seq_along(gq), function(i) {
    sq <- normalize_syntaxon_name(gq[[i]]$stems)
    sc <- normalize_syntaxon_name(gc[[i]]$stems)
    if (length(sq) != length(sc)) {
      sq <- paste(sq, collapse = "")
      sc <- paste(sc, collapse = "")
    }
    all(parts_close(sq, sc, .syntaxon_part_max_dist))
  }, logical(1L))
  keep <- keep & stems_close &
    syntaxon_epithets_agree(query, cand, .syntaxon_epithet_max_dist)
  matches[keep, , drop = FALSE]
}


#' Resolve a syntaxon written with fewer or more epithets than the backbone
#'
#' Vegetation data write a unit without its epithets as a matter of course
#' (`Cynosurion` for Cynosurion cristati, `Dicrano-Pinion` for
#' Dicrano-Pinion sylvestris, `Luzulo-Fagion` for Luzulo-Fagion sylvaticae),
#' and sometimes with more than the backbone records (`Luzulo
#' luzuloidis-Fagion sylvaticae`). The exact passes miss both, and a fuzzy
#' pass would only reach them by spending its whole distance budget on the
#' missing words. This stage looks the name up by its stems (`key_stem`) and
#' keeps the candidates at the query's rank whose epithets agree with every
#' epithet both names write.
#'
#' It runs once per direction. Before the fuzzy pass it accepts only a query
#' that omits epithets the backbone name writes (`query_shorter = TRUE`): a
#' short form names the unit, and no fuzzy candidate is closer. After it, it
#' accepts a query writing epithets the backbone name omits: such a query may
#' be a misspelling of a full name the backbone holds (`Puccinellion
#' phryganoidis` for Puccinellion phryganodis), which the fuzzy pass must reach
#' before the bare `Puccinellion` (a synonym of another alliance) is
#' considered.
#'
#' A stem key can name more than one unit (`Carpinion` is the stem of both
#' Carpinion betuli and Carpinion orientalis). An author the query carries
#' then chooses among them; when it does not single one out, the row is left
#' unresolved with the candidate accepted IDs in `accepted_ids` and their
#' number in `n_ids`, rather than guessing, as the abbreviated-genus stage
#' does for taxon names. A resolved row is labelled `match_type =
#' "short_name"`.
#'
#' @param backend A syntaxon `taxify_backend`.
#' @param result The match result data.frame.
#' @param names_df The cleaned-names frame.
#' @param vtr_path Path to the backbone `.vtr`.
#' @param query_shorter Logical. `TRUE` accepts only a query omitting
#'   epithets; `FALSE` only a backbone name omitting them.
#' @return `result`, updated.
#' @noRd
match_syntaxon_short <- function(backend, result, names_df, vtr_path,
                                 query_shorter = TRUE) {
  rows <- which(is.na(result$match_type) & !is.na(result$input_name) &
                  !is.na(names_df$cleaned))
  if (length(rows) == 0L) return(result)
  if (!"key_stem" %in% vtr_schema(vtr_path)) return(result)
  col_map <- backend$col_map

  key <- syntaxon_stem_key(names_df$cleaned[rows])
  ok <- !is.na(key)
  rows <- rows[ok]
  key <- key[ok]
  if (length(rows) == 0L) return(result)

  hits <- vectra::block_lookup(backbone_block(vtr_path), "key_stem",
                               unique(key))
  if (nrow(hits) == 0L) return(result)
  by_key <- split(seq_len(nrow(hits)), hits$key_stem)

  q_rank <- names_df$syntaxon_rank %||% rep(NA_character_, nrow(names_df))
  q_auth <- names_df$authorship %||% rep(NA_character_, nrow(names_df))
  cand_list <- vector("list", length(rows))
  for (k in seq_along(rows)) {
    at <- by_key[[key[k]]]
    if (is.null(at)) next
    cand <- hits[at, , drop = FALSE]
    i <- rows[k]
    cr <- syntaxon_rank_of(cand[[col_map$name]])
    keep <- (is.na(q_rank[i]) | is.na(cr) | cr == q_rank[i]) &
      syntaxon_epithets_agree(rep(names_df$cleaned[i], nrow(cand)),
                              cand[[col_map$name]],
                              omit = if (query_shorter) "a" else "b")
    cand <- cand[keep, , drop = FALSE]
    if (nrow(cand) == 0L) next
    # An author the query carries chooses among several units.
    if (!is.na(q_auth[i]) &&
        length(unique(cand$accepted_taxon_id)) > 1L) {
      by_auth <- authorship_compatible(q_auth[i], cand[[col_map$authorship]])
      if (any(by_auth)) cand <- cand[by_auth, , drop = FALSE]
    }
    cand$row_idx <- i
    cand_list[[k]] <- cand
  }
  matches <- do.call(rbind, cand_list)
  if (is.null(matches) || nrow(matches) == 0L) return(result)
  matches$query_idx <- NULL

  best <- pick_best_vec(standardize_pick_cols(matches, col_map))
  open <- best$n_ids > 1L & best$is_ambiguous %in% TRUE
  ok_rows <- best$row_idx[!open]
  if (length(ok_rows)) {
    result <- fill_compiled_matches(
      result, matches[matches$row_idx %in% ok_rows, , drop = FALSE],
      "short_name", col_map)
  }
  if (any(open)) {
    amb <- best[open, , drop = FALSE]
    result$n_ids[amb$row_idx]        <- amb$n_ids
    result$accepted_ids[amb$row_idx] <- amb$accepted_ids
  }
  result
}


#' The short-form stage before the fuzzy pass: the query omits epithets
#' @noRd
match_syntaxon_query_short <- function(backend, result, names_df, vtr_path) {
  match_syntaxon_short(backend, result, names_df, vtr_path,
                       query_shorter = TRUE)
}


#' The short-form stage after the fuzzy pass: the backbone name omits them
#' @noRd
match_syntaxon_backbone_short <- function(backend, result, names_df,
                                          vtr_path) {
  match_syntaxon_short(backend, result, names_df, vtr_path,
                       query_shorter = FALSE)
}
