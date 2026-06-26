#' Geographic range constraint for fuzzy matching
#'
#' These helpers restrict fuzzy match candidates to a user-declared geographic
#' region, using WCVP (World Checklist of Vascular Plants) per-species native
#' status keyed on TDWG Level 3 botanical regions. The fuzzy filter itself is a
#' categorical join on `tdwg_code`. User-facing inputs are resolved to TDWG
#' Level 3 codes before that join: a code is used directly, a region name
#' (`"Belgium"`, `"Europe"`) is looked up in the bundled WGSRPD crosswalk, and
#' coordinates (`c(lon, lat)`) are mapped to codes by point-in-polygon against
#' the WGSRPD Level 3 boundaries. Only fuzzy candidates are constrained; exact
#' matches are always trusted.
#'
#' @name region-filter
#' @keywords internal
NULL


#' Map a `range` mode to the WCVP `native_status` values it admits
#'
#' @param range_mode One of `"present"`, `"native"`, `"introduced"`.
#' @param native_status Character vector of WCVP status values.
#' @return Logical vector, `TRUE` where the status counts as in-region.
#' @noRd
range_status_ok <- function(range_mode, native_status) {
  switch(range_mode,
    present    = !is.na(native_status),
    native     = !is.na(native_status) & native_status == "native",
    introduced = !is.na(native_status) & native_status == "introduced",
    stop(sprintf("unknown range mode '%s'", range_mode), call. = FALSE)
  )
}


#' Fold a string to an accent-free lowercase lookup key
#'
#' Lower-cases, removes Latin diacritics (so a query without accents matches an
#' accented region name),
#' and collapses internal whitespace. Deterministic and platform-independent
#' (no reliance on `iconv` transliteration behaviour).
#'
#' @param x Character vector.
#' @return Character vector of folded keys.
#' @noRd
fold_region_key <- function(x) {
  # Latin-1 accented code points -> ASCII, built from code points to keep this
  # source file ASCII-only (CRAN portability).
  from <- intToUtf8(c(
    0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB,
    0xEC, 0xED, 0xEE, 0xEF, 0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF8,
    0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFF,
    0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xCB,
    0xCC, 0xCD, 0xCE, 0xCF, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD8,
    0xD9, 0xDA, 0xDB, 0xDC, 0xDD))
  to <- paste0(
    "aaaaaaaceeeeiiiidnoooooouuuuyy",
    "AAAAAAACEEEEIIIIDNOOOOOOUUUUY"
  )
  x <- chartr(from, to, x)
  x <- tolower(trimws(x))
  gsub("\\s+", " ", x)
}


#' Load the bundled WGSRPD Level 3 crosswalk
#'
#' Reads `inst/extdata/wgsrpd_level3.csv` (TDWG botanical-country codes and
#' names, Levels 1-3) once per session and caches it. Returns `NULL` if the
#' file is missing from the installed package.
#'
#' @return A data.frame with `code`, `name`, `level2_code`, `level2_name`,
#'   `level1_code`, `level1_name`, or `NULL`.
#' @noRd
wgsrpd_table <- function() {
  cached <- get0("wgsrpd_table", envir = .taxify_env, inherits = FALSE)
  if (!is.null(cached)) return(cached)
  path <- system.file("extdata", "wgsrpd_level3.csv", package = "taxify")
  if (!nzchar(path) || !file.exists(path)) return(NULL)
  tab <- utils::read.csv(path, stringsAsFactors = FALSE,
                         encoding = "UTF-8", colClasses = "character")
  assign("wgsrpd_table", tab, envir = .taxify_env)
  tab
}


