# Joining custom data with add_data()

## The problem

Taxonomic name matching is rarely the last step. After
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
resolves your species list to accepted names and IDs, the next task is
usually to attach trait data, occurrence records, or measurement tables
from external sources. The trouble is that external datasets almost
never use the same names as your backbone. A CSV of leaf trait
measurements might record *Pinus nigra* subsp. *laricio*, while the
backbone stores the accepted name as *Pinus nigra*. A colleague’s
spreadsheet might list *Picea excelsa* (a synonym retired decades ago),
while WFO recognises *Picea abies*.

Joining on raw species strings misses these cases: the rows do not
match, and the merged data.frame has `NA`s where values should exist.
The standard workaround is to run the external names through the
backbone first, resolve them to accepted IDs, and then join on those
IDs.
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
wraps that entire workflow into a single pipe step.

``` r

library(taxify)
```

## Joining a data.frame

The most common case: we have trait measurements in a data.frame sitting
in our R session, and we want to attach them to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result. Here we create a small table of specific leaf area (SLA) and
maximum height for five European tree species.

``` r

# Our taxify result
species <- c(
  "Quercus robur", "Fagus sylvatica", "Picea abies",
  "Pinus sylvestris", "Betula pendula"
)
result <- taxify(species, backend = "wfo")

# External trait data — note one synonym and one subspecies
traits <- data.frame(
  taxon = c(
    "Quercus robur", "Fagus sylvatica", "Picea excelsa",
    "Pinus sylvestris", "Betula pendula"
  ),
  sla = c(18.2, 24.1, 6.5, 8.0, 22.3),
  max_height_m = c(35, 40, 50, 30, 25)
)

# Join — "Picea excelsa" resolves to "Picea abies" through the backbone
result <- result |> add_data(traits, species_col = "taxon")
```

[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
takes the names from the `taxon` column, runs them through the same
backbone(s) used in the original
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) call,
resolves each to an `accepted_id`, and left-joins on that ID. *Picea
excelsa* is a synonym of *Picea abies* in WFO, so the SLA and height
values land on the correct row even though the literal strings differ.
The output has two new columns, `sla` and `max_height_m`, appended to
the existing result.

## Joining from a CSV file

When the data lives in a file rather than in memory, we can pass the
path directly.
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
reads `.csv` and `.csv.gz` files via vectra’s CSV reader, which handles
large files efficiently without loading everything into R at once.
Tab-separated files (`.tsv`, `.tsv.gz`) are also supported.

``` r

result <- taxify(species, backend = "wfo")
result <- result |> add_data("path/to/leaf_traits.csv")
```

If the CSV has a single obvious species-name column, auto-detection
picks it up. If there are several plausible character columns, or if the
names are encoded in a column with an unusual name like
`latin_binomial`, specifying `species_col` avoids ambiguity.

``` r

result |> add_data("leaf_traits.csv", species_col = "latin_binomial")
```

The same pattern works for compressed CSV files. A `.csv.gz` path is
detected and decompressed transparently.

``` r

result |> add_data("global_leaf_traits.csv.gz", species_col = "species")
```

## Joining from an Excel file

Spreadsheets are common in ecology, especially for hand-curated trait
databases shared among collaborators.
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
reads `.xlsx` files via the openxlsx2 package, which must be installed
separately.

``` r

# install.packages("openxlsx2")  # if not already installed
result |> add_data("bird_morphometry.xlsx")
```

When `sheet`, `start_row`, and `species_col` are all left at their
defaults,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
scans the workbook to find the right combination automatically. It tests
each sheet and up to 20 candidate header rows, probing character columns
against the backbone until it finds species names. This handles the
common case where a colleague’s spreadsheet has a title block, column
descriptions, or notes above the actual data table.

The scan reports what it found:

    Scanning Excel layout...
      Detected: sheet 'measurements', header row 3, species column 'latin_name' (90% match rate)

To skip auto-detection, specify any combination of `sheet`, `start_row`,
and `species_col` explicitly:

``` r

# Specific sheet by name or number
result |> add_data("bird_morphometry.xlsx", sheet = "measurements")
result |> add_data("bird_morphometry.xlsx", sheet = 2)

# Known header row (e.g., rows 1-2 are title/notes)
result |> add_data("bird_morphometry.xlsx", start_row = 3)

# All three specified — no scanning at all
result |> add_data("bird_morphometry.xlsx", sheet = 1, start_row = 3,
                   species_col = "latin_name")
```

## SQLite databases

When trait data lives in a SQLite database,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
reads the table via vectra’s SQLite reader (which depends on DBI and
RSQLite under the hood). Because a single `.sqlite` or `.db` file can
hold many tables, the `table` argument is mandatory here. Omitting it
raises an informative error rather than guessing.

``` r

# SQLite — requires DBI and RSQLite
result |> add_data(
  "traits.sqlite",
  table = "plant_traits",
  species_col = "species"
)
```

This is particularly handy when we already maintain a relational
database of measurements across projects. We can point
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
at the relevant table without exporting to CSV first, and the backbone
matching still runs the same way it does for any other format.

## vectra native format

