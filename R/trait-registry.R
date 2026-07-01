# Cross-source trait registry.
#
# Maps a canonical trait name to the enrichment sources that carry it, each with
# a crosswalk that harmonizes the source's raw column to one shared vocabulary
# (categorical traits) or unit (numeric traits). add_trait() reads this registry
# to attach a trait from every source at once; list_traits() and trait_info()
# describe it. Adding a trait, or a source to a trait, is an edit to this list --
# no new exported function.
#
# Numeric unit conversions were calibrated against species shared with a
# known-unit source: GIFT seed mass is grams (x1000 -> mg, ratio to Diaz mg is
# 1000), GIFT SLA is cm^2/g (x0.1 -> mm^2/mg, ratio to LEDA mm^2/mg is 0.1).
# Heights are metres in every source. Woodiness "herbaceous" (Zanne) is the
# canonical "non-woody"; GIFT already uses "non-woody".


# Map raw categorical values to a canonical vocabulary through a named lookup
# (names = source values, values = canonical). Case- and whitespace-insensitive;
# values with no lookup entry become NA.
.xw_cat <- function(v, lookup) {
  key <- tolower(trimws(as.character(v)))
  names(lookup) <- tolower(trimws(names(lookup)))
  out <- unname(lookup[key])
  out[is.na(match(key, names(lookup)))] <- NA_character_
  out
}


# The registry. Sources are listed in default coalesce-priority order.
.trait_registry <- function() {
  list(
    woodiness = list(
      label = "Woodiness",
      kind  = "categorical",
      unit  = NA_character_,
      vocab = c("woody", "non-woody", "variable"),
      sources = list(
        zanne = list(
          enrichment = "woodiness", col = "woodiness",
          citation   = "Zanne et al. 2014",
          note       = "Zanne 'herbaceous' maps to canonical 'non-woody'.",
          map        = function(v) .xw_cat(v, c(
            woody = "woody", herbaceous = "non-woody", variable = "variable"))
        ),
        gift = list(
          enrichment = "gift", col = "gift_woodiness_1",
          citation   = "GIFT (Weigelt et al. 2020)",
          note       = "GIFT woodiness used verbatim (woody / non-woody / variable).",
          map        = function(v) .xw_cat(v, c(
            woody = "woody", `non-woody` = "non-woody", variable = "variable"))
        )
      )
    ),
    plant_height = list(
      label = "Plant height",
      kind  = "numeric",
      unit  = "m",
      vocab = NULL,
      sources = list(
        diaz = list(
          enrichment = "diaz_traits", col = "plant_height_m",
          citation   = "Diaz et al. 2022",
          note       = "Species-mean height, metres.",
          map        = function(v) as.numeric(v)
        ),
        gift = list(
          enrichment = "gift", col = "gift_plant_height_max",
          citation   = "GIFT (Weigelt et al. 2020)",
          note       = "Maximum height, metres.",
          map        = function(v) as.numeric(v)
        )
      )
    ),
    seed_mass = list(
      label = "Seed mass",
      kind  = "numeric",
      unit  = "mg",
      vocab = NULL,
      sources = list(
        diaz = list(
          enrichment = "diaz_traits", col = "seed_mass_mg",
          citation   = "Diaz et al. 2022",
          note       = "Milligrams.",
          map        = function(v) as.numeric(v)
        ),
        gift = list(
          enrichment = "gift", col = "gift_seed_mass_mean",
          citation   = "GIFT (Weigelt et al. 2020)",
          note       = "GIFT grams converted to milligrams (x1000).",
          map        = function(v) as.numeric(v) * 1000
        )
      )
    ),
    sla = list(
      label = "Specific leaf area",
      kind  = "numeric",
      unit  = "mm2/mg",
      vocab = NULL,
      sources = list(
        leda = list(
          enrichment = "leda", col = "sla_mm2_mg",
          citation   = "LEDA Traitbase (Kleyer et al. 2008)",
          note       = "mm^2/mg.",
          map        = function(v) as.numeric(v)
        ),
        gift = list(
          enrichment = "gift", col = "gift_sla_mean",
          citation   = "GIFT (Weigelt et al. 2020)",
          note       = "GIFT cm^2/g converted to mm^2/mg (x0.1).",
          map        = function(v) as.numeric(v) * 0.1
        )
      )
    )
  )
}


# Resolve a user-supplied trait name to a registry key, or stop with a
# did-you-mean suggestion.
.resolve_trait_name <- function(trait, known) {
  if (length(trait) != 1L || !is.character(trait) || is.na(trait)) {
    stop("add_trait(): 'trait' must be a single trait name. See list_traits().",
         call. = FALSE)
  }
  if (trait %in% known) return(trait)
  d    <- utils::adist(tolower(trait), tolower(known))[1, ]
  near <- known[order(d)]
  near <- near[sort(d)[seq_along(near)] <= 3L]
  msg  <- sprintf("add_trait(): unknown trait '%s'.", trait)
  if (length(near)) {
    msg <- paste0(msg, " Did you mean: ", paste(near, collapse = ", "), "?")
  }
  stop(paste0(msg, "\n  See list_traits() for available traits."), call. = FALSE)
}


# Resolve the `sources` argument to a vector of registered source names, in
# registry order. NULL or "all" -> every source.
.resolve_trait_sources <- function(sources, all_src, trait) {
  if (is.null(sources) ||
      (length(sources) == 1L && !is.na(sources) && sources == "all")) {
    return(all_src)
  }
  sources <- as.character(sources)
  bad <- setdiff(sources, all_src)
  if (length(bad)) {
    stop(sprintf(
      "add_trait(): unknown source(s) for '%s': %s. Available: %s.",
      trait, paste(bad, collapse = ", "), paste(all_src, collapse = ", ")),
      call. = FALSE)
  }
  intersect(all_src, sources)
}


# Join a single source column onto x by accepted_name and return the raw vector
# (before crosswalk). Reuses enrich_simple() for the aggregate-aware join. A
# source that is unavailable (not installed, no download, no build) is skipped
# with a warning and returns NULL, so add_trait() still works from the rest.
.trait_join_one <- function(x, enrichment, col, kind, verbose = TRUE) {
  tmp  <- ".__taxify_trait_raw__"
  na_t <- stats::setNames(
    list(if (kind == "numeric") NA_real_ else NA_character_), tmp)
  res <- tryCatch(
    enrich_simple(
      x, enrichment_name = enrichment,
      col_map      = stats::setNames(col, tmp),
      source_label = enrichment,
      na_types     = na_t,
      verbose      = FALSE
    ),
    error = function(e) {
      if (verbose) {
        warning(sprintf(
          "add_trait(): source '%s' unavailable (%s); skipping.",
          enrichment, conditionMessage(e)), call. = FALSE)
      }
      NULL
    }
  )
  if (is.null(res)) return(NULL)
  res[[tmp]]
}