#' Build the folded-name to Level-3-code alias map
#'
#' One row per (folded region name, Level 3 code) pair, covering Level 3 names
#' directly and Level 2 / Level 1 names expanded to their member codes. So
#' `"belgium"` -> `BGM`, `"mexico"` (a Level 2 region) -> all Mexican codes,
#' `"europe"` (a Level 1 region) -> every European code.
#'
#' @return A data.frame with `key` and `code`, or `NULL` if the crosswalk is
#'   unavailable.
#' @noRd
region_alias_map <- function() {
  cached <- get0("region_alias_map", envir = .taxify_env, inherits = FALSE)
  if (!is.null(cached)) return(cached)
  tab <- wgsrpd_table()
  if (is.null(tab)) return(NULL)
  aliases <- rbind(
    data.frame(key = fold_region_key(tab$name),        code = tab$code,
               stringsAsFactors = FALSE),
    data.frame(key = fold_region_key(tab$level2_name), code = tab$code,
               stringsAsFactors = FALSE),
    data.frame(key = fold_region_key(tab$level1_name), code = tab$code,
               stringsAsFactors = FALSE)
  )
  aliases <- unique(aliases[nzchar(aliases$key), , drop = FALSE])
  assign("region_alias_map", aliases, envir = .taxify_env)
  aliases
}


#' Validate and normalize a user-supplied region argument
#'
#' Resolves each element to one or more TDWG Level 3 codes: a known code (or any
#' bare 3-letter token) is used directly; a region name (Level 1, 2, or 3, case-
#' and accent-insensitive) is expanded via the bundled WGSRPD crosswalk.
#' Unresolvable, non-code tokens trigger a warning and are dropped. Returns
#' `NULL` when nothing usable remains (so the caller treats it as "no filter").
#' Unrecognized codes are kept rather than rejected: a code that matches no WCVP
#' record makes the soft filter a no-op, so a typo degrades gracefully instead
#' of producing wrong results.
#'
#' @param region Character vector of TDWG Level 3 codes or region names, or
#'   `NULL`.
#' @return Normalized character vector of codes, or `NULL`.
#' @noRd
validate_region <- function(region) {
  if (is.null(region)) return(NULL)
  if (!is.character(region)) {
    stop("region must be a character vector of TDWG Level 3 codes or region ",
         "names, or NULL.", call. = FALSE)
  }
  region <- trimws(region)
  region <- region[!is.na(region) & nzchar(region)]
  if (length(region) == 0L) return(NULL)

  tab     <- wgsrpd_table()
  codes   <- if (is.null(tab)) character(0L) else tab$code
  aliases <- region_alias_map()

  out         <- character(0L)
  unresolved  <- character(0L)
  for (tok in region) {
    up <- toupper(tok)
    if (up %in% codes) {
      out <- c(out, up)
    } else if (!is.null(aliases) &&
               fold_region_key(tok) %in% aliases$key) {
      out <- c(out, aliases$code[aliases$key == fold_region_key(tok)])
    } else if (grepl("^[A-Za-z]{3}$", tok)) {
      out <- c(out, up)
    } else {
      unresolved <- c(unresolved, tok)
    }
  }

  if (length(unresolved) > 0L) {
    warning("Unrecognized region(s) dropped: ",
            paste(unique(unresolved), collapse = ", "),
            ". See taxify_regions() for valid codes and names.",
            call. = FALSE)
  }

  out <- unique(out)
  if (length(out) == 0L) return(NULL)
  out
}


