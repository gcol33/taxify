# ---- Enrichment build-from-source registry ----
#
# Allows users to build enrichment .vtr files locally when the pre-built
# download is unavailable or outdated. Each enrichment has a download function,
# a parse function, and metadata stored in .enrichment_build_registry.
#
# All functions in this file are internal (@noRd).


# ---- Generic download helpers ----

#' Download a file via curl
#'
#' @param url Character. URL to download.
#' @param dest_dir Character. Directory to save into.
#' @param filename Character. Output filename.
#' @return Path to the downloaded file.
#' @noRd
download_curl_file <- function(url, dest_dir, filename, referer = NULL,
                               user_agent = NULL) {
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(dest_dir, filename)
  if (file.exists(dest) && file.size(dest) > 100L) return(dest)

  h <- curl::new_handle()
  curl::handle_setopt(h, followlocation = TRUE, maxredirs = 10L)
  ua <- user_agent %||% "Mozilla/5.0 (compatible; taxify/0.5)"
  headers <- list("User-Agent" = ua)
  if (!is.null(referer)) headers[["Referer"]] <- referer
  do.call(curl::handle_setheaders, c(list(h), headers))
  curl::curl_download(url, dest, handle = h)

  if (!file.exists(dest) || file.size(dest) < 100L) {
    stop(sprintf("Download failed or produced empty file: %s", url),
         call. = FALSE)
  }
  dest
}


#' Download and unzip a file, returning the path to a matching file
#'
#' @param url Character. URL to a ZIP archive.
#' @param dest_dir Character. Directory for download and extraction.
#' @param pattern Character. Regex to match the target file inside the ZIP.
#'   If NULL, returns the extraction directory itself.
#' @return Path to the matched file, or the extraction directory if pattern
#'   is NULL.
#' @noRd
download_and_unzip <- function(url, dest_dir, pattern = NULL) {
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  zip_path <- file.path(dest_dir, "source.zip")

  if (!file.exists(zip_path) || file.size(zip_path) < 100L) {
    h <- curl::new_handle()
    curl::handle_setopt(h, followlocation = TRUE, maxredirs = 10L)
    curl::handle_setheaders(h, "User-Agent" = "R/4.5 taxify")
    curl::curl_download(url, zip_path, handle = h)
  }

  extract_dir <- file.path(dest_dir, "extracted")
  if (!dir.exists(extract_dir)) {
    dir.create(extract_dir, recursive = TRUE)
    utils::unzip(zip_path, exdir = extract_dir)
  }

  if (is.null(pattern)) return(extract_dir)

  files <- list.files(extract_dir, pattern = pattern, full.names = TRUE,
                      recursive = TRUE, ignore.case = TRUE)
  if (length(files) == 0L) {
    stop(sprintf(
      "No file matching '%s' found in ZIP.\nContents: %s",
      pattern,
      paste(list.files(extract_dir, recursive = TRUE), collapse = ", ")
    ), call. = FALSE)
  }
  files[1L]
}


#' Fetch paginated GBIF API results
#'
#' @param base_url Character. GBIF API endpoint.
#' @param params Named list. Query parameters (excluding offset/limit).
#' @param limit Integer. Page size.
#' @param max_pages Integer. Maximum pages to fetch per call.
#' @return A data.frame of combined results.
#' @noRd
download_gbif_api_pages <- function(base_url, params, limit = 1000L,
                                    max_pages = 100L) {
  all_rows <- vector("list", max_pages)
  offset <- 0L
  page <- 1L
  max_offset <- 9999L

  repeat {
    if (page > max_pages || offset > max_offset) break

    query <- c(params, list(limit = limit, offset = offset))
    query_str <- paste(
      vapply(names(query), function(k) {
        paste0(k, "=", utils::URLencode(as.character(query[[k]]), reserved = TRUE))
      }, character(1L)),
      collapse = "&"
    )
    url <- paste0(base_url, "?", query_str)

    resp <- curl::curl_fetch_memory(url)
    if (resp$status_code != 200L) break

    data <- jsonlite::fromJSON(rawToChar(resp$content))
    results <- data$results
    if (is.null(results) || nrow(results) == 0L) break

    all_rows[[page]] <- results
    page <- page + 1L

    if (isTRUE(data$endOfRecords)) break
    offset <- offset + limit
  }

  all_rows <- all_rows[!vapply(all_rows, is.null, logical(1L))]
  if (length(all_rows) == 0L) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  flat <- lapply(all_rows, function(df) {
    for (col in names(df)) {
      if (is.data.frame(df[[col]]) || is.list(df[[col]])) df[[col]] <- NULL
    }
    row.names(df) <- NULL
    df
  })
  as.data.frame(data.table::rbindlist(flat, fill = TRUE),
                stringsAsFactors = FALSE)
}


# ---- Per-enrichment parse functions ----

