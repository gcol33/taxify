# Analyze the ~200 unmatched names in detail
setwd("C:/Users/Gilles Colling/Documents/dev/vectra")
devtools::load_all()
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

truth <- utils::read.csv(
  "J:/Phd Local/Gilles_paper2/Data/ASAAS/Data prep/05_Taxa_WFO/02_eva_one_to_one_wfo_clean.csv",
  stringsAsFactors = FALSE
)

# Same subset
is_synonym    <- truth$EVA_TAXON != truth$WFO_TAXON & !is.na(truth$WFO_TAXON)
is_hybrid     <- grepl("\u00d7| x |^x ", truth$EVA_TAXON, ignore.case = FALSE)
is_infraspec  <- grepl("subsp\\.|var\\.|f\\.", truth$EVA_TAXON)
has_na_wfo    <- is.na(truth$WFO_TAXON) | truth$WFO_TAXON == ""

set.seed(42)
n_per_group <- 200
idx_synonym   <- sample(which(is_synonym & !is_hybrid), min(n_per_group, sum(is_synonym & !is_hybrid)))
idx_hybrid    <- sample(which(is_hybrid), min(n_per_group, sum(is_hybrid)))
idx_infraspec <- sample(which(is_infraspec & !is_synonym), min(n_per_group, sum(is_infraspec & !is_synonym)))
idx_exact     <- sample(which(!is_synonym & !is_hybrid & !is_infraspec & !has_na_wfo),
                        min(n_per_group, sum(!is_synonym & !is_hybrid & !is_infraspec & !has_na_wfo)))
idx_random    <- sample(nrow(truth), min(500, nrow(truth)))
all_idx <- sort(unique(c(idx_synonym, idx_hybrid, idx_infraspec, idx_exact, idx_random)))
subset <- truth[all_idx, ]

res <- taxify(subset$EVA_TAXON, backend = "wfo", fuzzy = TRUE, verbose = FALSE)

# Get unmatched
unmatched <- res$match_type == "none" | is.na(res$match_type)
has_truth <- !is.na(subset$WFO_TAXON) & subset$WFO_TAXON != ""

um <- data.frame(
  eva = subset$EVA_TAXON[unmatched],
  wfo_expected = subset$WFO_TAXON[unmatched],
  wfo_family = subset$WFO_FAMILY[unmatched],
  wfo_rank = subset$WFO_TAXON_RANK[unmatched],
  wfo_id = subset$WFO_ID[unmatched],
  has_truth = has_truth[unmatched],
  stringsAsFactors = FALSE
)

# Classify unmatched
um$category <- NA_character_

# 1. No ASAAS ground truth (WFO_TAXON is NA/empty)
um$category[!um$has_truth] <- "no_ground_truth"