#' Build the in-region and has-range-data sets for a vector of accepted names
#'
#' Looks the accepted names up in the WCVP range table (one inner_join against
#' the candidate names, so only matching rows are pulled). Returns two sets:
#' `present` (recorded in `region` under the chosen `range_mode`) and
#' `has_data` (recorded anywhere in WCVP, used to tell "absent from this region"
#' apart from "no range data at all").
#'
#' @param accepted_names Character vector of candidate accepted names.
#' @param region Character vector of TDWG Level 3 codes (already validated).
#' @param range_mode One of `"present"`, `"native"`, `"introduced"`.
#' @param verbose Logical.
#' @return List with `present` and `has_data` character vectors, or `NULL` when
#'   WCVP range data is unavailable (caller then skips filtering).
#' @noRd
region_range_sets <- function(accepted_names, region, range_mode,
                              verbose = FALSE) {
  an <- unique(accepted_names[!is.na(accepted_names) & nzchar(accepted_names)])
  if (length(an) == 0L) {
    return(list(present = character(0L), has_data = character(0L)))
  }

  vtr_path <- tryCatch(ensure_enrichment("wcvp", verbose = FALSE),
                       error = function(e) NULL)
  if (is.null(vtr_path)) {
    if (verbose) message("  Region filter skipped: WCVP range data unavailable.")
    return(NULL)
  }

  schema <- tryCatch(vectra::collect(utils::head(vectra::tbl(vtr_path), 1L)),
                     error = function(e) NULL)
  if (is.null(schema)) return(NULL)

  join_key <- if ("canonical_name" %in% names(schema)) {
    "canonical_name"
  } else if ("accepted_name" %in% names(schema)) {
    "accepted_name"
  } else {
    return(NULL)
  }
  if (!all(c("tdwg_code", "native_status") %in% names(schema))) return(NULL)

  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(data.frame(lookup_name = an, stringsAsFactors = FALSE), tmp)

  sel <- c(join_key, "tdwg_code", "native_status")
  joined <- tryCatch(
    vectra::inner_join(
      vectra::tbl(tmp),
      vectra::tbl(vtr_path) |>
        vectra::select(!!!lapply(sel, as.name)),
      by = stats::setNames(join_key, "lookup_name")
    ) |> vectra::collect(),
    error = function(e) NULL
  )
  if (is.null(joined) || nrow(joined) == 0L) {
    return(list(present = character(0L), has_data = character(0L)))
  }

  in_region <- joined$tdwg_code %in% region
  status_ok <- range_status_ok(range_mode, joined$native_status)
  list(
    present  = unique(joined$lookup_name[in_region & status_ok]),
    has_data = unique(joined$lookup_name)
  )
}


#' Map accepted names to the set of TDWG Level 1 continents they occur in
#'
#' Pulls every WCVP range row for the given accepted names and rolls the Level 3
#' `tdwg_code` of each up to its Level 1 continent via the bundled WGSRPD
#' crosswalk. All records count (any status), so this answers "where is this
#' species known to occur at all", the basis for the list-context range-outlier
#' check in [inspect()]. Level 1 is deliberately coarse: it is robust to the
#' gaps and range-edge artefacts in finer WCVP polygons.
#'
#' @param accepted_names Character vector of candidate accepted names.
#' @param verbose Logical.
#' @return A named list, one entry per name that has range data, holding its
#'   unique Level 1 codes; `list()` when no name has data; `NULL` when WCVP range
#'   data or the crosswalk is unavailable (caller then skips the check).
#' @noRd
species_range_continents <- function(accepted_names, verbose = FALSE) {
  an <- unique(accepted_names[!is.na(accepted_names) & nzchar(accepted_names)])
  if (length(an) == 0L) return(list())

  # Local-only: the inferred range-outlier check is opportunistic and must never
  # trigger a (large) WCVP download. Declared-region filtering, where the user
  # opted in, still downloads via region_range_sets().
  vtr_path <- enrichment_vtr_path("wcvp")
  if (!file.exists(vtr_path)) {
    if (verbose) message("  Range outlier check skipped: WCVP not installed.")
    return(NULL)
  }

  schema <- tryCatch(vectra::collect(utils::head(vectra::tbl(vtr_path), 1L)),
                     error = function(e) NULL)
  if (is.null(schema)) return(NULL)
  join_key <- if ("canonical_name" %in% names(schema)) {
    "canonical_name"
  } else if ("accepted_name" %in% names(schema)) {
    "accepted_name"
  } else {
    return(NULL)
  }
  if (!"tdwg_code" %in% names(schema)) return(NULL)

  tab <- wgsrpd_table()
  if (is.null(tab)) return(NULL)

  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(data.frame(lookup_name = an, stringsAsFactors = FALSE), tmp)

  sel <- c(join_key, "tdwg_code")
  joined <- tryCatch(
    vectra::inner_join(
      vectra::tbl(tmp),
      vectra::tbl(vtr_path) |>
        vectra::select(!!!lapply(sel, as.name)),
      by = stats::setNames(join_key, "lookup_name")
    ) |> vectra::collect(),
    error = function(e) NULL
  )
  if (is.null(joined) || nrow(joined) == 0L) return(list())

  l3_to_l1 <- stats::setNames(tab$level1_code, tab$code)
  cont     <- unname(l3_to_l1[joined$tdwg_code])
  ok       <- !is.na(cont) & nzchar(cont)
  if (!any(ok)) return(list())
  lapply(split(cont[ok], joined$lookup_name[ok]), unique)
}