#' Parse Zanne et al. 2014 woodiness CSV
#' @noRd
parse_woodiness <- function(path) {
  df <- read.csv(path, stringsAsFactors = FALSE)

  # Identify name column
  if ("gs" %in% names(df)) {
    name_col <- "gs"
  } else if ("Species" %in% names(df)) {
    name_col <- "Species"
  } else {
    name_col <- names(df)[1L]
  }

  # Identify woodiness column
  wood_col <- grep("wood", names(df), ignore.case = TRUE, value = TRUE)
  if (length(wood_col) == 0L) {
    stop("Cannot find woodiness column. Columns: ",
         paste(names(df), collapse = ", "), call. = FALSE)
  }
  wood_col <- wood_col[1L]

  raw <- tolower(trimws(df[[wood_col]]))
  woodiness <- ifelse(grepl("^h", raw), "herbaceous",
               ifelse(grepl("^w", raw), "woody",
               ifelse(grepl("^v", raw), "variable", NA_character_)))

  out <- data.frame(
    canonical_name = trimws(df[[name_col]]),
    woodiness      = woodiness,
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse EIVE 1.0 ecological indicator values (XLSX)
#' @noRd
parse_eive <- function(path) {
  if (!requireNamespace("openxlsx2", quietly = TRUE)) {
    stop("openxlsx2 is required to read EIVE xlsx. ",
         "Install with: install.packages('openxlsx2')", call. = FALSE)
  }

  df <- as.data.frame(
    openxlsx2::read_xlsx(path, sheet = "mainTable"),
    stringsAsFactors = FALSE
  )

  name_col <- if ("TaxonConcept" %in% names(df)) "TaxonConcept" else names(df)[1L]

  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(p, names(df), value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NA_character_
  }

  light_col <- find_col(c("^EIVEres-L$", "^EIVEres.L$"))
  temp_col  <- find_col(c("^EIVEres-T$", "^EIVEres.T$"))
  moist_col <- find_col(c("^EIVEres-M$", "^EIVEres.M$"))
  react_col <- find_col(c("^EIVEres-R$", "^EIVEres.R$"))
  nutr_col  <- find_col(c("^EIVEres-N$", "^EIVEres.N$"))

  safe_num <- function(x) suppressWarnings(as.numeric(x))

  out <- data.frame(
    canonical_name = trimws(df[[name_col]]),
    stringsAsFactors = FALSE
  )
  if (!is.na(light_col)) out$light       <- safe_num(df[[light_col]])
  if (!is.na(temp_col))  out$temperature  <- safe_num(df[[temp_col]])
  if (!is.na(moist_col)) out$moisture     <- safe_num(df[[moist_col]])
  if (!is.na(react_col)) out$reaction     <- safe_num(df[[react_col]])
  if (!is.na(nutr_col))  out$nutrients    <- safe_num(df[[nutr_col]])

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse EltonTraits 1.0 birds + mammals TSVs
#' @noRd
parse_elton_traits <- function(birds_path, mammals_path) {
  col_map <- list(
    diet_inv        = c("Diet.Inv", "Diet-Inv"),
    diet_vend       = c("Diet.Vend", "Diet-Vend"),
    diet_vect       = c("Diet.Vect", "Diet-Vect"),
    diet_vfish      = c("Diet.Vfish", "Diet-Vfish"),
    diet_vunk       = c("Diet.Vunk", "Diet-Vunk"),
    diet_scav       = c("Diet.Scav", "Diet-Scav"),
    diet_fruit      = c("Diet.Fruit", "Diet-Fruit"),
    diet_nect       = c("Diet.Nect", "Diet-Nect"),
    diet_seed       = c("Diet.Seed", "Diet-Seed"),
    diet_plantother = c("Diet.PlantO", "Diet-PlantO"),
    foraging_water      = c("ForStrat.watbelowsurf", "ForStrat-watbelowsurf"),
    foraging_ground     = c("ForStrat.ground", "ForStrat-ground"),
    foraging_understory = c("ForStrat.understory", "ForStrat-understory"),
    foraging_midhigh    = c("ForStrat.midhigh", "ForStrat-midhigh"),
    foraging_canopy     = c("ForStrat.canopy", "ForStrat-canopy"),
    foraging_aerial     = c("ForStrat.aerial", "ForStrat-aerial"),
    body_mass_g     = c("BodyMass.Value", "BodyMass-Value"),
    nocturnal       = c("Nocturnal", "Activity.Nocturnal", "Activity-Nocturnal")
  )

  resolve_col <- function(df, candidates) {
    for (cand in candidates) {
      if (cand %in% names(df)) return(cand)
      cand_dot <- gsub("-", ".", cand, fixed = TRUE)
      if (cand_dot %in% names(df)) return(cand_dot)
    }
    NULL
  }

  extract_one <- function(df) {
    name_col <- intersect(
      names(df), c("Scientific", "Scientific.Name", "ScientificName")
    )
    if (length(name_col) == 0L) name_col <- names(df)[1L] else name_col <- name_col[1L]

    out <- data.frame(
      canonical_name = trimws(df[[name_col]]),
      stringsAsFactors = FALSE
    )
    for (out_name in names(col_map)) {
      src <- resolve_col(df, col_map[[out_name]])
      out[[out_name]] <- if (!is.null(src)) {
        suppressWarnings(as.numeric(df[[src]]))
      } else {
        NA_real_
      }
    }
    out
  }

  birds <- read.delim(birds_path, stringsAsFactors = FALSE, quote = "")
  mammals <- read.delim(mammals_path, stringsAsFactors = FALSE, quote = "")

  out <- rbind(extract_one(birds), extract_one(mammals))
  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse AVONET bird morphology XLSX
#' @noRd
parse_avonet <- function(path) {
  if (!requireNamespace("openxlsx2", quietly = TRUE)) {
    stop("openxlsx2 is required to read AVONET xlsx. ",
         "Install with: install.packages('openxlsx2')", call. = FALSE)
  }

  sheets <- openxlsx2::wb_load(path) |> openxlsx2::wb_get_sheet_names()
  sp_sheet <- grep("AVONET.*Birdlife|species|averages", sheets,
                   ignore.case = TRUE, value = TRUE)
  if (length(sp_sheet) == 0L) {
    sp_sheet <- sheets[min(2L, length(sheets))]
  } else {
    sp_sheet <- sp_sheet[1L]
  }

  df <- as.data.frame(
    openxlsx2::read_xlsx(path, sheet = sp_sheet),
    stringsAsFactors = FALSE
  )

  name_col <- intersect(
    names(df),
    c("Species1", "Species1_BirdLife", "Species", "Scientific",
      "ScientificName", "species_name")
  )
  if (length(name_col) == 0L) name_col <- names(df)[1L] else name_col <- name_col[1L]

  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(paste0("^", p, "$"), names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    for (p in patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NULL
  }

  safe_num <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_real_, nrow(df)))
    suppressWarnings(as.numeric(df[[col_name]]))
  }
  safe_chr <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_character_, nrow(df)))
    as.character(df[[col_name]])
  }

  out <- data.frame(
    canonical_name  = trimws(df[[name_col]]),
    beak_length     = safe_num(find_col(c("Beak.Length_Culmen", "Beak.Length",
                                          "culmen_length", "Bill.Length"))),
    beak_depth      = safe_num(find_col(c("Beak.Depth", "bill_depth",
                                          "Bill.Depth"))),
    wing_length     = safe_num(find_col(c("Wing.Length", "wing_length"))),
    tail_length     = safe_num(find_col(c("Tail.Length", "tail_length"))),
    tarsus_length   = safe_num(find_col(c("Tarsus.Length", "tarsus_length"))),
    body_mass_g     = safe_num(find_col(c("Mass", "Body.Mass", "body_mass",
                                          "BodyMass", "Mass.g"))),
    hand_wing_index = safe_num(find_col(c("Hand.Wing.Index", "Hand-Wing.Index",
                                          "HWI", "hand_wing_index"))),
    habitat         = safe_chr(find_col(c("Habitat", "Primary.Lifestyle",
                                          "habitat"))),
    trophic_level   = safe_chr(find_col(c("Trophic.Level", "trophic_level"))),
    trophic_niche   = safe_chr(find_col(c("Trophic.Niche", "trophic_niche"))),
    migration       = safe_chr(find_col(c("Migration", "migration"))),
    stringsAsFactors = FALSE
  )

  # Normalize migration values
  if (!all(is.na(out$migration))) {
    mig <- tolower(trimws(out$migration))
    out$migration <- ifelse(grepl("^1$|^sedentar|^resident", mig), "sedentary",
                    ifelse(grepl("^2$|^partial", mig), "partial",
                    ifelse(grepl("^3$|^full|^migra", mig), "full",
                    NA_character_)))
  }

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse PanTHERIA mammal life-history traits (TSV)
#' @noRd
parse_pantheria <- function(path) {
  df <- read.delim(path, stringsAsFactors = FALSE,
                   na.strings = c("-999", "-999.00"))

  name_col <- intersect(
    names(df), c("MSW05_Binomial", "MSW93_Binomial", "Scientific_Name")
  )
  if (length(name_col) == 0L) name_col <- names(df)[1L] else name_col <- name_col[1L]

  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NULL
  }

  safe_num <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_real_, nrow(df)))
    x <- suppressWarnings(as.numeric(df[[col_name]]))
    x[x == -999] <- NA_real_
    x
  }

  out <- data.frame(
    canonical_name  = trimws(df[[name_col]]),
    body_mass_g     = safe_num(find_col(c("AdultBodyMass_g", "X5.1_AdultBodyMass",
                                          "BodyMass"))),
    longevity_mo    = safe_num(find_col(c("MaxLongevity_m", "X17.1_MaxLongevity"))),
    litter_size     = safe_num(find_col(c("LitterSize", "X15.1_LitterSize"))),
    gestation_d     = safe_num(find_col(c("GestationLen_d", "X9.1_GestationLen"))),
    weaning_d       = safe_num(find_col(c("WeaningAge_d", "X25.1_WeaningAge"))),
    home_range_km2  = safe_num(find_col(c("HomeRange_km2", "X22.1_HomeRange",
                                          "HomeRange_Indiv_km2"))),
    diet_breadth    = safe_num(find_col(c("DietBreadth", "X6.2_TrophicLevel",
                                          "diet_breadth"))),
    habitat_breadth = safe_num(find_col(c("HabitatBreadth", "X12.2_HabitatBreadth",
                                          "habitat_breadth"))),
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse AmphiBIO amphibian traits (CSV from ZIP)
#' @noRd
parse_amphibio <- function(path) {
  df <- read.csv(path, stringsAsFactors = FALSE)

  name_col <- intersect(names(df), c("Species", "species", "Scientific"))
  if (length(name_col) == 0L) name_col <- names(df)[1L] else name_col <- name_col[1L]

  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(paste0("^", p, "$"), names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    for (p in patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NULL
  }

  safe_num <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_real_, nrow(df)))
    suppressWarnings(as.numeric(df[[col_name]]))
  }
  safe_int <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_integer_, nrow(df)))
    suppressWarnings(as.integer(df[[col_name]]))
  }

  out <- data.frame(
    canonical_name      = trimws(df[[name_col]]),
    body_size_mm        = safe_num(find_col(c("Body_size_mm", "Body.size.mm",
                                              "SVL_mm", "Body_length_mm"))),
    age_maturity_d      = safe_num(find_col(c("Age_at_maturity_min_d",
                                              "Age.at.maturity",
                                              "Age_maturity_d"))),
    longevity_d         = safe_num(find_col(c("Longevity_max_d", "Longevity",
                                              "Longevity_d"))),
    litter_size         = safe_num(find_col(c("Litter_size_max_n",
                                              "Litter.size", "Clutch_size"))),
    reproductive_output = safe_num(find_col(c("Reproductive_output_y",
                                              "Reproductive.output"))),
    offspring_size_mm   = safe_num(find_col(c("Offspring_size_mm",
                                              "Offspring.size"))),
    direct_development  = safe_int(find_col(c("Dir", "Direct_development",
                                              "Devel_direct"))),
    larval              = safe_int(find_col(c("Lar", "Larval", "Has_larva"))),
    aquatic             = safe_int(find_col(c("Aqu", "Aquatic"))),
    fossorial           = safe_int(find_col(c("Fos", "Fossorial"))),
    arboreal            = safe_int(find_col(c("Arb", "Arboreal"))),
    diurnal             = safe_int(find_col(c("Diu", "Diurnal"))),
    nocturnal_amphibio  = safe_int(find_col(c("Noc", "Nocturnal"))),
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse FISHMORPH freshwater fish morphological traits (CSV)
#' @noRd
parse_fish_traits <- function(path) {
  df <- read.csv2(path, stringsAsFactors = FALSE,
                  fileEncoding = "latin1", dec = ".")

  # Species column: "Genus species" or "Genus.species" or "Species"
  name_col <- intersect(
    names(df), c("Genus.species", "Genus species", "Species",
                 "scientificNameStd")
  )
  if (length(name_col) == 0L) name_col <- names(df)[1L] else name_col <- name_col[1L]

  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(paste0("^", p, "$"), names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    for (p in patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NULL
  }

  safe_num <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_real_, nrow(df)))
    suppressWarnings(as.numeric(df[[col_name]]))
  }

  out <- data.frame(
    canonical_name             = trimws(gsub("_", " ", df[[name_col]])),
    max_body_length            = safe_num(find_col(c("MBl", "MBI",
                                                     "Max_body_length"))),
    body_elongation            = safe_num(find_col(c("BEl", "Body_elongation"))),
    vertical_eye_position      = safe_num(find_col(c("VEp",
                                                     "Vertical_eye_position"))),
    relative_eye_size          = safe_num(find_col(c("REs",
                                                     "Relative_eye_size"))),
    oral_gape_position         = safe_num(find_col(c("OGp",
                                                     "Oral_gape_position"))),
    relative_maxillary_length  = safe_num(find_col(c("RMl",
                                                     "Relative_maxillary_length"))),
    body_lateral_shape         = safe_num(find_col(c("BLs",
                                                     "Body_lateral_shape"))),
    pectoral_fin_position      = safe_num(find_col(c("PFv",
                                                     "Pectoral_fin_vertical"))),
    pectoral_fin_size          = safe_num(find_col(c("PFs",
                                                     "Pectoral_fin_size"))),
    caudal_peduncle_throttling = safe_num(find_col(c("CPt",
                                                     "Caudal_peduncle_throttling"))),
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse LEDA trait files (multiple semicolon/tab-delimited files)
#' @noRd
parse_leda <- function(dir_path) {
  trait_files <- list(
    life_form     = "life_form.txt",
    dispersal     = "dispersal_type.txt",
    tv            = "TV.txt",
    seed_mass     = "seed_mass.txt",
    canopy_height = "canopy_height.txt",
    leaf_mass     = "leaf_mass.txt",
    sla           = "SLA.txt",
    clonal_growth = "clonal_growth.txt",
    buoyancy      = "buoyancy.txt"
  )

  read_leda_trait <- function(path) {
    # LEDA text dumps prefix the data table with an SQL query preamble.
    # Some files (e.g. SLA.txt) pad the preamble with semicolons to match
    # the data column count, so a semicolon-count heuristic is unreliable.
    # Universal LEDA tables are keyed on "SBS name" or "SBS number", so
    # use that prefix to locate the header row.
    find_header_skip <- function(p, max_scan = 50L) {
      con <- file(p, encoding = "latin1")
      on.exit(close(con))
      lines <- readLines(con, n = max_scan, warn = FALSE)
      hits <- which(grepl("^SBS (name|number)\\s*;", lines,
                          ignore.case = TRUE))
      if (length(hits) == 0L) {
        # fallback: first line with 3+ semicolons that is NOT padded SQL.
        hits <- which(vapply(lines, function(l) {
          sc <- sum(charToRaw(l) == charToRaw(";"))
          sc >= 3L && !grepl("(SELECT |FROM |WHERE |\\(|^The following)", l)
        }, logical(1L)))
      }
      if (length(hits) == 0L) return(0L)
      hits[1L] - 1L
    }

    tryCatch({
      skip_n <- find_header_skip(path)
      df <- read.csv(path, sep = ";", stringsAsFactors = FALSE,
                     fileEncoding = "latin1", skip = skip_n,
                     check.names = FALSE)
      if (ncol(df) <= 1L) {
        df <- read.delim(path, stringsAsFactors = FALSE,
                         fileEncoding = "latin1", skip = skip_n,
                         check.names = FALSE)
      }
      df
    }, error = function(e) {
      tryCatch(
        read.delim(path, stringsAsFactors = FALSE, skip = 0L,
                   check.names = FALSE),
        error = function(e2) NULL
      )
    })
  }

  find_name_col <- function(df) {
    candidates <- c("SBS_name", "species", "Species", "SBS.name",
                     "species_name", "name", "taxon")
    col <- intersect(names(df), candidates)
    if (length(col) > 0L) return(col[1L])
    col <- grep("species|name|SBS", names(df), ignore.case = TRUE, value = TRUE)
    if (length(col) > 0L) return(col[1L])
    names(df)[1L]
  }

  merge_trait <- function(master, path, trait_col_patterns, out_col,
                          as_type = "numeric") {
    if (!file.exists(path)) return(master)
    df <- read_leda_trait(path)
    if (is.null(df) || nrow(df) == 0L) return(master)

    nc <- find_name_col(df)
    tc <- NULL
    for (p in trait_col_patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) { tc <- m[1L]; break }
    }
    if (is.null(tc)) tc <- names(df)[ncol(df)]

    vals <- if (as_type == "numeric") {
      suppressWarnings(as.numeric(df[[tc]]))
    } else if (as_type == "integer") {
      suppressWarnings(as.integer(df[[tc]]))
    } else {
      as.character(df[[tc]])
    }

    trait_df <- data.frame(
      canonical_name = trimws(df[[nc]]),
      val = vals,
      stringsAsFactors = FALSE
    )
    names(trait_df)[2L] <- out_col

    if (as_type %in% c("numeric", "integer")) {
      trait_df <- stats::aggregate(
        trait_df[[out_col]],
        by = list(canonical_name = trait_df$canonical_name),
        FUN = function(x) stats::median(x, na.rm = TRUE)
      )
      names(trait_df)[2L] <- out_col
    } else {
      trait_df <- trait_df[!duplicated(trait_df$canonical_name), ]
    }

    if (is.null(master)) return(trait_df)
    merge(master, trait_df, by = "canonical_name", all = TRUE)
  }

  master <- NULL

  # Life form (special: also track variable life forms)
  lf_path <- file.path(dir_path, trait_files$life_form)
  if (file.exists(lf_path)) {
    df <- read_leda_trait(lf_path)
    if (!is.null(df) && nrow(df) > 0L) {
      nc <- find_name_col(df)
      lf_col <- grep("life.form|raunkiaer|lf_", names(df),
                      ignore.case = TRUE, value = TRUE)
      if (length(lf_col) > 0L) {
        trait_df <- data.frame(
          canonical_name = trimws(df[[nc]]),
          raunkiaer_life_form = trimws(df[[lf_col[1L]]]),
          stringsAsFactors = FALSE
        )
        counts <- table(trait_df$canonical_name)
        variable_spp <- names(counts[counts > 1L])
        trait_df <- trait_df[!duplicated(trait_df$canonical_name), ]
        trait_df$raunkiaer_variable <- as.integer(
          trait_df$canonical_name %in% variable_spp
        )
        master <- trait_df
      }
    }
  }

  master <- merge_trait(
    master, file.path(dir_path, trait_files$dispersal),
    c("dispersal.*type", "dispersal_type", "disp"),
    "dispersal_type", "character"
  )
  master <- merge_trait(
    master, file.path(dir_path, trait_files$tv),
    c("terminal.*velocity", "tv", "TV"),
    "terminal_velocity_ms", "numeric"
  )
  master <- merge_trait(
    master, file.path(dir_path, trait_files$seed_mass),
    c("seed.*mass", "sm_mean", "mass"),
    "leda_seed_mass_mg", "numeric"
  )
  master <- merge_trait(
    master, file.path(dir_path, trait_files$canopy_height),
    c("canopy.*height", "ch_mean", "height"),
    "canopy_height_m", "numeric"
  )
  master <- merge_trait(
    master, file.path(dir_path, trait_files$leaf_mass),
    c("leaf.*mass", "lm_mean", "mass"),
    "leaf_mass_mg", "numeric"
  )
  master <- merge_trait(
    master, file.path(dir_path, trait_files$sla),
    c("sla", "SLA", "specific.*leaf"),
    "sla_mm2_mg", "numeric"
  )
  master <- merge_trait(
    master, file.path(dir_path, trait_files$clonal_growth),
    c("clonal", "CGO", "cgo"),
    "clonal_growth", "integer"
  )
  master <- merge_trait(
    master, file.path(dir_path, trait_files$buoyancy),
    c("buoyancy", "buoy"),
    "buoyancy", "character"
  )

  if (is.null(master) || nrow(master) == 0L) {
    stop("No LEDA data could be parsed from downloaded files.", call. = FALSE)
  }

  expected <- c("canonical_name", "raunkiaer_life_form", "raunkiaer_variable",
                "dispersal_type", "terminal_velocity_ms", "leda_seed_mass_mg",
                "canopy_height_m", "leaf_mass_mg", "sla_mm2_mg",
                "clonal_growth", "buoyancy")
  for (col in expected) {
    if (!col %in% names(master)) master[[col]] <- NA
  }
  master <- master[, expected]

  master <- master[!is.na(master$canonical_name) &
                     nchar(master$canonical_name) > 0L, ]
  master[!duplicated(master$canonical_name), ]
}


