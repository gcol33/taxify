# ---- Enrichment layer infrastructure ----
#
# Enrichment layers join external trait/status data to taxify results via
# accepted_name. The .vtr files are built by CI in taxifydb and
# distributed via GitHub Releases (same manifest system as matching backbones).
#
# Disk layout:
#   taxify_data_dir()/
#     enrichment/
#       conservation_status/
#         latest/conservation_status.vtr + meta.json
#       griis/
#         latest/griis.vtr + meta.json
#       ...


# ---- Path helpers ----

#' Enrichments taxify builds locally and never redistributes
#'
#' taxify only ships a pre-built `.vtr` for a source whose licence permits
#' redistribution. These sources do not qualify -- their terms are citation-only
#' or unstated -- so no asset is published, they carry no manifest entry, and no
#' version can be checked. Their doors reach them through taxifydb, which builds
#' the `.vtr` from the original source on the user's own machine. taxify
#' redistributes none of the data.
#'
#' None of them feeds the cross-source `add_trait()` registry, which admits only
#' downloadable sources: a source reachable solely where taxifydb is installed
#' would make the same code return a different number on two machines. `ccdb` is
#' the one that costs something -- 65,051 species against `kew_cvalues`' 9,375 --
#' and it is reached through `add_ccdb()` all the same.
#'
#' @return Character vector of enrichment identifiers.
#' @noRd
.build_only_enrichments <- function() {
  c("ccdb", "gmpd", "plantatt", "bryoatt", "clopla")
}


#' Return the versioned directory for an enrichment
#' @noRd
enrichment_dir <- function(name, version = "latest") {
  file.path(taxify_data_dir(), "enrichment", name, version)
}


#' Return the .vtr path for an enrichment
#' @noRd
enrichment_vtr_path <- function(name, version = "latest") {
  file.path(enrichment_dir(name, version), paste0(name, ".vtr"))
}


# ---- Enrichment metadata ----

#' Read meta.json from an enrichment directory
#'
#' @param vtr_path Character. Path to the enrichment `.vtr` file.
#' @return A named list with source, version, license, etc., or NULL.
#' @noRd
read_enrichment_meta <- function(vtr_path) {
  meta_path <- file.path(dirname(vtr_path), "meta.json")
  if (!file.exists(meta_path)) return(NULL)
  read_json_bom(meta_path, simplifyVector = TRUE)
}


#' Version and byte identity of the installed build of one enrichment
#'
#' Read at join time, so what a result records is the build it was actually
#' built from -- not whatever is installed when [taxify_lock()] is called later,
#' which may be a refresh or a restore away.
#'
#' A name with no installed build (a backbone-side layer, a custom `add_data()`
#' label) simply reports both fields missing.
#'
#' @param name Character. Enrichment identifier.
#' @return A list with `version` and `content_id`, each `NA_character_` when
#'   unavailable.
#' @noRd
enrichment_identity <- function(name) {
  none <- list(version = NA_character_, content_id = NA_character_)
  if (!is.character(name) || length(name) != 1L || is.na(name) ||
      !nzchar(name)) {
    return(none)
  }
  meta <- tryCatch(read_enrichment_meta(enrichment_vtr_path(name, "latest")),
                   error = function(e) NULL)
  if (is.null(meta)) return(none)
  list(version    = nz_or(meta$version, NA_character_),
       content_id = nz_or(meta$content_id, NA_character_))
}


# ---- Version checking ----

#' Check whether a local enrichment version is current
#'
#' Compares the version in the local meta.json against the manifest.
#' Returns TRUE if an update is needed.
#'
#' @param name Character. Enrichment identifier.
#' @return Logical. TRUE means a newer version is available.
#' @noRd
# Content identity of a built .vtr: the md5 of the file, used to detect a
# same-tag republish (rebuilt asset re-uploaded under an unchanged release tag).
# tools::md5sum is base R, so this adds no dependency.
content_id_of <- function(vtr_path) {
  if (is.null(vtr_path) || !file.exists(vtr_path)) return(NA_character_)
  unname(tools::md5sum(vtr_path))
}

# Adopt a content id into an existing cache's meta.json (idempotent, for a cache
# that stores no id and whose bytes already match the shipped asset), so
# later sessions compare the stored id instead of re-hashing the file. Works
# for enrichments and backbones alike -- both keep a meta.json beside the .vtr.
write_content_id_meta <- function(vtr_path, content_id) {
  meta_path <- file.path(dirname(vtr_path), "meta.json")
  meta <- if (file.exists(meta_path)) {
    tryCatch(read_json_bom(meta_path, simplifyVector = TRUE),
             error = function(e) list())
  } else list()
  meta$content_id <- content_id
  tryCatch(
    jsonlite::write_json(meta, meta_path, pretty = TRUE, auto_unbox = TRUE),
    error = function(e) NULL
  )
  invisible(content_id)
}

# Shared refresh decision by content identity, used by both the enrichment and
# backbone version checks. Returns TRUE/FALSE, or NA when no content id is
# shipped, leaving the caller to decide on the version string alone. A cache
# with no stored id is hashed in place when `hash_missing = TRUE` and, if its bytes
# already match the shipped id, the id is adopted via `adopt` so later sessions
# skip the hash. Backbones pass `hash_missing = FALSE` to avoid rehashing a
# multi-GB file: they compare only the id their downloaded meta already carries.
reconcile_content_id <- function(vtr_path, local_cid, bundled_cid,
                                 adopt = NULL, hash_missing = TRUE) {
  if (is.null(bundled_cid)) return(NA)
  if (is.null(local_cid)) {
    if (!isTRUE(hash_missing)) return(NA)
    local_cid <- content_id_of(vtr_path)
    if (identical(as.character(local_cid), as.character(bundled_cid)) &&
        !is.null(adopt)) {
      adopt(local_cid)
    }
  }
  !identical(as.character(local_cid), as.character(bundled_cid))
}

check_enrichment_version <- function(name) {
  # Never refresh against the read-only example database (offline fixtures).
  if (is_example_data_dir()) return(FALSE)

  # A build-only source publishes no asset and has no manifest entry, so there
  # is no version to compare against: the local build is the only copy.
  if (name %in% .build_only_enrichments()) return(FALSE)

  vtr_path <- enrichment_vtr_path(name)
  meta <- read_enrichment_meta(vtr_path)

  if (is.null(meta)) return(TRUE)  # No local copy

  # A build the user pinned -- restored by content id -- stays put. Refreshing
  # it to the current release would silently undo the pin at the next session,
  # which is the opposite of what pinning a build is for.
  if (isTRUE(as.logical(meta$pinned))) return(FALSE)

  # Static enrichments never phone home, but a same-tag republish would leave
  # the cache stale forever. Reconcile against the bundled manifest's content
  # id (a hash of the built .vtr) entirely offline: a package update ships a
  # changed content id for any rebuilt asset, which forces a one-time refresh.
  # A cache with no stored id is hashed in place, so an unchanged asset is
  # adopted without any download. A bundled manifest that carries no content id
  # leaves a static enrichment unrefreshed, as its name implies.
  #
  # The example database is exempted above by its location. A cache without
  # `downloaded_at` is one taxifydb built locally (fallback step 5), and it is
  # compared like any download: its label belongs to the source, not the
  # release, and its bytes never equal the published asset, so the first
  # session that can reach the release replaces it.
  if (isTRUE(meta$static)) {
    entry <- tryCatch(resolve_enrichment_entry(local_manifest(), name),
                      error = function(e) NULL)
    s <- reconcile_content_id(
      vtr_path, meta$content_id, entry$content_id,
      adopt = function(cid) write_content_id_meta(vtr_path, cid))
    return(if (is.na(s)) FALSE else s)
  }

  manifest <- fetch_manifest()
  entry <- resolve_enrichment_entry(manifest, name)
  if (is.null(entry)) return(FALSE)

  # Content identity decides, and the version string is the fallback -- the
  # same order the backbone gate uses. A version records when a build ran, not
  # what it read, so a rebuild republished under the tag it already carries
  # leaves the label untouched while the columns change underneath it: GRIIS
  # 2026.08 was rebuilt after its GBIF source stopped returning `recordid`, and
  # a label comparison holds the pre-rebuild .vtr forever.
  #
  # A downloaded cache that predates content ids is left to the version
  # comparison rather than rehashed on every session. A locally built cache is
  # hashed: it carries no id, and the hash is what tells it apart from the
  # release until the refresh replaces it.
  s <- reconcile_content_id(vtr_path, meta$content_id, entry$content_id,
                            hash_missing = is.null(meta$downloaded_at))
  if (!is.na(s)) return(s)

  isTRUE(meta$version != entry$latest)
}


# ---- Ensure / download ----

#' Ensure an enrichment .vtr is available
#'
#' Resolution order:
#' 1. Once-per-session version check (download update if needed)
#' 2. Session cache
#' 3. On disk
#' 4. Download pre-built .vtr from manifest
#' 5. Build from source (if enrichment is in the build registry)
#' 6. Error with report link
#'
#' @param name Character. Enrichment identifier (e.g., "iucn").
#' @param verbose Logical.
#' @return Character. Path to the .vtr file, or NULL if all paths failed
#'   (only when called with `allow_null = TRUE` internally).
#' @noRd
ensure_enrichment <- function(name, verbose = TRUE) {
  cache_key <- paste0("enrichment_", name)

  # 1. Version freshness check (once per session)
  check_key <- paste0(".enrichment_version_checked.", name)
  if (taxify_offline()) .taxify_env[[check_key]] <- TRUE
  if (!isTRUE(.taxify_env[[check_key]])) {
    .taxify_env[[check_key]] <- TRUE
    tryCatch(
      {
        if (check_enrichment_version(name)) {
          if (verbose) {
            message(sprintf(
              "Enrichment '%s' has a newer version. Updating...", name
            ))
          }
          download_enrichment(name, verbose = verbose)
          set_backbone_path(cache_key, NULL)
        }
      },
      error = function(e) {
        warning(
          sprintf(
            "Could not update enrichment '%s': %s\nUsing existing local version.",
            name, conditionMessage(e)
          ),
          call. = FALSE
        )
      }
    )
  }

  # 2. In-session cache
  cached <- get_backbone_path(cache_key)
  if (!is.null(cached) && file.exists(cached)) return(cached)

  # 3. On disk
  vtr_path <- enrichment_vtr_path(name)
  if (file.exists(vtr_path)) {
    set_backbone_path(cache_key, vtr_path)
    return(vtr_path)
  }

  # The example database is a read-only, offline fixture set living inside the
  # package installation. An enrichment not already bundled there (which would
  # have resolved at step 3) must never be downloaded or built into
  # inst/exampledb: stop with a clear message rather than writing a released
  # asset into the package source.
  if (is_example_data_dir()) {
    stop(sprintf(
      "enrichment '%s' is not bundled with the example database.", name
    ), call. = FALSE)
  }

  # 4. Download from manifest (a build-only source publishes no asset, so this
  #    step is skipped rather than attempted and swallowed).
  if (!name %in% .build_only_enrichments()) {
    path <- tryCatch(
      download_enrichment(name, verbose = verbose),
      error = function(e) NULL
    )
    if (!is.null(path) && file.exists(path)) {
      set_backbone_path(cache_key, path)
      return(path)
    }
  }

  # 5. Build from source via taxifydb (if installed). A build fetches the raw
  #    dataset, so offline mode stops before it.
  if (!taxify_offline() && requireNamespace("taxifydb", quietly = TRUE)) {
    available <- tryCatch(taxifydb::list_enrichments(),
                          error = function(e) character(0L))
    if (name %in% available) {
      if (verbose) {
        message(sprintf(
          if (name %in% .build_only_enrichments()) {
            "Enrichment '%s' is not redistributed by taxify. Building it from the original source via taxifydb (one time)..."
          } else {
            "Pre-built .vtr not available for enrichment '%s'. Building from source via taxifydb..."
          },
          name
        ))
      }
      path <- tryCatch(
        taxifydb::build_enrichment(name,
                                   output_dir = enrichment_dir(name),
                                   verbose = verbose),
        error = function(e) {
          if (verbose) {
            message(sprintf(
              "Build-from-source failed for '%s': %s",
              name, conditionMessage(e)
            ))
          }
          NULL
        }
      )
      if (!is.null(path) && file.exists(path)) {
        set_backbone_path(cache_key, path)
        return(path)
      }
    }
  }

  # 6. Return NULL — caller (enrich_simple/enrich_by_group) handles
  #    emergency fallback or error
  NULL
}


#' Assemble the meta.json list an installed enrichment carries
#'
#' Records the version, static flag, pinned flag, content id (md5 of the file on
#' disk, matching the manifest's content_id), and download date, then copies the
#' describing fields the manifest entry holds -- `group_col`, `available_groups`,
#' `license`, `citation` -- when present. Copying them makes an installed
#' enrichment self-describing offline: `enrichment_groups()` reads
#' `meta$group_col`, `cite()` reads `meta$license`, with no manifest round-trip.
#'
#' @param entry The resolved manifest enrichment entry.
#' @param actual_version Character. The version being written.
#' @param pinned Logical. Whether this is a pinned (non-latest) install.
#' @param vtr_path Character. Path to the freshly written `.vtr`.
#' @return A named list ready for `jsonlite::write_json()`.
#' @noRd
build_enrichment_meta <- function(entry, actual_version, pinned, vtr_path) {
  meta <- list(
    version       = actual_version,
    static        = isTRUE(entry$static),
    pinned        = isTRUE(pinned),
    content_id    = content_id_of(vtr_path),
    downloaded_at = format(Sys.Date(), "%Y-%m-%d")
  )
  if (!is.null(entry$group_col))        meta$group_col        <- entry$group_col
  if (!is.null(entry$available_groups)) meta$available_groups <- entry$available_groups
  if (!is.null(entry$license))          meta$license          <- entry$license
  if (!is.null(entry$citation))         meta$citation         <- entry$citation
  if (!is.null(entry$references$url)) {
    meta$references <- list(file       = basename(entry$references$url),
                            content_id = entry$references$content_id,
                            nrow       = entry$references$nrow)
  }
  meta
}