#' Drop out-of-region fuzzy candidates where a better candidate survives
#'
#' Given the candidate rows from a fuzzy pass (post-`standardize_pick_cols`,
#' carrying `row_idx` and `accepted_name`), classifies each candidate as
#' in-region, out-of-region, or unknown-range, then removes out-of-region
#' candidates only for input names that still have an in-region or
#' unknown-range candidate. Candidates with no WCVP range data are never
#' dropped (absence of data is not absence from the region), so non-plant
#' matches pass through untouched. If every candidate for an input name is
#' out of region, all are kept rather than losing the match.
#'
#' @param matches Candidate rows with `row_idx` and `accepted_name`.
#' @param region Character vector of validated TDWG Level 3 codes.
#' @param range_mode One of `"present"`, `"native"`, `"introduced"`.
#' @param verbose Logical.
#' @return `matches` with out-of-region candidates removed where a better
#'   candidate survives.
#' @noRd
filter_fuzzy_by_region <- function(matches, region, range_mode,
                                   verbose = FALSE) {
  if (is.null(region) || length(region) == 0L) return(matches)
  if (nrow(matches) == 0L) return(matches)
  if (!all(c("row_idx", "accepted_name") %in% names(matches))) return(matches)

  sets <- region_range_sets(matches$accepted_name, region, range_mode, verbose)
  if (is.null(sets)) return(matches)

  an          <- matches$accepted_name
  is_present  <- an %in% sets$present
  has_data    <- an %in% sets$has_data
  status_out  <- has_data & !is_present

  grp <- matches$row_idx
  non_out_any <- tapply(!status_out, grp, any)
  has_keep    <- non_out_any[as.character(grp)]
  drop        <- status_out & !is.na(has_keep) & has_keep

  if (any(drop)) matches <- matches[!drop, , drop = FALSE]
  matches
}


# ---- Coordinate -> TDWG Level 3 code (point-in-polygon) ----
#
# Coordinates are mapped to botanical regions by point-in-polygon against the
# WGSRPD Level 3 boundaries. The boundary file is downloaded once and cached in
# the taxify data directory. The default engine is a native ray-casting test
# (no spatial dependency); when terra or sf is installed it is used instead
# (faster on large point sets, handles CRS reprojection), selectable via
# options(taxify.pip_engine = "terra" | "sf" | "native").

#' Default URL for the WGSRPD Level 3 GeoJSON boundaries
#' @noRd
wgsrpd_geojson_url <- function() {
  getOption(
    "taxify.wgsrpd_url",
    "https://raw.githubusercontent.com/tdwg/wgsrpd/master/geojson/level3.geojson"
  )
}


#' Path to the cached WGSRPD Level 3 GeoJSON, downloading it if needed
#'
#' @param download Logical. Fetch the file if it is not already cached.
#' @param verbose Logical.
#' @return Character path to the cached GeoJSON, or `NULL` if it is unavailable.
#' @noRd
wgsrpd_geojson_path <- function(download = TRUE, verbose = FALSE) {
  dir  <- file.path(taxify_data_dir(), "wgsrpd")
  path <- file.path(dir, "level3.geojson")
  if (file.exists(path)) return(path)
  if (!download) return(NULL)

  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  url <- wgsrpd_geojson_url()
  if (verbose) message("  Downloading WGSRPD Level 3 boundaries...")
  tmp <- tempfile(tmpdir = dir, fileext = ".geojson.tmp")
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  ok <- tryCatch({
    h <- curl::new_handle()
    curl::handle_setheaders(h, "User-Agent" = "R taxify")
    curl::curl_download(url, tmp, handle = h, quiet = !verbose)
    TRUE
  }, error = function(e) FALSE)
  if (!ok || !file.exists(tmp)) return(NULL)
  file.rename(tmp, path)
  path
}


