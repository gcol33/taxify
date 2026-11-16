# Capture the mapping declared by a source door without executing a join.
.enrichment_door_spec <- function(source, available = NULL) {
  door <- if (source == "combine") "add_combine_reported" else paste0("add_", source)
  ns <- environment(.enrichment_door_spec)
  if (!exists(door, envir = ns, inherits = FALSE)) return(NULL)
  fun <- get(door, envir = ns)
  env <- new.env(parent = environment(fun))
  capture <- function(x, enrichment_name = source, col_map = NULL,
                      value_cols = NULL, prefix = .enrichment_prefix(source),
                      group_col = NULL, default_cols = NULL, ...) {
    if (source == "combine") prefix <- .enrichment_prefix(source)
    map <- col_map %||% value_cols
    names(map) <- .prefix_columns(names(map), prefix)
    list(map = map, prefix = prefix, group_col = group_col,
         default_cols = default_cols, enrichment_name = enrichment_name)
  }
  env$enrich_simple <- env$enrich_by_group <- env$enrich_via_tr8 <- capture
  env$.euromed_resolve_regions <- identity
  if (!is.null(available)) {
    env$.enrichment_available_cols <- function(...) available
  }
  environment(fun) <- env
  args <- list(x = data.frame(accepted_name = character(), genus = character()),
               verbose = FALSE)
  for (arg in intersect(c("country", "region", "location"), names(formals(fun)))) {
    args[[arg]] <- "all"
  }
  do.call(fun, args)
}
