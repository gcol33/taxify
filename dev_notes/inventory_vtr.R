setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all(quiet = TRUE)
dd <- taxify_data_dir()
cat("data_dir:", dd, "\n\n")
files <- list.files(dd, pattern = "\\.vtr$", recursive = TRUE, full.names = TRUE)
if (!length(files)) {
  cat("no .vtr files\n"); quit(save = "no")
}
info <- file.info(files)
df <- data.frame(
  path = sub(paste0("^", gsub("\\\\", "/", dd), "/?"), "", gsub("\\\\", "/", files)),
  size_MB = round(info$size / 1048576, 1),
  mtime = format(info$mtime, "%Y-%m-%d %H:%M")
)
df <- df[order(df$path), ]
print(df, row.names = FALSE)
cat("\nTotal .vtr count:", nrow(df), "  Total size:", round(sum(info$size) / 1048576, 1), "MB\n")