#' Parse the WGSRPD Level 3 GeoJSON into per-feature polygon rings
#'
#' Caches the parsed structure in the session environment. Each feature is a
#' list with `code`, a bounding box `bbox` (`xmin, xmax, ymin, ymax`) for fast
#' rejection, and `polys` (a list of polygons, each a list of rings where the
#' first ring is the outer boundary and the rest are holes; every ring is a
#' two-column matrix of longitude/latitude).
#'
#' @param verbose Logical.
#' @return A list of features, or `NULL` if the boundaries are unavailable.
#' @noRd
wgsrpd_polygons <- function(verbose = FALSE) {
  cached <- get0("wgsrpd_polygons", envir = .taxify_env, inherits = FALSE)
  if (!is.null(cached)) return(cached)

  path <- wgsrpd_geojson_path(download = TRUE, verbose = verbose)
  if (is.null(path)) return(NULL)

  gj <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE),
                 error = function(e) NULL)
  if (is.null(gj) || is.null(gj$features)) return(NULL)

  ring_matrix <- function(ring) {
    do.call(rbind, lapply(ring, function(pt) c(pt[[1L]], pt[[2L]])))
  }

  feats <- lapply(gj$features, function(ft) {
    code <- ft$properties$LEVEL3_COD
    geom <- ft$geometry
    if (is.null(geom) || is.null(geom$type)) return(NULL)
    polys <- if (geom$type == "Polygon") {
      list(lapply(geom$coordinates, ring_matrix))
    } else if (geom$type == "MultiPolygon") {
      lapply(geom$coordinates, function(poly) lapply(poly, ring_matrix))
    } else {
      return(NULL)
    }
    all_pts <- do.call(rbind, lapply(polys, function(p) p[[1L]]))
    list(
      code  = code,
      bbox  = c(min(all_pts[, 1L]), max(all_pts[, 1L]),
                min(all_pts[, 2L]), max(all_pts[, 2L])),
      polys = polys
    )
  })
  feats <- feats[!vapply(feats, is.null, logical(1L))]
  assign("wgsrpd_polygons", feats, envir = .taxify_env)
  feats
}


#' Even-odd ray-casting test for points against one polygon ring
#'
#' @param px,py Numeric vectors of query coordinates (same length).
#' @param ring Two-column matrix of ring vertices.
#' @return Logical vector, `TRUE` where the point is inside the ring.
#' @noRd
points_in_ring <- function(px, py, ring) {
  n <- nrow(ring)
  if (n < 3L) return(rep(FALSE, length(px)))
  xi <- ring[, 1L]; yi <- ring[, 2L]
  xj <- c(xi[n], xi[-n]); yj <- c(yi[n], yi[-n])
  inside <- rep(FALSE, length(px))
  for (k in seq_len(n)) {
    crosses <- (yi[k] > py) != (yj[k] > py)
    if (!any(crosses)) next
    xint <- (xj[k] - xi[k]) * (py - yi[k]) / (yj[k] - yi[k]) + xi[k]
    hit  <- crosses & (px < xint)
    inside[hit] <- !inside[hit]
  }
  inside
}


#' Locate points within WGSRPD Level 3 features
#'
#' @param lon,lat Numeric vectors of coordinates (same length).
#' @param feats Parsed features from [wgsrpd_polygons()].
#' @return Character vector of Level 3 codes (`NA` where no feature contains the
#'   point), one per input point.
#' @noRd
locate_points <- function(lon, lat, feats) {
  out <- rep(NA_character_, length(lon))
  for (ft in feats) {
    todo <- which(is.na(out) &
                  lon >= ft$bbox[1L] & lon <= ft$bbox[2L] &
                  lat >= ft$bbox[3L] & lat <= ft$bbox[4L])
    if (length(todo) == 0L) next
    px <- lon[todo]; py <- lat[todo]
    inside <- rep(FALSE, length(todo))
    for (poly in ft$polys) {
      in_outer <- points_in_ring(px, py, poly[[1L]])
      if (length(poly) > 1L) {
        for (hole in poly[-1L]) {
          in_outer <- in_outer & !points_in_ring(px, py, hole)
        }
      }
      inside <- inside | in_outer
    }
    if (any(inside)) out[todo[inside]] <- ft$code
  }
  out
}