#' Download the reference table an enrichment entry declares
#'
#' Fetched into the build's directory, preferring the immutable content-addressed
#' copy, and kept only when its bytes hash to the id the manifest records. A
#' failure is a warning: the enrichment's values stay usable, only resolving its
#' provenance ids to citations needs the table.
#'
#' @param entry The manifest entry.
#' @param dest_dir The build directory.
#' @return `TRUE` when the table is in place, else `FALSE` (invisibly).
#' @noRd
download_enrichment_references <- function(entry, dest_dir, verbose = TRUE) {
  refs <- entry$references
  if (is.null(refs$url)) return(invisible(FALSE))
  dest <- file.path(dest_dir, basename(refs$url))
  tmp  <- tempfile(tmpdir = dest_dir, fileext = ".refs.tmp")
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  ok <- tryCatch({
    fetch_asset_file(refs$content_url %||% refs$url, tmp,
                     sprintf("reference table '%s'", basename(refs$url)),
                     verbose = verbose)
    got <- content_id_of(tmp)
    if (!is.null(refs$content_id) && !identical(as.character(got), refs$content_id)) {
      stop(sprintf("bytes hash to %s, not the recorded %s", got, refs$content_id))
    }
    install_vtr_file(tmp, dest)
    TRUE
  }, error = function(e) {
    warning(sprintf("Reference table '%s' not installed: %s",
                    basename(refs$url), conditionMessage(e)), call. = FALSE)
    FALSE
  })
  invisible(isTRUE(ok))
}


