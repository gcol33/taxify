# Hermetic test data directory.
#
# The default backend (backend = NULL) resolves to every *installed* backbone.
# Point taxify at an empty temp dir -- never the machine's real ~/.../taxify
# install, which may hold many downloaded backbones and make bare taxify()
# calls non-reproducible -- and seed it with the standard wfo mock backbone on
# disk. So across the suite a bare taxify() resolves to exactly that one wfo,
# matching the pre-existing tests. Tests that need other backbones either set
# taxify.data_dir to the example database (restoring to this value on exit), or
# inject mocks into the session cache and call them via an explicit
# backend = ... .
#
# Set with a bare options() so it holds for the entire run (a deferred restore
# tied to teardown_env() can fire too early and re-expose the real data dir).
# The test process exits when the suite ends, so there is nothing to restore.
local({
  dd <- file.path(tempdir(), "taxify_test_datadir")
  wfo_dir <- file.path(dd, "wfo", "latest")
  dir.create(wfo_dir, recursive = TRUE, showWarnings = FALSE)
  file.copy(mock_backbone_vtr(), file.path(wfo_dir, "wfo.vtr"), overwrite = TRUE)
  options(taxify.data_dir = dd)
})