#' Select the point-in-polygon engine
#'
#' Honors `getOption("taxify.pip_engine")` (`"native"`, `"terra"`, or `"sf"`).
#' The default `"auto"` prefers terra, then sf, then the native ray-casting
#' fallback, using whichever spatial package is installed.
#'
#' @return One of `"terra"`, `"sf"`, `"native"`.
#' @noRd
region_pip_engine <- function() {
  opt <- getOption("taxify.pip_engine", "auto")
  if (identical(opt, "native")) return("native")
  if (identical(opt, "terra")) return("terra")
  if (identical(opt, "sf")) return("sf")
  if (requireNamespace("terra", quietly = TRUE)) return("terra")
  if (requireNamespace("sf", quietly = TRUE)) return("sf")
  "native"
}


#' Locate points with terra
#'
#' @param m Two-column lon/lat matrix.
#' @param verbose Logical.
#' @return Character vector of Level 3 codes (`NA` outside any region), or `NULL`
#'   if the boundaries are unavailable.
#' @noRd
locate_points_terra <- function(m, verbose = FALSE) {
  path <- wgsrpd_geojson_path(download = TRUE, verbose = verbose)
  if (is.null(path)) return(NULL)
  polys <- get0("wgsrpd_terra", envir = .taxify_env, inherits = FALSE)
  if (is.null(polys)) {
    polys <- terra::vect(path)
    assign("wgsrpd_terra", polys, envir = .taxify_env)
  }
  pts <- terra::vect(m, type = "points", crs = "EPSG:4326")
  ex  <- terra::extract(polys, pts)
  ex$LEVEL3_COD[match(seq_len(nrow(m)), ex$id.y)]
}


#' Locate points with sf
#'
#' The WGSRPD polygons trip s2's spherical validity checks, so the planar GEOS
#' backend is used for the intersection (restored afterwards).
#'
#' @param m Two-column lon/lat matrix.
#' @param verbose Logical.
#' @return Character vector of Level 3 codes (`NA` outside any region), or `NULL`
#'   if the boundaries are unavailable.
#' @noRd
locate_points_sf <- function(m, verbose = FALSE) {
  path <- wgsrpd_geojson_path(download = TRUE, verbose = verbose)
  if (is.null(path)) return(NULL)
  polys <- get0("wgsrpd_sf", envir = .taxify_env, inherits = FALSE)
  if (is.null(polys)) {
    polys <- sf::st_read(path, quiet = TRUE)
    assign("wgsrpd_sf", polys, envir = .taxify_env)
  }
  old <- suppressMessages(sf::sf_use_s2(FALSE))
  on.exit(suppressMessages(sf::sf_use_s2(old)), add = TRUE)
  pts <- sf::st_as_sf(data.frame(lon = m[, 1L], lat = m[, 2L]),
                      coords = c("lon", "lat"), crs = 4326)
  idx <- suppressMessages(sf::st_intersects(pts, polys))
  vapply(idx, function(i) if (length(i)) polys$LEVEL3_COD[i[1L]] else NA_character_,
         character(1L))
}


#' Locate points, dispatching to the selected engine with a native fallback
#'
#' @param m Two-column lon/lat matrix.
#' @param verbose Logical.
#' @return Character vector of Level 3 codes, or `NULL` if the boundaries are
#'   unavailable.
#' @noRd
locate_codes <- function(m, verbose = FALSE) {
  engine <- region_pip_engine()
  if (engine != "native") {
    res <- tryCatch(
      switch(engine,
             terra = locate_points_terra(m, verbose),
             sf    = locate_points_sf(m, verbose)),
      error = function(e) {
        if (verbose) {
          message(sprintf("  %s point-in-polygon failed (%s); using native.",
                          engine, conditionMessage(e)))
        }
        "__fallback__"
      }
    )
    if (!identical(res, "__fallback__")) return(res)
  }
  feats <- wgsrpd_polygons(verbose = verbose)
  if (is.null(feats)) return(NULL)
  locate_points(m[, 1L], m[, 2L], feats)
}