#' Parse Diaz et al. 2022 supplementary traits (XLSX)
#' @noRd
parse_diaz_traits <- function(path) {
  if (!requireNamespace("openxlsx2", quietly = TRUE)) {
    stop("openxlsx2 is required to read Diaz supplementary xlsx. ",
         "Install with: install.packages('openxlsx2')", call. = FALSE)
  }

  df <- as.data.frame(
    openxlsx2::read_xlsx(path, sheet = 1L),
    stringsAsFactors = FALSE
  )

  name_col <- intersect(
    names(df),
    c("Species", "species", "SpecName", "Taxon", "Scientific_name",
      "AccSpeciesName")
  )
  if (length(name_col) == 0L) {
    name_col <- grep("spec|taxon|name", names(df), ignore.case = TRUE,
                     value = TRUE)
    if (length(name_col) == 0L) name_col <- names(df)[1L]
  }
  name_col <- name_col[1L]

  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NULL
  }

  safe_num <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_real_, nrow(df)))
    suppressWarnings(as.numeric(df[[col_name]]))
  }

  seed_col <- find_col(c("seed.*mass", "Seed.mass", "sm_", "SeedMass",
                         "Diaspore.mass"))
  height_col <- find_col(c("plant.*height", "Height", "PlantHeight",
                           "Hmax", "height_m"))

  out <- data.frame(
    canonical_name = trimws(df[[name_col]]),
    seed_mass_mg   = safe_num(seed_col),
    plant_height_m = safe_num(height_col),
    stringsAsFactors = FALSE
  )

  # Unit corrections
  if (!all(is.na(out$seed_mass_mg))) {
    median_val <- stats::median(out$seed_mass_mg, na.rm = TRUE)
    if (median_val < 1) {
      out$seed_mass_mg <- out$seed_mass_mg * 1000
    }
  }
  if (!all(is.na(out$plant_height_m))) {
    median_val <- stats::median(out$plant_height_m, na.rm = TRUE)
    if (median_val > 100) {
      out$plant_height_m <- out$plant_height_m / 100
    }
  }

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  has_data <- !is.na(out$seed_mass_mg) | !is.na(out$plant_height_m)
  out <- out[has_data, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse GRIIS Country Compendium CSV
#' @noRd
parse_griis <- function(path) {
  df <- read.csv(path, stringsAsFactors = FALSE)

  # Prefer "species" (canonical binomial) over scientificName (has authorship)
  if ("species" %in% names(df)) {
    name_col <- "species"
  } else {
    name_col <- intersect(
      names(df),
      c("scientificName", "canonicalName", "taxonName", "Scientific.Name",
        "accepted_name")
    )
    if (length(name_col) == 0L) {
      name_col <- grep("scien|canon|species|taxon|name", names(df),
                       ignore.case = TRUE, value = TRUE)
      if (length(name_col) == 0L) name_col <- names(df)[1L]
    }
    name_col <- name_col[1L]
  }

  cc_col <- if ("countryCode_alpha2" %in% names(df)) {
    "countryCode_alpha2"
  } else {
    cc <- grep("countryCode|country_code", names(df), ignore.case = TRUE,
               value = TRUE)
    if (length(cc) > 0L) cc[1L] else NULL
  }

  country_codes <- if (!is.null(cc_col)) {
    toupper(trimws(df[[cc_col]]))
  } else {
    rep(NA_character_, nrow(df))
  }

  is_inv <- if ("isInvasive" %in% names(df)) {
    tolower(trimws(df$isInvasive))
  } else {
    rep("null", nrow(df))
  }
  estab <- if ("establishmentMeans" %in% names(df)) {
    tolower(trimws(df$establishmentMeans))
  } else {
    rep("", nrow(df))
  }

  invasive_status <- ifelse(
    is_inv == "invasive", "invasive",
    ifelse(estab %in% c("alien", "introduced"), "introduced",
    ifelse(estab == "native", "native", "introduced"))
  )

  out <- data.frame(
    canonical_name  = trimws(df[[name_col]]),
    country_code    = country_codes,
    invasive_status = invasive_status,
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out <- out[!is.na(out$country_code) & nchar(out$country_code) == 2L, ]
  out[!duplicated(paste(out$canonical_name, out$country_code)), ]
}


# ---- Alien first records (Seebens et al.) ----

#' Seebens region name to ISO 3166-1 alpha-2 mapping
#'
#' Sub-national regions are mapped to their parent country.
#' Multi-country entries (e.g., "USACanada") are mapped to NA and dropped.
#' @noRd
.seebens_region_map <- c(
  "Afghanistan" = "AF",
  "Aland Islands" = "AX",
  "\u00c5land Islands" = "AX",
  "Alaska" = "US",

  "Albania" = "AL",
  "Algeria" = "DZ",
  "American Samoa" = "AS",
  "Amsterdam Island" = "TF",
  "Andaman and Nicobar Islands" = "IN",
  "Andorra" = "AD",
  "Angola" = "AO",
  "Anguilla" = "AI",
  "Antarctica" = "AQ",
  "Anticosti Island" = "CA",
  "Antigua and Barbuda" = "AG",
  "Argentina" = "AR",
  "Armenia" = "AM",
  "Aruba" = "AW",
  "Ascension" = "SH",
  "Australia" = "AU",
  "Austria" = "AT",
  "Azerbaijan" = "AZ",
  "Azores" = "PT",
  "Bahamas" = "BS",
  "Bahrain" = "BH",
  "Balearic Islands" = "ES",
  "Bali" = "ID",
  "Bangladesh" = "BD",
  "Barbados" = "BB",
  "Belarus" = "BY",
  "Belgium" = "BE",
  "Belgium, France, Netherlands, Uk" = NA_character_,
  "Belize" = "BZ",
  "Benin" = "BJ",
  "Bermuda" = "BM",
  "Bhutan" = "BT",
  "Biak" = "ID",
  "Bolivia" = "BO",
  "Bonaire" = "BQ",
  "Bosnia and Herzegovina" = "BA",
  "Botswana" = "BW",
  "Brazil" = "BR",
  "British Virgin Islands" = "VG",
  "Brunei Darussalam" = "BN",
  "Bulgaria" = "BG",
  "Burkina Faso" = "BF",
  "Burundi" = "BI",
  "Cambodia" = "KH",
  "Cameroon" = "CM",
  "Campbell" = "NZ",
  "Canada" = "CA",
  "Canary Islands" = "ES",
  "Cape Verde" = "CV",
  "Cayman Islands" = "KY",
  "Central African Republic" = "CF",
  "Chad" = "TD",
  "Chagos Archipelago" = "IO",
  "Channel Islands" = "GB",
  "Chile" = "CL",
  "China" = "CN",
  "Christmas Island" = "CX",
  "Clipperton Island" = "FR",
  "Cocos (Keeling) Islands" = "CC",
  "Colombia" = "CO",
  "Comoros" = "KM",
  "Congo, Democratic Republic of the" = "CD",
  "Congo, Republic of" = "CG",
  "Cook Islands" = "CK",
  "Corse" = "FR",
  "Costa Rica" = "CR",
  "Cote D'Ivoire" = "CI",
  "Crete" = "GR",
  "Croatia" = "HR",
  "Crozet Islands Group" = "TF",
  "Cuba" = "CU",
  "Curacao" = "CW",
  "Cyprus" = "CY",
  "Czech Republic" = "CZ",
  "De" = NA_character_,
  "Denmark" = "DK",
  "Djibouti" = "DJ",
  "Dominica" = "DM",
  "Dominican Republic" = "DO",
  "Easter Island" = "CL",
  "Ecuador" = "EC",
  "Egypt" = "EG",
  "El Salvador" = "SV",
  "Equatorial Guinea" = "GQ",
  "Eritrea" = "ER",
  "Estonia" = "EE",
  "Eswatini" = "SZ",
  "Ethiopia" = "ET",
  "Falkland Islands" = "FK",
  "Faroe Islands" = "FO",
  "Fernando De Noronha" = "BR",
  "Fiji" = "FJ",
  "Finland" = "FI",
  "France" = "FR",
  "France, Turkey" = NA_character_,
  "French Guiana" = "GF",
  "French Polynesia" = "PF",
  "Gabon" = "GA",
  "Galapagos" = "EC",
  "Gambia" = "GM",
  "Georgia" = "GE",
  "Germany" = "DE",
  "Germany and France" = NA_character_,
  "Germany and Spain" = NA_character_,
  "Ghana" = "GH",
  "Gibraltar" = "GI",
  "Greece" = "GR",
  "Greenland" = "GL",
  "Grenada" = "GD",
  "Guadeloupe" = "GP",
  "Guam" = "GU",
  "Guatemala" = "GT",
  "Guinea" = "GN",
  "Guinea-Bissau" = "GW",
  "Guyana" = "GY",
  "Haiti" = "HT",
  "Hawaiian Islands" = "US",
  "Heard and Mcdonald Islands" = "HM",
  "Honduras" = "HN",
  "Hong Kong" = "HK",
  "Hungary" = "HU",
  "Iceland" = "IS",
  "India" = "IN",
  "Indonesia" = "ID",
  "Iran, Islamic Republic of" = "IR",
  "Iraq" = "IQ",
  "Ireland" = "IE",
  "Israel" = "IL",
  "Italy" = "IT",
  "Italy and Germany" = NA_character_,
  "Italy, Hungary, Spain" = NA_character_,
  "Izu Islands" = "JP",
  "Jamaica" = "JM",
  "Japan" = "JP",
  "Jordan" = "JO",
  "Kazakhstan" = "KZ",
  "Kenya" = "KE",
  "Kerguelen Islands" = "TF",
  "Kermadec Islands" = "NZ",
  "Kiribati" = "KI",
  "Kuwait" = "KW",
  "Kyrgyzstan" = "KG",
  "Laos" = "LA",
  "Latvia" = "LV",
  "Lebanon" = "LB",
  "Lesotho" = "LS",
  "Lesser Sunda Islands" = "ID",
  "Liberia" = "LR",
  "Libya" = "LY",
  "Liechtenstein" = "LI",
  "Lithuania" = "LT",
  "Lord Howe Island" = "AU",
  "Luxembourg" = "LU",
  "Macao" = "MO",
  "Macedonia" = "MK",
  "Macquarie" = "AU",
  "Madagascar" = "MG",
  "Madeira" = "PT",
  "Malawi" = "MW",
  "Malaysia" = "MY",
  "Maldives" = "MV",
  "Mali" = "ML",
  "Malta" = "MT",
  "Maluku" = "ID",
  "Marshall Islands" = "MH",
  "Martinique" = "MQ",
  "Mauritania" = "MR",
  "Mauritius" = "MU",
  "Mayotte" = "YT",
  "Mexico" = "MX",
  "Micronesia, Federated States of" = "FM",
  "Moldova" = "MD",
  "Monaco" = "MC",
  "Mongolia" = "MN",
  "Montenegro" = "ME",
  "Montserrat" = "MS",
  "Morocco" = "MA",
  "Mozambique" = "MZ",
  "Myanmar" = "MM",
  "Namibia" = "NA",
  "Nauru" = "NR",
  "Nepal" = "NP",
  "Netherlands" = "NL",
  "New Caledonia" = "NC",
  "New Zealand" = "NZ",
  "Nicaragua" = "NI",
  "Niger" = "NE",
  "Nigeria" = "NG",
  "Niue" = "NU",
  "Norfolk Island" = "NF",
  "North Korea" = "KP",
  "Northern Mariana Islands" = "MP",
  "Norway" = "NO",
  "Ogasawara Islands" = "JP",
  "Oman" = "OM",
  "Pakistan" = "PK",
  "Palau" = "PW",
  "Palestine, State of" = "PS",
  "Panama" = "PA",
  "Paraguay" = "PY",
  "Peru" = "PE",
  "Philippines" = "PH",
  "Pitcairn Islands" = "PN",
  "Poland" = "PL",
  "Portugal" = "PT",
  "Puerto Rico" = "PR",
  "Qatar" = "QA",
  "Reunion" = "RE",
  "Rodriguez Island" = "MU",
  "Romania" = "RO",
  "Russia" = "RU",
  "Rwanda" = "RW",
  "Ryukyu Islands" = "JP",
  "Saint Barthelemy" = "BL",
  "Saint Helena" = "SH",
  "Saint Kitts and Nevis" = "KN",
  "Saint Lucia" = "LC",
  "Saint Martin" = "MF",
  "Saint Paul (France)" = "TF",
  "Saint Pierre and Miquelon" = "PM",
  "Saint Vincent and the Grenadines" = "VC",
  "Samoa" = "WS",
  "San Marino" = "SM",
  "Sao Tome and Principe" = "ST",
  "Sardinia" = "IT",
  "Saudi Arabia" = "SA",
  "Scattered Islands" = "TF",
  "Sea of Cortez Islands" = "MX",
  "Senegal" = "SN",
  "Serbia" = "RS",
  "Seychelles" = "SC",
  "Shetland Islands" = "GB",
  "Sicily" = "IT",
  "Sierra Leone" = "SL",
  "Singapore" = "SG",
  "Sint Maarten" = "SX",
  "Slovakia" = "SK",
  "Slovenia" = "SI",
  "Socotra Island" = "YE",
  "Solomon Islands" = "SB",
  "Somalia" = "SO",
  "South Africa" = "ZA",
  "South Georgia and the South Sandwich Islands" = "GS",
  "South Korea" = "KR",
  "South Orkney Islands" = "AQ",
  "Spain" = "ES",
  "Spain, France, Hungary" = NA_character_,
  "Sri Lanka" = "LK",
  "Sudan" = "SD",
  "Sumatra" = "ID",
  "Suriname" = "SR",
  "Svalbard and Jan Mayen" = "SJ",
  "Sweden" = "SE",
  "Switzerland" = "CH",
  "Syria" = "SY",
  "Taiwan" = "TW",
  "Tajikistan" = "TJ",
  "Tanzania" = "TZ",
  "Tasmania" = "AU",
  "Thailand" = "TH",
  "Timor Leste" = "TL",
  "Togo" = "TG",
  "Tokelau" = "TK",
  "Tonga" = "TO",
  "Trinidad and Tobago" = "TT",
  "Tristan da Cunha" = "SH",
  "Tunisia" = "TN",
  "Turkey" = "TR",
  "Turkmenistan" = "TM",
  "Turks and Caicos" = "TC",
  "Tuvalu" = "TV",
  "Uganda" = "UG",
  "Uk and Netherlands" = NA_character_,
  "Ukraine" = "UA",
  "United Arab Emirates" = "AE",
  "United Kingdom" = "GB",
  "United States" = "US",
  "Uruguay" = "UY",
  "US Minor Outlying Islands" = "UM",
  "USACanada" = NA_character_,
  "Uzbekistan" = "UZ",
  "Vancouver Island" = "CA",
  "Vanuatu" = "VU",
  "Venezuela" = "VE",
  "Vietnam" = "VN",
  "Virgin Islands, US" = "VI",
  "Wallis and Futuna" = "WF",
  "Western Sahara" = "EH",
  "Yemen" = "YE",
  "Zambia" = "ZM",
  "Zanzibar Island" = "TZ",
  "Zimbabwe" = "ZW"
)


#' Parse Seebens et al. Global Alien Species First Record Database
#'
#' Reads the "FirstRecords" sheet from the Seebens Excel file, maps region
#' names to ISO 3166-1 alpha-2 codes, and deduplicates per species x country
#' (keeping the earliest year).
#' @noRd
parse_alien_first_records <- function(path) {
  if (!requireNamespace("openxlsx2", quietly = TRUE)) {
    stop("Package 'openxlsx2' is required to parse the Seebens database.",
         call. = FALSE)
  }

  df <- openxlsx2::read_xlsx(path, sheet = "FirstRecords")

  # Map region names to ISO alpha-2
  df$country_code <- .seebens_region_map[df$Region]

  # Build output
  out <- data.frame(
    canonical_name              = trimws(df$TaxonName),
    country_code                = df$country_code,
    alien_first_record          = as.integer(df$FirstRecord),
    alien_first_record_source   = df$Source,
    alien_first_record_reference = df$Reference,
    stringsAsFactors = FALSE
  )

  # Drop unmappable rows

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out <- out[!is.na(out$country_code) & nchar(out$country_code) == 2L, ]

  # Deduplicate: keep earliest year per species x country
  out <- out[order(out$canonical_name, out$country_code, out$alien_first_record,
                   na.last = TRUE), ]
  out <- out[!duplicated(paste(out$canonical_name, out$country_code)), ]

  rownames(out) <- NULL
  out
}


#' Parse conservation status from GBIF species search API
#' @noRd
parse_conservation_status <- function(dummy_path) {
  # This enrichment fetches from the GBIF API directly, not from a file.
  # The dummy_path argument is ignored (keeps the interface uniform).

  iucn_categories <- c(
    "LEAST_CONCERN"          = "LC",
    "NEAR_THREATENED"        = "NT",
    "VULNERABLE"             = "VU",
    "ENDANGERED"             = "EN",
    "CRITICALLY_ENDANGERED"  = "CR",
    "EXTINCT_IN_THE_WILD"    = "EW",
    "EXTINCT"                = "EX",
    "DATA_DEFICIENT"         = "DD"
  )

  base_url <- "https://api.gbif.org/v1/species/search"
  all_data <- list()

  for (category in names(iucn_categories)) {
    abbrev <- iucn_categories[[category]]
    message(sprintf("  Fetching %s (%s)...", category, abbrev))

    results <- download_gbif_api_pages(
      base_url,
      params = list(threat = category),
      limit = 1000L,
      max_pages = 100L
    )

    if (nrow(results) == 0L) next

    names_vec <- results$canonicalName
    if (is.null(names_vec)) {
      names_vec <- sub("\\s+[A-Z].*$", "", results$scientificName)
    }

    rows <- data.frame(
      canonical_name      = names_vec,
      conservation_status = abbrev,
      stringsAsFactors = FALSE
    )

    # For large categories, also split by rank to bypass GBIF offset limit
    if (!is.null(results) && nrow(results) >= 9000L) {
      for (rank in c("SPECIES", "SUBSPECIES", "VARIETY")) {
        extra <- download_gbif_api_pages(
          base_url,
          params = list(threat = category, rank = rank),
          limit = 1000L,
          max_pages = 100L
        )
        if (nrow(extra) > 0L) {
          extra_names <- extra$canonicalName
          if (is.null(extra_names)) {
            extra_names <- sub("\\s+[A-Z].*$", "", extra$scientificName)
          }
          rows <- rbind(rows, data.frame(
            canonical_name      = extra_names,
            conservation_status = abbrev,
            stringsAsFactors = FALSE
          ))
        }
      }
    }

    all_data[[category]] <- rows
    message(sprintf("    %s species", format(nrow(rows), big.mark = ",")))
  }

  out <- do.call(function(...) rbind(..., make.row.names = FALSE), all_data)

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]

  # Keep most threatened status per species
  severity <- c("EX" = 1L, "EW" = 2L, "CR" = 3L, "EN" = 4L, "VU" = 5L,
                "NT" = 6L, "LC" = 7L, "DD" = 8L)
  out$sev <- severity[out$conservation_status]
  out <- out[order(out$canonical_name, out$sev), ]
  out <- out[!duplicated(out$canonical_name), ]
  out$sev <- NULL

  out
}


#' Parse WCVP names + distribution (from extracted ZIP directory)
#' @noRd
parse_wcvp <- function(dir_path) {
  csvs <- list.files(dir_path, pattern = "\\.csv$|\\.txt$",
                     full.names = TRUE, recursive = TRUE)
  names_file <- grep("(?i)name", csvs, value = TRUE)
  dist_file <- grep("(?i)distribut", csvs, value = TRUE)

  if (length(names_file) == 0L || length(dist_file) == 0L) {
    stop(sprintf(
      "Could not find WCVP names/distribution files in: %s\nFiles: %s",
      dir_path, paste(basename(csvs), collapse = ", ")
    ), call. = FALSE)
  }
  names_file <- names_file[1L]
  dist_file <- dist_file[1L]

  if (requireNamespace("data.table", quietly = TRUE)) {
    names_df <- as.data.frame(data.table::fread(names_file, showProgress = FALSE))
    dist_df <- as.data.frame(data.table::fread(dist_file, showProgress = FALSE))
  } else {
    names_df <- read.csv(names_file, stringsAsFactors = FALSE)
    dist_df <- read.csv(dist_file, stringsAsFactors = FALSE)
  }

  find_col <- function(df, patterns) {
    for (p in patterns) {
      m <- grep(paste0("^", p, "$"), names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    for (p in patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NULL
  }

  id_col     <- find_col(names_df, c("plant_name_id", "kew_id", "id"))
  name_col   <- find_col(names_df, c("taxon_name", "scientific_name",
                                      "full_name", "name"))
  status_col <- find_col(names_df, c("taxon_status", "status",
                                      "taxonomic_status"))

  dist_id_col <- find_col(dist_df, c("plant_name_id", "kew_id", "id"))
  area_col    <- find_col(dist_df, c("area_code_l3", "area", "tdwg_code",
                                      "region_code"))
  intro_col   <- find_col(dist_df, c("introduced", "is_introduced"))
  extinct_col <- find_col(dist_df, c("extinct", "is_extinct"))

  # Keep only accepted names
  if (!is.null(status_col)) {
    accepted <- names_df[tolower(names_df[[status_col]]) == "accepted", ]
  } else {
    accepted <- names_df
  }

  id_to_name <- stats::setNames(
    trimws(accepted[[name_col]]),
    as.character(accepted[[id_col]])
  )

  dist_df$canonical_name <- id_to_name[as.character(dist_df[[dist_id_col]])]
  dist_df <- dist_df[!is.na(dist_df$canonical_name), ]

  introduced <- if (!is.null(intro_col)) {
    as.integer(dist_df[[intro_col]])
  } else {
    rep(0L, nrow(dist_df))
  }
  extinct <- if (!is.null(extinct_col)) {
    as.integer(dist_df[[extinct_col]])
  } else {
    rep(0L, nrow(dist_df))
  }

  native_status <- ifelse(
    extinct == 1L, "extinct",
    ifelse(introduced == 1L, "introduced", "native")
  )

  out <- data.frame(
    canonical_name = dist_df$canonical_name,
    tdwg_code      = trimws(dist_df[[area_col]]),
    native_status  = native_status,
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out <- out[!is.na(out$tdwg_code) & nchar(out$tdwg_code) > 0L, ]
  out[!duplicated(paste(out$canonical_name, out$tdwg_code)), ]
}


#' Parse common names from GBIF, NCBI, and OTT
#'
#' Merges vernacular names from three sources:
#' - GBIF: VernacularName.tsv (has ISO 639-1 language codes)
#' - NCBI: names.dmp where name_class == "common name" (no language)
#' - OTT: synonyms.tsv where type == "common name" (no language)
#'
#' NCBI and OTT common names have no language tag, so lang is set to NA.
#' @noRd
parse_common_names <- function(dir_path) {
  gbif_dir <- file.path(dir_path, "gbif")
  ncbi_dir <- file.path(dir_path, "ncbi")
  ott_dir  <- file.path(dir_path, "ott")

  parts <- list()

  # ---- GBIF ----
  if (dir.exists(gbif_dir)) {
    gbif <- parse_gbif_common_names(gbif_dir)
    gbif$source <- "gbif"
    parts <- c(parts, list(gbif))
  }

  # ---- NCBI ----
  if (dir.exists(ncbi_dir)) {
    ncbi <- parse_ncbi_common_names(ncbi_dir)
    ncbi$source <- "ncbi"
    parts <- c(parts, list(ncbi))
  }

  # ---- OTT ----
  if (dir.exists(ott_dir)) {
    ott <- parse_ott_common_names(ott_dir)
    ott$source <- "ott"
    parts <- c(parts, list(ott))
  }

  if (length(parts) == 0L) {
    stop("No common name sources found in: ", dir_path, call. = FALSE)
  }

  out <- do.call(rbind, parts)

  # Deduplicate: prefer rows with a language tag (GBIF) over NA (NCBI/OTT)
  out <- out[order(!is.na(out$lang), decreasing = TRUE), ]
  out <- out[!duplicated(paste(out$canonical_name, out$common_name)), ]

  # Drop source column (build provenance goes in meta.json)
  out$source <- NULL
  out
}


#' Parse GBIF vernacular names (VernacularName.tsv + Taxon.tsv)
#' @noRd
parse_gbif_common_names <- function(dir_path) {
  vn_path <- file.path(dir_path, "VernacularName.tsv")
  taxon_path <- file.path(dir_path, "Taxon.tsv")

  if (!file.exists(vn_path) || !file.exists(taxon_path)) {
    vn_found <- list.files(dir_path, pattern = "VernacularName", recursive = TRUE,
                           full.names = TRUE)
    taxon_found <- list.files(dir_path, pattern = "^Taxon\\.tsv$", recursive = TRUE,
                              full.names = TRUE)
    if (length(vn_found) == 0L || length(taxon_found) == 0L) {
      stop(sprintf(
        "Could not find VernacularName.tsv and Taxon.tsv in: %s", dir_path
      ), call. = FALSE)
    }
    vn_path <- vn_found[1L]
    taxon_path <- taxon_found[1L]
  }

  if (requireNamespace("data.table", quietly = TRUE)) {
    vn <- as.data.frame(data.table::fread(
      vn_path, header = TRUE, sep = "\t", quote = "", showProgress = FALSE
    ))
    taxon_map <- as.data.frame(data.table::fread(
      taxon_path, header = TRUE, sep = "\t", quote = "",
      select = c("taxonID", "canonicalName"), showProgress = FALSE
    ))
  } else {
    vn <- read.delim(vn_path, stringsAsFactors = FALSE, quote = "")
    taxon_full <- read.delim(taxon_path, stringsAsFactors = FALSE, quote = "")
    taxon_map <- taxon_full[, c("taxonID", "canonicalName"), drop = FALSE]
  }

  names(taxon_map) <- c("taxon_id", "canonical_name")
  taxon_map <- taxon_map[!is.na(taxon_map$canonical_name) &
                           nchar(taxon_map$canonical_name) > 0L, ]

  vn$taxon_id <- as.integer(vn$taxonID)
  taxon_map$taxon_id <- as.integer(taxon_map$taxon_id)
  merged <- merge(vn, taxon_map, by = "taxon_id", all.x = FALSE)

  out <- data.frame(
    canonical_name = trimws(merged$canonical_name),
    lang           = tolower(trimws(merged$language)),
    common_name    = trimws(merged$vernacularName),
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out <- out[!is.na(out$common_name) & nchar(out$common_name) > 0L, ]
  out[!is.na(out$lang) & nchar(out$lang) >= 2L & nchar(out$lang) <= 3L, ]
}


#' Parse NCBI common names from names.dmp
#'
#' Reads names.dmp, extracts rows where name_class == "common name",
#' and resolves tax_id to scientific name via the "scientific name" rows.
#' No language information available — lang is set to NA.
#' @noRd
parse_ncbi_common_names <- function(dir_path) {
  names_file <- file.path(dir_path, "names.dmp")
  if (!file.exists(names_file)) {
    stop("Could not find names.dmp in: ", dir_path, call. = FALSE)
  }

  raw <- readLines(names_file, warn = FALSE)
  split <- strsplit(raw, "\t\\|\t?", perl = TRUE)
  df <- data.frame(
    tax_id     = vapply(split, `[`, character(1L), 1L),
    name_txt   = trimws(vapply(split, `[`, character(1L), 2L)),
    name_class = trimws(vapply(split, `[`, character(1L), 4L)),
    stringsAsFactors = FALSE
  )

  # Build tax_id -> scientific name lookup
  sci <- df[df$name_class == "scientific name", ]
  sci_lookup <- sci$name_txt
  names(sci_lookup) <- sci$tax_id

  # Extract common names
  common <- df[df$name_class == "common name", ]
  common <- common[!is.na(common$name_txt) & nchar(common$name_txt) > 0L, ]

  # Resolve tax_id to canonical name
  canonical <- sci_lookup[common$tax_id]

  out <- data.frame(
    canonical_name = unname(canonical),
    lang           = NA_character_,
    common_name    = common$name_txt,
    stringsAsFactors = FALSE
  )

  out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
}


#' Parse OTT common names from synonyms.tsv + taxonomy.tsv
#'
#' Reads synonyms.tsv, extracts rows where type contains "common name",
#' and resolves uid to scientific name via taxonomy.tsv.
#' No language information available — lang is set to NA.
#' @noRd
parse_ott_common_names <- function(dir_path) {
  syn_file <- file.path(dir_path, "synonyms.tsv")
  tax_file <- file.path(dir_path, "taxonomy.tsv")
  if (!file.exists(syn_file) || !file.exists(tax_file)) {
    stop("Could not find synonyms.tsv and taxonomy.tsv in: ", dir_path,
         call. = FALSE)
  }

  # Read taxonomy.tsv for uid -> name lookup
  tax_raw <- readLines(tax_file, warn = FALSE)
  tax_raw <- tax_raw[-1L]  # skip header
  tax_split <- strsplit(tax_raw, "\t\\|\t?", perl = TRUE)
  tax_lookup <- trimws(vapply(tax_split, `[`, character(1L), 3L))
  names(tax_lookup) <- vapply(tax_split, `[`, character(1L), 1L)

  # Read synonyms.tsv
  syn_raw <- readLines(syn_file, warn = FALSE)
  syn_raw <- syn_raw[-1L]  # skip header
  syn_split <- strsplit(syn_raw, "\t\\|\t?", perl = TRUE)
  syns <- data.frame(
    name = trimws(vapply(syn_split, `[`, character(1L), 1L)),
    uid  = trimws(vapply(syn_split, `[`, character(1L), 2L)),
    type = trimws(vapply(syn_split, function(x) {
      if (length(x) >= 3L) x[3L] else ""
    }, character(1L))),
    stringsAsFactors = FALSE
  )

  # Keep only common name types
  common <- syns[grepl("common", syns$type, ignore.case = TRUE), ]
  common <- common[!is.na(common$name) & nchar(common$name) > 0L, ]

  # Resolve uid to canonical name
  canonical <- tax_lookup[common$uid]

  out <- data.frame(
    canonical_name = unname(canonical),
    lang           = NA_character_,
    common_name    = common$name,
    stringsAsFactors = FALSE
  )

  out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
}


# ---- FUNGuild parser ----

#' Parse FUNGuild JSON database dump
#'
#' Reads the JSON array returned by the FUNGuild API, filters to genus and
#' species-level entries, and returns a clean data.frame with canonical_name
#' and trait columns.
#'
#' @param path Character. Path to the downloaded JSON file.
#' @return A data.frame with columns: canonical_name, taxon_level,
#'   trophic_mode, guild, growth_morphology, confidence_ranking.
#' @noRd
parse_funguild <- function(path) {
  txt <- readLines(path, warn = FALSE)
  txt <- paste(txt, collapse = "\n")
  # stbates.org wraps the JSON array in <html>...<body>...JSON...</body></html>.
  # Extract the JSON array between the first '[' and the matching trailing ']'.
  start <- regexpr("\\[", txt)
  end   <- max(gregexpr("\\]", txt)[[1L]])
  if (start <= 0L || end <= start) {
    stop("Cannot locate JSON array in FUNGuild response.", call. = FALSE)
  }
  json_str <- substr(txt, start, end)
  raw <- jsonlite::fromJSON(json_str, simplifyVector = TRUE)

  # FUNGuild uses Index Fungorum numeric taxonomic levels:
  # 12=family, 13=genus, 20=species, 25=variety, 26=form, 27=subspecies.
  level_col <- intersect(names(raw), c("taxonomicLevel", "taxonLevel"))
  if (length(level_col) == 0L) {
    stop("FUNGuild response missing taxonomicLevel/taxonLevel column.",
         call. = FALSE)
  }
  level_raw <- trimws(as.character(raw[[level_col[1L]]]))
  level_norm <- ifelse(grepl("^[0-9]+$", level_raw),
    c("13" = "genus", "20" = "species", "25" = "species",
      "26" = "species", "27" = "species")[level_raw],
    tolower(level_raw)
  )
  raw$taxonLevel <- level_norm

  keep <- level_norm %in% c("genus", "species")
  df <- raw[keep, ]

  if (nrow(df) == 0L) {
    stop("No genus/species-level entries found in FUNGuild JSON.", call. = FALSE)
  }

  taxon <- trimws(df$taxon)
  taxon_level <- tolower(trimws(df$taxonLevel))

  # Extract trophic mode, guild, growth morphology, confidence

  trophic <- if ("trophicMode" %in% names(df)) {
    trimws(df$trophicMode)
  } else if ("trophic_mode" %in% names(df)) {
    trimws(df$trophic_mode)
  } else {
    NA_character_
  }

  guild <- if ("guild" %in% names(df)) {
    trimws(df$guild)
  } else {
    NA_character_
  }

  growth <- if ("growthMorphology" %in% names(df)) {
    trimws(df$growthMorphology)
  } else if ("growthForm" %in% names(df)) {
    trimws(df$growthForm)
  } else if ("growth_morphology" %in% names(df)) {
    trimws(df$growth_morphology)
  } else {
    NA_character_
  }

  confidence <- if ("confidenceRanking" %in% names(df)) {
    trimws(df$confidenceRanking)
  } else if ("confidence_ranking" %in% names(df)) {
    trimws(df$confidence_ranking)
  } else if ("confidence" %in% names(df)) {
    trimws(df$confidence)
  } else {
    NA_character_
  }

  # Replace empty strings with NA
  trophic[!nzchar(trophic)] <- NA_character_
  guild[!nzchar(guild)] <- NA_character_
  growth[!nzchar(growth)] <- NA_character_
  confidence[!nzchar(confidence)] <- NA_character_

  out <- data.frame(
    canonical_name     = taxon,
    taxon_level        = taxon_level,
    trophic_mode       = trophic,
    guild              = guild,
    growth_morphology  = growth,
    confidence_ranking = confidence,
    stringsAsFactors   = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]

  # Deduplicate: keep first occurrence per canonical_name (species-level

  # entries sort before genus-level, so species wins)
  out <- out[order(out$taxon_level != "species", out$canonical_name), ]
  out <- out[!duplicated(out$canonical_name), ]

  # Drop taxon_level (used only for dedup)
  out$taxon_level <- NULL

  out
}


#' Parse FishBase species and ecology tables (via rfishbase)
#'
#' Pulls the `species` and `ecology` tables from rfishbase, joins them,
#' and builds a canonical_name + trait data.frame.
#'
#' @param path Character. Not used (rfishbase fetches data directly), but
#'   kept for interface consistency with other parse functions.
#' @return A data.frame with columns: canonical_name, body_length_cm,
#'   body_mass_g, trophic_level, depth_min_m, depth_max_m, vulnerability,
#'   habitat, importance.
#' @noRd
parse_fishbase <- function(path) {
  if (!requireNamespace("rfishbase", quietly = TRUE)) {
    stop("rfishbase is required to build the FishBase enrichment from source.\n",
         "Install it with: install.packages(\"rfishbase\")", call. = FALSE)
  }

  sp <- rfishbase::species(server = "fishbase")
  eco <- rfishbase::ecology(server = "fishbase")

  # Build canonical name from Genus + Species columns
  sp$canonical_name <- trimws(paste(sp$Genus, sp$Species))

  # Join ecology table by SpecCode
  eco_sub <- eco[, intersect(
    names(eco),
    c("SpecCode", "FeedingType", "DietTroph")
  ), drop = FALSE]
  # Deduplicate ecology rows per species (take first)
  eco_sub <- eco_sub[!duplicated(eco_sub$SpecCode), ]
  merged <- merge(sp, eco_sub, by = "SpecCode", all.x = TRUE)

  safe_num <- function(col_name) {
    if (!col_name %in% names(merged)) return(rep(NA_real_, nrow(merged)))
    suppressWarnings(as.numeric(merged[[col_name]]))
  }

  safe_chr <- function(col_name) {
    if (!col_name %in% names(merged)) return(rep(NA_character_, nrow(merged)))
    x <- as.character(merged[[col_name]])
    x[is.na(x) | nchar(trimws(x)) == 0L] <- NA_character_
    trimws(x)
  }

  out <- data.frame(
    canonical_name  = merged$canonical_name,
    body_length_cm  = safe_num("Length"),
    body_mass_g     = safe_num("Weight"),
    trophic_level   = safe_num("DietTroph"),
    depth_min_m     = safe_num("DepthRangeShallow"),
    depth_max_m     = safe_num("DepthRangeDeep"),
    vulnerability   = safe_num("Vulnerability"),
    habitat         = safe_chr("DemersPelag"),
    importance      = safe_chr("Importance"),
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


# ---- FungalTraits parser (genus-level) ----

#' Parse FungalTraits XLSX (Table S1, genus-level traits)
#'
#' Reads the Polme et al. (2020) supplementary XLSX, selects the most
#' informative trait columns, and returns a data.frame keyed on `genus`.
#'
#' @param path Character. Path to the downloaded XLSX file.
#' @return A data.frame with `genus` + 9 trait columns.
#' @noRd
parse_fungal_traits <- function(path) {
  if (!requireNamespace("openxlsx2", quietly = TRUE)) {
    stop("openxlsx2 is required to read FungalTraits xlsx. ",
         "Install with: install.packages('openxlsx2')", call. = FALSE)
  }

  df <- as.data.frame(
    openxlsx2::read_xlsx(path, sheet = 1L),
    stringsAsFactors = FALSE
  )

  # Locate key columns — the XLSX header names vary slightly across versions.
  # Use case-insensitive regex to be robust.
  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(p, names(df), value = TRUE, ignore.case = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NA_character_
  }

  genus_col      <- find_col(c("^GENUS$", "^genus$"))
  primary_col    <- find_col(c("primary_lifestyle", "Primary.lifestyle"))
  secondary_col  <- find_col(c("secondary_lifestyle", "Secondary.lifestyle"))
  growth_col     <- find_col(c("growth_form", "Growth.form"))
  fruit_col      <- find_col(c("fruitbody_type", "Fruitbody.type"))
  decay_col      <- find_col(c("decay_substrate", "Decay.substrate",
                                "Decay.type"))
  plant_path_col <- find_col(c("plant_pathogenic_capacity",
                                "Plant.pathogenic.capacity",
                                "Plant.pathogenic"))
  animal_col     <- find_col(c("animal_biotrophic_capacity",
                                "Animal.biotrophic.capacity",
                                "Animal.biotrophic"))
  endo_col       <- find_col(c("endophytic_interaction_capability",
                                "Endophytic.interaction",
                                "Endophyte"))
  ecto_col       <- find_col(c("ectomycorrhiza_exploration_type",
                                "Ectomycorrhiza.exploration.type",
                                "Exploration.type"))

  if (is.na(genus_col)) {
    stop("Could not find a 'GENUS' column in FungalTraits XLSX.", call. = FALSE)
  }

  safe_char <- function(x) {
    x <- as.character(x)
    x[x %in% c("", "NA", "na", "N/A")] <- NA_character_
    trimws(x)
  }

  out <- data.frame(genus = trimws(df[[genus_col]]), stringsAsFactors = FALSE)

  if (!is.na(primary_col))    out$primary_lifestyle    <- safe_char(df[[primary_col]])
  if (!is.na(secondary_col))  out$secondary_lifestyle  <- safe_char(df[[secondary_col]])
  if (!is.na(growth_col))     out$growth_form          <- safe_char(df[[growth_col]])
  if (!is.na(fruit_col))      out$fruitbody_type       <- safe_char(df[[fruit_col]])
  if (!is.na(decay_col))      out$decay_substrate      <- safe_char(df[[decay_col]])
  if (!is.na(plant_path_col)) out$plant_pathogenic_capacity     <- safe_char(df[[plant_path_col]])
  if (!is.na(animal_col))     out$animal_biotrophic_capacity    <- safe_char(df[[animal_col]])
  if (!is.na(endo_col))       out$endophytic_interaction_capability <- safe_char(df[[endo_col]])
  if (!is.na(ecto_col))       out$ectomycorrhiza_exploration_type   <- safe_char(df[[ecto_col]])

  # Drop rows with no genus
  out <- out[!is.na(out$genus) & nchar(out$genus) > 0L, ]

  # Deduplicate by genus (keep first occurrence)
  out <- out[!duplicated(out$genus), , drop = FALSE]
  rownames(out) <- NULL
  out
}


# ---- AlgaeTraits parser ----

#' Parse AlgaeTraits macroalgal traits (WoRMS ZIP export)
#' @noRd
parse_algae_traits <- function(path) {
  csvs <- list.files(path, pattern = "\\.csv$", full.names = TRUE,
                     recursive = TRUE, ignore.case = TRUE)
  txts <- list.files(path, pattern = "\\.txt$", full.names = TRUE,
                     recursive = TRUE, ignore.case = TRUE)
  xlsxs <- list.files(path, pattern = "\\.xlsx$", full.names = TRUE,
                      recursive = TRUE, ignore.case = TRUE)
  candidates <- c(csvs, txts)

  if (length(candidates) == 0L && length(xlsxs) > 0L) {
    if (!requireNamespace("openxlsx2", quietly = TRUE)) {
      stop("openxlsx2 is required to read AlgaeTraits XLSX files.\n",
           "Install with: install.packages('openxlsx2')", call. = FALSE)
    }
    sizes <- file.size(xlsxs)
    main_file <- xlsxs[which.max(sizes)]
    df <- as.data.frame(
      openxlsx2::read_xlsx(main_file),
      stringsAsFactors = FALSE
    )
  } else if (length(candidates) > 0L) {
    sizes <- file.size(candidates)
    main_file <- candidates[which.max(sizes)]
    first_line <- readLines(main_file, n = 1L, warn = FALSE)
    sep <- if (grepl("\t", first_line)) "\t" else ","
    df <- read.delim(main_file, sep = sep, stringsAsFactors = FALSE,
                     quote = "\"", fill = TRUE, comment.char = "")
  } else {
    stop("No data files found in AlgaeTraits archive.\n",
         "Contents: ", paste(list.files(path, recursive = TRUE),
                             collapse = ", "), call. = FALSE)
  }

  names(df) <- tolower(trimws(names(df)))

  # Identify species name column
  name_col <- NULL
  name_candidates <- c("scientificname", "scientific_name", "species",
                        "taxon", "valid_name", "validname",
                        "canonical_name", "scientificnameaccepted")
  for (nc in name_candidates) {
    if (nc %in% names(df)) { name_col <- nc; break }
  }
  if (is.null(name_col)) {
    for (i in seq_len(ncol(df))) {
      if (is.character(df[[i]])) { name_col <- names(df)[i]; break }
    }
  }
  if (is.null(name_col)) {
    stop("Cannot identify species name column. Columns: ",
         paste(names(df), collapse = ", "), call. = FALSE)
  }

  # Check if data is in long format (trait name + value columns)
  trait_col <- NULL
  value_col <- NULL
  long_trait_names <- c("measurementtype", "measurement_type", "traitname",
                        "trait_name", "trait", "category", "attributename")
  long_value_names <- c("measurementvalue", "measurement_value", "traitvalue",
                        "trait_value", "value", "attributevalue")
  for (tc in long_trait_names) {
    if (tc %in% names(df)) { trait_col <- tc; break }
  }
  for (vc in long_value_names) {
    if (vc %in% names(df)) { value_col <- vc; break }
  }

  if (!is.null(trait_col) && !is.null(value_col)) {
    out <- pivot_algae_long(df, name_col, trait_col, value_col)
  } else {
    out <- extract_algae_wide(df, name_col)
  }

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Pivot long-format AlgaeTraits data to wide
#' @noRd
pivot_algae_long <- function(df, name_col, trait_col, value_col) {
  species <- trimws(df[[name_col]])
  traits  <- tolower(trimws(df[[trait_col]]))
  values  <- trimws(as.character(df[[value_col]]))

  unique_species <- unique(species[!is.na(species) & nchar(species) > 0L])

  trait_map <- list(
    body_size_cm  = c("body size", "bodysize", "thallus length",
                      "thallus_length", "maximum length", "size"),
    growth_form   = c("body shape", "bodyshape", "growth form",
                      "growth_form", "morphology", "morphological type"),
    calcification = c("calcification", "calcified"),
    life_span     = c("life span", "lifespan", "life_span", "longevity"),
    tidal_zone    = c("tidal zonation", "tidal_zonation", "tidal zone",
                      "tidal_zone", "zonation"),
    wave_exposure = c("wave exposure", "wave_exposure", "exposure"),
    environment   = c("environment", "habitat", "salinity regime"),
    substrate     = c("environmental position", "environmental_position",
                      "substrate", "substratum", "attachment")
  )

  out <- data.frame(
    canonical_name = unique_species,
    body_size_cm   = NA_real_,
    growth_form    = NA_character_,
    calcification  = NA_character_,
    life_span      = NA_character_,
    tidal_zone     = NA_character_,
    wave_exposure  = NA_character_,
    environment    = NA_character_,
    substrate      = NA_character_,
    stringsAsFactors = FALSE
  )

  sp_idx <- stats::setNames(seq_along(unique_species), unique_species)

  for (trait_out in names(trait_map)) {
    patterns <- trait_map[[trait_out]]
    mask <- traits %in% patterns
    if (!any(mask)) next

    sub_sp  <- species[mask]
    sub_val <- values[mask]

    for (j in seq_along(sub_sp)) {
      s <- sub_sp[j]
      v <- sub_val[j]
      if (is.na(s) || is.na(v) || nchar(v) == 0L) next
      row <- sp_idx[s]
      if (is.na(row)) next

      if (trait_out == "body_size_cm") {
        if (is.na(out$body_size_cm[row])) {
          num <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", v)))
          out$body_size_cm[row] <- num
        }
      } else {
        if (is.na(out[[trait_out]][row])) {
          out[[trait_out]][row] <- v
        }
      }
    }
  }

  out
}


#' Extract trait columns from wide-format AlgaeTraits data
#' @noRd
extract_algae_wide <- function(df, name_col) {
  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(p, names(df), value = TRUE, ignore.case = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NA_character_
  }

  size_col  <- find_col(c("body.?size", "thallus.?length", "max.?length",
                           "^size$"))
  form_col  <- find_col(c("body.?shape", "growth.?form", "morpholog"))
  calc_col  <- find_col(c("calcif"))
  span_col  <- find_col(c("life.?span", "longevity"))
  tide_col  <- find_col(c("tidal", "zonation"))
  wave_col  <- find_col(c("wave", "exposure"))
  env_col   <- find_col(c("^environment$", "^habitat$", "salinity"))
  sub_col   <- find_col(c("environmental.?position", "substrate",
                           "substratum", "attachment"))

  safe_num <- function(col) {
    if (is.na(col)) return(rep(NA_real_, nrow(df)))
    suppressWarnings(as.numeric(df[[col]]))
  }

  safe_chr <- function(col) {
    if (is.na(col)) return(rep(NA_character_, nrow(df)))
    x <- trimws(as.character(df[[col]]))
    x[!nzchar(x)] <- NA_character_
    x
  }

  data.frame(
    canonical_name = trimws(df[[name_col]]),
    body_size_cm   = safe_num(size_col),
    growth_form    = safe_chr(form_col),
    calcification  = safe_chr(calc_col),
    life_span      = safe_chr(span_col),
    tidal_zone     = safe_chr(tide_col),
    wave_exposure  = safe_chr(wave_col),
    environment    = safe_chr(env_col),
    substrate      = safe_chr(sub_col),
    stringsAsFactors = FALSE
  )
}


# ---- Meiri lizard traits parser ----

#' Parse Meiri (2018) lizard traits (XLSX from Figshare)
#' @noRd
parse_lizard_traits <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    df <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  } else if (ext %in% c("tsv", "txt")) {
    df <- read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    if (!requireNamespace("openxlsx2", quietly = TRUE)) {
      stop("Package 'openxlsx2' is required to parse lizard traits XLSX.",
           call. = FALSE)
    }
    # ReptTraits 2024 puts traits on a sheet named "Data"; older Meiri 2018
    # XLSX has data on sheet 1. Pick the sheet named (case-insensitive)
    # "Data" if present, otherwise the widest sheet.
    sheets <- openxlsx2::wb_get_sheet_names(openxlsx2::wb_load(path))
    pick <- sheets[tolower(sheets) %in% c("data", "data sheet", "trait data")]
    if (length(pick) == 0L) {
      ncols <- vapply(sheets, function(s) {
        h <- tryCatch(openxlsx2::read_xlsx(path, sheet = s, rows = 1:1),
                      error = function(e) NULL)
        if (is.null(h)) 0L else ncol(h)
      }, integer(1L))
      pick <- sheets[which.max(ncols)]
    }
    df <- openxlsx2::read_xlsx(path, sheet = pick[1L])
  }

  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NULL
  }

  name_col <- find_col(c("^species$", "^binomial$", "^scientific.?name$"))
  if (is.null(name_col)) name_col <- names(df)[1L]

  safe_num <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_real_, nrow(df)))
    suppressWarnings(as.numeric(df[[col_name]]))
  }

  safe_chr <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_character_, nrow(df)))
    x <- as.character(df[[col_name]])
    x[x == "" | x == "NA"] <- NA_character_
    trimws(x)
  }

  out <- data.frame(
    canonical_name    = trimws(gsub("_", " ", df[[name_col]])),
    body_mass_g       = safe_num(find_col(c("mass", "body.?mass", "weight"))),
    svl_mm            = safe_num(find_col(c("SVL", "snout.?vent", "SVL_mm"))),
    tail_length_mm    = safe_num(find_col(c("tail", "tail.?length"))),
    clutch_size       = safe_num(find_col(c("clutch.?size", "litter.?size",
                                            "litter.?clutch"))),
    clutch_frequency  = safe_num(find_col(c("clutch.?freq", "clutches.?per",
                                            "reproductive.?freq"))),
    longevity_yr      = safe_num(find_col(c("longevity", "max.?age",
                                            "maximum.?longevity"))),
    diet              = safe_chr(find_col(c("^diet$", "diet.?type",
                                            "trophic"))),
    habitat           = safe_chr(find_col(c("^habitat$", "habitat.?type",
                                            "microhabitat"))),
    activity_time     = safe_chr(find_col(c("activity", "activity.?time",
                                            "diel"))),
    foraging_mode     = safe_chr(find_col(c("foraging", "foraging.?mode",
                                            "forage"))),
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse LepTraits 1.0 butterfly consensus CSV
#' @noRd
parse_leptraits <- function(path) {
  df <- read.csv(path, stringsAsFactors = FALSE)

  # Species column: "Species" contains full binomial
  name_col <- intersect(names(df), c("Species", "species", "Scientific"))
  if (length(name_col) == 0L) name_col <- names(df)[1L] else name_col <- name_col[1L]

  safe_num <- function(col_name) {
    if (is.null(col_name) || !col_name %in% names(df)) {
      return(rep(NA_real_, nrow(df)))
    }
    suppressWarnings(as.numeric(df[[col_name]]))
  }

  safe_chr <- function(col_name) {
    if (is.null(col_name) || !col_name %in% names(df)) {
      return(rep(NA_character_, nrow(df)))
    }
    x <- as.character(df[[col_name]])
    x[x == "" | x == "NA"] <- NA_character_
    trimws(x)
  }

  # Wingspan: midpoint of WS_L and WS_U (lower/upper bounds, mm)
  ws_l <- safe_num("WS_L")
  ws_u <- safe_num("WS_U")
  wingspan_mm <- ifelse(!is.na(ws_l) & !is.na(ws_u), (ws_l + ws_u) / 2,
                 ifelse(!is.na(ws_l), ws_l,
                 ifelse(!is.na(ws_u), ws_u, NA_real_)))

  # Flight months: sum of month columns (Jan..Dec)
  month_cols <- intersect(
    names(df),
    c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  )
  if (length(month_cols) > 0L) {
    month_mat <- as.matrix(df[, month_cols, drop = FALSE])
    month_mat <- suppressWarnings(apply(month_mat, 2L, as.numeric))
    flight_months <- as.integer(rowSums(month_mat, na.rm = TRUE))
    flight_months[rowSums(!is.na(month_mat)) == 0L] <- NA_integer_
  } else {
    flight_months <- safe_num("FlightDuration")
  }

  out <- data.frame(
    canonical_name       = trimws(df[[name_col]]),
    wingspan_mm          = wingspan_mm,
    voltinism            = safe_num("Voltinism"),
    diapause_stage       = safe_chr("DiapauseStage"),
    canopy_affinity      = safe_chr("CanopyAffinity"),
    edge_affinity        = safe_chr("EdgeAffinity"),
    moisture_affinity    = safe_chr("MoistureAffinity"),
    disturbance_affinity = safe_chr("DisturbanceAffinity"),
    n_hostplant_families = suppressWarnings(as.integer(df[["NumberOfHostplantFamilies"]])),
    flight_months        = flight_months,
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  # Remove entries without any trait data
  trait_cols <- setdiff(names(out), "canonical_name")
  has_data <- rowSums(!is.na(out[, trait_cols, drop = FALSE])) > 0L
  out <- out[has_data, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse AnimalTraits observations CSV (aggregate to species medians)
#' @noRd
parse_animaltraits <- function(path) {
  df <- read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")

  # Species column: "species" contains full binomial
  name_col <- intersect(names(df), c("species", "Species", "scientificName"))
  if (length(name_col) == 0L) name_col <- names(df)[1L] else name_col <- name_col[1L]

  # Body mass column has spaces in name
  bm_col <- intersect(names(df), c("body.mass", "body mass", "Body.mass"))
  if (length(bm_col) == 0L) {
    bm_col <- grep("^body[._]?mass$", names(df), ignore.case = TRUE, value = TRUE)
  }
  mr_col <- intersect(names(df), c("metabolic.rate", "metabolic rate",
                                    "Metabolic.rate"))
  if (length(mr_col) == 0L) {
    mr_col <- grep("^metabolic[._]?rate$", names(df), ignore.case = TRUE,
                   value = TRUE)
  }

  canonical <- trimws(df[[name_col]])

  bm <- if (length(bm_col) > 0L) {
    suppressWarnings(as.numeric(df[[bm_col[1L]]]))
  } else {
    rep(NA_real_, nrow(df))
  }

  mr <- if (length(mr_col) > 0L) {
    suppressWarnings(as.numeric(df[[mr_col[1L]]]))
  } else {
    rep(NA_real_, nrow(df))
  }

  obs <- data.frame(
    canonical_name = canonical,
    body_mass_kg   = bm,
    metabolic_rate_w = mr,
    stringsAsFactors = FALSE
  )
  obs <- obs[!is.na(obs$canonical_name) & nchar(obs$canonical_name) > 0L, ]

  # Aggregate to species medians
  species <- unique(obs$canonical_name)
  out <- data.frame(
    canonical_name   = species,
    body_mass_kg     = NA_real_,
    metabolic_rate_w = NA_real_,
    stringsAsFactors = FALSE
  )

  idx <- match(obs$canonical_name, species)
  bm_split <- split(obs$body_mass_kg, idx)
  mr_split <- split(obs$metabolic_rate_w, idx)

  out$body_mass_kg <- vapply(bm_split, function(x) {
    x <- x[!is.na(x) & x > 0]
    if (length(x) == 0L) NA_real_ else stats::median(x)
  }, numeric(1L))

  out$metabolic_rate_w <- vapply(mr_split, function(x) {
    x <- x[!is.na(x) & x > 0]
    if (length(x) == 0L) NA_real_ else stats::median(x)
  }, numeric(1L))

  has_data <- !is.na(out$body_mass_kg) | !is.na(out$metabolic_rate_w)
  out[has_data, ]
}


#' Parse NW European Arthropod DwC-A (taxon + measurement + description)
#' @noRd
parse_arthropod_traits <- function(dir_path) {
  # Find files (DwC-A uses .txt extension)
  find_file <- function(patterns) {
    for (p in patterns) {
      f <- list.files(dir_path, pattern = p, full.names = TRUE,
                      recursive = TRUE, ignore.case = TRUE)
      if (length(f) > 0L) return(f[1L])
    }
    NULL
  }

  taxon_file <- find_file(c("taxon\\.txt$", "taxon\\.csv$"))
  mof_file <- find_file(c("measurementorfact", "measurement"))
  desc_file <- find_file(c("description\\.txt$", "description\\.csv$"))

  if (is.null(taxon_file)) {
    stop("Cannot find taxon file in DwC archive.\nContents: ",
         paste(list.files(dir_path, recursive = TRUE), collapse = ", "),
         call. = FALSE)
  }

  # Read taxon core
  taxon <- read.delim(taxon_file, stringsAsFactors = FALSE, quote = "")

  # Species names: strip authorship from scientificName
  name_col <- intersect(names(taxon), c("scientificName", "canonicalName",
                                         "species"))
  if (length(name_col) == 0L) name_col <- names(taxon)[2L] else name_col <- name_col[1L]
  raw_names <- taxon[[name_col]]

  # Strip authorship: keep only first two words (genus + species)
  canonical <- vapply(raw_names, function(n) {
    parts <- strsplit(trimws(n), "\\s+")[[1L]]
    if (length(parts) >= 2L) paste(parts[1L], parts[2L]) else trimws(n)
  }, character(1L), USE.NAMES = FALSE)

  # ID column for joining
  id_col <- intersect(names(taxon), c("id", "taxonID", "ID"))
  if (length(id_col) == 0L) id_col <- names(taxon)[1L] else id_col <- id_col[1L]

  out <- data.frame(
    canonical_name = canonical,
    taxon_id       = taxon[[id_col]],
    stringsAsFactors = FALSE
  )

  # ---- Quantitative traits from measurementorfact ----
  if (!is.null(mof_file)) {
    mof <- read.delim(mof_file, stringsAsFactors = FALSE, quote = "")
    mof_id <- intersect(names(mof), c("id", "taxonID", "coreid"))
    if (length(mof_id) == 0L) mof_id <- names(mof)[1L] else mof_id <- mof_id[1L]

    type_col <- intersect(names(mof), c("measurementType", "type"))
    if (length(type_col) == 0L) type_col <- names(mof)[2L] else type_col <- type_col[1L]
    val_col <- intersect(names(mof), c("measurementValue", "value"))
    if (length(val_col) == 0L) val_col <- names(mof)[3L] else val_col <- val_col[1L]

    # Map measurementType to output column names
    quant_map <- c(
      "Body_size"        = "body_size_mm",
      "Dispersal_ability" = "dispersal",
      "Voltinism_mean"   = "voltinism",
      "Fecundity"        = "fecundity",
      "Development_time" = "development_d",
      "Lifespan"         = "lifespan_d",
      "Thermal_mean"     = "thermal_mean"
    )

    for (mtype in names(quant_map)) {
      out_col <- quant_map[[mtype]]
      rows <- mof[[type_col]] == mtype
      if (!any(rows)) {
        out[[out_col]] <- NA_real_
        next
      }
      sub <- mof[rows, c(mof_id, val_col), drop = FALSE]
      names(sub) <- c("taxon_id", "val")
      sub$val <- suppressWarnings(as.numeric(sub$val))
      sub <- sub[!is.na(sub$val), ]
      sub <- sub[!duplicated(sub$taxon_id), ]
      idx <- match(out$taxon_id, sub$taxon_id)
      out[[out_col]] <- sub$val[idx]
    }
  }

  # ---- Categorical traits from description ----
  if (!is.null(desc_file)) {
    desc <- read.delim(desc_file, stringsAsFactors = FALSE, quote = "")
    desc_id <- intersect(names(desc), c("id", "taxonID", "coreid"))
    if (length(desc_id) == 0L) desc_id <- names(desc)[1L] else desc_id <- desc_id[1L]

    desc_col <- intersect(names(desc), c("description", "value"))
    if (length(desc_col) == 0L) desc_col <- names(desc)[2L] else desc_col <- desc_col[1L]
    type_col2 <- intersect(names(desc), c("type", "measurementType"))
    if (length(type_col2) == 0L) type_col2 <- names(desc)[3L] else type_col2 <- type_col2[1L]

    cat_map <- c(
      "Diurnality"         = "diurnality",
      "Feeding_guild_adult" = "feeding_guild",
      "Trophic_range_adult" = "trophic_range"
    )

    for (dtype in names(cat_map)) {
      out_col <- cat_map[[dtype]]
      rows <- desc[[type_col2]] == dtype
      if (!any(rows)) {
        out[[out_col]] <- NA_character_
        next
      }
      sub <- desc[rows, c(desc_id, desc_col), drop = FALSE]
      names(sub) <- c("taxon_id", "val")
      sub$val <- trimws(sub$val)
      sub$val[sub$val == "" | sub$val == "NA"] <- NA_character_
      sub <- sub[!duplicated(sub$taxon_id), ]
      idx <- match(out$taxon_id, sub$taxon_id)
      out[[out_col]] <- sub$val[idx]
    }
  }

  # Drop taxon_id helper column
  out$taxon_id <- NULL

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  trait_cols <- setdiff(names(out), "canonical_name")
  has_data <- rowSums(!is.na(out[, trait_cols, drop = FALSE])) > 0L
  out <- out[has_data, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse AnAge longevity and life-history traits (TSV from ZIP)
#' @noRd
parse_anage <- function(path) {
  df <- read.delim(path, stringsAsFactors = FALSE, quote = "")

  # Species column: genus + species binomial
  genus_col <- intersect(names(df), c("Genus", "genus"))
  sp_col <- intersect(names(df), c("Species", "species"))

  if (length(genus_col) > 0L && length(sp_col) > 0L) {
    canonical <- trimws(paste(df[[genus_col[1L]]], df[[sp_col[1L]]]))
  } else {
    # Fallback: look for a combined name column
    name_col <- intersect(
      names(df),
      c("Scientific_name", "ScientificName", "scientific_name",
        "Common_name", "Binomial")
    )
    if (length(name_col) == 0L) name_col <- names(df)[1L] else name_col <- name_col[1L]
    canonical <- trimws(df[[name_col]])
  }

  find_col <- function(patterns) {
    for (p in patterns) {
      m <- grep(p, names(df), ignore.case = TRUE, value = TRUE)
      if (length(m) > 0L) return(m[1L])
    }
    NULL
  }

  safe_num <- function(col_name) {
    if (is.null(col_name)) return(rep(NA_real_, nrow(df)))
    x <- suppressWarnings(as.numeric(df[[col_name]]))
    x[x < 0] <- NA_real_  # sentinel values
    x
  }

  # Maximum longevity: stored in years in AnAge
  longevity_col <- find_col(c(
    "Maximum.longevity..yrs.", "Maximum_longevity_yrs",
    "Maximum.longevity", "MaxLongevity", "max_longevity"
  ))

  out <- data.frame(
    canonical_name         = canonical,
    max_longevity_yr       = safe_num(longevity_col),
    body_mass_g            = safe_num(find_col(c(
      "Body.mass..g.", "Body_mass_g", "Adult.weight..g.",
      "AdultWeight", "body_mass"
    ))),
    metabolic_rate_w       = safe_num(find_col(c(
      "Metabolic.rate..W.", "Metabolic_rate_W", "MetabolicRate",
      "metabolic_rate"
    ))),
    female_maturity_d      = safe_num(find_col(c(
      "Female.maturity..days.", "Female_maturity_days",
      "FemaleMaturity", "female_maturity"
    ))),
    male_maturity_d        = safe_num(find_col(c(
      "Male.maturity..days.", "Male_maturity_days",
      "MaleMaturity", "male_maturity"
    ))),
    gestation_incubation_d = safe_num(find_col(c(
      "Gestation.Incubation..days.", "Gestation_Incubation_days",
      "GestationIncubation", "gestation_incubation"
    ))),
    litter_size            = safe_num(find_col(c(
      "Litter.Clutch.size", "Litter_Clutch_size",
      "LitterClutchSize", "litter_clutch_size"
    ))),
    birth_mass_g           = safe_num(find_col(c(
      "Birth.weight..g.", "Birth_weight_g",
      "BirthWeight", "birth_weight"
    ))),
    growth_rate            = safe_num(find_col(c(
      "Growth.rate..1.days.", "Growth_rate",
      "GrowthRate", "growth_rate"
    ))),
    temperature_k          = safe_num(find_col(c(
      "Temperature..K.", "Temperature_K",
      "Temperature", "temperature"
    ))),
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  # Remove entries without any trait data
  trait_cols <- setdiff(names(out), "canonical_name")
  has_data <- rowSums(!is.na(out[, trait_cols, drop = FALSE])) > 0L
  out <- out[has_data, ]
  out[!duplicated(out$canonical_name), ]
}


#' Parse GloNAF taxon-region data (multiple CSVs from ZIP)
#' @noRd
parse_glonaf <- function(dir_path) {
  # GloNAF 2.0 (2024) ships as XLSX on Zenodo; older versions used CSV.
  find_file <- function(patterns) {
    for (p in patterns) {
      f <- list.files(dir_path, pattern = p, full.names = TRUE,
                      recursive = TRUE, ignore.case = TRUE)
      if (length(f) > 0L) return(f[1L])
    }
    NULL
  }

  read_table <- function(path) {
    if (is.null(path)) return(NULL)
    ext <- tolower(tools::file_ext(path))
    if (ext == "csv") {
      read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
    } else if (ext %in% c("xlsx", "xls")) {
      if (!requireNamespace("openxlsx2", quietly = TRUE)) {
        stop("openxlsx2 is required to read GloNAF XLSX files. ",
             "Install with: install.packages('openxlsx2')", call. = FALSE)
      }
      as.data.frame(openxlsx2::read_xlsx(path), stringsAsFactors = FALSE)
    } else {
      read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
    }
  }

  # Main occurrence table: taxon x region
  flora_file <- find_file(c(
    "glonaf_flora.*\\.xlsx", "glonaf_flora.*\\.csv",
    "flora2?\\.xlsx",        "flora2?\\.csv"
  ))
  if (is.null(flora_file)) {
    flora_file <- find_file(c("glonaf_TxR.*\\.xlsx", "glonaf_TxR.*\\.csv",
                              "TxR\\.csv"))
  }
  if (is.null(flora_file)) {
    stop("Cannot find GloNAF flora/TxR table.\nContents: ",
         paste(list.files(dir_path, recursive = TRUE), collapse = ", "),
         call. = FALSE)
  }

  # Taxon table: maps IDs to species names
  taxon_file <- find_file(c(
    "glonaf_taxon.*\\.xlsx", "glonaf_taxon.*\\.csv",
    "taxon_wcvp.*\\.xlsx",   "taxon_wcvp.*\\.csv"
  ))
  # exclude data dictionaries from main tables
  if (!is.null(taxon_file) && grepl("datadictionary", taxon_file,
                                     ignore.case = TRUE)) {
    taxon_file <- find_file(c(
      "^glonaf_taxon[^_]*\\.xlsx$", "^glonaf_taxon[^_]*\\.csv$",
      "^glonaf_taxon_wcvp\\.xlsx$",  "^glonaf_taxon_wcvp\\.csv$"
    ))
  }
  # Region table: maps region IDs to region codes/names
  region_file <- find_file(c(
    "glonaf_region.*\\.xlsx", "glonaf_region.*\\.csv",
    "region\\.csv"
  ))
  if (!is.null(region_file) && grepl("datadictionary", region_file,
                                      ignore.case = TRUE)) {
    region_file <- find_file(c(
      "^glonaf_region[^_]*\\.xlsx$", "^glonaf_region[^_]*\\.csv$"
    ))
  }

  flora <- read_table(flora_file)

  # Resolve species names
  if (!is.null(taxon_file)) {
    taxon <- read_table(taxon_file)
    # Find the join key
    flora_taxon_col <- intersect(
      names(flora),
      c("taxon_wcvp_id", "taxon_id", "id", "ID")
    )
    taxon_id_col <- intersect(
      names(taxon),
      c("id", "taxon_wcvp_id", "taxon_id", "ID")
    )
    taxon_name_col <- intersect(
      names(taxon),
      c("taxa_accepted", "taxon_corrected", "species_name",
        "accepted_name", "taxon_name", "name",
        "scientificName", "canonical_name")
    )

    if (length(flora_taxon_col) > 0L && length(taxon_id_col) > 0L &&
        length(taxon_name_col) > 0L) {
      taxon_lookup <- taxon[, c(taxon_id_col[1L], taxon_name_col[1L])]
      names(taxon_lookup) <- c("join_key", "canonical_name")
      taxon_lookup <- taxon_lookup[!duplicated(taxon_lookup$join_key), ]
      flora$join_key <- flora[[flora_taxon_col[1L]]]
      flora <- merge(flora, taxon_lookup, by = "join_key", all.x = TRUE)
    }
  }

  # If no taxon table or merge failed, look for name column directly
  if (!"canonical_name" %in% names(flora)) {
    name_col <- intersect(
      names(flora),
      c("species_name", "accepted_name", "taxon_name", "scientificName",
        "canonical_name", "species")
    )
    if (length(name_col) == 0L) {
      stop("Cannot resolve species names in GloNAF data.", call. = FALSE)
    }
    flora$canonical_name <- trimws(flora[[name_col[1L]]])
  }

  # Resolve region codes
  if (!is.null(region_file)) {
    region <- read_table(region_file)
    region_id_col <- intersect(
      names(region),
      c("region_id", "OBJIDsic", "id", "ID")
    )
    region_code_col <- intersect(
      names(region),
      c("code", "tdwg4_code", "tdwg3_code", "tdwg2_code",
        "iso_equivalent", "country_code", "region_code", "name")
    )
    flora_region_col <- intersect(
      names(flora),
      c("region_id", "OBJIDsic", "region")
    )

    if (length(region_id_col) > 0L && length(region_code_col) > 0L &&
        length(flora_region_col) > 0L) {
      region_lookup <- region[, c(region_id_col[1L], region_code_col[1L])]
      names(region_lookup) <- c("region_join", "region_code_resolved")
      region_lookup <- region_lookup[!duplicated(region_lookup$region_join), ]
      flora$region_join <- flora[[flora_region_col[1L]]]
      flora <- merge(flora, region_lookup, by = "region_join", all.x = TRUE)
      flora$region_id <- as.character(flora$region_code_resolved)
    }
  }

  # If region_id still missing, use the raw region column
  if (!"region_id" %in% names(flora) || all(is.na(flora$region_id))) {
    region_col <- intersect(
      names(flora),
      c("region_id", "region", "OBJIDsic", "region_id_raw")
    )
    if (length(region_col) > 0L) {
      flora$region_id <- as.character(flora[[region_col[1L]]])
    } else {
      stop("Cannot resolve region identifiers in GloNAF data.", call. = FALSE)
    }
  }

  out <- data.frame(
    canonical_name = trimws(flora$canonical_name),
    region_id      = as.character(flora$region_id),
    naturalized    = 1L,
    stringsAsFactors = FALSE
  )

  out <- out[!is.na(out$canonical_name) & nchar(out$canonical_name) > 0L, ]
  out <- out[!is.na(out$region_id) & nchar(out$region_id) > 0L, ]
  out[!duplicated(paste(out$canonical_name, out$region_id)), ]
}


# ---- Build registry ----

#' @noRd
.enrichment_build_registry <- list(

  woodiness = list(
    source_url  = "https://raw.githubusercontent.com/ejedwards/reanalysis_zanne2014/master/dryad/GlobalWoodinessDatabase.csv",
    source_doi  = "10.5061/dryad.63q27",
    version     = "2014.1",
    license     = "CC0",
    attribution = "Zanne AE et al. (2014) Three keys to the radiation of angiosperms into freezing environments. Nature 506:89-92. (Dryad CSV mirrored unaltered in github.com/ejedwards/reanalysis_zanne2014.)",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "GlobalWoodinessDatabase.csv")
    },
    parse_fn    = parse_woodiness,
    group_col   = NULL,
    requires    = character(0)
  ),

  eive = list(
    source_url  = "https://zenodo.org/records/7534792/files/EIVE_Paper_1.0_SM_08.xlsx?download=1",
    source_doi  = "10.3897/VCS.98324",
    version     = "1.0",
    license     = "CC BY 4.0",
    attribution = "Dengler J et al. (2023) EIVE 1.0 -- a standardized set of Ecological Indicator Values for Europe. Vegetation Classification and Survey 4:7-29.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "EIVE_1.0.xlsx")
    },
    parse_fn    = parse_eive,
    group_col   = NULL,
    requires    = "openxlsx2"
  ),

  elton_traits = list(
    source_url  = "https://ndownloader.figshare.com/files/5631081",
    source_doi  = "10.6084/m9.figshare.c.3306933.v1",
    version     = "1.0",
    license     = "CC0",
    attribution = "Wilman H et al. (2014) EltonTraits 1.0: Species-level foraging attributes of the world's birds and mammals. Ecology 95:2027.",
    download_fn = function(url, dest) {
      dir.create(dest, recursive = TRUE, showWarnings = FALSE)
      birds_path <- download_curl_file(
        "https://ndownloader.figshare.com/files/5631081",
        dest, "BirdFuncDat.txt"
      )
      mammals_path <- download_curl_file(
        "https://ndownloader.figshare.com/files/5631084",
        dest, "MamFuncDat.txt"
      )
      dest
    },
    parse_fn    = function(path) {
      parse_elton_traits(
        file.path(path, "BirdFuncDat.txt"),
        file.path(path, "MamFuncDat.txt")
      )
    },
    group_col   = NULL,
    requires    = character(0)
  ),

  avonet = list(
    source_url  = "https://ndownloader.figshare.com/files/34480856",
    source_doi  = "10.6084/m9.figshare.16586228.v5",
    version     = "1.0",
    license     = "CC BY 4.0",
    attribution = "Tobias JA et al. (2022) AVONET: morphological, ecological and geographical data for all birds. Ecology Letters 25:581-597.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "AVONET_BirdLife.xlsx")
    },
    parse_fn    = parse_avonet,
    group_col   = NULL,
    requires    = "openxlsx2"
  ),

  pantheria = list(
    source_url  = "https://esapubs.org/archive/ecol/E090/184/PanTHERIA_1-0_WR05_Aug2008.txt",
    source_doi  = "10.1890/08-1494.1",
    version     = "1.0",
    license     = "CC0",
    attribution = "Jones KE et al. (2009) PanTHERIA: a species-level database of life history, ecology, and geography of extant and recently extinct mammals. Ecology 90:2648.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "PanTHERIA.txt")
    },
    parse_fn    = parse_pantheria,
    group_col   = NULL,
    requires    = character(0)
  ),

  amphibio = list(
    source_url  = "https://ndownloader.figshare.com/files/8828578",
    source_doi  = "10.6084/m9.figshare.4644424.v5",
    version     = "1.0",
    license     = "CC BY 4.0",
    attribution = "Oliveira BF et al. (2017) AmphiBIO, a global database for amphibian ecological traits. Scientific Data 4:170123.",
    download_fn = function(url, dest) {
      download_and_unzip(url, dest, "\\.csv$")
    },
    parse_fn    = parse_amphibio,
    group_col   = NULL,
    requires    = character(0)
  ),

  leda = list(
    source_url  = "https://uol.de/f/5/inst/biologie/ag/landeco/download/LEDA/Data_files/",
    source_doi  = "10.1111/j.1365-2745.2008.01430.x",
    version     = "2008.1",
    license     = "Free for academic use",
    attribution = "Kleyer M et al. (2008) The LEDA Traitbase: a database of life-history traits of the Northwest European flora. J Ecol 96:1266-1274.",
    download_fn = function(url, dest) {
      dir.create(dest, recursive = TRUE, showWarnings = FALSE)
      leda_base <- "https://uol.de/f/5/inst/biologie/ag/landeco/download/LEDA/Data_files/"
      # LEDA filenames map: parser-expected name -> upstream filename(s).
      # Some traits were re-released with year suffix in 2016.
      trait_files <- c(
        "life_form.txt"         = "plant_growth_form.txt",
        "dispersal_type.txt"    = "dispersal_type.txt",
        "TV.txt"                = "TV_2016.txt",
        "seed_mass.txt"         = "seed_mass.txt",
        "canopy_height.txt"     = "canopy_height.txt",
        "leaf_mass.txt"         = "leaf_mass.txt",
        "SLA.txt"               = "SLA_und_geo_neu2.txt",
        "clonal_growth.txt"     = "CGO.txt",
        "buoyancy.txt"          = "buoyancy_2016.txt"
      )
      for (out_name in names(trait_files)) {
        upstream <- trait_files[[out_name]]
        tryCatch(
          download_curl_file(paste0(leda_base, upstream), dest, out_name),
          error = function(e) {
            message(sprintf("  Warning: failed to download LEDA %s (%s): %s",
                            out_name, upstream, conditionMessage(e)))
          }
        )
      }
      dest
    },
    parse_fn    = parse_leda,
    group_col   = NULL,
    requires    = character(0)
  ),

  diaz_traits = list(
    source_url  = "https://static-content.springer.com/esm/art%3A10.1038%2Fs41586-022-05606-z/MediaObjects/41586_2022_5606_MOESM3_ESM.xlsx",
    source_doi  = "10.1038/s41586-022-05606-z",
    version     = "2022.1",
    license     = "CC BY 3.0",
    attribution = "Diaz S et al. (2022) The global spectrum of plant form and function: enhanced species-level trait data. Nature.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "Diaz_2022_traits.xlsx")
    },
    parse_fn    = parse_diaz_traits,
    group_col   = NULL,
    requires    = "openxlsx2"
  ),

  griis = list(
    source_url  = "https://zenodo.org/records/6348164/files/GRIIS%20-%20Country%20Compendium%20V1_0.csv?download=1",
    source_doi  = "10.15468/6jcu0q",
    version     = "1.0",
    license     = "CC BY 4.0",
    attribution = "Pagad S et al. GRIIS - Global Register of Introduced and Invasive Species.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "GRIIS_Country_Compendium_V1_0.csv")
    },
    parse_fn    = parse_griis,
    group_col   = "country_code",
    requires    = character(0)
  ),

  alien_first_records = list(
    source_url  = "https://doi.org/10.6084/m9.figshare.c.3924424.v3",
    source_doi  = "10.6084/m9.figshare.c.3924424.v3",
    version     = "3.1",
    license     = "CC BY 4.0",
    attribution = "Seebens H et al. (2017) No saturation in the accumulation of alien species worldwide. Nature Communications 8, 14435.",
    download_fn = function(url, dest) {
      download_curl_file(
        url, dest,
        "GlobalAlienSpeciesFirstRecordDatabase_v3.1_freedata.xlsx"
      )
    },
    parse_fn    = parse_alien_first_records,
    group_col   = "country_code",
    requires    = "openxlsx2"
  ),

  conservation_status = list(
    source_url  = "https://api.gbif.org/v1/species/search",
    source_doi  = NULL,
    version     = format(Sys.Date(), "%Y.%m"),
    license     = "Factual data (not copyrightable)",
    attribution = "Conservation status from GBIF Backbone Taxonomy (IUCN Red List categories).",
    download_fn = function(url, dest) {
      # API-based: no file download; return a dummy marker path
      dir.create(dest, recursive = TRUE, showWarnings = FALSE)
      marker <- file.path(dest, ".api_source")
      writeLines("gbif_species_search", marker)
      marker
    },
    parse_fn    = parse_conservation_status,
    group_col   = NULL,
    requires    = character(0)
  ),

  wcvp = list(
    source_url  = "https://sftp.kew.org/pub/data-repositories/WCVP/wcvp.zip",
    source_doi  = "10.1038/s41597-021-00997-6",
    version     = "2024.1",
    license     = "CC BY",
    attribution = "WCVP (2024) World Checklist of Vascular Plants. Royal Botanic Gardens, Kew.",
    download_fn = function(url, dest) {
      download_and_unzip(url, dest, pattern = NULL)
    },
    parse_fn    = parse_wcvp,
    group_col   = "tdwg_code",
    requires    = character(0)
  ),

  common_names = list(
    source_url  = paste(
      "https://hosted-datasets.gbif.org/datasets/backbone/current/backbone.zip",
      "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz",
      "https://files.opentreeoflife.org/ott/ott3.7.3/ott3.7.3.tgz",
      sep = " ; "
    ),
    source_doi  = NULL,
    version     = format(Sys.Date(), "%Y.%m"),
    license     = "CC0 (GBIF, OTT) / public domain (NCBI)",
    attribution = paste(
      "GBIF Secretariat. GBIF Backbone Taxonomy vernacular names.",
      "NCBI Taxonomy (common names from names.dmp).",
      "Open Tree of Life Taxonomy (common names from synonyms.tsv).",
      sep = " "
    ),
    download_fn = function(url, dest) {
      dir.create(dest, recursive = TRUE, showWarnings = FALSE)
      urls <- strsplit(url, " ; ", fixed = TRUE)[[1L]]
      gbif_url <- urls[1L]
      ncbi_url <- urls[2L]
      ott_url  <- urls[3L]

      # ---- GBIF ----
      gbif_dir <- file.path(dest, "gbif")
      if (!dir.exists(gbif_dir)) {
        dir.create(gbif_dir, recursive = TRUE)
        zip_path <- file.path(dest, "backbone.zip")
        if (!file.exists(zip_path)) {
          h <- curl::new_handle()
          curl::handle_setopt(h, followlocation = TRUE, maxredirs = 10L)
          curl::handle_setheaders(h, "User-Agent" = "R/4.5 taxify")
          curl::curl_download(gbif_url, zip_path, handle = h)
        }
        zip_contents <- utils::unzip(zip_path, list = TRUE)
        vn_file <- zip_contents$Name[grepl("VernacularName", zip_contents$Name)]
        taxon_file <- zip_contents$Name[grepl("^Taxon\\.tsv$", zip_contents$Name)]
        utils::unzip(zip_path, files = c(vn_file, taxon_file),
                     exdir = gbif_dir, junkpaths = TRUE)
      }

      # ---- NCBI ----
      ncbi_dir <- file.path(dest, "ncbi")
      if (!dir.exists(ncbi_dir)) {
        dir.create(ncbi_dir, recursive = TRUE)
        tar_path <- file.path(dest, "taxdump.tar.gz")
        if (!file.exists(tar_path)) {
          utils::download.file(ncbi_url, tar_path, mode = "wb", quiet = TRUE)
        }
        utils::untar(tar_path, files = "names.dmp", exdir = ncbi_dir)
      }

      # ---- OTT (optional; files.opentreeoflife.org is not always reachable) ----
      ott_dir <- file.path(dest, "ott")
      if (!dir.exists(ott_dir)) {
        tryCatch({
          dir.create(ott_dir, recursive = TRUE)
          tgz_path <- file.path(dest, "ott.tgz")
          if (!file.exists(tgz_path)) {
            utils::download.file(ott_url, tgz_path, mode = "wb", quiet = TRUE)
          }
          utils::untar(tgz_path, exdir = dest)
          ott_extracted <- list.dirs(dest, recursive = FALSE, full.names = TRUE)
          ott_extracted <- ott_extracted[grepl("^ott", basename(ott_extracted))][1L]
          if (!is.na(ott_extracted)) {
            file.copy(file.path(ott_extracted, "taxonomy.tsv"), ott_dir)
            file.copy(file.path(ott_extracted, "synonyms.tsv"), ott_dir)
            unlink(ott_extracted, recursive = TRUE)
          }
        }, error = function(e) {
          message(sprintf(
            "  Warning: OTT common names skipped (%s). ",
            conditionMessage(e)
          ))
          unlink(ott_dir, recursive = TRUE)
        })
      }

      dest
    },
    parse_fn    = parse_common_names,
    group_col   = "lang",
    requires    = character(0)
  ),

  funguild = list(
    source_url  = "http://www.stbates.org/funguild_db_2.php",
    source_doi  = "10.1016/j.funeco.2015.06.006",
    version     = "2024.1",
    license     = "CC BY 4.0",
    attribution = "Nguyen NH et al. (2016) FUNGuild: An open annotation tool for parsing fungal community datasets by ecological guild. Fungal Ecology 20:241-248.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "funguild_db.html")
    },
    parse_fn    = parse_funguild,
    group_col   = NULL,
    requires    = character(0)
  ),

  fishbase = list(
    source_url  = "https://fishbase.ropensci.org",
    source_doi  = "10.14284/XXX",
    version     = format(Sys.Date(), "%Y.%m"),
    license     = "CC BY-NC 3.0",
    attribution = "Froese R, Pauly D (eds.) (2024) FishBase. World Wide Web electronic publication, https://www.fishbase.org.",
    download_fn = function(url, dest) {
      # rfishbase fetches data directly; dest is used only for interface
      # consistency. Return dest so the parse function receives a path.
      dir.create(dest, recursive = TRUE, showWarnings = FALSE)
      dest
    },
    parse_fn    = parse_fishbase,
    group_col   = NULL,
    requires    = "rfishbase"
  ),

  fungal_traits = list(
    source_url  = "https://static-content.springer.com/esm/art%3A10.1007%2Fs13225-020-00466-2/MediaObjects/13225_2020_466_MOESM4_ESM.xlsx",
    source_doi  = "10.1007/s13225-020-00466-2",
    version     = "2020.1",
    license     = "CC BY 4.0",
    attribution = "Polme S et al. (2020) FungalTraits: a user-friendly traits database of fungi and fungus-like stramenopiles. Fungal Diversity 105:1-16.",
    download_fn = function(url, dest) {
      download_curl_file(
        url, dest, "FungalTraits.xlsx",
        referer = "https://link.springer.com/article/10.1007/s13225-020-00466-2"
      )
    },
    parse_fn    = parse_fungal_traits,
    group_col   = NULL,
    name_col    = "genus",
    requires    = "openxlsx2"
  ),

  algae_traits = list(
    source_url  = "https://mda.vliz.be/download.php?file=VLIZ_00000308_62bf06138859e409561556",
    source_doi  = "10.14284/574",
    version     = "2022.06",
    license     = "CC BY 4.0",
    attribution = "Vranken S et al. (2023) AlgaeTraits: a trait database for (European) seaweeds. Earth System Science Data 15:2711-2754.",
    download_fn = function(url, dest) {
      download_and_unzip(url, dest, pattern = NULL)
    },
    parse_fn    = parse_algae_traits,
    group_col   = NULL,
    requires    = character(0)
  ),

  fish_traits = list(
    source_url  = "https://ndownloader.figshare.com/files/28672242",
    source_doi  = "10.6084/m9.figshare.14891412",
    version     = "1.0",
    license     = "CC BY 4.0",
    attribution = "Brosse S et al. (2021) FISHMORPH: A global database on morphological traits of freshwater fishes. Global Ecology and Biogeography 30:2330-2336.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "FISHMORPH_Database.csv")
    },
    parse_fn    = parse_fish_traits,
    group_col   = NULL,
    requires    = character(0)
  ),

  lizard_traits = list(
    source_url  = "https://ndownloader.figshare.com/files/45408133",
    source_doi  = "10.6084/m9.figshare.24572683",
    version     = "1.2",
    license     = "CC BY 4.0",
    attribution = "Etard A et al. (2024) ReptTraits: a comprehensive dataset of ecological traits in reptiles. Scientific Data 11:243.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "ReptTraits_v1-2.xlsx")
    },
    parse_fn    = parse_lizard_traits,
    group_col   = NULL,
    requires    = "openxlsx2"
  ),

  anage = list(
    source_url  = "https://genomics.senescence.info/species/dataset.zip",
    source_doi  = "10.1111/j.1420-9101.2009.01783.x",
    version     = "15.0",
    license     = "CC BY",
    attribution = "Tacutu R et al. (2018) Human Ageing Genomic Resources: new and updated databases. Nucleic Acids Research 46:D1083-D1090.",
    download_fn = function(url, dest) {
      download_and_unzip(url, dest, "(?i)anage.*\\.txt$")
    },
    parse_fn    = parse_anage,
    group_col   = NULL,
    requires    = character(0)
  ),

  glonaf = list(
    source_url  = "https://zenodo.org/api/records/13235357",
    source_doi  = "10.1002/ecy.2542",
    version     = "2024.1",
    license     = "CC BY 4.0",
    attribution = "van Kleunen M et al. (2019) The Global Naturalized Alien Flora (GloNAF) database. Ecology 100:e02542.",
    download_fn = function(url, dest) {
      dir.create(dest, recursive = TRUE, showWarnings = FALSE)
      base <- "https://zenodo.org/records/13235357/files/"
      files <- c("glonaf_flora2.xlsx", "glonaf_taxon_wcvp.xlsx",
                 "glonaf_region.xlsx")
      for (f in files) {
        tryCatch(
          download_curl_file(paste0(base, f, "?download=1"), dest, f),
          error = function(e) {
            message(sprintf("  Warning: failed to download GloNAF %s: %s",
                            f, conditionMessage(e)))
          }
        )
      }
      dest
    },
    parse_fn    = parse_glonaf,
    group_col   = "region_id",
    requires    = "openxlsx2"
  ),

  leptraits = list(
    source_url  = "https://raw.githubusercontent.com/RiesLabGU/LepTraits/main/consensus/consensus.csv",
    source_doi  = "10.1038/s41597-022-01473-5",
    version     = "1.0",
    license     = "CC0",
    attribution = "Shirey V et al. (2022) LepTraits 1.0: A globally comprehensive dataset of butterfly traits. Scientific Data 9:398.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "consensus.csv")
    },
    parse_fn    = parse_leptraits,
    group_col   = NULL,
    requires    = character(0)
  ),

  animaltraits = list(
    source_url  = "https://zenodo.org/record/6468938/files/observations.csv?download=1",
    source_doi  = "10.1038/s41597-022-01364-9",
    version     = "1.0",
    license     = "CC0",
    attribution = "Hebert K et al. (2022) AnimalTraits -- a curated animal trait database for body mass, metabolic rate and brain size. Scientific Data 9:265.",
    download_fn = function(url, dest) {
      download_curl_file(url, dest, "observations.csv")
    },
    parse_fn    = parse_animaltraits,
    group_col   = NULL,
    requires    = character(0)
  ),

  arthropod_traits = list(
    source_url  = "https://ipt.biodiversity.be/archive.do?r=arthropod-trait-dataset&v=1.1",
    source_doi  = "10.3897/BDJ.13.e146785",
    version     = "1.1",
    license     = "CC BY-NC",
    attribution = "Logghe A et al. (2025) An in-depth dataset of northwestern European arthropod life histories and ecological traits. Biodiversity Data Journal 13:e146785.",
    download_fn = function(url, dest) {
      download_and_unzip(url, dest, pattern = NULL)
    },
    parse_fn    = parse_arthropod_traits,
    group_col   = NULL,
    requires    = character(0)
  )
)