#' Download an enrichment .vtr from the manifest
#'
#' @param name Character. Enrichment identifier.
#' @param version Character. "latest" or a specific version.
#' @param verbose Logical.
#' @return Path to the downloaded .vtr (invisibly).
#' @noRd
download_enrichment <- function(name, version = "latest", verbose = TRUE) {
  dest_dir <- enrichment_dir(name, version)
  vtr_path <- file.path(dest_dir, paste0(name, ".vtr"))

  # Pinned versions: never overwrite

  if (version != "latest" && file.exists(vtr_path)) {
    if (verbose) {
      message(sprintf(
        "\u2713 Enrichment '%s' v%s already present (pinned). Skipping.",
        name, version
      ))
    }
    return(invisible(vtr_path))
  }

  # Resolve from manifest
  manifest <- fetch_manifest()
  entry <- resolve_enrichment_entry(manifest, name)
  if (is.null(entry)) {
    stop(sprintf("Enrichment '%s' not found in manifest.", name),
         call. = FALSE)
  }

  actual_version <- if (version == "latest") entry$latest else version
  base_url <- entry$full_url %||% entry$url

  # A pinned version is a different release tag, not a relabelling of the
  # current asset: derive its URL and refuse a version that was never published
  # (#62). Offline is checked first, so an offline pin fails on the mode rather
  # than on an unreachable HEAD request.
  if (taxify_offline() && !startsWith(base_url, "file://")) {
    stop(sprintf("taxify is in offline mode; not downloading enrichment '%s'.",
                 name), call. = FALSE)
  }
  url <- if (version == "latest") {
    base_url
  } else {
    pinned_asset_url(base_url, name, version, entry$latest)
  }

  if (verbose) {
    message(sprintf(
      "\u2139 Downloading enrichment '%s' v%s...", name, actual_version
    ))
  }

  # The temp file lives one level up, in the enrichment's store root, so
  # archiving the build being replaced (which moves everything out of the
  # version directory) cannot sweep the download in progress along with it.
  store_root <- asset_store_root(name, "enrichment")
  dir.create(store_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  tmp_path <- tempfile(tmpdir = store_root, fileext = ".vtr.tmp")
  on.exit(if (file.exists(tmp_path)) unlink(tmp_path), add = TRUE)

  fetch_asset_file(url, tmp_path, sprintf("enrichment '%s'", name),
                   verbose = verbose)

  # Keep the build being replaced, under its own content id, so a refetch adds
  # a directory instead of destroying the only copy of what a lockfile pinned.
  # Only once the new bytes are safely in the temp file: a failed download
  # leaves the installed enrichment untouched.
  if (version == "latest" && keep_superseded_builds("enrichment")) {
    archive_active_build(name, "enrichment", verbose = verbose)
  }

  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  install_vtr_file(tmp_path, vtr_path)

  # Write meta.json. The content id is the md5 of the freshly downloaded file,
  # which matches the manifest's content_id and lets the static-cache gate
  # detect a future same-tag republish offline. build_enrichment_meta() also
  # copies the manifest entry's describing fields (group_col, available_groups,
  # license, citation) so the installed enrichment is self-describing.
  meta <- build_enrichment_meta(entry, actual_version,
                                pinned = version != "latest", vtr_path)
  if (version == "latest" && !is.null(meta$references)) {
    download_enrichment_references(entry, dest_dir, verbose = verbose)
  } else {
    meta$references <- NULL
  }
  jsonlite::write_json(
    meta, file.path(dest_dir, "meta.json"),
    pretty = TRUE, auto_unbox = TRUE
  )

  if (verbose) {
    size_mb <- file.size(vtr_path) / 1048576
    message(sprintf(
      "\u2713 Enrichment '%s' ready (v%s, %.1f MB).",
      name, actual_version, size_mb
    ))
  }

  invisible(vtr_path)
}


#' Resolve an enrichment entry from the manifest
#'
#' Looks under `manifest$enrichments` (v2 schema) for the named enrichment.
#'
#' @param manifest The parsed manifest list.
#' @param name Character.
#' @return The entry list, or NULL.
#' @noRd
resolve_enrichment_entry <- function(manifest, name) {
  if (!is.null(manifest$enrichments)) {
    manifest$enrichments[[name]]
  } else {
    NULL
  }
}


#' Download one or more enrichment .vtr files
#'
#' Downloads pre-built enrichment `.vtr` files from the taxify manifest.
#'
#' @param enrichment Character. One or more enrichment names (e.g.,
#'   `"iucn"`, `"griis"`, `"zanne"`).
#' @param version Character. `"latest"` (default) or a specific version string.
#' @param content_id Character or `NULL` (default). The content id of one exact
#'   build -- the md5 of its `.vtr`, as recorded by [taxify_lock()] and by the
#'   manifest. Given one, taxify fetches that build from the immutable copy
#'   published beside the rolling asset, verifies the bytes hash back to the id,
#'   and makes it the active build; the build it replaces is kept on disk under
#'   its own content id. This is what turns a lockfile's recorded id back into
#'   bytes. Pass one id per `enrichment`, or one shared by all of them.
#' @param verbose Logical. Default `TRUE`.
#' @return The path(s) to the downloaded `.vtr` file(s) (invisibly).
#'
#' @details
#' Available enrichments:
#' \describe{
#'   \item{iucn}{IUCN conservation status (LC/NT/VU/EN/CR/EW/EX)}
#'   \item{griis}{GRIIS invasive species status by country}
#'   \item{zanne}{Zanne et al. 2014 woody/herbaceous classification}
#'   \item{wcvp}{WCVP native range by TDWG botanical region}
#'   \item{eive}{EIVE 1.0 ecological indicator values (European plants)}
#'   \item{diaz_traits}{Diaz et al. 2022 seed mass and plant height}
#'   \item{elton_traits}{EltonTraits 1.0 diet and foraging (birds + mammals)}
#'   \item{avonet}{AVONET bird morphology and migration}
#'   \item{pantheria}{PanTHERIA mammal life-history traits}
#'   \item{common_names}{GBIF vernacular names (multi-language)}
#'   \item{amphibio}{AmphiBIO amphibian life-history and ecological traits}
#'   \item{leda}{LEDA Traitbase NW European plant traits (Kleyer et al. 2008)}
#' }
#'
#' @seealso [taxify_store()] for the builds already on disk, [taxify_restore()]
#'   to reinstall everything a lockfile pins.
#' @export
taxify_download_enrichment <- function(enrichment,
                                       version = "latest",
                                       content_id = NULL,
                                       verbose = TRUE) {
  content_id <- recycle_content_ids(content_id, enrichment, "enrichment")
  paths <- vapply(seq_along(enrichment), function(i) {
    name <- enrichment[[i]]
    if (!is.null(content_id)) {
      return(download_content_build(name, content_id[[i]], "enrichment",
                                    version = version, verbose = verbose))
    }
    download_enrichment(name, version = version, verbose = verbose)
  }, character(1L))
  names(paths) <- enrichment
  invisible(paths)
}


# ---- Shared enrichment join helpers ----


#' NA sentinel matching a column's storage type
#'
#' Returns the typed `NA` that keeps an output column the same type as its
#' source column, so a door never has to hand-declare `na_types`.
#'
#' @param v A prototype value (one element of the source column).
#' @return `NA_integer_`, `NA_real_`, `NA` (logical), or `NA_character_`.
#' @noRd
na_sentinel_for <- function(v) {
  if (is.integer(v)) NA_integer_
  else if (is.numeric(v)) NA_real_
  else if (is.logical(v)) NA
  else NA_character_
}


#' Set one column of a result to a single value
#'
#' Recycles `value` to the frame's height. A length-1 replacement into a
#' zero-row frame is an error in R, and a result filtered to nothing is ordinary
#' input to a door, so every scalar column assignment goes through here.
#'
#' @param x A data.frame.
#' @param col Character. Column name.
#' @param value Length-1 value (typically an NA sentinel, or a unit string).
#' @return `x` with the column set.
#' @noRd
set_col_value <- function(x, col, value) {
  x[[col]] <- rep(value, length.out = nrow(x))
  x
}


#' Build aggregate-aware candidate join keys for a species-level enrichment
#'
#' Encodes the trait-resolution rule for aggregates. A species query takes its
#' own name first, then the aggregate key (`"<binomial> aggr."`) as a downward
#' fallback -- a member inherits its aggregate's value. An aggregate query takes
#' the aggregate key first; when `binomial_fallback` is `TRUE` (the default) it
#' then falls *up* to the nominal binomial where the source carries no
#' aggregate-level value. That upward hit is the binomial's own trait standing
#' in for the aggregate, not a real aggregate-level measurement, and
#' `agg_select_idx()` records it as `basis = "binomial"`. With
#' `binomial_fallback = FALSE` an aggregate query stays unmatched when no
#' aggregate-level value exists. Aggregate markers are canonicalized so the keys
#' line up with enrichment sources regardless of spelling.
#'
#' @param acc Character vector of accepted names (the join column).
#' @param qualifier Character vector of canonical qualifiers from `taxify()`
#'   (`NA` when absent -- every row is then treated as a species query).
#' @param binomial_fallback Logical. When `TRUE`, an aggregate query with no
#'   aggregate-level value falls back to the nominal binomial's value.
#' @return A list with `primary`, `inherit`, and `is_agg` (logical) vectors,
#'   each the length of `acc`. For a species query `inherit` is the aggregate
#'   form; for an aggregate query it is the bare binomial (or `NA` when
#'   `binomial_fallback = FALSE`).
#' @noRd
agg_join_keys <- function(acc, qualifier, binomial_fallback = TRUE) {
  if (is.null(qualifier)) qualifier <- rep(NA_character_, length(acc))
  is_agg   <- !is.na(qualifier) & qualifier %in% .aggregate_tokens
  binom    <- strip_agg_marker(acc)
  agg_form <- ifelse(!is.na(binom), paste0(binom, " aggr."), NA_character_)
  agg_inherit <- if (isTRUE(binomial_fallback)) binom else NA_character_
  list(
    primary = ifelse(is_agg, agg_form, canon_agg_marker(acc)),
    inherit = ifelse(is_agg, agg_inherit, agg_form),
    is_agg  = is_agg
  )
}


#' Resolve aggregate-aware join keys against an enrichment key vector
#'
#' Picks the primary-key hit when present, else the inherited hit, and records
#' the basis of each filled value.
#'
#' @param keys List from `agg_join_keys()`.
#' @param enr_key Character vector of canonicalized enrichment lookup keys.
#' @return A list with `idx` (row index into `enr_key` per query row, `NA` for
#'   no match), `inherited` (logical; `TRUE` where the value came from an
#'   inherited key rather than a same-level hit), and `basis` (character:
#'   `"primary"` a same-level hit, `"aggregate"` a species inheriting its
#'   aggregate's value downward, `"binomial"` an aggregate falling back to the
#'   nominal binomial upward, `NA` no match).
#' @noRd
agg_select_idx <- function(keys, enr_key) {
  idx_p <- match(keys$primary, enr_key)
  idx_i <- match(keys$inherit, enr_key)
  inherited <- is.na(idx_p) & !is.na(idx_i)
  idx <- ifelse(!is.na(idx_p), idx_p, idx_i)
  is_agg <- keys$is_agg
  if (is.null(is_agg)) is_agg <- rep(FALSE, length(idx))
  basis <- rep(NA_character_, length(idx))
  basis[!is.na(idx_p)]       <- "primary"
  basis[inherited & !is_agg] <- "aggregate"
  basis[inherited &  is_agg] <- "binomial"
  list(idx = idx, inherited = inherited, basis = basis)
}


#' In-memory enrichment join from a data.frame (emergency fallback)
#'
#' Joins an in-memory data.frame (from `enrichment_emergency_fallback()`) to
#' a taxify result using `accepted_name == canonical_name`. Does NOT write to
#' disk — results are ephemeral.
#'
#' @param x A taxify_result data.frame.
#' @param df Data.frame with at least `canonical_name` plus trait columns.
#' @param enrichment_name Character. Enrichment identifier.
#' @param col_map Named character vector. Names = output columns,
#'   values = source columns in `df`.
#' @param source_label Character.
#' @param na_types Named list of NA sentinels (optional).
#' @return The enriched data.frame.
#' @noRd
enrich_from_dataframe <- function(x, df, enrichment_name, col_map,
                                  source_label, na_types = NULL,
                                  join_col = "accepted_name") {
  # Filter col_map to columns that exist in df
  col_map <- col_map[col_map %in% names(df)]
  if (length(col_map) == 0L) return(x)

  # Initialize output columns, typing each NA sentinel from its source column
  # (numeric -> NA_real_, else NA_character_) unless na_types overrides it.
  if (is.null(na_types)) na_types <- list()
  for (out_col in names(col_map)) {
    if (is.null(na_types[[out_col]])) {
      src <- col_map[[out_col]]
      na_types[[out_col]] <- if (src %in% names(df)) {
        na_sentinel_for(df[[src]])
      } else {
        NA_character_
      }
    }
    x <- set_col_value(x, out_col, na_types[[out_col]])
  }

  # License lookup is delegated to taxifydb; emergency fallback leaves it unset.
  lic <- NA_character_

  # Determine the df-side join key: genus-level uses "genus", else canonical_name
  df_join_key <- if (join_col == "genus") "genus" else "canonical_name"

  valid_rows <- which(!is.na(x[[join_col]]))
  if (length(valid_rows) == 0L) {
    return(register_enrichment(x, enrichment_name, source_label,
                               "emergency", 0L, license = lic))
  }

  # Resolve a per-row index into df (aggregate-aware for species-level joins)
  if (join_col == "accepted_name") {
    keys    <- agg_join_keys(x[[join_col]], x[["qualifier"]],
                             binomial_fallback =
                               getOption("taxify.aggregate_trait_fallback", TRUE))
    enr_key <- canon_agg_marker(df[[df_join_key]])
    keep    <- !duplicated(enr_key)
    df      <- df[keep, , drop = FALSE]
    enr_key <- enr_key[keep]
    sel <- agg_select_idx(keys, enr_key)
    idx <- sel$idx
    if (isTRUE(getOption("taxify.trait_provenance", FALSE))) {
      x[[paste0(enrichment_name, "_basis")]] <- sel$basis
    }
  } else {
    df  <- df[!duplicated(df[[df_join_key]]), , drop = FALSE]
    idx <- match(x[[join_col]], df[[df_join_key]])
  }

  matched <- which(!is.na(idx))
  for (out_col in names(col_map)) {
    src_col <- col_map[[out_col]]
    if (src_col %in% names(df)) {
      x[[out_col]][matched] <- df[[src_col]][idx[matched]]
    }
  }

  n_enriched <- sum(
    rowSums(!is.na(x[, names(col_map), drop = FALSE])) > 0L
  )
  register_enrichment(x, enrichment_name, source_label, "emergency", n_enriched,
                      license = lic)
}


#' In-memory group-based enrichment join (emergency fallback)
#'
#' Group-based variant of `enrich_from_dataframe()` for enrichments that
#' filter/pivot by a grouping column (country, language, etc.).
#'
#' @param x A taxify_result data.frame.
#' @param df Data.frame with canonical_name, group_col, and value columns.
#' @param enrichment_name Character.
#' @param group_col Character. Column to filter/pivot on.
#' @param groups Character vector of group values.
#' @param value_cols Named character vector. Names = base output column names,
#'   values = source columns in df.
#' @param source_label Character.
#' @param na_types Named list of NA sentinels (optional).
#' @return The enriched data.frame.
#' @noRd
enrich_from_dataframe_grouped <- function(x, df, enrichment_name, group_col,
                                          groups, value_cols, source_label,
                                          na_types = NULL) {
  if (!group_col %in% names(df)) return(x)

  # License lookup is delegated to taxifydb; emergency fallback leaves it unset.
  lic <- NA_character_

  # Resolve "all" groups
  if (length(groups) == 1L && !anyNA(groups) && groups == "all") {
    groups <- sort(unique(df[[group_col]]))
    groups <- groups[!is.na(groups)]
  }

  # Build output column names, typing each NA sentinel from its source column
  # in df (unless na_types overrides it), then initialize per group.
  if (is.null(na_types)) na_types <- list()
  for (base_col in names(value_cols)) {
    if (is.null(na_types[[base_col]])) {
      src <- value_cols[[base_col]]
      na_types[[base_col]] <- if (src %in% names(df)) {
        na_sentinel_for(df[[src]])
      } else {
        NA_character_
      }
    }
  }
  out_cols <- character(0L)
  for (g in groups) {
    for (base_col in names(value_cols)) {
      out_col <- .group_out_col(base_col, g, groups)
      out_cols <- c(out_cols, out_col)
      x <- set_col_value(x, out_col, na_types[[base_col]])
    }
  }

  valid_rows <- which(!is.na(x$accepted_name))
  if (length(valid_rows) == 0L) {
    return(register_enrichment(x, enrichment_name, source_label,
                               "emergency", 0L, license = lic))
  }

  # Filter to requested groups
  df <- df[df[[group_col]] %in% groups, , drop = FALSE]
  if (nrow(df) == 0L) {
    return(register_enrichment(x, enrichment_name, source_label,
                               "emergency", 0L, license = lic))
  }

  # The same fill the main path uses, so the NA group (NCBI/Open Tree common
  # names carry lang = NA) selects the NA rows here too rather than every row,
  # and the output column naming has one definition.
  df$lookup_name <- df$canonical_name
  x <- .enrich_group_fill(x, df, x$accepted_name, groups, value_cols, group_col)

  n_enriched <- sum(
    rowSums(!is.na(x[, out_cols, drop = FALSE])) > 0L
  )
  x <- register_enrichment(x, enrichment_name, source_label, "emergency",
                            n_enriched, license = lic)

  # Stamp reshape metadata so taxify_long() can auto-detect
  reshape_entry <- list(cols = names(value_cols), group_col = group_col)
  prev <- attr(x, "taxify_reshape") %||% list()
  attr(x, "taxify_reshape") <- c(prev, list(reshape_entry))

  x
}


#' Try emergency fallback for an enrichment
#'
#' Attempts to build the enrichment from source in memory. Returns the
#' data.frame on success, or stops with an informative error.
#'
#' @param name Character. Enrichment identifier.
#' @param download_error Character or NULL. The error that caused the fallback.
#' @param verbose Logical.
#' @return A data.frame with canonical_name + trait columns.
#' @noRd
try_emergency_fallback <- function(name, download_error = NULL, verbose = TRUE) {
  if (taxify_offline()) {
    stop(sprintf(paste0(
      "Enrichment '%s' is not on disk, and offline mode fetches nothing ",
      "(options(taxify.offline) / TAXIFY_OFFLINE)."), name), call. = FALSE)
  }
  if (!requireNamespace("taxifydb", quietly = TRUE)) {
    if (name %in% .build_only_enrichments()) {
      stop(sprintf(
        paste0("Enrichment '%s' requires the 'taxifydb' package.\n",
               "  Its licence does not permit redistribution, so taxify ships no\n",
               "  pre-built copy: taxifydb builds it from the original source on\n",
               "  your own machine.\n",
               "  Install with: remotes::install_github(\"gcol33/taxifydb\")"),
        name
      ), call. = FALSE)
    }
    stop(sprintf(
      paste0("Enrichment '%s' is not available:\n",
             "  %s\n",
             "  Build-from-source requires the 'taxifydb' package.\n",
             "  Install with: remotes::install_github(\"gcol33/taxifydb\")\n",
             "  Report issues: https://github.com/gcol33/taxify/issues"),
      name,
      if (!is.null(download_error)) download_error else "download failed"
    ), call. = FALSE)
  }

  available <- tryCatch(taxifydb::list_enrichments(),
                        error = function(e) character(0L))
  if (!name %in% available) {
    stop(sprintf(
      paste0("Enrichment '%s' is not available:\n",
             "  %s\n",
             "  No build-from-source recipe available in taxifydb.\n",
             "  Report issues: https://github.com/gcol33/taxify/issues"),
      name,
      if (!is.null(download_error)) download_error else "download failed"
    ), call. = FALSE)
  }

  df <- tryCatch(
    taxifydb::enrichment_emergency_fallback(name, verbose = verbose),
    error = function(e) {
      stop(sprintf(
        paste0("Enrichment '%s' is not available.\n",
               "  Pre-built download: %s\n",
               "  Build-from-source: %s\n",
               "  Report issues: https://github.com/gcol33/taxify/issues"),
        name,
        if (!is.null(download_error)) download_error else "failed",
        conditionMessage(e)
      ), call. = FALSE)
    }
  )

  if (verbose) {
    warning(sprintf(
      paste0("[enrichment/%s] Using emergency in-memory fallback.\n",
             "  Rows: %s\n",
             "  Reason: %s\n",
             "  This is temporary and will not be cached to disk.\n",
             "  Report issues: https://github.com/gcol33/taxify/issues"),
      name,
      format(nrow(df), big.mark = ","),
      if (!is.null(download_error)) download_error else "pre-built .vtr unavailable"
    ), call. = FALSE, immediate. = TRUE)
  }

  df
}


#' Simple name-based enrichment join
#'
#' Joins an enrichment .vtr on `accepted_name == canonical_name`. Used by
#' enrichment functions that add columns without filtering (iucn,
#' zanne, indicator_values, etc.).
#'
#' @param x A taxify_result data.frame.
#' @param enrichment_name Character. Enrichment identifier for ensure/download.
#' @param col_map Named character vector. Names = output columns in x,
#'   values = source columns in .vtr.
#' @param source_label Character. Human-readable source for register_enrichment.
#' @param na_types Named list of NA sentinel values for output columns. Defaults
#'   to NA_character_ for all columns. Use NA_real_ for numeric columns, etc.
#' @param join_col Character. Column in `x` to join on. Default `"accepted_name"`
#'   for species-level enrichments. Use `"genus"` for genus-level enrichments.
#' @param genus_fallback Logical. For a mixed-resolution source keyed at both
#'   species and genus level, fill rows that found no species-level match from
#'   their genus-level row (species resolution still wins). Only applies when
#'   `join_col = "accepted_name"` and `x` has a `genus` column. Default `FALSE`.
#' @param verbose Logical.
#' @return The enriched data.frame.
#' @noRd
# Read the attachable trait columns of an enrichment .vtr: every column bar the
# join keys, with its type ("numeric"/"character"). Optionally restrict to a
# name prefix. Returns data.frame(column, type), or NULL if the enrichment is
# unavailable (no download and no taxifydb to build it). Shared by add_gift(),
# the enrichment_cols() browse, and any door offering a cols= selector.
.enrichment_available_cols <- function(enrichment_name, prefix = NULL,
                                       verbose = TRUE) {
  vtr_path <- ensure_enrichment(enrichment_name, verbose = verbose)
  if (is.null(vtr_path)) return(NULL)
  head1 <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  cols  <- setdiff(names(head1), c("canonical_name", "accepted_name", "genus"))
  if (!is.null(prefix)) cols <- grep(paste0("^", prefix), cols, value = TRUE)
  if (length(cols) == 0L) return(NULL)
  types <- vapply(cols, function(cc)
    if (is.numeric(head1[[cc]])) "numeric" else "character", character(1))
  data.frame(column = cols, type = unname(types), stringsAsFactors = FALSE)
}


# Resolve a user `cols` selection to a subset of `col_map` (names = the output
# columns a door attaches). NULL -> default_cols, or every column when no
# default; "all" -> every column; a character vector -> those columns, tolerant
# of a missing `prefix` (so gift's "plant_height_max" resolves to
# "gift_plant_height_max"). Errors with a browse pointer on unknown names.
.apply_col_selection <- function(col_map, cols, default_cols, prefix,
                                 enrichment_name) {
  out <- names(col_map)
  if (is.null(cols)) {
    sel <- if (is.null(default_cols)) out else intersect(default_cols, out)
    return(col_map[sel])
  }
  if (length(cols) == 1L && identical(tolower(cols), "all")) return(col_map)
  want <- as.character(cols)
  # A name as given first, then with the prefix: the auto-exposed extras keep
  # their raw names when a door sets no out_prefix, so only the as-given pass
  # can reach them.
  idx  <- match(tolower(want), tolower(out))
  if (!is.null(prefix) && anyNA(idx)) {
    miss <- is.na(idx)
    idx[miss] <- match(tolower(paste0(prefix, want[miss])), tolower(out))
  }
  if (anyNA(idx)) {
    stop(sprintf(paste0(
      "add_%s(): unknown column(s): %s. Pass column names, \"all\", or NULL ",
      "for the default set. See enrichment_cols(\"%s\")."),
      enrichment_name, paste(want[is.na(idx)], collapse = ", "),
      enrichment_name), call. = FALSE)
  }
  col_map[out[idx]]
}


#' Browse the trait columns an enrichment door can attach
#'
#' Lists the columns available from an enrichment's pre-built `.vtr`, so you can
#' choose which to attach through the doors that accept a `cols` argument (such
#' as [add_gift()] and [add_floraweb()]). Read offline from the local `.vtr`;
#' the first call may trigger the one-time download.
#'
#' @param source Character. An enrichment name (see [list_enrichments()]).
#' @return A data.frame with one row per column: `column` (the name) and `type`
#'   (`"numeric"` or `"character"`).
#' @seealso [add_gift()], [add_floraweb()], [list_enrichments()]
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#' enrichment_cols("gift")
#' options(old)
#' @export
enrichment_cols <- function(source) {
  ac <- .enrichment_available_cols(source, verbose = FALSE)
  if (is.null(ac)) {
    stop(sprintf(paste0(
      "enrichment_cols(): enrichment '%s' is not available. It downloads on ",
      "first use; install 'taxifydb' to build it, or check your connection."),
      source), call. = FALSE)
  }
  ac
}


#' Browse the group values a grouped enrichment can filter on
#'
#' Some enrichment doors attach data per group: GRIIS invasive status by country
#' ([add_griis()]), WCVP native ranges by TDWG region ([add_wcvp()]), vernacular
#' names by language ([add_common_names()]), alien first records by location
#' ([add_alien_first_records()]). This lists the valid group values for such a
#' door, the way [enrichment_cols()] lists a door's columns, so a country,
#' region, or language code need not be guessed. Read offline from the local
#' `.vtr` metadata (falling back to the manifest, then a scan of the `.vtr`); the
#' first call may trigger the one-time download.
#'
#' @param source Character. A grouped enrichment name (see [list_enrichments()]).
#' @param verbose Logical. Print the group column and count. Default `TRUE`.
#' @return A character vector of the available group values, sorted. Stops with a
#'   pointer to [enrichment_cols()] when `source` is a flat (non-grouped)
#'   enrichment, which has no group values.
#' @seealso [enrichment_cols()], [list_enrichments()], [add_griis()],
#'   [add_wcvp()], [add_common_names()], [add_alien_first_records()]
#' @examples
#' old <- options(taxify.data_dir = taxify_example_data())
#' enrichment_groups("griis")   # ISO country codes GRIIS covers
#' options(old)
#' @export
enrichment_groups <- function(source, verbose = TRUE) {
  vtr_path <- ensure_enrichment(source, verbose = verbose)
  if (is.null(vtr_path)) {
    stop(sprintf(paste0(
      "enrichment_groups(): enrichment '%s' is not available. It downloads on ",
      "first use; install 'taxifydb' to build it, or check your connection."),
      source), call. = FALSE)
  }

  meta <- read_enrichment_meta(vtr_path)

  blank <- function(v) {
    is.null(v) || length(v) == 0L || is.na(v[[1L]]) || !nzchar(v[[1L]])
  }

  # The describing fields are copied from the manifest entry into meta.json at
  # download time. An enrichment installed before that copying existed has none
  # of them locally, so the manifest is the fallback for both. Fetched at most
  # once per call.
  entry     <- NULL
  fetched   <- FALSE
  entry_for <- function() {
    if (!fetched) {
      manifest <- tryCatch(fetch_manifest(), error = function(e) NULL)
      entry   <<- if (is.null(manifest)) NULL else
        resolve_enrichment_entry(manifest, source)
      fetched <<- TRUE
    }
    entry
  }

  group_col <- meta$group_col
  if (blank(group_col)) group_col <- entry_for()$group_col
  if (blank(group_col)) {
    stop(sprintf(paste0(
      "enrichment_groups(): '%s' is not a grouped enrichment (no group ",
      "column). Use enrichment_cols(\"%s\") to see its columns."),
      source, source), call. = FALSE)
  }
  group_col <- as.character(group_col)[[1L]]

  groups <- resolve_all_groups(vtr_path, source, group_col,
                               entry = entry_for())
  if (verbose) {
    message(sprintf("%s: %d group value(s) in column '%s'.",
                    source, length(groups), group_col))
  }
  groups
}


#' Every group value an installed enrichment carries
#'
#' Resolution order: the local build's own `meta.json` (O(1), and the only
#' source that describes the bytes on disk), then the manifest entry for an
#' enrichment installed before that field was copied locally, then a distinct
#' scan of the `.vtr`. Reading the manifest first is what made a pinned,
#' restored or stale build report the current release's groups -- all-NA columns
#' for groups it does not carry, and nothing for the groups it does (#64).
#'
#' @param vtr_path Character. Path to the installed `.vtr`.
#' @param name Character. Enrichment identifier.
#' @param group_col Character. The grouping column.
#' @param entry The manifest entry, or `NULL` to fetch it only if needed.
#' @return Sorted character vector of group values, `NA` dropped.
#' @noRd
resolve_all_groups <- function(vtr_path, name, group_col, entry = NULL) {
  meta   <- read_enrichment_meta(vtr_path)
  groups <- meta$available_groups
  if (is.null(groups) || length(groups) == 0L) {
    if (is.null(entry)) {
      manifest <- tryCatch(fetch_manifest(), error = function(e) NULL)
      entry <- if (is.null(manifest)) NULL else
        resolve_enrichment_entry(manifest, name)
    }
    groups <- entry$available_groups
  }
  if (is.null(groups) || length(groups) == 0L) {
    grp <- vectra::tbl(vtr_path) |>
      vectra::select(!!as.name(group_col)) |>
      vectra::distinct() |>
      vectra::collect()
    groups <- grp[[group_col]]
  }
  sort(unique(as.character(groups[!is.na(groups)])))
}


# Resolve a set of parent binomials to their accepted name and accepted-taxon
# backbone id against backbone(s). Memoized per (backbone, parent-set) within a
# session so a chain of add_trait sources -- and the name / id lookups below --
# over the same hybrids resolve the parents only once.
.resolve_parents_resolved <- function(parents, backbone) {
  empty <- data.frame(input_name = character(0L), accepted_name = character(0L),
                      accepted_id = character(0L), stringsAsFactors = FALSE)
  parents <- unique(parents[!is.na(parents) & nzchar(parents)])
  if (length(parents) == 0L) return(empty)
  be_key <- paste(as.character(backbone), collapse = "+")
  key    <- paste0(be_key, "_", paste(sort(parents), collapse = "|"))
  cached <- memo_get(".pres", key)
  if (!is.null(cached)) return(cached)
  pr  <- taxify(parents, backbone = backbone, verbose = FALSE)
  out <- data.frame(
    input_name    = pr$input_name,
    accepted_name = pr$accepted_name,
    accepted_id   = pr$accepted_id %||% rep(NA_character_, nrow(pr)),
    stringsAsFactors = FALSE)
  memo_set(".pres", key, out)
}

# Accepted name of each parent, keyed by input name (the shape callers expect).
.resolve_parents_accepted <- function(parents, backbone) {
  r <- .resolve_parents_resolved(parents, backbone)
  stats::setNames(r$accepted_name, r$input_name)
}

# Accepted-taxon backbone id of each parent, keyed by input name.
.resolve_parents_accepted_id <- function(parents, backbone) {
  r <- .resolve_parents_resolved(parents, backbone)
  stats::setNames(r$accepted_id, r$input_name)
}

# Look up a set of names in an enrichment .vtr, returning the joined rows.
.enrichment_vtr_lookup <- function(vtr_path, join_key, keys, src_cols) {
  keys <- unique(keys[!is.na(keys)])
  if (length(keys) == 0L) return(NULL)
  nd  <- data.frame(lookup_name = keys, stringsAsFactors = FALSE)
  tmp <- tempfile(fileext = ".vtr")
  on.exit(unlink(tmp), add = TRUE)
  vectra::write_vtr(nd, tmp)
  select_cols <- unique(c(join_key, src_cols))
  vectra::inner_join(
    vectra::tbl(tmp),
    vectra::tbl(vtr_path) |> vectra::select(!!!lapply(select_cols, as.name)),
    by = stats::setNames(join_key, "lookup_name")
  ) |> vectra::collect()
}


# ---- Cross-backbone name recovery ---------------------------------------
#
# An enrichment .vtr is keyed on its source's own accepted names, expanded at
# build time onto every backbone's treatment of the same concept
# (taxifydb::resolve_enrichment_names()). Where that expansion missed a
# backbone, the join finds nothing under the name that backbone routed the
# query to, along the same code path and with the same empty output as a name
# the source genuinely does not cover. Minuartia hybrida is the worked case:
# WFO keeps the name, WCVP, COL and Euro+Med have all moved it to Sabulina, and
# the wcvp enrichment holds 49 regions under the Sabulina name and none under
# the Minuartia one.
#
# Recovery runs the same expansion late instead of early: names left empty by
# the direct join are re-resolved through the other installed backbones and the
# join is retried under their accepted names. Only unmatched rows pay for it,
# matching is exact-only, and the pass is skipped when fewer than two backbones
# are installed. Disable with options(taxify.cross_backbone_recovery = FALSE).

# Accepted name, authorship and genus that one set of query names carries in
# each installed backbone, long format, in backbone priority order. Memoized
# per name set for the session, so a chain of add_*() calls over the same
# result resolves them once.
.cross_backbone_alternatives <- function(names_in, kingdoms = NULL) {
  empty <- data.frame(input_name = character(0L), backbone = character(0L),
                      alt_name = character(0L), alt_authorship = character(0L),
                      alt_genus = character(0L), alt_id = character(0L),
                      stringsAsFactors = FALSE)
  q <- unique(names_in[!is.na(names_in) & nzchar(names_in)])
  if (length(q) == 0L) return(empty)
  # Fewer than two backbones is a legitimate no-op (nothing to cross-check
  # against) and stays quiet; a listing that *failed* is not the same fact, and
  # would otherwise switch the whole pass off with no signal.
  bbs <- tryCatch(installed_backbones(), error = function(e) {
    warning(sprintf(
      "Cross-backbone recovery is off: the installed backbones could not be listed (%s).",
      conditionMessage(e)), call. = FALSE)
    NULL
  })
  if (is.null(bbs) || length(bbs) < 2L) return(empty)
  bbs <- order_by_priority(bbs)

  # A backbone scoped to a single kingdom by construction cannot hold the
  # synonymy of a taxon from another one, so it is not worth opening for it --
  # the pass costs about a second per backbone, most of it in opening the .vtr.
  # Backbones with no fixed kingdom (the multi-kingdom syntheses and the
  # aggregators) are always consulted, and so is every backbone when any
  # queried kingdom is unknown.
  if (length(kingdoms) > 0L) {
    reg   <- .backbone_registry()
    fixed <- stats::setNames(reg$fixed_kingdom, reg$name)[bbs]
    bbs   <- bbs[is.na(fixed) | fixed %in% kingdoms]
    if (length(bbs) < 2L) return(empty)
  }

  key <- paste0(paste(bbs, collapse = "+"), "_", paste(sort(q), collapse = "|"))
  cached <- memo_get(".xbb", key)
  if (!is.null(cached)) return(cached)

  # A backbone that fails to resolve the set contributes no alternatives, and
  # the pass then returns fewer recovered values along the same code path as a
  # concept no backbone moved. Naming it is what keeps a failure here from
  # reading as a coverage result, one level below where #55 did exactly that.
  failed <- character(0L)
  per_be <- lapply(bbs, function(bb) {
    r <- tryCatch(taxify(q, backbone = bb, fuzzy = FALSE, verbose = FALSE),
                  error = function(e) {
                    failed <<- c(failed, sprintf("%s (%s)", bb,
                                                 conditionMessage(e)))
                    NULL
                  })
    if (is.null(r) || nrow(r) == 0L) return(empty)
    data.frame(
      input_name     = r$input_name,
      backbone       = bb,
      alt_name       = r$accepted_name,
      alt_authorship = r$accepted_authorship %||% NA_character_,
      alt_genus      = r$genus %||% NA_character_,
      alt_id         = as.character(r$accepted_id %||% NA_character_),
      stringsAsFactors = FALSE
    )
  })
  if (length(failed) > 0L) {
    warning(sprintf(
      paste0("Cross-backbone recovery could not resolve against %s. Any value ",
             "those backbone(s) would have recovered is missing from this join."),
      paste(failed, collapse = "; ")), call. = FALSE)
  }
  out <- do.call(rbind, per_be)
  out <- out[!is.na(out$alt_name), , drop = FALSE]
  rownames(out) <- NULL
  memo_set(".xbb", key, out)
}

# For the rows of `x` a direct join left empty, the highest-priority
# alternative accepted name (or genus, for a genus-keyed asset) that the
# enrichment .vtr does hold. Returns NULL when nothing is recoverable, else a
# list with the per-row alternative, the backbone whose treatment supplied it,
# that backbone's authorship for it, and the joined source rows.
.cross_backbone_recover <- function(x, rows, vtr_path, join_key, join_col,
                                    src_cols, enrichment_name = NULL) {
  if (length(rows) == 0L) return(NULL)
  if (!isTRUE(getOption("taxify.cross_backbone_recovery", TRUE))) return(NULL)
  if (!"accepted_name" %in% names(x)) return(NULL)

  own     <- x$accepted_name[rows]
  own_key <- x[[join_col]][rows]
  keep    <- !is.na(own) & nzchar(own)
  rows    <- rows[keep]; own <- own[keep]; own_key <- own_key[keep]
  if (length(rows) == 0L) return(NULL)

  kingdoms <- if ("kingdom_group" %in% names(x)) {
    k <- unique(x$kingdom_group[rows])
    if (anyNA(k)) NULL else k
  } else {
    NULL
  }
  alts <- .cross_backbone_alternatives(own, kingdoms)
  if (nrow(alts) == 0L) return(NULL)

  by_name <- split(seq_len(nrow(alts)), alts$input_name)
  hit     <- by_name[own]
  reps    <- lengths(hit)
  if (sum(reps) == 0L) return(NULL)
  a <- alts[unlist(hit, use.names = FALSE), , drop = FALSE]

  cand <- data.frame(
    row        = rep(rows, reps),
    own_key    = rep(own_key, reps),
    backbone   = a$backbone,
    alt        = if (join_col == "genus") a$alt_genus else a$alt_name,
    authorship = a$alt_authorship,
    id         = a$alt_id %||% rep(NA_character_, nrow(a)),
    stringsAsFactors = FALSE
  )
  cand <- cand[!is.na(cand$alt) &
                 (is.na(cand$own_key) | cand$alt != cand$own_key), ,
               drop = FALSE]
  if (nrow(cand) == 0L) return(NULL)

  joined <- .enrichment_vtr_lookup(vtr_path, join_key, cand$alt, src_cols)
  if (is.null(joined) || nrow(joined) == 0L) return(NULL)
  cand <- cand[cand$alt %in% joined$lookup_name, , drop = FALSE]
  if (nrow(cand) == 0L) return(NULL)

  # Backbones disagree about where a moved name went (Minuartia hybrida is
  # Sabulina tenuifolia subsp. tenuifolia in WCVP and subsp. hybrida in COL,
  # two taxa the source gives different ranges), so recovery picks one the same
  # way the fallback chain picks accepted_name: first match in backbone
  # priority order, not a vote. The one departure is that a source taxify also
  # carries as a backbone goes first -- the .vtr's rows are keyed on that
  # source's own accepted names, and the other backbones' names are what the
  # build-time expansion added on top, so its treatment is the source's own.
  pref <- order_by_priority(unique(cand$backbone))
  if (!is.null(enrichment_name) && enrichment_name %in% pref) {
    pref <- c(enrichment_name, setdiff(pref, enrichment_name))
  }
  cand <- cand[order(cand$row, match(cand$backbone, pref)), , drop = FALSE]
  cand <- cand[!duplicated(cand$row), , drop = FALSE]

  fill_vec <- function(v) {
    out <- rep(NA_character_, nrow(x))
    out[cand$row] <- v
    out
  }
  list(alt        = fill_vec(cand$alt),
       via        = fill_vec(cand$backbone),
       authorship = fill_vec(cand$authorship),
       id         = fill_vec(cand$id),
       joined     = joined)
}

# Which rows are still completely empty for this enrichment's output columns.
.enrichment_gap_rows <- function(x, out_cols, join_col) {
  which(!is.na(x[[join_col]]) &
          rowSums(!is.na(x[, out_cols, drop = FALSE])) == 0L)
}

# One message per enrichment call, never one per name: a name absent from a
# source is the normal case for any query set wider than the source's scope, so
# the reportable signal is that another backbone's treatment of the same concept
# does have a row, not that this name has no data.
.report_cross_backbone_recovery <- function(enrichment_name, via, verbose) {
  n <- sum(!is.na(via))
  if (n == 0L || !isTRUE(verbose)) return(invisible(NULL))
  message(sprintf(
    paste0("add_%s(): %d name(s) had no row under the accepted name they were ",
           "matched to; recovered via %s."),
    enrichment_name, n, paste(sort(unique(via[!is.na(via)])), collapse = ", ")
  ))
  invisible(NULL)
}


# ---- Infraspecific rank-marker recovery ---------------------------------
#
# The runtime counterpart of the taxifydb build-side fix (gcol33/taxifydb#45).
# GBIF's backbone renders an infraspecific taxon's accepted name without its
# rank connecting term -- "Erica tenella var. tenella" comes out
# "Erica tenella tenella" -- where every other backbone and every botanical
# source keeps the marker. taxifydb reinstates it at build time from the
# verbatim scientific name, but a user still on an older gbif.vtr holds the
# marker-less form, so a join keyed on the rendered name misses in either
# direction: an enrichment key that carries the marker against a stale
# marker-less backbone name, or a marker-less enrichment key against a backbone
# name that kept it.
#
# For rows a direct (and cross-backbone) join left empty, recovery retries the
# join under the name's alternative marker renderings -- the bare trinomial and
# each canonical marker (.infra_marker_variants) -- so a match lands only when
# the rank marker is the sole difference. A rank-insensitive comparison can
# collide DISTINCT taxa: "Aus bus var. cus" and "Aus bus subsp. cus" are
# different names, not one taxon spelled two ways. So when a row's alternatives
# reach more than one distinct enrichment name the row is left unmatched rather
# than resolved to a guess. Zoological trinomials ("Panthera leo persica") are
# correctly marker-less and match directly, so they never reach this fallback;
# one that does (absent from the source) finds no marker-ful form and stays
# unmatched. Runs only on still-empty rows and is exact under the marker
# normalization. Disable with options(taxify.infra_marker_recovery = FALSE).

# For the still-empty `rows` of `x`, the single enrichment key each row's
# alternative marker renderings reach -- when they reach exactly one. Returns
# NULL when nothing is recoverable, else a list with the per-row key
# (`alt`, one entry per row of `x`, NA where none or ambiguous) and the joined
# source rows for filling.
.infra_marker_recover <- function(x, rows, vtr_path, join_key, join_col,
                                  src_cols) {
  if (length(rows) == 0L) return(NULL)
  if (!isTRUE(getOption("taxify.infra_marker_recovery", TRUE))) return(NULL)

  own  <- x[[join_col]][rows]
  keep <- !is.na(own) & nzchar(own)
  rows <- rows[keep]; own <- own[keep]
  if (length(rows) == 0L) return(NULL)

  vars <- lapply(own, .infra_marker_variants)
  reps <- lengths(vars)
  if (sum(reps) == 0L) return(NULL)
  cand <- data.frame(
    row = rep(rows, reps),
    alt = unlist(vars, use.names = FALSE),
    stringsAsFactors = FALSE
  )

  joined <- .enrichment_vtr_lookup(vtr_path, join_key, cand$alt, src_cols)
  if (is.null(joined) || nrow(joined) == 0L) return(NULL)
  cand <- unique(cand[cand$alt %in% joined$lookup_name, , drop = FALSE])
  if (nrow(cand) == 0L) return(NULL)

  # A rank-insensitive key can name more than one real taxon. Where a row's
  # alternatives reach two or more distinct enrichment names, the marker is not
  # the only difference between real names, so the row is left unmatched rather
  # than resolved to an arbitrary one.
  n_by_row <- table(cand$row)
  ok_rows  <- as.integer(names(n_by_row))[n_by_row == 1L]
  cand     <- cand[cand$row %in% ok_rows, , drop = FALSE]
  if (nrow(cand) == 0L) return(NULL)

  alt <- rep(NA_character_, nrow(x))
  alt[cand$row] <- cand$alt
  list(alt = alt, joined = joined)
}

# Hybrid trait ladder: for a formula-hybrid row whose trait is still missing
# after the direct join, fill it from the two parents -- numeric averaged, a
# categorical taken as the shared value or "A x B" on disagreement (with a
# warning on the door path). When the parents were materialized as columns
# (add_hybrid_info) and the door exposes all columns, per-parent trait values
# are added as `<trait>_parent1` / `<trait>_parent2`.
.hybrid_trait_fallback <- function(x, col_map, join_key, vtr_path,
                                   expose_all = TRUE, verbose = TRUE) {
  if (!all(c("hybrid_type", "input_name") %in% names(x))) return(x)
  hf <- which(!is.na(x$hybrid_type) & x$hybrid_type == "formula")
  if (length(hf) == 0L) return(x)

  pf <- lapply(x$input_name[hf], parse_hybrid_formula)
  p1 <- vapply(pf, function(z) z$parent_1 %||% NA_character_, character(1L))
  p2 <- vapply(pf, function(z) z$parent_2 %||% NA_character_, character(1L))

  meta    <- attr(x, "taxify_meta")
  backbone <- if (!is.null(meta$backbone)) meta$backbone else "wfo"
  acc <- .resolve_parents_accepted(c(p1, p2), backbone)
  a1  <- unname(acc[p1]); a2 <- unname(acc[p2])

  lk <- .enrichment_vtr_lookup(vtr_path, join_key, c(a1, a2), unname(col_map))
  if (is.null(lk) || nrow(lk) == 0L) return(x)
  lk  <- lk[!duplicated(lk$lookup_name), , drop = FALSE]
  ix1 <- match(a1, lk$lookup_name)
  ix2 <- match(a2, lk$lookup_name)

  show_parents <- isTRUE(expose_all) && "hybrid_parent_1" %in% names(x)
  conflict <- character(0L)

  for (out_col in names(col_map)) {
    src <- col_map[[out_col]]
    if (!src %in% names(lk)) next
    v1 <- lk[[src]][ix1]
    v2 <- lk[[src]][ix2]
    numeric_col <- is.numeric(x[[out_col]])

    for (k in seq_along(hf)) {
      r <- hf[k]
      if (!is.na(x[[out_col]][r])) next            # a direct value wins
      w1 <- v1[k]; w2 <- v2[k]
      if (is.na(w1) && is.na(w2)) next
      if (is.na(w1)) {
        x[[out_col]][r] <- w2
      } else if (is.na(w2)) {
        x[[out_col]][r] <- w1
      } else if (numeric_col) {
        x[[out_col]][r] <- mean(c(w1, w2))
      } else if (identical(as.character(w1), as.character(w2))) {
        x[[out_col]][r] <- w1
      } else {
        x[[out_col]][r] <- paste(w1, "x", w2)
        conflict <- c(conflict, out_col)
      }
    }

    if (show_parents) {
      p1col <- paste0(out_col, "_parent1")
      p2col <- paste0(out_col, "_parent2")
      x[[p1col]] <- if (numeric_col) NA_real_ else NA_character_
      x[[p2col]] <- if (numeric_col) NA_real_ else NA_character_
      x[[p1col]][hf] <- v1
      x[[p2col]][hf] <- v2
    }
  }

  if (length(conflict) > 0L && isTRUE(expose_all)) {
    warning(sprintf(
      "Hybrid parents disagree on categorical trait(s): %s; combined as \"A x B\".",
      paste(unique(conflict), collapse = ", ")), call. = FALSE)
  }
  x
}


enrich_simple <- function(x, enrichment_name, col_map, source_label,
                          na_types = NULL, join_col = "accepted_name",
                          cols = NULL, default_cols = NULL, col_prefix = NULL,
                          out_prefix = NULL,
                          expose_all = TRUE, verbose = TRUE,
                          genus_fallback = FALSE,
                          aggregate_trait_fallback =
                            getOption("taxify.aggregate_trait_fallback", TRUE)) {
  if (!join_col %in% names(x)) {
    stop(sprintf("x must have a '%s' column (from taxify())", join_col),
         call. = FALSE)
  }

  # Expose every other column the .vtr carries (the sources were widened at
  # build time so no trait is dropped), while keeping the door's curated
  # col_map as the default output. One place makes all doors cols=-aware: the
  # default attaches the curated set, cols = "all" attaches everything, cols =
  # <names> picks any. Doors that manage selection themselves (default_cols
  # given, e.g. add_gift) opt out.
  if (isTRUE(expose_all) && is.null(default_cols)) {
    av <- tryCatch(.enrichment_available_cols(enrichment_name, verbose = FALSE),
                   error = function(e) NULL)
    if (!is.null(av)) {
      extra <- setdiff(av$column, unname(col_map))
      if (length(extra) > 0L) {
        default_cols <- names(col_map)               # curated output = default
        # Auto-exposed extras keep their raw .vtr names unless the door sets an
        # out_prefix (namespacing every exposed column, so two sibling sources
        # -- e.g. combine + combine_imputed -- never collide on a shared extra).
        raw_out <- if (is.null(out_prefix)) extra else paste0(out_prefix, extra)
        ex_out  <- make.unique(c(names(col_map), raw_out))[-seq_along(col_map)]
        col_map <- c(col_map, stats::setNames(extra, ex_out))
        if (is.null(na_types)) na_types <- list()
        et <- av$type[match(extra, av$column)]
        for (k in seq_along(ex_out)) {
          na_types[[ex_out[k]]] <-
            if (identical(et[k], "numeric")) NA_real_ else NA_character_
        }
      }
    }
  }

  # User column selection (only engaged when a door forwards cols/default_cols).
  if (!is.null(cols) || !is.null(default_cols)) {
    full_n  <- length(col_map)
    col_map <- .apply_col_selection(col_map, cols, default_cols, col_prefix,
                                    enrichment_name)
    if (is.null(cols) && !is.null(default_cols) && verbose &&
        length(col_map) < full_n &&
        is.null(.taxify_env[[paste0(".cols_notice.", enrichment_name)]])) {
      message(sprintf(paste0(
        "add_%s(): attaching %d of %d columns. Pass cols = \"all\" for all, ",
        "or see enrichment_cols(\"%s\")."),
        enrichment_name, length(col_map), full_n, enrichment_name))
      .taxify_env[[paste0(".cols_notice.", enrichment_name)]] <- TRUE
    }
  }

  vtr_path <- ensure_enrichment(enrichment_name, verbose = verbose)

  # Emergency fallback: ensure_enrichment() returned NULL → all paths failed

  if (is.null(vtr_path)) {
    df <- try_emergency_fallback(enrichment_name, verbose = verbose)
    return(enrich_from_dataframe(x, df, enrichment_name, col_map,
                                 source_label, na_types,
                                 join_col = join_col))
  }

  # Read the .vtr schema once: it types the output columns and confirms which
  # source columns exist. NA sentinels are derived from the source column's type
  # (numeric -> NA_real_, else NA_character_), so a door never hand-declares
  # na_types; an explicit na_types entry still wins.
  schema <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  if (is.null(na_types)) na_types <- list()
  for (out_col in names(col_map)) {
    if (is.null(na_types[[out_col]])) {
      src <- col_map[[out_col]]
      na_types[[out_col]] <- if (src %in% names(schema)) {
        na_sentinel_for(schema[[src]])
      } else {
        NA_character_
      }
    }
    x <- set_col_value(x, out_col, na_types[[out_col]])
  }

  valid_rows <- which(!is.na(x[[join_col]]))

  # A species-level join can still enrich a formula hybrid (accepted_name NA)
  # from its parents, so an empty valid_rows is not necessarily the end.
  has_formula <- join_col == "accepted_name" && "hybrid_type" %in% names(x) &&
    any(!is.na(x$hybrid_type) & x$hybrid_type == "formula")

  mapped_src    <- unname(col_map)
  available_src <- intersect(mapped_src, names(schema))

  # A mapped source column absent from the .vtr schema attaches an all-NA output
  # column, which is indistinguishable from a genuine registry/column typo. Name
  # the gap instead of dropping it silently. Two absences are expected, not
  # bugs, and are excluded: the trait verb's spread join maps optional
  # within-source partners <col>_min / <col>_max alongside each value column
  # <col> (the join falls back to the point value when they are absent), so a
  # missing _min/_max whose base column is itself mapped is skipped; and
  # auto-exposed extras are drawn from the schema, so they never appear here.
  # The bundled example database is held to the same bar: its fixtures carry
  # every column a door maps (test-doors-all.R), so a warning there is drift.
  missing_src <- setdiff(mapped_src, names(schema))
  spread_partner <- grepl("_(min|max)$", missing_src) &
    sub("_(min|max)$", "", missing_src) %in% mapped_src
  missing_src <- missing_src[!spread_partner]
  if (length(missing_src) > 0L) {
    warning(sprintf(
      "Enrichment '%s': mapped column(s) not in the .vtr: %s. Attached as all-NA.",
      enrichment_name, paste(sort(unique(missing_src)), collapse = ", ")
    ), call. = FALSE)
  }

  if (length(available_src) == 0L ||
      (length(valid_rows) == 0L && !has_formula)) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L,
                               license = lic))
  }

  # Filter col_map to available columns
  col_map <- col_map[col_map %in% available_src]

  # Determine join key in enrichment .vtr. A genus-level enrichment sets
  # join_col = "genus" and its .vtr carries a "genus" column; the species
  # default ("accepted_name") resolves against canonical_name/accepted_name. A
  # join_col the door set explicitly (anything but the accepted_name default)
  # that the .vtr does not carry is a wiring bug: a genus join against a
  # species-keyed asset would fall through to canonical_name and match "Amanita"
  # against "Amanita muscaria", attaching an all-NA column, so it stops instead.
  if (join_col != "accepted_name" && !(join_col %in% names(schema))) {
    stop(sprintf(
      paste0("Enrichment '%s' was joined on '%s', but its .vtr has no '%s' ",
             "column (has: %s). A door requesting join_col = \"%s\" against an ",
             "asset not keyed at that level is a wiring bug."),
      enrichment_name, join_col, join_col,
      paste(names(schema), collapse = ", "), join_col
    ), call. = FALSE)
  }
  join_key <- if (join_col == "genus" && "genus" %in% names(schema)) {
    "genus"
  } else if ("canonical_name" %in% names(schema)) {
    "canonical_name"
  } else if ("accepted_name" %in% names(schema)) {
    "accepted_name"
  } else {
    stop(sprintf(
      "Enrichment '%s' .vtr has no joinable column (tried: %s, canonical_name, accepted_name).",
      enrichment_name, join_col
    ), call. = FALSE)
  }

  # Direct join (only when there are resolved rows to look up). Species-level
  # joins are aggregate-aware: an aggregate query reaches the aggregate trait
  # row, a species query inherits an aggregate-level trait when no species-level
  # one exists (downward), and -- when aggregate_trait_fallback is on -- an
  # aggregate query with no aggregate-level value falls back to the nominal
  # binomial (upward, recorded as basis = "binomial"). Genus-level joins keep
  # plain exact matching.
  if (length(valid_rows) > 0L) {
    agg_aware <- join_col == "accepted_name"
    if (agg_aware) {
      keys <- agg_join_keys(x[[join_col]], x[["qualifier"]],
                            binomial_fallback = aggregate_trait_fallback)
      lookup_pool <- unique(c(keys$primary[valid_rows], keys$inherit[valid_rows]))
      lookup_pool <- lookup_pool[!is.na(lookup_pool)]
    } else {
      lookup_pool <- unique(x[[join_col]][valid_rows])
    }

    joined <- .enrichment_vtr_lookup(vtr_path, join_key, lookup_pool,
                                     unname(col_map))

    if (!is.null(joined) && nrow(joined) > 0L) {
      if (agg_aware) {
        enr_key <- canon_agg_marker(joined$lookup_name)
        keep    <- !duplicated(enr_key)
        joined  <- joined[keep, , drop = FALSE]
        enr_key <- enr_key[keep]
        sel <- agg_select_idx(keys, enr_key)
        idx <- sel$idx
        if (isTRUE(getOption("taxify.trait_provenance", FALSE))) {
          x[[paste0(enrichment_name, "_basis")]] <- sel$basis
        }
      } else {
        joined <- joined[!duplicated(joined$lookup_name), , drop = FALSE]
        idx <- match(x[[join_col]], joined$lookup_name)
      }

      matched <- which(!is.na(idx))
      for (out_col in names(col_map)) {
        src_col <- col_map[[out_col]]
        if (src_col %in% names(joined)) {
          x[[out_col]][matched] <- joined[[src_col]][idx[matched]]
        }
      }
    }
  }

  # Cross-backbone recovery: a row still empty here may be one the source does
  # cover, under the accepted name a different backbone gives the same concept.
  recovered <- rep(NA_character_, nrow(x))
  rec <- .cross_backbone_recover(
    x, .enrichment_gap_rows(x, names(col_map), join_col),
    vtr_path, join_key, join_col, unname(col_map), enrichment_name)
  if (!is.null(rec)) {
    before <- rowSums(!is.na(x[, names(col_map), drop = FALSE])) > 0L
    lk  <- rec$joined[!duplicated(rec$joined$lookup_name), , drop = FALSE]
    idx <- match(rec$alt, lk$lookup_name)
    for (out_col in names(col_map)) {
      src_col <- col_map[[out_col]]
      if (!src_col %in% names(lk)) next
      fill <- which(is.na(x[[out_col]]) & !is.na(idx))
      x[[out_col]][fill] <- lk[[src_col]][idx[fill]]
    }
    got <- rowSums(!is.na(x[, names(col_map), drop = FALSE])) > 0L & !before
    recovered[got] <- rec$via[got]
    .report_cross_backbone_recovery(enrichment_name, recovered, verbose)
  }

  # Infraspecific rank-marker recovery: a row still empty may match an
  # enrichment key that renders the same taxon with a different (or, for a stale
  # GBIF backbone name, a dropped) infraspecific rank marker.
  rec2 <- .infra_marker_recover(
    x, .enrichment_gap_rows(x, names(col_map), join_col),
    vtr_path, join_key, join_col, unname(col_map))
  if (!is.null(rec2)) {
    lk  <- rec2$joined[!duplicated(rec2$joined$lookup_name), , drop = FALSE]
    idx <- match(rec2$alt, lk$lookup_name)
    for (out_col in names(col_map)) {
      src_col <- col_map[[out_col]]
      if (!src_col %in% names(lk)) next
      fill <- which(is.na(x[[out_col]]) & !is.na(idx))
      x[[out_col]][fill] <- lk[[src_col]][idx[fill]]
    }
  }

  # Hybrid ladder: a formula whose trait is still missing after the direct join
  # is filled from the average of its two parents (species-level joins only).
  if (join_col == "accepted_name") {
    x <- .hybrid_trait_fallback(x, col_map, join_key, vtr_path,
                                expose_all = expose_all, verbose = verbose)
  }

  # Genus fallback, last: a mixed-resolution source (e.g. the USEPA freshwater
  # trait table) records each trait at the finest level available -- some at
  # species, some only at genus, and often a mix within one species. Any trait
  # cell still empty after every species-level pass above is filled from the
  # taxon's genus-level row (x$genus matched against the same key column, where
  # the genus-rank strings live). The fill is per cell and runs after the
  # recovery passes, so species resolution always wins: filling a cell early
  # would take the row out of `.enrichment_gap_rows()`, which selects only rows
  # that are still entirely empty, and the species-level value the source holds
  # under another backbone's accepted name would never be looked for (#64).
  if (isTRUE(genus_fallback) && join_col == "accepted_name" &&
      "genus" %in% names(x)) {
    gap_rows <- which(
      !is.na(x[["genus"]]) &
        rowSums(is.na(x[, names(col_map), drop = FALSE])) > 0L
    )
    if (length(gap_rows) > 0L) {
      gpool <- unique(x[["genus"]][gap_rows])
      gjoin <- .enrichment_vtr_lookup(vtr_path, join_key, gpool,
                                      unname(col_map))
      if (!is.null(gjoin) && nrow(gjoin) > 0L) {
        gjoin <- gjoin[!duplicated(gjoin$lookup_name), , drop = FALSE]
        gidx  <- match(x[["genus"]], gjoin$lookup_name)
        for (out_col in names(col_map)) {
          src_col <- col_map[[out_col]]
          if (src_col %in% names(gjoin)) {
            fill <- which(is.na(x[[out_col]]) & !is.na(gidx))
            x[[out_col]][fill] <- gjoin[[src_col]][gidx[fill]]
          }
        }
      }
    }
  }

  meta <- read_enrichment_meta(vtr_path)
  ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
  lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
  n_enriched <- sum(
    rowSums(!is.na(x[, names(col_map), drop = FALSE])) > 0L
  )
  register_enrichment(x, enrichment_name, source_label, ver, n_enriched,
                      license = lic,
                      n_recovered = sum(!is.na(recovered)))
}


