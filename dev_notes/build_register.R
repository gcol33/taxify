setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
options(timeout = 7200)
devtools::load_all(quiet = TRUE)

cat(sprintf("[%s] Building genus_register over installed backbones\n",
            format(Sys.time())))

t0 <- Sys.time()
build_genus_register(verbose = TRUE)
cat(sprintf("[%s] genus_register done in %.1f min\n",
            format(Sys.time()),
            as.numeric(Sys.time() - t0, units = "mins")))

t1 <- Sys.time()
build_backend_coverage(verbose = TRUE)
cat(sprintf("[%s] backend_coverage done in %.1f min\n",
            format(Sys.time()),
            as.numeric(Sys.time() - t1, units = "mins")))

# Quick coverage report
register_path <- file.path(taxify_data_dir(), "unified", "latest", "genus_register.vtr")
coverage_path <- file.path(taxify_data_dir(), "unified", "latest", "backend_coverage.vtr")

cat(sprintf("\nregister: %.1f MB\n", file.size(register_path) / 1048576))
cat(sprintf("coverage: %.1f MB\n", file.size(coverage_path) / 1048576))

reg <- vectra::tbl(register_path) |> vectra::collect()
cat(sprintf("genera total:    %d\n", nrow(reg)))
cat(sprintf("kingdom set:     %d (%.1f%%)\n",
            sum(!is.na(reg$kingdom)),
            100 * mean(!is.na(reg$kingdom))))
cat("\nkingdom distribution:\n")
print(sort(table(reg$kingdom, useNA = "ifany"), decreasing = TRUE))