If we have pre-built `.vtr` files (the columnar format that taxify uses
internally for backbone storage), they can be passed directly. vectra
reads these with near-zero overhead because no parsing or type inference
is needed.

``` r

result |> add_data("prebuilt_traits.vtr", species_col = "canonical_name")
```

This is mainly useful when sharing processed trait tables between team
members or across projects. A `.vtr` file produced by one workflow can
be re-used in another without converting back through CSV. The
[`export_data()`](https://gillescolling.com/taxify/reference/export_data.md)
function makes this easy:

``` r

# Save a taxify result (with enrichments) as .vtr
result |> export_data("processed_traits.vtr")

# A colleague can load it directly
other_result |> add_data("processed_traits.vtr")
```

[`export_data()`](https://gillescolling.com/taxify/reference/export_data.md)
also supports `.csv`, `.tsv`, and `.xlsx` for interoperability with
tools outside R.

``` r

result |> export_data("for_excel_users.xlsx")
result |> export_data("for_python.csv")
```

## Joining from a TSV file

Tab-separated files work the same way as CSV.
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
reads `.tsv` and `.tsv.gz` files via
[`read.delim()`](https://rdrr.io/r/utils/read.table.html).

``` r

result |> add_data("leaf_traits.tsv", species_col = "species")
result |> add_data("leaf_traits.tsv.gz")
```

## Other file formats

For formats not directly supported (`.parquet`, `.rds`), reading the
file into a data.frame first and passing it to
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
works in every case.

``` r

my_data <- readRDS("legacy_traits.rds")
result |> add_data(my_data, species_col = "sp")
```

## Species column auto-detection

When `species_col` is not specified,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
probes each character column in the external data. It takes the first 10
rows of each column, runs them through
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
against the same backbone, and picks the column with the highest match
rate. A column needs at least 50% of its probe names to match before it
qualifies.

``` r

# Auto-detection in action
traits <- data.frame(
  site = c("A", "A", "B", "B"),
  species = c("Quercus robur", "Fagus sylvatica",
              "Betula pendula", "Picea abies"),
  habitat = c("forest", "forest", "forest edge", "boreal"),
  sla = c(18.2, 24.1, 22.3, 6.5)
)

# Three character columns: site, species, habitat
# Only "species" will produce >50% backbone matches
result |> add_data(traits)
```

Auto-detection works well when the species column contains clean
binomial names and the other character columns contain obviously
non-taxonomic strings (site codes, habitat descriptions, observer
names). It can fail when column names are ambiguous, or when species
names are heavily misspelled or use common names. In those situations,
specifying `species_col` explicitly saves time and avoids a confusing
error message.

## Selecting columns with `cols`

By default,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
joins all columns from the external data except the species column. When
the external dataset has dozens of columns and we only need two or
three, the `cols` argument keeps the output tidy.

``` r

# Full trait table with many columns
big_traits <- data.frame(
  species = c("Quercus robur", "Fagus sylvatica"),
  sla = c(18.2, 24.1),
  max_height_m = c(35, 40),
  leaf_nitrogen = c(2.1, 2.4),
  wood_density = c(0.56, 0.58),
  seed_mass_mg = c(3500, 220),
  bark_thickness_mm = c(25, 8)
)

# Only join SLA and wood density
result |> add_data(big_traits, species_col = "species",
                   cols = c("sla", "wood_density"))
```

This also helps when some columns in the external data would create name
collisions (discussed below) that we would rather avoid entirely.

## Column name collisions

If the external data has columns with the same name as columns already
present in the
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
prefixes the incoming columns with `data_`. Existing columns in the
taxify result remain unchanged regardless of what the external data
contains.

``` r

# The taxify result already has a "family" column
# External data also has a "family" column (taxonomic family from a
# different source) plus a "leaf_area" column
external <- data.frame(
  species = c("Quercus robur", "Fagus sylvatica"),
  family = c("Fagaceae", "Fagaceae"),
  leaf_area = c(45.2, 38.7)
)

result |> add_data(external, species_col = "species")
# Output gains "data_family" (from external) and "leaf_area" (no collision)
```

A message prints when collisions are detected, listing the renamed
columns. If we know in advance that a collision will occur and we do not
need the conflicting column, filtering it out via `cols` is cleaner than
letting the rename happen.

## Duplicate species handling

External datasets sometimes contain the same species more than once.
This happens with repeated measurements across sites, multiple
literature sources compiled into one table, or subspecies that resolve
to the same accepted species.
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
distinguishes two cases.

**Exact duplicates** occur when all trait values for a given species are
identical across the repeated rows. This is harmless: the duplicates are
collapsed into a single row with a warning.

``` r

# Harmless: same species, same values (perhaps from two sites)
dup_ok <- data.frame(
  species = c("Quercus robur", "Quercus robur", "Fagus sylvatica"),
  sla = c(18.2, 18.2, 24.1)
)
result |> add_data(dup_ok, species_col = "species")
# Warning: 1 duplicate rows ... deduplicated.
```

**Conflicting duplicates** occur when the same species appears with
different trait values. “Conflicting” here means that at least one of
the selected trait columns differs between two rows that share the same
`accepted_id`. The comparison is column-by-column and treats two `NA`
values as equal (both missing counts as agreement). So if two rows for
*Quercus robur* have SLA values of 18.2 and 21.5, that is a conflict. If
both rows have SLA of 18.2 but one has `NA` for wood density while the
other has 0.56, that is also a conflict. Only when every selected column
matches exactly across all rows for a given species do we consider the
duplicates identical.

Because
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
cannot decide which value is correct when a conflict exists, it raises
an error and names the offending species.

``` r

# Conflicting: same species, different SLA values
dup_bad <- data.frame(
  species = c("Quercus robur", "Quercus robur", "Fagus sylvatica"),
  sla = c(18.2, 21.5, 24.1)
)
result |> add_data(dup_bad, species_col = "species")
# Error: 1 species resolved to the same accepted_id but have
#   different trait values.
#   Examples: 'Quercus robur' (wfo-0000309171)
```

The fix depends on the data. If the duplicates represent within-species
variation (e.g., measurements from different populations), aggregating
before joining is the right approach. If they represent data entry
errors, removing the bad rows resolves the issue. The `cols` argument
can also help when only some columns conflict: selecting the
non-conflicting subset lets the join proceed.

``` r

# Aggregate first, then join
library(stats)
dup_agg <- aggregate(sla ~ species, data = dup_bad, FUN = mean)
result |> add_data(dup_agg, species_col = "species")
```

Note that duplicates are checked after backbone resolution, not on the
raw names. If the external data lists both *Picea excelsa* and *Picea
abies* with different SLA values, those two names resolve to the same
accepted species and trigger the conflicting-duplicate error. This is
intentional: the join key is the accepted ID, and conflicting values for
the same key cannot coexist.

## How the join works

The full pipeline inside
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
has five steps:

1.  **Read** the external data. File paths are dispatched by extension
    (`.csv`, `.csv.gz`, `.tsv`, `.tsv.gz`, `.xlsx`, `.sqlite`, `.vtr`).
    Data.frames pass through directly. The format detection is based
    solely on the file extension, so a misnamed file (e.g., a
    tab-separated file saved as `.csv`) will produce a read error rather
    than silent misparse.

2.  **Identify** the species column, either from the explicit
    `species_col` argument or via auto-detection. When auto-detecting,
    [`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
    samples the first 10 rows of every character column and runs each
    sample through
    [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
    against the same backbone(s). The column whose sample achieves the
    highest match rate wins, provided it clears the 50% threshold.
    Columns containing site codes, habitat labels, or observer names
    rarely match any backbone entry, so the true species column tends to
    stand out clearly.

3.  **Match** the species names through the same backbone(s) used in the
    original
    [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
    call. This produces an `accepted_id` for each row in the external
    data. The backbone choice is read from the `taxify_meta` attribute
    that
    [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
    attaches to its output, so we do not need to specify it again. Fuzzy
    matching is on by default (controlled via `fuzzy` and
    `fuzzy_threshold`). Any names that fail to resolve are dropped from
    the joinable pool, and their count appears in the summary message at
    the end.

4.  **Check for duplicates.** After backbone resolution, any rows that
    share the same `accepted_id` are inspected. Exact duplicates
    (identical trait values across all selected columns) are collapsed
    with a warning. Conflicting duplicates raise an error, as described
    in the section above.

5.  **Left join** on `accepted_id`. Every row in the original
    [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
    result that has a matching `accepted_id` in the external data
    receives the trait columns. Rows without a match get `NA`. Column
    name collisions are resolved by prefixing the incoming columns with
    `data_`.

The join preserves every row of the original result; nothing is dropped.
Species present in the external data but absent from the original result
are ignored. A summary message reports how many species were matched and
how many names in the external data could not be resolved through the
backbone.

### Controlling fuzzy matching

By default,
[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
uses the same fuzzy matching as
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) to
resolve names in the external data. Fuzzy matching catches typos and
minor spelling differences, but it can produce false matches for short
or similar names. The `fuzzy_threshold` argument controls how permissive
the matching is. Lower values are stricter.

``` r

# Strict: only very close matches
result |> add_data(traits, species_col = "taxon", fuzzy_threshold = 0.1)

# Exact matching only (no fuzzy)
result |> add_data(traits, species_col = "taxon", fuzzy = FALSE)
```

Disabling fuzzy matching entirely (`fuzzy = FALSE`) is useful when the
external data is already well-curated and we want to avoid any risk of
cross-species contamination from approximate string matches.

## Combining add_data() with enrichments

[`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
fits naturally into a pipe chain alongside the built-in enrichment
functions. Custom data and pre-built enrichments use the same
`accepted_id` join key, so they can be stacked in any order.

``` r

result <- taxify(species, backend = "wfo") |>
  add_iucn() |>
  add_zanne() |>
  add_data(traits, species_col = "taxon")
```

Each step appends columns to the result. The final data.frame contains
the core
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
output, IUCN conservation status, woodiness classification, and our
custom SLA and height measurements, all aligned by accepted species
identity.