#' Authorship-like column in an enrichment .vtr schema, if any
#'
#' Grouped enrichments join on a bare accepted-name string (see
#' `enrich_by_group()`), which collapses distinct homonymous concepts that
#' happen to share a name. An authorship column is the only signal available
#' to tell them apart; this picks the first alias present, in order of how
#' likely it is to be the taxon's own authorship rather than something else.
#' taxifydb reads the same column at build time, so that the row it keys under
#' a name is the one this guard will accept.
#'
#' @param schema_names Character vector of column names in the enrichment
#'   `.vtr`.
#' @return The matching column name, or `NULL` if none of the aliases is
#'   present.
#' @keywords internal
#' @export
enrichment_authorship_col <- function(schema_names) {
  aliases <- c("taxon_authors", "scientificNameAuthorship", "authorship",
              "author")
  hit <- aliases[aliases %in% schema_names]
  if (length(hit) == 0L) NULL else hit[1L]
}


#' Normalized parts of an authorship string, for comparison
#'
#' Backbones and enrichment sources spell one authorship several ways -- `et`
#' or `&`, with or without the periods after an abbreviation, and occasionally
#' a plain misspelling (WFO records *Calluna vulgaris* as `(L.) Hill` where
#' every other source says `(L.) Hull`). A raw string comparison therefore
#' reads a spelling difference as a different taxonomic concept (#51). This
#' splits an authorship into its basionym author (the parenthetical part,
#' empty when there is none) and its combining author, and reduces each to
#' lowercase letters with `&` as the only separator kept.
#'
#' @param x Character vector of authorship strings.
#' @return List of three character vectors, each the length of `x`: `paren`,
#'   `terminal`, and `key` (the two joined, the full comparison key). `NA` or
#'   empty input gives `NA` in all three.
#' @noRd
author_key_parts <- function(x) {
  x <- trimws(x)
  x[!is.na(x) & !nzchar(x)] <- NA_character_
  na <- is.na(x)

  paren <- rep("", length(x))
  rest <- x
  wrapped <- !na & startsWith(x, "(")
  if (any(wrapped)) {
    paren[wrapped] <- sub("^[(]([^)]*)[)].*$", "\\1", x[wrapped])
    rest[wrapped] <- sub("^[(][^)]*[)]", "", x[wrapped])
  }

  norm <- function(s) {
    s <- tolower(s)
    s <- gsub("&", " and ", s, fixed = TRUE)
    s <- gsub("(^| )et( |$)", " and ", s)
    s <- gsub("[^a-z]+", " ", s)
    s <- gsub("(^| )and( |$)", " & ", s)
    trimws(gsub(" +", " ", s))
  }
  paren <- norm(paren)
  terminal <- norm(rest)
  key <- ifelse(nzchar(paren), paste0("(", paren, ") ", terminal), terminal)

  paren[na] <- NA_character_
  terminal[na] <- NA_character_
  key[na] <- NA_character_
  list(paren = paren, terminal = terminal, key = key)
}


