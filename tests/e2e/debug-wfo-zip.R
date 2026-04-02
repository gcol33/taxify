setwd("C:/Users/Gilles Colling/Documents/dev/taxify")
devtools::load_all()

dest <- taxify_data_dir()
zip_path <- file.path(dest, "wfo_download.zip")

# Re-download if not present
if (!file.exists(zip_path)) {
  url <- "https://zenodo.org/records/14538251/files/_DwC_backbone_R.zip"
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  utils::download.file(url, zip_path, mode = "wb")
}

# List archive contents
files <- utils::unzip(zip_path, list = TRUE)
cat("Files in WFO archive:\n")
print(files)
