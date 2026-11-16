# Source keys and door names use underscores between words.
.door_declaration <- function(source) {
  key <- paste0(".door_", chartr("-", "_", source))
  ns <- environment(.door_declaration)
  if (!exists(key, envir = ns, inherits = FALSE)) return(NULL)
  get(key, envir = ns, inherits = FALSE)
}

# Column maps may depend on the available source schema.
.resolve_door_declaration <- function(door, available = NULL) {
  for (field in intersect(c("col_map", "value_cols"), names(door))) {
    if (is.function(door[[field]])) door[[field]] <- door[[field]](available)
  }
  door
}

# Browse column declarations without running a source door.
.enrichment_door_spec <- function(source, available = NULL) {
  door <- .door_declaration(source)
  if (is.null(door)) return(NULL)
  door <- .resolve_door_declaration(door, available)
  enrichment_name <- door$enrichment_name %||% tolower(door$db)
  prefix <- door$prefix %||% .enrichment_prefix(enrichment_name)
  map <- door$col_map %||% door$value_cols
  names(map) <- .prefix_columns(names(map), prefix)
  list(map = map, prefix = prefix, group_col = door$group_col,
       default_cols = door$default_cols, enrichment_name = enrichment_name)
}
