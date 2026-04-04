# Working with large species lists

taxify is designed for lists of a few hundred names and lists of a few
hundred thousand names alike. The underlying engine (vectra) stores
backbone databases in a columnar binary format (.vtr) that supports
memory-mapped access, hash-indexed lookups, and OpenMP-parallel fuzzy
joins. None of this requires special configuration from the user. But
knowing how the pieces fit together helps when tuning a workflow for
speed, memory, or disk usage at scale.

This vignette covers the performance-relevant internals, gives concrete
timing guidance for different list sizes, and walks through four worked
examples: exact vs. fuzzy matching, multi-backend fallback ordering,
batch processing of very large lists, and pre-downloading resources
before a batch run.

``` r

library(taxify)
```

## How taxify scales

### The .vtr columnar format

Every backbone ships as a `.vtr` file: a binary columnar format written
by the vectra C11 engine. Unlike CSV or TSV, the `.vtr` format stores
each column contiguously on disk with lightweight compression. taxify
never parses text at query time. There is no
[`read.csv()`](https://rdrr.io/r/utils/read.table.html) step, no string
splitting, no quote escaping. The backbone is already in a query-ready
binary layout.

Traditional taxonomic matching tools read a CSV backbone on every
session start (WorldFlora takes 15-30 seconds to parse WFO’s
classification.txt), or call a remote API per name (taxize, subject to
rate limits and network latency). taxify’s approach eliminates both
bottlenecks. The one-time conversion from Darwin Core CSV to `.vtr`
happens at download time and never needs to be repeated. The resulting
file is typically 30-50% smaller than the original CSV because the
columnar layout compresses string columns more efficiently than
row-oriented text.

### Exact matching: hash-indexed lookups

When a backbone is first used in a session, vectra materializes it into
an in-memory columnar block with hash indexes on the name and genus
columns. Subsequent lookups against that block run in essentially
constant time per name.

Exact matching uses `block_lookup()`, which resolves each input name via
a hash index. This is an O(1) operation per name and the reason exact
matching scales linearly with list size. A list of 100,000 clean plant
names matches against WFO in seconds, not minutes.

The exact pipeline is more thorough than a simple string comparison. It
runs five passes in sequence, each catching a different class of name
variation:

1.  **Case-sensitive exact match** against the canonical name column.

2.  **Case-insensitive match** against a precomputed lowercased key.

3.  **Latin orthographic normalization** that maps common epithet
    variants (e.g., *-ii* to *-i*, *-anum* to *-ana*) to a canonical
    form.

4.  **Infraspecific-to-species fallback** that strips variety/subspecies
    qualifiers and matches against the binomial.

5.  **Hybrid name normalization** that resolves nothospecies formatting
    differences (e.g., *Salix x rubens* vs. *Salix xrubens*).

All five passes use hash lookups. A name that matches in pass 1 is never
tested in passes 2-5. In practice, pass 1 resolves 85-95% of names from
clean input, and passes 2-4 pick up another 2-5%. The total cost of
exact matching is dominated by the hash lookups, which are O(1) per name
regardless of backbone size.

### Fuzzy matching: genus-blocked string distance

Fuzzy matching is fundamentally more expensive. For each unmatched name,
vectra computes string distances (Damerau-Levenshtein by default)
against all backbone entries that share the same genus. This
genus-blocking strategy reduces the search space from millions of
backbone entries to a few hundred or thousand (the typical number of
species per genus). The computation is parallelized across cores via
OpenMP, using 4 threads by default.

On a 4-core machine, fuzzy matching 5,000 names against WFO takes
roughly 10-30 seconds depending on genus sizes. Large genera like
*Carex* (~2,000 entries in WFO) or *Astragalus* (~3,000 entries) are
more expensive per name than small genera. The cost grows with the
number of names that fail exact matching and with the size of the
backbone. Against GBIF’s 7 million rows, the same 5,000 names might take
30-90 seconds because each genus block is proportionally larger.

A secondary fuzzy pass handles misspelled genera. When the genus itself
is wrong (e.g., *Qurecus* instead of *Quercus*), the genus-blocked join
misses the name entirely. taxify runs a fallback pass that blocks on the
first two characters of the name instead of the full genus. This catches
most single- character genus typos while keeping the search space much
smaller than a full cross-join.

The practical consequence: exact-only matching is fast at any scale, and
fuzzy matching is the knob that controls how long a run takes.

## Backbone loading and the session cache

The first time
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) is
called for a given backend, several things happen behind the scenes. The
function resolves the backbone path through a four-step fallback:
session cache, versioned directory on disk, legacy flat directory, and
finally auto-download from Zenodo if no local copy exists. Once the path
is known, vectra materializes the `.vtr` into an in-memory columnar
block and builds hash indexes on the name and genus columns. This
initialization step takes 1-3 seconds for WFO (~400,000 rows) and 5-10
seconds for GBIF (~7 million rows). Every subsequent
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
in the same R session reuses the materialized block. There is no
repeated file I/O.

