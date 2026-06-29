# Geographic range constraint for fuzzy matching

These helpers restrict fuzzy match candidates to a user-declared
geographic region, using WCVP (World Checklist of Vascular Plants)
per-species native status keyed on TDWG Level 3 botanical regions. The
fuzzy filter itself is a categorical join on `tdwg_code`. User-facing
inputs are resolved to TDWG Level 3 codes before that join: a code is
used directly, a region name (`"Belgium"`, `"Europe"`) is looked up in
the bundled WGSRPD crosswalk, and coordinates (`c(lon, lat)`) are mapped
to codes by point-in-polygon against the WGSRPD Level 3 boundaries. Only
fuzzy candidates are constrained; exact matches are always trusted.