# ---- Main build function ----

#' Build an enrichment .vtr from original source data
#'
#' Downloads the original source data, parses it using the enrichment's
#' built-in pipeline (cleaning, deduplication, country mapping, etc.), and
#' writes a local `.vtr` file. Use this to rebuild an enrichment with the
#' latest upstream data, or point it at a custom URL for a newer release.
#'
#' @param name Character. Enrichment identifier (e.g., `"conservation_status"`,
#'   `"griis"`, `"alien_first_records"`). See `list_enrichments()` for
#'   available names.
#' @param url Character or `NULL`. Custom source URL to download from instead
#'   of the default. The same download and parse pipeline is used, so the file
#'   at the URL must have the same format as the original source. Default
#'   `NULL` (use the registry's built-in URL).
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#' @return Path to the built `.vtr` file (invisibly).
#'
#' @examples
#' \dontrun{
#' # Rebuild from default source
#' build_enrichment_from_source("conservation_status")
#'
#' # Rebuild from a newer release URL
#' build_enrichment_from_source(
#'   "alien_first_records",
#'   url = "https://figshare.com/ndownloader/articles/6192923/versions/4"
#' )
#' }
#'
#' @export
build_enrichment_from_source <- function(name, url = NULL, verbose = TRUE) {
  reg <- .enrichment_build_registry[[name]]
  if (is.null(reg)) {
    available <- paste(names(.enrichment_build_registry), collapse = ", ")
    stop(sprintf(
      "Unknown enrichment '%s'. Available: %s", name, available
    ), call. = FALSE)
  }

  # Check required packages
  for (pkg in reg$requires) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(sprintf(
        paste0("Package '%s' is required to build enrichment '%s' from source. ",
               "Install with: install.packages('%s')"),
        pkg, name, pkg
      ), call. = FALSE)
    }
  }

  source_url <- url %||% reg$source_url
  if (verbose) message(sprintf("Building enrichment '%s' from source...", name))

  # Download raw source
  dl_dir <- file.path(tempdir(), "taxify_enrichment_build", name)
  if (verbose) message("  Downloading source data...")
  source_path <- reg$download_fn(source_url, dl_dir)

  # Parse to data.frame
  if (verbose) message("  Parsing...")
  df <- reg$parse_fn(source_path)

  if (!is.data.frame(df) || nrow(df) == 0L) {
    stop(sprintf("Parse function for '%s' returned no data.", name),
         call. = FALSE)
  }

  if (verbose) {
    message(sprintf("  Parsed %s rows.", format(nrow(df), big.mark = ",")))
  }

  # Build .vtr
  vtr_path <- enrichment_vtr_path(name)
  build_local_enrichment_vtr(
    df, vtr_path,
    name        = name,
    version     = if (!is.null(url)) format(Sys.Date(), "%Y.%m") else reg$version,
    source_url  = source_url,
    source_doi  = if (!is.null(url)) NULL else reg$source_doi,
    license     = reg$license,
    attribution = reg$attribution,
    group_col   = reg$group_col,
    name_col    = reg$name_col %||% "canonical_name"
  )

  if (verbose) {
    size_mb <- file.size(vtr_path) / 1048576
    message(sprintf(
      "  Built '%s' enrichment: %s rows, %.1f MB.",
      name, format(nrow(df), big.mark = ","), size_mb
    ))
  }

  invisible(vtr_path)
}