Two caches operate in parallel. The path cache (`.taxify_cache`) maps
backend names to `.vtr` file paths on disk. Once a path is resolved, it
stays cached so that `ensure_backbone()` does not re-scan the file
system. The data cache (`.taxify_env`) holds the materialized columnar
block itself, keyed by file path. It also stores the session manifest,
version-check flags, enrichment paths, and coverage data for the genus
register. Both are package-level environments that persist for the
duration of the R session and are shared across all
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
calls.

The first
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
in a session also triggers a version check. taxify fetches a manifest
from GitHub (a small JSON file listing the latest version of each
backbone) and compares it against the locally installed version. If a
newer backbone is available, it is downloaded automatically. This check
runs once per backend per session. Subsequent calls skip it entirely. If
the network is unavailable, the check fails silently and the local copy
is used as-is.

To see where backbones live on disk:

``` r

taxify_data_dir()
#> [1] "C:/Users/jane/AppData/Local/R/taxify"
```

On Linux this is typically `~/.local/share/R/taxify`, on macOS
`~/Library/Application Support/R/taxify`. The path is determined by
`tools::R_user_dir("taxify", "data")` and is shared across all R
projects on the same machine. Two R sessions running on the same machine
can read the same backbone files concurrently without conflict because
the `.vtr` files are read-only at query time.

## Worked example: exact vs. fuzzy matching

The simplest performance lever is the `fuzzy` argument. When input names
are clean (e.g., names from a curated database, an existing taxonomic
checklist, or the output of a previous taxify run), disabling fuzzy
matching skips the string-distance computation entirely.

Consider a list of 10,000 plant names extracted from an herbarium
database where names are already in standard binomial form. We time both
modes:

``` r

# Assume `species_list` is a character vector of 10,000 plant names

# Exact + fuzzy (default)
t_fuzzy <- system.time(
  result_fuzzy <- taxify(species_list, backend = "wfo", fuzzy = TRUE)
)

# Exact only
t_exact <- system.time(
  result_exact <- taxify(species_list, backend = "wfo", fuzzy = FALSE)
)

t_fuzzy["elapsed"]
#> elapsed
#>   18.4

t_exact["elapsed"]
#> elapsed
#>    2.1
```

The exact-only run is about an order of magnitude faster. The exact pass
matches most names on the first try through its five-pass pipeline
(case-sensitive, case-insensitive, Latin orthographic normalization,
infraspecific fallback, and hybrid normalization). Fuzzy matching picks
up the remaining names with minor misspellings, but at a cost that
scales with the number of unmatched names times the average genus size
in the backbone.

The ratio between the two modes depends on input quality. For a list of
names extracted from a curated database (GBIF occurrence records, a
published checklist, or a previous taxify run), the exact pass resolves
95-99% of names and the fuzzy pass adds very little. For OCR-transcribed
herbarium labels or citizen science data with frequent misspellings, the
exact pass might resolve only 70-80% and the fuzzy pass becomes
essential.