#' Extract lon/lat from an sf point object, reprojecting to WGS84
#'
#' @param coords An `sf`, `sfc`, or `sfg` point object.
#' @return A two-column numeric matrix (longitude, latitude).
#' @noRd
coords_from_sf <- function(coords) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("`coords` is an sf object but the 'sf' package is not installed.",
         call. = FALSE)
  }
  g  <- sf::st_geometry(coords)
  gt <- unique(as.character(sf::st_geometry_type(g)))
  if (!all(gt %in% c("POINT", "MULTIPOINT"))) {
    stop("`coords` sf object must have POINT or MULTIPOINT geometry.",
         call. = FALSE)
  }
  if (!is.na(sf::st_crs(g)) && !isTRUE(sf::st_is_longlat(g))) {
    g <- sf::st_transform(g, 4326)
  }
  xy <- sf::st_coordinates(g)
  m  <- cbind(as.numeric(xy[, "X"]), as.numeric(xy[, "Y"]))
  m[stats::complete.cases(m), , drop = FALSE]
}


#' Extract lon/lat from a terra SpatVector, reprojecting to WGS84
#'
#' @param coords A point `SpatVector`.
#' @return A two-column numeric matrix (longitude, latitude).
#' @noRd
coords_from_spatvector <- function(coords) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("`coords` is a SpatVector but the 'terra' package is not installed.",
         call. = FALSE)
  }
  if (!identical(terra::geomtype(coords), "points")) {
    stop("`coords` SpatVector must have point geometry.", call. = FALSE)
  }
  if (!isTRUE(terra::is.lonlat(coords, warn = FALSE)) &&
      nzchar(terra::crs(coords))) {
    coords <- terra::project(coords, "EPSG:4326")
  }
  xy <- terra::crds(coords)
  m  <- cbind(as.numeric(xy[, 1L]), as.numeric(xy[, 2L]))
  m[stats::complete.cases(m), , drop = FALSE]
}


#' Normalize a coordinate argument to a two-column lon/lat matrix
#'
#' Accepts a length-2 numeric vector (`c(lon, lat)`), a matrix/data.frame with
#' longitude/latitude columns (named `lon`/`lat` or `x`/`y`, else the first two
#' columns in that order), or a point-geometry spatial object (`sf`/`sfc`/`sfg`
#' or a terra `SpatVector`), which is reprojected to longitude/latitude.
#'
#' @param coords Coordinate input.
#' @return A two-column numeric matrix (longitude, latitude).
#' @noRd
normalize_coords <- function(coords) {
  if (inherits(coords, c("sf", "sfc", "sfg"))) {
    return(coords_from_sf(coords))
  }
  if (inherits(coords, "SpatVector")) {
    return(coords_from_spatvector(coords))
  }
  if (is.numeric(coords) && is.null(dim(coords))) {
    if (length(coords) != 2L) {
      stop("A numeric `coords` vector must be length 2: c(lon, lat).",
           call. = FALSE)
    }
    m <- matrix(as.numeric(coords), ncol = 2L)
  } else if (is.matrix(coords) || is.data.frame(coords)) {
    df <- as.data.frame(coords, stringsAsFactors = FALSE)
    if (ncol(df) < 2L) {
      stop("`coords` must have at least two columns (longitude, latitude).",
           call. = FALSE)
    }
    nm  <- tolower(names(df))
    lon <- which(nm %in% c("lon", "long", "longitude", "x"))[1L]
    lat <- which(nm %in% c("lat", "latitude", "y"))[1L]
    if (is.na(lon) || is.na(lat)) { lon <- 1L; lat <- 2L }
    m <- cbind(as.numeric(df[[lon]]), as.numeric(df[[lat]]))
  } else {
    stop("`coords` must be c(lon, lat) or a matrix/data.frame of lon/lat.",
         call. = FALSE)
  }
  ok <- stats::complete.cases(m)
  if (any(m[ok, 1L] < -180 | m[ok, 1L] > 180 |
          m[ok, 2L] <  -90 | m[ok, 2L] >  90)) {
    stop("`coords` out of range: longitude in [-180, 180], latitude in ",
         "[-90, 90]. Order is c(lon, lat).", call. = FALSE)
  }
  m[ok, , drop = FALSE]
}


