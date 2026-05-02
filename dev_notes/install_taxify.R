options(repos = c(CRAN = "https://cloud.r-project.org"))
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")

devtools::install_deps(dependencies = TRUE, upgrade = FALSE, quiet = FALSE)

devtools::load_all(quiet = TRUE)
cat("\ntaxify loaded\n")
cat("data dir:", taxify_data_dir(), "\n")
cat("vectra:  ", as.character(packageVersion("vectra")), "\n")
