options(repos = c(CRAN = "https://cloud.r-project.org"))

needed <- c("devtools", "remotes", "Rcpp", "RcppParallel", "cli",
            "rlang", "jsonlite", "DBI", "RSQLite", "openxlsx2",
            "curl", "data.table")
to_install <- setdiff(needed, rownames(installed.packages()))
if (length(to_install)) {
  cat("Installing:", paste(to_install, collapse = ", "), "\n")
  install.packages(to_install, Ncpus = 8)
}

devtools::install("C:/Users/Gilles Colling/Documents/dev/vectra",
                  upgrade = FALSE, quick = TRUE, quiet = FALSE)

cat("\nvectra version:", as.character(packageVersion("vectra")), "\n")
library(vectra)
cat("vectra loaded OK\n")