# 2. Lichens/mosses/fungi mapped to vascular plants (ASAAS bug)
# Check if EVA name looks like a lichen/moss but WFO expected is a vascular plant
lichen_genera <- c("Peltigera", "Cladonia", "Caloplaca", "Leptogium", "Collema",
                   "Umbilicaria", "Buellia", "Stereocaulon", "Toninia", "Placidium",
                   "Dermatocarpon", "Xanthoria", "Parmelia", "Lecidea", "Verrucaria",
                   "Cladina", "Cetraria", "Usnea", "Ramalina", "Hypogymnia",
                   "Pertusaria", "Ochrolechia", "Lepraria", "Diploschistes",
                   "Physcia", "Phaeophyscia", "Lobaria", "Nephroma", "Pannaria",
                   "Solorina", "Sticta", "Pseudevernia", "Flavoparmelia",
                   "Melanelia", "Platismatia", "Vulpicida", "Brodoa",
                   "Marchesinia", "Herbertus", "Telaranea", "Lophozia",
                   "Barbilophozia", "Scapania", "Diplophyllum", "Plagiochila",
                   "Porella", "Frullania", "Radula", "Metzgeria", "Pellia",
                   "Riccardia", "Calypogeia", "Lepidozia", "Bazzania",
                   "Trichocolea", "Nowellia", "Odontoschisma", "Cephalozia",
                   "Gymnomitrion", "Marsupella", "Nardia", "Jungermannia",
                   "Sphagnum", "Polytrichum", "Dicranum", "Leucobryum",
                   "Mnium", "Rhizomnium", "Plagiomnium", "Hylocomium",
                   "Pleurozium", "Rhytidiadelphus", "Thuidium", "Hypnum",
                   "Neckera", "Isothecium", "Anomodon", "Leucodon",
                   "Antitrichia", "Homalothecium", "Brachythecium",
                   "Eurhynchium", "Drepanocladus", "Scorpidium", "Calliergon",
                   "Sanionia", "Cratoneuron", "Philonotis", "Bartramia",
                   "Meesia", "Paludella", "Aulacomnium", "Atrichum",
                   "Pogonatum", "Dendroalsia", "Hedwigia", "Racomitrium",
                   "Grimmia", "Schistidium", "Andreaea", "Tortula",
                   "Syntrichia", "Bryum", "Pohlia", "Leskea", "Orthotrichum",
                   "Ulota", "Zygodon", "Encalypta", "Funaria", "Fissidens",
                   "Ditrichum", "Ceratodon", "Barbula", "Didymodon",
                   "Trichostomum", "Weissia", "Campylopus", "Dicranella",
                   "Tortella", "Aloina", "Ptychomitrium", "Fontinalis",
                   "Cinclidotus", "Bryoerythrophyllum", "Pseudocrossidium",
                   "Crossidium", "Microbryum", "Ephemerum", "Phascum",
                   "Amblystegium", "Rhynchostegium", "Oxyrrhynchium",
                   "Cirriphyllum", "Plagiothecium", "Herzogiella",
                   "Pylaisia", "Entodon", "Climacium", "Leucolepis",
                   "Timmia", "Tetraphis", "Splachnaceae", "Algal",
                   "Lichenes", "Nostoc")

eva_genus <- sub(" .*", "", um$eva)
um$category[is.na(um$category) & eva_genus %in% lichen_genera] <- "lichen_moss_to_vascular"

# 3. Hybrid names with × that didn't match
um$category[is.na(um$category) & grepl("\u00d7| x |^x ", um$eva)] <- "hybrid_unmatched"

# 4. Names with "aggr." or other qualifiers
um$category[is.na(um$category) & grepl("aggr\\.|sect\\.|s\\.l\\.", um$eva)] <- "aggregate_qualifier"

# 5. Infraspecific that didn't collapse
um$category[is.na(um$category) & grepl("subsp\\.|var\\.|f\\.", um$eva)] <- "infraspec_missed"

# Remaining
um$category[is.na(um$category)] <- "other"

cat("=== UNMATCHED ANALYSIS ===\n\n")
cat(sprintf("Total unmatched: %d\n", nrow(um)))
cat(sprintf("  With ASAAS ground truth: %d\n", sum(um$has_truth)))
cat(sprintf("  Without ground truth: %d\n\n", sum(!um$has_truth)))

cat("--- Category counts ---\n")
tbl <- table(um$category)
for (nm in names(sort(tbl, decreasing = TRUE))) {
  cat(sprintf("  %-25s %d\n", nm, tbl[nm]))
}

for (cat_name in names(sort(tbl, decreasing = TRUE))) {
  sub <- um[um$category == cat_name, ]
  cat(sprintf("\n\n=== %s (%d) ===\n", toupper(cat_name), nrow(sub)))
  for (i in seq_len(nrow(sub))) {
    expected <- if (sub$has_truth[i]) {
      sprintf("-> %s (%s, %s)", sub$wfo_expected[i], sub$wfo_family[i], sub$wfo_id[i])
    } else {
      "-> [no WFO match in ASAAS]"
    }
    cat(sprintf("  %s %s\n", sub$eva[i], expected))
  }
}