#' Is one normalized authorship a spelling variant of another?
#'
#' Applied only after exact comparison on the normalized key has failed, to
#' tell a source that spells the author differently from one that names a
#' genuinely different author. Both sides must agree exactly on the basionym
#' author, and the combining author must be either one edit apart or a
#' truncated abbreviation of the other (`schischk` of `schischkin`, the
#' continuation letter required so `hook` does not swallow `hook f`). The
#' four-character floor keeps the one- and two-letter abbreviations that
#' actually distinguish authors (`L.` vs `L.f.`) out of the comparison.
#'
#' @param q,cand Lists with `paren` and `terminal`, from `author_key_parts()`.
#' @return `TRUE` when the two are the same author spelled differently.
#' @noRd
author_key_near <- function(q, cand) {
  if (is.na(q$terminal) || is.na(cand$terminal)) return(FALSE)
  if (!identical(q$paren, cand$paren)) return(FALSE)
  a <- q$terminal
  b <- cand$terminal
  if (nchar(a) < 4L || nchar(b) < 4L) return(FALSE)
  if (as.integer(utils::adist(a, b)) <= 1L) return(TRUE)
  short <- if (nchar(a) <= nchar(b)) a else b
  long <- if (nchar(a) <= nchar(b)) b else a
  startsWith(long, short) &&
    grepl("^[a-z]$", substr(long, nchar(short) + 1L, nchar(short) + 1L))
}