# ---- Emergency fallback ----

#' Build enrichment from source and return the raw data.frame
#'
#' Same as `build_enrichment_from_source()` but returns the parsed data.frame
#' instead of writing a .vtr file. Useful as a temporary fallback when
#' vectra is unavailable or the user needs the raw data for debugging.
#'
#' @param name Character. Enrichment identifier.
#' @param verbose Logical. Default `TRUE`.
#' @return A data.frame with canonical_name + trait columns.
#' @noRd
enrichment_emergency_fallback <- function(name, verbose = TRUE) {
  reg <- .enrichment_build_registry[[name]]
  if (is.null(reg)) {
    available <- paste(names(.enrichment_build_registry), collapse = ", ")
    stop(sprintf(
      "Unknown enrichment '%s'. Available: %s", name, available
    ), call. = FALSE)
  }

  for (pkg in reg$requires) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(sprintf(
        paste0("Package '%s' is required for enrichment '%s'. ",
               "Install with: install.packages('%s')"),
        pkg, name, pkg
      ), call. = FALSE)
    }
  }

  if (verbose) {
    warning(sprintf(
      paste0("Building enrichment '%s' in emergency fallback mode. ",
             "This returns a temporary in-memory data.frame, not a ",
             "persistent .vtr file. Run build_enrichment_from_source('%s') ",
             "for a permanent build."),
      name, name
    ), call. = FALSE, immediate. = TRUE)
  }

  dl_dir <- file.path(tempdir(), "taxify_enrichment_fallback", name)
  if (verbose) message(sprintf("Downloading '%s' source data...", name))
  source_path <- reg$download_fn(reg$source_url, dl_dir)

  if (verbose) message("Parsing...")
  df <- reg$parse_fn(source_path)

  if (verbose) {
    message(sprintf(
      "Emergency fallback: %s rows for '%s'.",
      format(nrow(df), big.mark = ","), name
    ))
  }

  df
}