A practical two-pass pattern for large lists: run exact-only first,
inspect the unmatched names, and decide whether the fuzzy pass is worth
the time.

``` r

# Pass 1: exact only
result <- taxify(species_list, backend = "wfo", fuzzy = FALSE)

# How many names remain unmatched?
n_unmatched <- sum(result$match_type == "none")
message(n_unmatched, " names unmatched after exact pass")

# Pass 2: fuzzy only on the unmatched subset
if (n_unmatched > 0) {
  unmatched_names <- result$input_name[result$match_type == "none"]
  fuzzy_result <- taxify(unmatched_names, backend = "wfo", fuzzy = TRUE)

  # Merge back
  matched_rows <- fuzzy_result$match_type != "none"
  idx <- match(fuzzy_result$input_name[matched_rows],
               result$input_name)
  result[idx, ] <- fuzzy_result[matched_rows, ]
}
```

This pattern is especially useful when only 1-5% of names need fuzzy
matching. The exact pass finishes in seconds even for 100,000 names, and
the fuzzy pass operates on a much smaller subset. The total wall time is
often less than half of what a single `fuzzy = TRUE` call would take,
because the fuzzy engine does not need to allocate working memory or
build query tables for the names that already matched exactly.

One subtlety: the second call to
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) does
not re-materialize the backbone. The session cache from the first call
is still active, so the fuzzy-only pass starts immediately with the
string-distance computation. There is no penalty for splitting the work
into two calls.

## Worked example: multi-backend fallback ordering

When [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
receives multiple backends, it processes them as a sequential fallback
chain. Names matched by an earlier backend are excluded from later ones.
The order matters for performance: the first backend sees all names, the
second sees only those that failed, and so on.

Suppose we have a mixed-kingdom species list from a freshwater ecology
survey: mostly aquatic plants, some fish, a handful of invertebrates.
WFO covers the plants, COL covers everything but is larger and slower to
search. Putting WFO first means the plant names (the majority) are
resolved quickly, and only the animal names fall through to COL.

``` r

# 8,000 names: ~6,000 plants, ~1,500 fish, ~500 invertebrates
t_wfo_first <- system.time(
  result_a <- taxify(survey_names,
                     backend = c("wfo", "col"),
                     fuzzy = TRUE)
)
t_wfo_first["elapsed"]
#> elapsed
#>   25.3

# Reversed order: COL first, WFO second
t_col_first <- system.time(
  result_b <- taxify(survey_names,
                     backend = c("col", "wfo"),
                     fuzzy = TRUE)
)
t_col_first["elapsed"]
#> elapsed
#>   41.7
```

The results are identical in terms of name resolution (both backends
ultimately resolve the same names to accepted names), but the WFO-first
ordering is faster because WFO’s smaller backbone (~400,000 rows)
resolves 75% of the list before COL’s larger backbone (~4.5 million
rows) is ever touched. The saving comes from two sources: the exact pass
against WFO is faster (smaller hash table), and the fuzzy pass against
COL runs on 2,000 names instead of 8,000. Since fuzzy matching cost
scales linearly with the number of unmatched names, resolving 6,000
names via WFO’s fast exact pass eliminates the need for 6,000 fuzzy
comparisons against COL’s much larger genus blocks.

Note that the `backend` column in the output records which backend
resolved each name. This is useful for quality control: if a name was
resolved by the second backend in the chain, it means the first backend
either did not contain it or matched it differently. Inspecting the
`backend` column after a multi-backend run can reveal patterns in
taxonomic coverage gaps.

General guidelines for backend ordering:

- Plant-only lists: `"wfo"` alone is sufficient. WFO has the most
  complete plant synonym coverage and a compact backbone.
- Marine lists: `"worms"` first, then `"col"` or `"gbif"` for anything
  WoRMS misses.
- Mixed-kingdom lists: put the backbone that covers the dominant kingdom
  first. For a list that is 80% plants and 20% animals,
  `c("wfo", "col")` is faster than `c("col", "wfo")`.
- Maximizing coverage: `c("wfo", "col", "gbif")` casts the widest net
  but involves three backbone loads. For lists under 10,000 names the
  extra loading time is negligible. For 100,000+ names, the extra fuzzy
  passes add up.

## Backbone sizes on disk

Each backbone’s `.vtr` file is a one-time download stored in
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md).
The sizes below are approximate and depend on the backbone version.