#' Rank a scientific name is written at, from its connecting term
#'
#' `"species"` for a binomial, the lowercased rank word for a trinomial with a
#' marker (`subsp.` -> `"subspecies"`), `NA` for anything else (a genus, a
#' marker-less zoological trinomial).
#'
#' @param nm Character vector of names.
#' @return Character vector, the length of `nm`.
#' @noRd
name_rank_of <- function(nm) {
  markers <- c("subsp." = "subspecies", "ssp." = "subspecies",
               "var." = "variety", "f." = "form", "forma" = "form",
               "subvar." = "subvariety", "subf." = "subform",
               "nothosubsp." = "nothosubsp.", "nothovar." = "nothovar.")
  tok <- strsplit(trimws(nm), " +")
  vapply(tok, function(t) {
    if (length(t) == 2L) return("species")
    if (length(t) == 4L && t[3L] %in% names(markers)) return(markers[[t[3L]]])
    NA_character_
  }, character(1L), USE.NAMES = FALSE)
}

# Is each name an autonym (`Quercus robur subsp. robur`)?
name_is_autonym <- function(nm) {
  tok <- strsplit(trimws(nm), " +")
  vapply(tok, function(t) length(t) == 4L && identical(t[2L], t[4L]),
         logical(1L), USE.NAMES = FALSE)
}

# Rank strings as the backbones and WCVP write them ("SUBSPECIES",
# "Subspecies", "nothosubsp.") reduced to the vocabulary of name_rank_of().
norm_rank <- function(r) {
  r <- tolower(trimws(r))
  r[r %in% c("subsp.", "ssp.")] <- "subspecies"
  r[r == "var."] <- "variety"
  r[r %in% c("f.", "forma")] <- "form"
  r
}


