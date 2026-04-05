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
download_curl_file <- function(url, dest_dir, filename) {
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(dest_dir, filename)
  if (file.exists(dest) && file.size(dest) > 100L) return(dest)

  h <- curl::new_handle()
  curl::handle_setopt(h, followlocation = TRUE, maxredirs = 10L)
  curl::handle_setheaders(h, "User-Agent" = "R/4.5 taxify")
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
  do.call(rbind, all_rows)
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
    tryCatch({
      df <- read.csv(path, sep = ";", stringsAsFactors = FALSE,
                     fileEncoding = "latin1")
      if (ncol(df) <= 1L) {
        df <- read.delim(path, stringsAsFactors = FALSE, fileEncoding = "latin1")
      }
      df
    }, error = function(e) {
      tryCatch(
        read.delim(path, stringsAsFactors = FALSE),
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

  out <- do.call(rbind, all_data)
  rownames(out) <- NULL

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


# ---- Build registry ----

#' @noRd
.enrichment_build_registry <- list(

  woodiness = list(
    source_url  = "https://datadryad.org/api/v2/datasets/doi%3A10.5061%2Fdryad.63q27/download",
    source_doi  = "10.5061/dryad.63q27",
    version     = "2014.1",
    license     = "CC0",
    attribution = "Zanne AE et al. (2014) Three keys to the radiation of angiosperms into freezing environments. Nature 506:89-92.",
    download_fn = function(url, dest) {
      download_and_unzip(url, dest, "(?i)(woodiness|GlobalWood).*\\.csv$")
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
    source_url  = "https://uol.de/fileadmin/user_upload/biologie/ag/landeco/download/LEDA/",
    source_doi  = "10.1111/j.1365-2745.2008.01430.x",
    version     = "2008.1",
    license     = "Free for academic use",
    attribution = "Kleyer M et al. (2008) The LEDA Traitbase: a database of life-history traits of the Northwest European flora. J Ecol 96:1266-1274.",
    download_fn = function(url, dest) {
      dir.create(dest, recursive = TRUE, showWarnings = FALSE)
      leda_base <- "https://uol.de/fileadmin/user_upload/biologie/ag/landeco/download/LEDA/"
      trait_files <- c("life_form.txt", "dispersal_type.txt", "TV.txt",
                       "seed_mass.txt", "canopy_height.txt", "leaf_mass.txt",
                       "SLA.txt", "clonal_growth.txt", "buoyancy.txt")
      for (f in trait_files) {
        tryCatch(
          download_curl_file(paste0(leda_base, f), dest, f),
          error = function(e) {
            message(sprintf("  Warning: failed to download LEDA %s: %s",
                            f, conditionMessage(e)))
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
      "https://files.opentreeoflife.org/ott/ott3.7/ott3.7.tgz",
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

      # ---- OTT ----
      ott_dir <- file.path(dest, "ott")
      if (!dir.exists(ott_dir)) {
        dir.create(ott_dir, recursive = TRUE)
        tgz_path <- file.path(dest, "ott.tgz")
        if (!file.exists(tgz_path)) {
          utils::download.file(ott_url, tgz_path, mode = "wb", quiet = TRUE)
        }
        utils::untar(tgz_path, exdir = dest)
        # OTT extracts to e.g. ott3.7/ — move the files we need
        ott_extracted <- list.dirs(dest, recursive = FALSE, full.names = TRUE)
        ott_extracted <- ott_extracted[grepl("^ott", basename(ott_extracted))][1L]
        if (!is.na(ott_extracted)) {
          file.copy(file.path(ott_extracted, "taxonomy.tsv"), ott_dir)
          file.copy(file.path(ott_extracted, "synonyms.tsv"), ott_dir)
          unlink(ott_extracted, recursive = TRUE)
        }
      }

      dest
    },
    parse_fn    = parse_common_names,
    group_col   = "lang",
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
    group_col   = reg$group_col
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
