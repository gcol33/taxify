suppressPackageStartupMessages({
  library(vectra)
})
setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
cat("vectra:", as.character(packageVersion("vectra")), "\n\n")

dd <- "C:/Users/Gilles Colling/AppData/Roaming/R/data/R/taxify"
files <- list.files(dd, pattern = "\\.vtr$", recursive = TRUE, full.names = TRUE)

results <- data.frame(
  file = character(),
  open_ok = logical(),
  head_ok = logical(),
  count_ok = logical(),
  ncol = integer(),
  nrow = integer(),
  has_index = logical(),
  index_files = integer(),
  error = character(),
  stringsAsFactors = FALSE
)

short <- function(p) sub(paste0("^", gsub("\\\\", "/", dd), "/?"), "",
                         gsub("\\\\", "/", p))

for (f in files) {
  sf <- short(f)
  cat(sprintf("%-65s ", sf))
  rec <- list(file = sf, open_ok = FALSE, head_ok = FALSE, count_ok = FALSE,
              ncol = NA_integer_, nrow = NA_integer_,
              has_index = FALSE, index_files = 0L, error = "")
  err <- ""
  ok_open <- FALSE; ok_head <- FALSE; ok_count <- FALSE
  ncol_h <- NA_integer_; nrow_n <- NA_integer_

  tryCatch({
    t1 <- vectra::tbl(f)
    ok_open <- TRUE
    h <- vectra::collect(vectra::slice_head(t1, n = 5L))
    ok_head <- TRUE
    ncol_h <- ncol(h)
  }, error = function(e) err <<- paste(err, "open/head:", conditionMessage(e)))

  tryCatch({
    t2 <- vectra::tbl(f)
    s <- vectra::collect(vectra::tally(t2))
    nrow_n <- as.integer(s$n)
    ok_count <- TRUE
  }, error = function(e) err <<- paste(err, "count:", conditionMessage(e)))

  idx_dir <- paste0(f, ".idx")
  has_idx <- dir.exists(idx_dir)
  n_idx <- if (has_idx) length(list.files(idx_dir)) else 0L

  rec$open_ok <- ok_open
  rec$head_ok <- ok_head
  rec$count_ok <- ok_count
  rec$ncol <- ncol_h
  rec$nrow <- nrow_n
  rec$has_index <- has_idx && n_idx > 0L
  rec$index_files <- as.integer(n_idx)
  rec$error <- err

  status <- if (ok_open && ok_head && ok_count) "OK" else "FAIL"
  cat(sprintf("%-4s  ncol=%-3s nrow=%-9s idx=%-2s %s\n",
              status,
              if (is.na(ncol_h)) "?" else as.character(ncol_h),
              if (is.na(nrow_n)) "?" else as.character(nrow_n),
              n_idx,
              substr(err, 1, 60)))

  results <- rbind(results, as.data.frame(rec, stringsAsFactors = FALSE))
}

cat("\n=== Summary ===\n")
cat("Total files:        ", nrow(results), "\n")
cat("Open OK:            ", sum(results$open_ok), "\n")
cat("Head OK:            ", sum(results$head_ok), "\n")
cat("Count OK:           ", sum(results$count_ok), "\n")
cat("With index dir:     ", sum(results$has_index), "\n")
cat("Fully passing:      ", sum(results$open_ok & results$head_ok & results$count_ok), "\n")
fail <- !(results$open_ok & results$head_ok & results$count_ok)
cat("Failing:            ", sum(fail), "\n")
if (any(fail)) {
  cat("\nFailing files:\n")
  print(results[fail, c("file", "error")], row.names = FALSE)
}

saveRDS(results, "dev_notes/vtr_compat_results.rds")
write.csv(results, "dev_notes/vtr_compat_results.csv", row.names = FALSE)