#' Every name a backbone places inside an accepted taxon
#'
#' The circumscription of each accepted taxon in `ids`, as the backbone draws
#' it: the taxon itself and its synonyms, plus, for a species, its accepted
#' infraspecific taxa and their synonyms. COL keeps *Eucalyptus bicostata*
#' Maiden, Blakely & Simmonds as *E. globulus* subsp. *bicostata*, so its
#' *E. globulus* covers the name; WFO keeps it a species of its own, so WFO's
#' does not. Session-memoized per backbone and id set.
#'
#' @param backbone Backbone name.
#' @param ids Accepted taxon ids in that backbone.
#' @return A data.frame with `root` (the id from `ids`), `authorship`, `rank`,
#'   `specific_epithet`, `infraspecific_epithet`; `NULL` when the backbone
#'   cannot be read or carries none of the needed columns.
#' @noRd
.backbone_circumscription <- function(backbone, ids) {
  ids <- sort(unique(ids[!is.na(ids) & nzchar(ids)]))
  if (length(ids) == 0L || is.na(backbone)) return(NULL)
  key <- paste0(backbone, "_", paste(ids, collapse = "|"))
  cached <- memo_get(".circ", key)
  if (!is.null(cached)) return(cached)

  bb <- tryCatch(backbone_path(backbone, verbose = FALSE),
                 error = function(e) NULL)
  if (is.null(bb)) return(NULL)
  schema <- vtr_schema(bb)
  if (!all(c("taxon_id", "accepted_taxon_id", "authorship") %in% schema)) {
    return(NULL)
  }
  cols <- intersect(c("taxon_id", "accepted_taxon_id", "authorship",
                      "taxon_rank", "specific_epithet",
                      "infraspecific_epithet", "key_species", "is_synonym"),
                    schema)
  pad <- function(df) {
    for (cc in setdiff(cols, names(df))) df[[cc]] <- NA_character_
    df
  }

  own <- backbone_join(bb, ids, "accepted_taxon_id", cols)
  if (is.null(own) || nrow(own) == 0L) return(NULL)
  own <- pad(own)
  own$root <- own$lookup
  parts <- list(own)

  # A species' accepted infraspecific taxa share its key_species. A key two
  # accepted species hold (a homonym pair in the backbone) cannot say whose
  # children they are, so it contributes none.
  if (all(c("key_species", "is_synonym", "taxon_rank") %in% cols)) {
    roots <- own[own$taxon_id == own$root &
                   norm_rank(own$taxon_rank) == "species" &
                   !is.na(own$key_species), , drop = FALSE]
    roots <- roots[!duplicated(roots$root), , drop = FALSE]
    shared <- roots$key_species[duplicated(roots$key_species)]
    roots <- roots[!roots$key_species %in% shared, , drop = FALSE]
    if (nrow(roots) > 0L) {
      kids <- backbone_join(bb, roots$key_species, "key_species", cols,
                            pre = function(t) vectra::filter(t, is_synonym == FALSE))
      if (!is.null(kids) && nrow(kids) > 0L) {
        kids <- kids[kids$taxon_id == kids$accepted_taxon_id &
                       norm_rank(kids$taxon_rank) != "species", , drop = FALSE]
      }
      if (!is.null(kids) && nrow(kids) > 0L) {
        kid_root <- roots$root[match(kids$lookup, roots$key_species)]
        under <- backbone_join(bb, kids$taxon_id, "accepted_taxon_id", cols)
        if (!is.null(under) && nrow(under) > 0L) {
          under <- pad(under)
          under$root <- kid_root[match(under$lookup, kids$taxon_id)]
          parts <- c(parts, list(under))
        }
      }
    }
  }

  keep <- c("root", "authorship", "taxon_rank", "specific_epithet",
            "infraspecific_epithet")
  out <- do.call(rbind, lapply(parts, function(p) p[, keep, drop = FALSE]))
  names(out)[names(out) == "taxon_rank"] <- "rank"
  out$rank <- norm_rank(out$rank)
  rownames(out) <- NULL
  memo_set(".circ", key, out)
}


#' Does a backbone's circumscription contain an enrichment row's concept?
#'
#' A row keyed under a name by the build-time expansion carries the authorship
#' of its own concept, which can differ from the one the name resolved to. It
#' belongs to the resolved taxon when the backbone places a name of that
#' concept inside it: the same author (exactly or as a spelling variant), or a
#' basionym relation in either direction -- COL's *E. globulus* subsp.
#' *bicostata* (Maiden, Blakely & Simmonds) J.B.Kirkp. is the recombination of
#' the WCVP species *E. bicostata* Maiden, Blakely & Simmonds. An autonym has
#' no author, so it is recognised by its rank and epithet instead.
#'
#' @param rparts Author parts of the row (`paren`, `terminal`, `key`, scalars).
#' @param rrank,rinfra The row's rank (normalized) and infraspecific epithet.
#' @param circ The rows of `.backbone_circumscription()` for one root.
#' @return Logical scalar.
#' @noRd
row_in_circumscription <- function(rparts, rrank, rinfra, circ) {
  if (is.null(circ) || nrow(circ) == 0L) return(FALSE)
  if (is.na(rparts$key)) {
    if (is.na(rinfra) || is.na(rrank)) return(FALSE)
    auto <- !is.na(circ$infraspecific_epithet) &
      circ$infraspecific_epithet == circ$specific_epithet
    return(any(auto & circ$infraspecific_epithet == rinfra &
                 circ$rank == rrank, na.rm = TRUE))
  }
  cp <- author_key_parts(circ$authorship)
  known <- !is.na(cp$key)
  if (!any(known)) return(FALSE)
  if (rparts$key %in% cp$key[known]) return(TRUE)
  if (any(nzchar(cp$paren[known]) & cp$paren[known] == rparts$key)) return(TRUE)
  if (nzchar(rparts$paren) && rparts$paren %in% cp$key[known]) return(TRUE)
  any(vapply(which(known), function(i) {
    author_key_near(rparts, list(paren = cp$paren[i], terminal = cp$terminal[i]))
  }, logical(1L)))
}


#' Keep the rows of a group join that belong to the concept `x` resolved to
#'
#' `enrich_by_group()` joins on a bare accepted-name string, so a name that
#' resolves to more than one distinct concept in the source (different
#' authorship) would otherwise keep whichever row happens to survive the
#' later per-group `!duplicated()` dedup -- silently, and not necessarily the
#' concept `x` actually resolved to (#50).
#'
#' Concepts are counted on the normalized authorship key, and the concept `x`
#' resolved to is picked by that key, then by a spelling-variant test, then by
#' a shared basionym author (#51). Exact string equality alone is not enough:
#' the sources disagree over how an author is written and over who is credited
#' with a recombination, so on its own it discards the data of names that are
#' not homonyms at all. When no pass picks exactly one concept, every row for
#' the name is dropped -- left NA rather than guessing.
#'
#' A row with no authorship is a concept too. WCVP writes no author for an
#' autonym, and the build keys an autonym's range under every name a backbone
#' sends it to, so *Erigeron caucasicus* subsp. *caucasicus* sits under
#' *Erigeron pulchellus*. Under an autonym key such rows are the name's own
#' concept; under any other key they are some other name's autonym.
#'
#' Rows of the other concepts are kept when the backbone `x` matched through
#' places that concept inside the matched taxon (`row_in_circumscription()`),
#' so a name follows the matched backbone's own treatment: through COL,
#' *E. globulus* carries *E. bicostata*'s New South Wales record, through WFO
#' it does not. A row of a broader rank than the name (a species' range under
#' one of its subspecies) never is.
#'
#' The warning distinguishes two reasons (#87), since they call for different
#' follow-up. A **tie**: at least one candidate is a near-miss or shares the
#' query's basionym author, but more than one does, so picking one would be a
#' guess between plausible matches. A **no-match**: none of the candidates
#' share anything with the query's authorship at all -- not a tie to break,
#' but a sign the matched concept may not be in this enrichment under any
#' spelling (sunk into a broader taxon, split differently, or filed as a
#' synonym elsewhere). Each reason gets its own aggregate warning.
#'
#' @param joined The `join_key`-on-`lookup_name` join result, before group
#'   filtering. Must carry `lookup_name` and `authorship_col`.
#' @param x The taxify_result being enriched, for `accepted_authorship`.
#' @param authorship_col Name of the authorship-like column in `joined`.
#' @param enrichment_name Character, for the warning message.
#' @param rank_col,infra_col Names of the row's rank and infraspecific-epithet
#'   columns in `joined`, or `NULL` when the source carries none.
#' @return `joined`, row-filtered to the resolved concept and the concepts the
#'   matched backbone places inside it, the resolved concept's rows first.
#' @noRd
disambiguate_by_name_authorship <- function(joined, x, authorship_col,
                                            enrichment_name, rank_col = NULL,
                                            infra_col = NULL) {
  parts <- author_key_parts(joined[[authorship_col]])
  key <- parts$key
  nm_row <- joined$lookup_name
  rrank <- if (!is.null(rank_col)) norm_rank(joined[[rank_col]]) else
    rep(NA_character_, nrow(joined))
  rinfra <- if (!is.null(infra_col)) joined[[infra_col]] else
    rep(NA_character_, nrow(joined))

  # Concept of each row: its authorship key, the name's own autonym, or some
  # other autonym (no author, under a name it is not the autonym of).
  auto_key <- name_is_autonym(nm_row)
  last_epi <- vapply(strsplit(nm_row, " +"), function(t) t[length(t)],
                     character(1L))
  own_autonym <- is.na(key) & auto_key & !is.na(rinfra) & rinfra == last_epi &
    (is.na(rrank) | rrank == name_rank_of(nm_row))
  concept <- key
  concept[own_autonym] <- "<autonym>"
  concept[is.na(concept)] <- "<other autonym>"

  pairs <- unique(data.frame(nm = nm_row, k = concept,
                             stringsAsFactors = FALSE))
  counts <- table(pairs$nm)
  ambiguous_names <- names(counts)[counts > 1L]
  if (length(ambiguous_names) == 0L) return(joined)

  qparts <- author_key_parts(x$accepted_authorship)
  first <- !duplicated(x$accepted_name)
  qname <- x$accepted_name[first]
  qkey <- stats::setNames(qparts$key[first], qname)
  qparen <- stats::setNames(qparts$paren[first], qname)
  qterm <- stats::setNames(qparts$terminal[first], qname)
  qid <- stats::setNames(
    if ("accepted_id" %in% names(x)) as.character(x$accepted_id[first]) else
      rep(NA_character_, length(qname)), qname)
  qbb <- stats::setNames(
    if ("backbone" %in% names(x)) as.character(x$backbone[first]) else
      rep(NA_character_, length(qname)), qname)

  # One circumscription read per backbone, over every ambiguous name x
  # resolved through it.
  amb_q <- intersect(ambiguous_names, qname)
  circ <- list()
  for (bb in unique(stats::na.omit(qbb[amb_q]))) {
    ids <- qid[amb_q][qbb[amb_q] == bb]
    cb <- .backbone_circumscription(bb, ids)
    if (!is.null(cb)) circ[[bb]] <- split(cb, cb$root)
  }

  rows_by_name <- split(seq_len(nrow(joined)), nm_row)
  keep <- rep(TRUE, nrow(joined))
  own_row <- rep(TRUE, nrow(joined))
  # Two distinct unresolved reasons (#87): `unresolved` is a genuine tie --
  # at least one candidate is a plausible near-miss or shares the query's
  # basionym author, but more than one does, so picking would be a guess.
  # `no_match` is every candidate sharing nothing at all with the query's
  # authorship -- not a tie to break, but evidence the matched concept may
  # not be in this enrichment under any spelling (its own accepted taxon,
  # a broader/narrower rank, or a synonym elsewhere).
  unresolved <- character(0L)
  no_match <- character(0L)

  for (nm in ambiguous_names) {
    rows <- rows_by_name[[nm]]
    k <- concept[rows]
    nm_rank <- name_rank_of(nm)
    # A row of a broader rank than the name is never its own concept.
    rank_ok <- is.na(rrank[rows]) | is.na(nm_rank) | rrank[rows] == nm_rank
    authored <- unique(k[rank_ok & !k %in% c("<autonym>", "<other autonym>")])
    concepts <- authored
    want <- if (nm %in% qname) qkey[[nm]] else NA_character_
    sel <- NA_character_
    shared <- FALSE
    if ("<autonym>" %in% k) {
      # An autonym has no author of its own, whatever a backbone writes beside
      # it, so its authorless rows are the name's concept.
      sel <- "<autonym>"
    } else if (is.na(want) && !auto_key[rows[1L]] && length(authored) == 1L) {
      # Nothing to compare against, but authorless rows under a name that is
      # not an autonym are another name's autonym: one authored concept left.
      sel <- authored
    } else if (!is.na(want)) {
      rep_row <- rows[match(concepts, k)]
      if (want %in% concepts) {
        sel <- want
        shared <- TRUE
      } else {
        q <- list(paren = qparen[[nm]], terminal = qterm[[nm]])
        near <- concepts[vapply(rep_row, function(i) {
          author_key_near(q, list(paren = parts$paren[i],
                                  terminal = parts$terminal[i]))
        }, logical(1L))]
        if (length(near) == 1L) sel <- near
        shared <- shared || length(near) > 0L
      }
      # Sources also disagree over who is credited with a recombination while
      # naming the same basionym author -- Glaucium corniculatum is (L.) Curtis
      # in WFO and (L.) Rudolph in WCVP. Epithet plus basionym author pins the
      # basionym, and with it the type, so a concept that is the only candidate
      # carrying the query's basionym author is the same taxon whoever made the
      # combination. Two candidates sharing it are not separable this way and
      # fall through to the drop below, which is what keeps a homonym pair with
      # no basionym author at all (Erigeron pulchellus Michx. vs Hoppe &
      # Hornsch., #50) out of this branch entirely.
      qp <- qparen[[nm]]
      if (is.na(sel) && !is.na(qp) && nzchar(qp)) {
        same_basionym <- concepts[parts$paren[rep_row] == qp]
        if (length(same_basionym) == 1L) sel <- same_basionym
        shared <- shared || length(same_basionym) > 0L
      }
    }
    if (is.na(sel)) {
      keep[rows] <- FALSE
      # `want` unknown (nm not among x's own accepted names, e.g. reached via
      # cross-backbone recovery) leaves nothing to compare against -- treated
      # as a tie rather than asserting "no match" from no evidence either way.
      if (is.na(want) || shared) {
        unresolved <- c(unresolved, nm)
      } else {
        no_match <- c(no_match, nm)
      }
    } else {
      own <- k == sel
      member <- own
      broader <- !is.na(nm_rank) & nm_rank != "species" &
        !is.na(rrank[rows]) & rrank[rows] == "species"
      cn <- if (nm %in% qname && !is.na(qbb[[nm]]) && !is.na(qid[[nm]])) {
        circ[[qbb[[nm]]]][[qid[[nm]]]]
      }
      for (j in which(!own & !broader)) {
        i <- rows[j]
        member[j] <- row_in_circumscription(
          list(paren = parts$paren[i], terminal = parts$terminal[i],
               key = parts$key[i]),
          rrank[i], rinfra[i], cn)
      }
      keep[rows] <- member
      own_row[rows] <- own
    }
  }

  if (length(unresolved) > 0L) {
    warning(sprintf(
      paste0("Enrichment '%s': %d name(s) match more than one concept ",
             "(differing authorship) and could not be resolved to the one ",
             "%s() actually matched; left NA rather than guessing: %s"),
      enrichment_name, length(unresolved), "taxify",
      paste(utils::head(unresolved, 5L), collapse = "; ")
    ), call. = FALSE)
  }
  if (length(no_match) > 0L) {
    warning(sprintf(
      paste0("Enrichment '%s': %d name(s) have candidate concept(s) under ",
             "the same name, but none share any authorship with the one ",
             "%s() actually matched; left NA rather than guessing. This is ",
             "not a tie between plausible matches -- the matched concept may ",
             "not be recognised by this enrichment under any spelling, or ",
             "may be filed there as a synonym under a different name: %s"),
      enrichment_name, length(no_match), "taxify",
      paste(utils::head(no_match, 5L), collapse = "; ")
    ), call. = FALSE)
  }

  # The resolved concept's rows first, so the per-group dedup in the fill keeps
  # its value wherever a contained concept also holds the region.
  joined[c(which(keep & own_row), which(keep & !own_row)), , drop = FALSE]
}