| Backend | Rows (approx.) | .vtr size on disk | Scope                          |
|---------|----------------|-------------------|--------------------------------|
| WFO     | 400,000        | 50-70 MB          | Plants (vascular + bryophytes) |
| COL     | 4,500,000      | 250-350 MB        | All kingdoms                   |
| GBIF    | 7,000,000      | 500-700 MB        | All kingdoms (largest)         |
| ITIS    | 800,000        | 80-120 MB         | North American focus           |
| NCBI    | 2,500,000      | 200-300 MB        | Molecular/genomic taxa         |
| OTT     | 3,500,000      | 300-400 MB        | Synthetic tree (multi-source)  |
| WoRMS   | 600,000        | 60-80 MB          | Marine taxa                    |

A full installation of all seven backbones occupies roughly 1.5-2 GB.
Most workflows need only one or two. The WFO backbone alone covers the
vast majority of plant taxonomy use cases at under 70 MB.

The download sizes are comparable to the on-disk sizes since the `.vtr`
format is already compressed. No additional decompression step runs
after download. The file that arrives on disk is the file that vectra
reads at query time.

Enrichment files are much smaller. The largest enrichment is WCVP
(native range data, ~2 million rows) at roughly 30-40 MB. Most
enrichments are under 5 MB. A full set of 12 enrichments adds about
80-100 MB to disk usage.

## Memory footprint

When a backbone is loaded for the first time in a session, vectra
materializes it as an in-memory columnar block. The memory footprint is
roughly 1.5-2x the `.vtr` file size because the columnar block includes
hash indexes and decompressed string data. WFO occupies about 80-100 MB
in memory, COL about 400-500 MB, and GBIF about 800 MB-1 GB. The block
persists for the session and is reused by every
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call.
Loading a second backbone (e.g., during a multi-backend fallback) adds
its own block to memory. The two blocks coexist independently.

Fuzzy matching adds a transient memory cost on top of the backbone
block. For each fuzzy pass, taxify writes a temporary `.vtr` containing
the unmatched names and their genera, then passes it to vectra’s
`fuzzy_join()` function. The join allocates a working buffer
proportional to the number of unmatched names times the average genus
block size. For 5,000 unmatched names against WFO, this working set is
roughly 10-20 MB. For 50,000 unmatched names against GBIF, it can reach
100-200 MB. The temporary files and working buffers are freed after each
fuzzy pass.

