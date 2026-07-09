# Install a mock enrichment .vtr into the session cache (no disk/manifest),
# clearing it when the calling test ends. Shared by the hybrid-ladder and
# aggregate-fallback enrichment tests.
install_mock_enrichment <- function(name, df) {
  p <- tempfile(fileext = ".vtr")
  vectra::write_vtr(df, p)
  cache_key <- paste0("enrichment_", name)
  flag_key  <- paste0(".enrichment_version_checked.", name)
  set_backbone_path(cache_key, p)
  .taxify_env[[flag_key]] <- TRUE
  withr::defer({
    set_backbone_path(cache_key, NULL)
    if (exists(flag_key, envir = .taxify_env)) {
      rm(list = flag_key, envir = .taxify_env)
    }
  }, envir = parent.frame())
  p
}