#' Map coordinates to TDWG Level 3 codes
#'
#' @param coords Coordinate input (see [normalize_coords()]).
#' @param verbose Logical.
#' @return Character vector of unique Level 3 codes (possibly empty), or `NULL`
#'   if the boundaries are unavailable.
#' @noRd
coords_to_codes <- function(coords, verbose = FALSE) {
  if (is.null(coords)) return(NULL)
  m <- normalize_coords(coords)
  if (nrow(m) == 0L) return(character(0L))

  codes <- locate_codes(m, verbose = verbose)
  if (is.null(codes)) {
    warning("Coordinate region lookup skipped: WGSRPD boundaries unavailable ",
            "(offline, or download failed).", call. = FALSE)
    return(NULL)
  }

  n_miss <- sum(is.na(codes))
  if (n_miss > 0L && verbose) {
    message(sprintf("  %d coordinate(s) fell outside any botanical region.",
                    n_miss))
  }
  unique(codes[!is.na(codes)])
}


#' Resolve region names, codes, and coordinates to TDWG Level 3 codes
#'
#' The single front door used by [taxify()]: normalizes the character `region`
#' argument (codes and names) and the numeric `coords` argument (point-in-
#' polygon) and returns their union, or `NULL` when the result is empty so the
#' caller applies no filter.
#'
#' @param region Character codes/names, or `NULL`.
#' @param coords Coordinate input, or `NULL`.
#' @param verbose Logical.
#' @return Character vector of Level 3 codes, or `NULL`.
#' @noRd
resolve_region <- function(region = NULL, coords = NULL, verbose = FALSE) {
  from_region <- validate_region(region)
  from_coords <- if (is.null(coords)) NULL else coords_to_codes(coords, verbose)
  out <- unique(c(from_region, from_coords))
  out <- out[!is.na(out) & nzchar(out)]
  if (length(out) == 0L) return(NULL)
  out
}


#' List TDWG botanical regions
#'
#' Returns the bundled WGSRPD (World Geographical Scheme for Recording Plant
#' Distributions) Level 3 crosswalk: the botanical-country codes and names used
#' by the `region` argument of [taxify()] and by [add_wcvp()]. Optionally
#' filtered by a search term matched (case- and accent-insensitively) against
#' the code and the Level 1, 2, and 3 names.
#'
#' @param search Optional character string. If supplied, only regions whose
#'   code or name contains it are returned.
#' @return A data.frame with columns `code`, `name`, `level2_name`, and
#'   `level1_name`, one row per Level 3 region.
#' @examples
#' head(taxify_regions())
#' taxify_regions("belgium")
#' taxify_regions("Europe")
#' @export
taxify_regions <- function(search = NULL) {
  tab <- wgsrpd_table()
  if (is.null(tab)) {
    return(data.frame(code = character(0L), name = character(0L),
                      level2_name = character(0L), level1_name = character(0L),
                      stringsAsFactors = FALSE))
  }
  out <- tab[, c("code", "name", "level2_name", "level1_name")]
  if (!is.null(search) && length(search) == 1L && nzchar(search)) {
    key <- fold_region_key(search)
    hay <- fold_region_key(paste(out$code, out$name,
                                 out$level2_name, out$level1_name))
    out <- out[grepl(key, hay, fixed = TRUE), , drop = FALSE]
  }
  rownames(out) <- NULL
  out
}