Enrichment `.vtr` files are loaded on demand. Calling
[`add_conservation_status()`](https://gillescolling.com/taxify/reference/add_conservation_status.md)
loads the conservation_status enrichment (~60,000 rows, a few MB).
Calling
[`add_elton_traits()`](https://gillescolling.com/taxify/reference/add_elton_traits.md)
loads EltonTraits (~15,000 rows). Enrichment joins use a different
mechanism than backbone matching: they build a temporary `.vtr` of
unique accepted names, run an `inner_join()` against the enrichment
`.vtr`, and fill the result via
[`match()`](https://rdrr.io/r/base/match.html). The enrichment `.vtr`
itself is not fully materialized into memory; only the joined subset is
collected. The memory cost per enrichment join is proportional to the
number of unique accepted names in the result, which is typically much
smaller than the input list (synonyms collapse to shared accepted
names).

For a typical session matching 50,000 plant names against WFO with two
enrichments, expect about 150 MB of total memory usage from taxify’s
caches. Matching the same names against GBIF with five enrichments
brings that closer to 1.2 GB. On a machine with 8 GB of RAM, this leaves
ample room for downstream analysis. On a shared server with 2-4 GB per
process, the GBIF backbone might be tight.

If memory is tight, three strategies help:

1.  Use a smaller backbone. WFO at ~100 MB in memory is 8x lighter than
    GBIF. For plant-only lists there is no coverage penalty.
2.  Clear the cache between analysis phases. After matching is done and
    the result is saved, release the backbone from memory before running
    downstream models.
3.  Process enrichments in the same loop as matching (the
    chunk-and-write pattern shown below), rather than accumulating the
    full result in memory and enriching after.

``` r

# Match names
result <- taxify(species_list, backend = "gbif")

# Save result
saveRDS(result, "matched_names.rds")

# Free the backbone from memory
taxify_clear_cache()

# Now ~800 MB of RAM is available for downstream work
gc()
```

## Worked example: batch processing a very large list

Lists above 100,000 names are common in biodiversity informatics. A
national herbarium digitization project might produce 500,000 label
transcriptions. A metabarcoding pipeline might output 200,000 OTU
labels. Processing these in a single
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
works, but splitting into chunks gives two practical benefits: progress
monitoring and memory stability.

taxify’s matching engine handles the full vector internally, and a
single
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
on 500,000 names will produce correct results. But two practical issues
arise at this scale. First, the fuzzy-join working set grows with input
size: 500,000 names with 10% unmatched means 50,000 fuzzy comparisons,
each scanning a genus block. The temporary `.vtr` files and distance
matrices for this many comparisons can spike memory by several hundred
MB. Second, if the R process is interrupted mid-run (Ctrl+C, OOM kill,
session timeout), the entire result is lost. Chunking at 50,000-100,000
names keeps peak memory predictable and provides natural restart points.

``` r

# 300,000 names from a herbarium digitization project
all_names <- readLines("herbarium_names.txt")
chunk_size <- 50000

# Split into chunks
chunks <- split(all_names,
                ceiling(seq_along(all_names) / chunk_size))

# Process each chunk
results <- lapply(seq_along(chunks), function(i) {
  message(sprintf("Chunk %d/%d (%d names)...",
                  i, length(chunks), length(chunks[[i]])))
  taxify(chunks[[i]], backend = "wfo", fuzzy = TRUE, verbose = FALSE)
})

# Combine
result <- do.call(rbind, results)
nrow(result)
#> [1] 300000
```

The backbone stays in memory across chunks (the session cache is not
cleared between calls), so each chunk after the first skips the
initialization overhead. Only the fuzzy-join working set is allocated
and freed per chunk.

For lists in the millions (e.g., processing all occurrence records from
a GBIF download), consider writing results to disk after each chunk
rather than accumulating in memory:

``` r

output_dir <- "results"
dir.create(output_dir, showWarnings = FALSE)

for (i in seq_along(chunks)) {
  message(sprintf("Chunk %d/%d", i, length(chunks)))
  res <- taxify(chunks[[i]], backend = "wfo",
                fuzzy = TRUE, verbose = FALSE)
  saveRDS(res, file.path(output_dir,
                         sprintf("chunk_%04d.rds", i)))
}

# Combine when needed
all_files <- list.files(output_dir, pattern = "\\.rds$",
                        full.names = TRUE)
result <- do.call(rbind, lapply(all_files, readRDS))
```

This pattern keeps R’s memory usage bounded by a single chunk regardless
of total list size. It also makes the workflow resumable: if the process
dies at chunk 47 of 60, we can check which `.rds` files exist and
restart from chunk 48. Adding a simple skip condition handles this:

``` r

for (i in seq_along(chunks)) {
  out_file <- file.path(output_dir, sprintf("chunk_%04d.rds", i))
  if (file.exists(out_file)) next
  message(sprintf("Chunk %d/%d", i, length(chunks)))
  res <- taxify(chunks[[i]], backend = "wfo",
                fuzzy = TRUE, verbose = FALSE)
  saveRDS(res, out_file)
}
```

One detail worth noting: the chunk boundaries are arbitrary and do not
affect matching quality. Each chunk is matched independently against the
backbone. A name that appears in chunk 3 gets the same result as if it
appeared in chunk 7 because the backbone is deterministic and the
matching logic is stateless across calls. The only shared state between
chunks is the session cache (the materialized backbone block), which
improves performance by avoiding repeated initialization.

## Cache management

taxify uses two internal environments for session-level caching. The
path cache stores the disk location of each loaded backbone. The data
cache stores materialized columnar blocks, the session manifest,
version-check flags, and enrichment paths. Both persist until the R
session ends or the user explicitly clears them.

[`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md)
removes all loaded backbone paths from memory. The next
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
will re-read from disk and re-materialize. This is useful after a large
matching run when the backbone is no longer needed and the memory can be
reclaimed.

``` r

# After finishing all matching work
taxify_clear_cache()
gc()
```

Clearing the cache does not delete any files from disk. The `.vtr` files
remain in
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md)
and will be reloaded on the next use. The cost of reloading is the same
1-10 second initialization time that the first call in a session incurs.
For a workflow where matching is done in one phase and downstream
modelling in another, this is a worthwhile trade: spend 3 seconds
reloading WFO later if needed, but free 100 MB of RAM for a
memory-intensive ordination or species distribution model.

[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md)
is a narrower operation: it invalidates the cached copy of the remote
manifest (the JSON file listing the latest version of each backbone and
enrichment). This forces the next
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
to re-check for updates. Normally the manifest is fetched once per
session and cached. In a long-running R session (e.g., an RStudio
session that stays open for days), calling
[`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md)
before a batch run ensures you are working against the latest backbone
version. If a new backbone release was published since the session
started, the version check will detect it and trigger an automatic
download.

``` r

taxify_refresh_manifest()
```

## Disk storage and sharing across projects

All taxify data lives under
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md),
which resolves to the platform-specific user data directory via
`tools::R_user_dir("taxify", "data")`. The layout is:

    taxify_data_dir()/
      wfo/
        latest/
          wfo.vtr          # the backbone
          wfo.meta         # download provenance
          meta.json        # version metadata
      col/
        latest/
          col.vtr
          ...
      enrichment/
        conservation_status/
          latest/
            conservation_status.vtr
            meta.json
        woodiness/
          latest/
            woodiness.vtr
            meta.json
        ...

This directory is per-user, not per-project. A backbone downloaded once
is available to every R project on the machine without duplication.
There is no need to copy `.vtr` files into a project directory or
version-control them.

If multiple users on a shared server need the same backbones, one user
can download them and the others can set the `R_USER_DATA_DIR`
environment variable (or symlink
[`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md))
to a shared location. The `.vtr` files are read-only at query time, so
concurrent access from multiple R sessions is safe. No file locking is
needed.

To check how much disk space taxify is currently using:

``` r

# Total size of all backbones and enrichments
data_dir <- taxify_data_dir()
files <- list.files(data_dir, recursive = TRUE, full.names = TRUE)
total_mb <- sum(file.size(files), na.rm = TRUE) / 1048576
message(sprintf("taxify data: %.0f MB across %d files",
                total_mb, length(files)))
```

To remove a specific backbone (e.g., GBIF after finishing a project that
needed it), delete its directory:

``` r

# Remove GBIF backbone (frees ~500-700 MB)
unlink(file.path(taxify_data_dir(), "gbif"), recursive = TRUE)

# Clear the session cache so taxify() doesn't try to use the old path
taxify_clear_cache()
```

Deleting a backbone directory is safe. The next
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call
for that backend will re-download it from Zenodo if needed.

## Worked example: pre-downloading resources

For a reproducible batch pipeline (e.g., a Makefile or targets plan), it
is cleaner to separate the download step from the analysis step.
Downloads can fail due to network issues, and you want to know about
that before a 2-hour matching run starts.

[`taxify_download_vtr()`](https://gillescolling.com/taxify/reference/taxify_download_vtr.md)
downloads one or more backbone `.vtr` files.
[`taxify_download_enrichment()`](https://gillescolling.com/taxify/reference/taxify_download_enrichment.md)
does the same for enrichment layers. Both are idempotent: if the file
already exists and the version is current, they return immediately.

``` r

# Pre-download everything needed for a multi-kingdom analysis
# with conservation status and trait enrichments

# Backbones
taxify_download_vtr(c("wfo", "col"))

# Enrichments
taxify_download_enrichment(c(
  "conservation_status",
  "woodiness",
  "eive",
  "elton_traits"
))

# Now the analysis can run fully offline
result <- taxify(species_list, backend = c("wfo", "col"))
result <- add_conservation_status(result)
result <- add_woodiness(result)
```

In a CI/CD or cluster environment, the download step can run in a setup
script or container build phase. The matching step then operates
entirely from local disk, with no network dependency and no risk of
mid-run download failures. This separation also makes the pipeline
reproducible: the download step pins a specific backbone version
(recorded in the `meta.json` sidecar file), and the matching step uses
whatever version is on disk.

For a targets or drake plan, the download calls fit naturally as
upstream targets that the matching targets depend on. The return value
(the `.vtr` path) can be passed through the dependency graph, though in
practice the path is resolved internally by `ensure_backbone()` and does
not need to be passed explicitly.

To see which enrichments are available and their current versions:

``` r

list_enrichments()
#>                name version    nrow static
#> 1 conservation_status 2026.04   59583  FALSE
#> 2               griis 2026.04   98131  FALSE
#> 3                wcvp 2026.04 1973234  FALSE
#> 4                eive     1.0   14835   TRUE
#> 5        elton_traits     1.0   15394   TRUE
#> 6              avonet     1.0   11009   TRUE
#> ...
```

Static enrichments (those based on published, version-locked datasets
like EltonTraits 1.0 or PanTHERIA 1.0) are never re-downloaded after the
initial fetch. Non-static enrichments (conservation_status, griis, wcvp,
common_names) are checked once per session and updated if a newer build
is available.

## Practical scaling guidance

The table below summarizes recommended settings by list size. These are
guidelines, not hard thresholds. The actual performance depends on input
cleanliness (how many names need fuzzy matching), backbone size (WFO vs.
GBIF), and hardware (number of cores, available RAM, disk speed).

**Under 1,000 names.** The defaults work well. `taxify(names)` with
`fuzzy = TRUE` and a single backend completes in a few seconds. No
tuning is needed. This is the regime for most interactive analysis: a
field survey, a thesis species list, a table extracted from a paper.
Memory usage is negligible.

**1,000 to 50,000 names.** If the input is clean (names from a curated
database, a previous taxify run, or a standard checklist), consider
`fuzzy = FALSE`. The exact pipeline handles case differences, Latin
orthographic variants (e.g., *-ii* vs. *-i* endings), and
infraspecific-to- species fallback without string-distance computation.
Enabling fuzzy on a clean list of 50,000 names might add 30-60 seconds
for no practical gain. If the input has known quality issues (OCR
transcriptions, citizen science data), leave fuzzy on and expect 1-3
minutes against WFO.

**50,000 to 500,000 names.** Backend ordering starts to matter. Put the
backbone that covers the dominant taxon group first. For a plant list,
`"wfo"` alone suffices. For mixed-kingdom lists, `c("wfo", "col")`
resolves most names on the faster WFO pass. Consider the two-pass
pattern (exact first, fuzzy on unmatched) if only a small fraction of
names have quality issues. The GBIF backbone at ~7 million rows is the
most expensive for fuzzy matching; avoid it as the first backend unless
the list is primarily non-plant, non-marine taxa not covered by COL.

**Over 500,000 names.** Batch in chunks of 50,000-100,000 names. The
backbone stays cached across chunks, so there is no repeated
initialization cost. Write results to disk per chunk if total memory is
a concern. Clear the cache between analysis phases (matching,
enrichment, downstream modelling) to keep memory usage bounded. If
enriching with multiple layers, apply all enrichments to each chunk
before writing rather than accumulating the full result in memory and
enriching after.

``` r

# Pattern for 500,000+ names with enrichments
for (i in seq_along(chunks)) {
  res <- taxify(chunks[[i]], backend = "wfo",
                fuzzy = TRUE, verbose = FALSE)
  res <- add_conservation_status(res, verbose = FALSE)
  res <- add_woodiness(res, verbose = FALSE)
  saveRDS(res, sprintf("results/chunk_%04d.rds", i))
}
```

**Backend selection cheat sheet:**

| List composition               | Recommended backend(s)    |
|--------------------------------|---------------------------|
| Plants only                    | `"wfo"`                   |
| Plants + animals               | `c("wfo", "col")`         |
| Marine taxa                    | `c("worms", "col")`       |
| Fungi                          | `c("fungorum", "col")`    |
| Algae                          | `c("algaebase", "col")`   |
| All kingdoms, maximum coverage | `c("wfo", "col", "gbif")` |
| Molecular/genomic taxa         | `c("ncbi", "col")`        |
| North American biodiversity    | `c("itis", "col")`        |

For any single-kingdom list, starting with the specialist backbone (WFO
for plants, WoRMS for marine, NCBI for molecular) and falling back to
COL or GBIF gives the best balance of speed and coverage. The specialist
backbone resolves most names quickly (smaller backbone, faster exact
pass), and the generalist backbone catches the remainder.

## The fuzzy_threshold parameter

The default fuzzy threshold is 0.2 (normalized Damerau-Levenshtein
distance: edits divided by the maximum of the two name lengths). A
threshold of 0.2 allows roughly one edit per five characters, which
catches single-character typos in binomials of typical length (15-25
characters). This is a good default for most use cases.

For large lists with noisy input (OCR, handwriting transcription), a
slightly higher threshold like 0.25 catches more misspellings but also
increases false positives. For clean input where fuzzy matching serves
only as a safety net, a lower threshold like 0.1 or 0.15 reduces the
risk of incorrect matches without sacrificing much recall.

The threshold also affects performance. A higher threshold means more
backbone entries pass the distance filter, which means more candidate
matches to evaluate and rank. The difference is modest for most inputs
but can be noticeable for very large genera: at threshold 0.2, a query
against *Astragalus* (~3,000 WFO entries) might return 5 candidates; at
0.3, it might return 20.

An alternative mode uses integer thresholds. Setting
`fuzzy_threshold = 2L` allows at most 2 raw edit operations regardless
of name length. This is useful for long infraspecific names where a
normalized threshold of 0.2 might allow too many edits. Integer
thresholds are not supported with the Jaro-Winkler method
(`fuzzy_method = "jw"`).

``` r

# Tight threshold for clean input
result <- taxify(clean_names, backend = "wfo",
                 fuzzy = TRUE, fuzzy_threshold = 0.1)

# Integer threshold: at most 2 edits, period
result <- taxify(noisy_names, backend = "wfo",
                 fuzzy = TRUE, fuzzy_threshold = 2L)
```

## Summary of performance-relevant functions

| Function | Purpose |
|----|----|
| `taxify(..., fuzzy = FALSE)` | Skip fuzzy matching for clean input |
| `taxify(..., backend = c("wfo", "col"))` | Multi-backend fallback chain |
| [`taxify_data_dir()`](https://gillescolling.com/taxify/reference/taxify_data_dir.md) | Find where backbones are stored |
| [`taxify_download_vtr()`](https://gillescolling.com/taxify/reference/taxify_download_vtr.md) | Pre-download backbone `.vtr` files |
| [`taxify_download_enrichment()`](https://gillescolling.com/taxify/reference/taxify_download_enrichment.md) | Pre-download enrichment `.vtr` files |
| [`taxify_clear_cache()`](https://gillescolling.com/taxify/reference/taxify_clear_cache.md) | Free backbone memory after matching |
| [`taxify_refresh_manifest()`](https://gillescolling.com/taxify/reference/taxify_refresh_manifest.md) | Force re-check for backbone updates |
| [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md) | See available enrichments and versions |
