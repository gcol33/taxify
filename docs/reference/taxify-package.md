# taxify: Offline Taxonomic Name Matching Against Darwin Core Backbones

taxify matches taxonomic names to their accepted names against local
copies of published backbones, such as the Catalogue of Life, World
Flora Online and WoRMS. It performs the name-resolution step of 'taxize'
and 'WorldFlora', run offline against local backbone files. Each
backbone is downloaded once and recorded by version on every result row.

## Functions by task

- Matching:

  [`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
  matches a character vector of names and returns one row per name with
  its accepted name, how it was matched and the backbone version;
  [summary()](https://gillescolling.com/taxify/reference/summary.taxify_result.md)
  counts how a batch resolved.

- Checking:

  [`inspect()`](https://gillescolling.com/taxify/reference/inspect.md)
  returns only the names that need a look;
  [`reconcile()`](https://gillescolling.com/taxify/reference/reconcile.md)
  reports how a checklist maps onto a backbone's current treatment.

- Joining data:

  [`add_data()`](https://gillescolling.com/taxify/reference/add_data.md)
  joins a table the user supplies on the accepted name; each published
  dataset has its own `add_<source>()` function, listed by
  [`list_enrichments()`](https://gillescolling.com/taxify/reference/list_enrichments.md);
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
  gathers one trait from every dataset that carries it.

- Exploring the backbone:

  [`synonyms()`](https://gillescolling.com/taxify/reference/synonyms.md),
  [`children()`](https://gillescolling.com/taxify/reference/children.md),
  [`downstream()`](https://gillescolling.com/taxify/reference/downstream.md),
  [`upstream()`](https://gillescolling.com/taxify/reference/upstream.md),
  [`add_classification()`](https://gillescolling.com/taxify/reference/add_classification.md),
  [`class2tree()`](https://gillescolling.com/taxify/reference/class2tree.md),
  [`id2name()`](https://gillescolling.com/taxify/reference/id2name.md),
  [`parse_name()`](https://gillescolling.com/taxify/reference/parse_name.md),
  [`comm2sci()`](https://gillescolling.com/taxify/reference/comm2sci.md)
  and
  [`sci2comm()`](https://gillescolling.com/taxify/reference/sci2comm.md).

- Backbones and versions:

  [`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md),
  [`install_backbones()`](https://gillescolling.com/taxify/reference/install_backbones.md),
  [`taxify_download()`](https://gillescolling.com/taxify/reference/taxify_download.md),
  [`taxify_lock()`](https://gillescolling.com/taxify/reference/taxify_lock.md),
  [`taxify_restore()`](https://gillescolling.com/taxify/reference/taxify_restore.md)
  and [`cite()`](https://gillescolling.com/taxify/reference/cite.md).

## Where to start

[`vignette("taxify")`](https://gillescolling.com/taxify/articles/taxify.md)
goes from a messy list of names to accepted names with traits attached.
The articles at <https://gillescolling.com/taxify/> cover each task in
full.

## Citation

`citation("taxify")` gives the reference of the package;
[`cite()`](https://gillescolling.com/taxify/reference/cite.md) on a
result lists the references of every backbone and dataset it used.

## See also

Useful links:

- <https://gillescolling.com/taxify/>

- <https://github.com/gcol33/taxify>

- Report bugs at <https://github.com/gcol33/taxify/issues>

## Author

**Maintainer**: Gilles Colling <gilles.colling051@gmail.com>
([ORCID](https://orcid.org/0000-0003-3070-6066)) \[copyright holder\]

Authors:

- Gilles Colling <gilles.colling051@gmail.com>
  ([ORCID](https://orcid.org/0000-0003-3070-6066)) \[copyright holder\]