# Output column a (base column, group) pair pivots into. A single group keeps
# the base name; several suffix it, so the caller and the fill agree on one rule.
.group_out_col <- function(base_col, g, groups) {
  if (length(groups) == 1L) base_col else paste0(base_col, "_", g)
}

# Fill the pivoted output columns from a joined source frame, one match() per
# group, matching `lookup` (one name per row of x) against the join key. Only
# empty cells are written, so a second pass over the same frame -- the
# cross-backbone recovery below -- never overwrites a direct hit.
.enrich_group_fill <- function(x, joined, lookup, groups, value_cols,
                               group_col) {
  for (g in groups) {
    g_data <- if (is.na(g)) {
      joined[is.na(joined[[group_col]]), , drop = FALSE]
    } else {
      joined[!is.na(joined[[group_col]]) & joined[[group_col]] == g, ,
             drop = FALSE]
    }
    if (nrow(g_data) == 0L) next
    g_data <- g_data[!duplicated(g_data$lookup_name), , drop = FALSE]
    idx <- match(lookup, g_data$lookup_name)
    if (!any(!is.na(idx))) next
    for (base_col in names(value_cols)) {
      src_col <- value_cols[[base_col]]
      if (!src_col %in% names(g_data)) next
      out_col <- .group_out_col(base_col, g, groups)
      fill <- which(!is.na(idx) & is.na(x[[out_col]]))
      x[[out_col]][fill] <- g_data[[src_col]][idx[fill]]
    }
  }
  x
}


#' Group-based enrichment join (country/region/language filtering + pivot)
#'
#' Joins an enrichment .vtr on accepted_name, filters by a grouping column
#' (country_code, tdwg_code, lang), and pivots to wide format.
#'
#' @param x A taxify_result data.frame.
#' @param enrichment_name Character. Enrichment identifier.
#' @param group_col Character. Column in .vtr to filter/pivot on
#'   (e.g., "country_code").
#' @param groups Character vector of group values to include, or "all".
#' @param value_cols Named character vector. Names = base output column names,
#'   values = source columns in .vtr. When length(groups) == 1, output columns
#'   use the base name; when > 1, they get a suffix (e.g., "invasive_status_AT").
#' @param source_label Character.
#' @param na_types Named list of NA sentinels (optional).
#' @param verbose Logical.
#' @return The enriched data.frame.
#' @noRd
enrich_by_group <- function(x, enrichment_name, group_col, groups,
                            value_cols, source_label,
                            na_types = NULL, cols = NULL, col_prefix = NULL,
                            expose_all = TRUE, verbose = TRUE) {
  if (!"accepted_name" %in% names(x)) {
    stop("x must have an 'accepted_name' column (from taxify())", call. = FALSE)
  }

  vtr_path <- ensure_enrichment(enrichment_name, verbose = verbose)

  # Emergency fallback: ensure_enrichment() returned NULL → all paths failed
  if (is.null(vtr_path)) {
    df <- try_emergency_fallback(enrichment_name, verbose = verbose)
    return(enrich_from_dataframe_grouped(x, df, enrichment_name, group_col,
                                          groups, value_cols, source_label,
                                          na_types))
  }

  # Check schema
  schema <- vectra::tbl(vtr_path) |> utils::head(1L) |> vectra::collect()
  join_key <- if ("canonical_name" %in% names(schema)) {
    "canonical_name"
  } else if ("accepted_name" %in% names(schema)) {
    "accepted_name"
  } else {
    stop(sprintf(
      "Enrichment '%s' .vtr has no 'canonical_name' or 'accepted_name' column.",
      enrichment_name
    ), call. = FALSE)
  }

  if (!group_col %in% names(schema)) {
    stop(sprintf(
      "Enrichment '%s' .vtr has no '%s' column.", enrichment_name, group_col
    ), call. = FALSE)
  }

  # Expose every other per-(species, group) column the widened .vtr carries,
  # defaulting output to the door's curated value_cols. cols selects among them
  # ("all" or a vector); the extras keep their .vtr names.
  default_vc <- names(value_cols)
  if (isTRUE(expose_all)) {
    reserved <- c(join_key, group_col, "canonical_name", "accepted_name",
                  "genus", unname(value_cols))
    extra <- setdiff(names(schema), reserved)
    extra <- extra[!is.na(extra) & nzchar(extra)]
    if (length(extra) > 0L) {
      ex_out <- make.unique(c(names(value_cols), extra))[-seq_along(value_cols)]
      value_cols <- c(value_cols, stats::setNames(extra, ex_out))
      if (is.null(na_types)) na_types <- list()
      for (k in seq_along(ex_out)) {
        na_types[[ex_out[k]]] <-
          if (is.numeric(schema[[extra[k]]])) NA_real_ else NA_character_
      }
    }
  }
  # Same selector the ungrouped doors use, so cols behaves identically on both
  # (and is honoured even when the .vtr carries no extras beyond the curated
  # set, which the grouped path used to skip).
  value_cols <- .apply_col_selection(value_cols, cols, default_vc, col_prefix,
                                     enrichment_name)

  # Resolve "all" groups against the build actually installed, not the manifest.
  if (length(groups) == 1L && !anyNA(groups) && groups == "all") {
    groups <- resolve_all_groups(vtr_path, enrichment_name, group_col)
  }

  if (verbose && length(groups) > 1L &&
      is.null(.taxify_env[[".taxify_long_tip_shown"]])) {
    message("Tip: pipe into taxify_long() to reshape wide columns to long format.")
    .taxify_env[[".taxify_long_tip_shown"]] <- TRUE
  }

  # Build output column names, typing each NA sentinel from its source column
  # (unless na_types overrides it), then initialize per group.
  if (is.null(na_types)) na_types <- list()
  for (base_col in names(value_cols)) {
    if (is.null(na_types[[base_col]])) {
      src <- value_cols[[base_col]]
      na_types[[base_col]] <- if (src %in% names(schema)) {
        na_sentinel_for(schema[[src]])
      } else {
        NA_character_
      }
    }
  }
  out_cols <- character(0L)
  for (g in groups) {
    for (base_col in names(value_cols)) {
      out_col <- .group_out_col(base_col, g, groups)
      out_cols <- c(out_cols, out_col)
      x <- set_col_value(x, out_col, na_types[[base_col]])
    }
  }

  valid_rows <- which(!is.na(x$accepted_name))
  if (length(valid_rows) == 0L) {
    meta <- read_enrichment_meta(vtr_path)
    ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
    lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
    return(register_enrichment(x, enrichment_name, source_label, ver, 0L,
                               license = lic))
  }

  # Select needed columns. The authorship-like column (when the source carries
  # one) is pulled in too, even if not requested as output: it is the only
  # signal available for disambiguate_by_name_authorship() below.
  authorship_col <- enrichment_authorship_col(names(schema))
  rank_col <- intersect("taxon_rank", names(schema))
  infra_col <- intersect("infraspecies", names(schema))
  if (length(rank_col) == 0L) rank_col <- NULL
  if (length(infra_col) == 0L) infra_col <- NULL
  select_cols <- unique(c(group_col, unname(value_cols), authorship_col,
                          rank_col, infra_col))
  select_cols <- intersect(select_cols, names(schema))

  has_na_group <- anyNA(groups)

  # One pass over a set of looked-up rows: resolve homonyms against the
  # authorship the caller matched, then narrow to the requested groups. Shared
  # by the direct join and the cross-backbone recovery below, which differ only
  # in the name each row is looked up under.
  #
  # A name the join_key resolves to more than one row that disagree on
  # authorship is a homonym collision: the same accepted-name string covers
  # two distinct taxonomic concepts in the source (#50 -- add_wcvp() joining
  # Erigeron pulchellus Michx. onto Erigeron pulchellus Hoppe & Hornsch. ex
  # Bluff & Fingerh.'s European range because both share the bare name).
  # Resolve against the caller's own accepted_authorship where it uniquely
  # picks one concept; otherwise drop every row for that name so its output
  # cells stay NA rather than silently keeping an arbitrary one.
  prepare <- function(joined, xa) {
    if (is.null(joined) || nrow(joined) == 0L) return(NULL)
    if (!is.null(authorship_col) && "accepted_authorship" %in% names(xa)) {
      joined <- disambiguate_by_name_authorship(
        joined, xa, authorship_col, enrichment_name, rank_col, infra_col)
    }
    joined <- joined[
      joined[[group_col]] %in% groups |
        (has_na_group & is.na(joined[[group_col]])),
      , drop = FALSE
    ]
    if (nrow(joined) == 0L) NULL else joined
  }

  direct <- prepare(
    .enrichment_vtr_lookup(vtr_path, join_key, x$accepted_name[valid_rows],
                           select_cols),
    x)
  if (!is.null(direct)) {
    x <- .enrich_group_fill(x, direct, x$accepted_name, groups, value_cols,
                            group_col)
  }

  # Cross-backbone recovery: a row still empty here may be one the source does
  # cover, under the accepted name a different backbone gives the same concept.
  # The alternative carries that backbone's own authorship, so the homonym
  # guard above applies to it on the same terms.
  recovered <- rep(NA_character_, nrow(x))
  rec <- .cross_backbone_recover(
    x, .enrichment_gap_rows(x, out_cols, "accepted_name"),
    vtr_path, join_key, "accepted_name", select_cols, enrichment_name)
  if (!is.null(rec)) {
    xa <- x
    xa$accepted_name       <- rec$alt
    xa$accepted_authorship <- rec$authorship
    xa$accepted_id         <- rec$id
    xa$backbone            <- rec$via
    alt <- prepare(rec$joined, xa)
    if (!is.null(alt)) {
      before <- rowSums(!is.na(x[, out_cols, drop = FALSE])) > 0L
      x <- .enrich_group_fill(x, alt, rec$alt, groups, value_cols, group_col)
      got <- rowSums(!is.na(x[, out_cols, drop = FALSE])) > 0L & !before
      recovered[got] <- rec$via[got]
      .report_cross_backbone_recovery(enrichment_name, recovered, verbose)
    }
  }

  # Infraspecific rank-marker recovery (see enrich_simple): retry still-empty
  # rows under the name's alternative marker renderings. The recovered concept
  # keeps x's own authorship, so the homonym guard in prepare() applies to it on
  # the same terms as a direct hit.
  rec2 <- .infra_marker_recover(
    x, .enrichment_gap_rows(x, out_cols, "accepted_name"),
    vtr_path, join_key, "accepted_name", select_cols)
  if (!is.null(rec2)) {
    xa <- x
    xa$accepted_name <- rec2$alt
    alt2 <- prepare(rec2$joined, xa)
    if (!is.null(alt2)) {
      x <- .enrich_group_fill(x, alt2, rec2$alt, groups, value_cols, group_col)
    }
  }

  meta <- read_enrichment_meta(vtr_path)
  ver <- if (!is.null(meta)) meta$version %||% NA_character_ else NA_character_
  lic <- if (!is.null(meta)) meta$license %||% NA_character_ else NA_character_
  n_enriched <- sum(
    rowSums(!is.na(x[, out_cols, drop = FALSE])) > 0L
  )
  x <- register_enrichment(x, enrichment_name, source_label, ver, n_enriched,
                            license = lic,
                            n_recovered = sum(!is.na(recovered)))

  # Stamp reshape metadata so taxify_long() can auto-detect
  reshape_entry <- list(cols = names(value_cols), group_col = group_col)
  prev <- attr(x, "taxify_reshape") %||% list()
  attr(x, "taxify_reshape") <- c(prev, list(reshape_entry))

  x
}


#' List available enrichments
#'
#' Returns a summary of all enrichment layers available in the taxify manifest,
#' including version, row count, whether the dataset is static, and which
#' trait columns are provided.
#'
#' @param verbose Logical. Default `TRUE`.
#' @return A data.frame with columns: `name`, `version`, `nrow`, `static`,
#'   `trait_cols` (comma-separated), and `source_url`.
#'
#' @examples
#' \dontrun{
#' list_enrichments()
#' }
#'
#' @export
list_enrichments <- function(verbose = TRUE) {
  manifest <- fetch_manifest()
  entries <- manifest$enrichments
  if (is.null(entries) || length(entries) == 0L) {
    if (verbose) message("No enrichments found in manifest.")
    return(data.frame(
      name = character(0L), version = character(0L),
      nrow = integer(0L), static = logical(0L),
      trait_cols = character(0L), source_url = character(0L),
      stringsAsFactors = FALSE
    ))
  }

  nms <- names(entries)
  data.frame(
    name       = nms,
    version    = vapply(nms, function(n) entries[[n]]$latest %||% NA_character_, character(1L)),
    nrow       = vapply(nms, function(n) as.integer(entries[[n]]$nrow %||% NA_integer_), integer(1L)),
    static     = vapply(nms, function(n) isTRUE(entries[[n]]$static), logical(1L)),
    trait_cols = vapply(nms, function(n) {
      tc <- entries[[n]]$trait_cols
      if (is.null(tc)) NA_character_ else paste(tc, collapse = ", ")
    }, character(1L)),
    source_url = vapply(nms, function(n) entries[[n]]$source_url %||% NA_character_, character(1L)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}
