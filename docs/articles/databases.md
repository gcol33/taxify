# The backbones and datasets

This page lists every backbone taxify matches names against and every
published dataset it can attach, with the version, size, licence and
reference of each. The tables are generated from the manifest of this
taxify version when the site is built. Installation is covered in [Get
started](https://gillescolling.com/taxify/taxify.md); how to choose
backbones is in [Choosing and combining
backbones](https://gillescolling.com/taxify/backbones.md), and how to
attach datasets in [Attaching published
data](https://gillescolling.com/taxify/enrichments.md).

In R, the same lists are returned by these functions:

``` r

list_backbones()     # the backbones
list_enrichments()   # the published datasets
list_traits()        # the traits add_trait() gathers across datasets
taxify_databases()   # backbones and datasets in one table
```

## Backbones

A backbone is downloaded once, on first use, and read from disk after
that. `Names` counts accepted names and synonyms together.

| Backbone | Full name | Scope | Names | MB | Version | Licence | Reference |
|:---|:---|:---|---:|---:|:---|:---|:---|
| `wfo` | World Flora Online | Vascular plants | 1,664,014 | 785 | 2026.06 |  | [Borsch et al. 2020](https://doi.org/10.1002/tax.12373) |
| `col` | Catalogue of Life | All kingdoms | 5,432,444 | 1,997 | 2026.09 |  | [Banki et al. 2024](https://doi.org/10.48580/d4t2) |
| `colxr` | Catalogue of Life Extended Release | All kingdoms | 8,479,599 | 1,393 | 2026.09 |  | [Banki et al. 2026](https://doi.org/10.48580/dgykv) |
| `gbif` | GBIF Backbone Taxonomy | All kingdoms | 6,404,001 | 1,622 | 2023.08 |  | [GBIF Secretariat 2024](https://doi.org/10.15468/39omei) |
| `itis` | Integrated Taxonomic Information System | US focus, freshwater/marine | 1,000,552 | 197 | 2026.09 |  | [ITIS 2025](https://doi.org/10.5066/F7KH0KBK) |
| `ncbi` | NCBI Taxonomy | All life | 2,952,424 | 524 | 2026.09 |  |  |
| `ott` | Open Tree of Life Taxonomy | All life (synthetic) | 3,690,217 | 728 | 2026.09 |  |  |
| `worms` | World Register of Marine Species | Marine/aquatic | 1,565,652 | 290 | 2026.09 |  |  |
| `euromed` | Euro+Med PlantBase | European/Mediterranean plants | 146,922 | 33 | 2026.08 |  | [Euro+Med 2026](https://europlusmed.org) |
| `fungorum` | Species Fungorum Plus | Fungi | 315,037 | 68 | 2026.08 |  |  |
| `algaebase` | AlgaeBase | Algae | 172,351 | 34 | 2026.09 |  |  |
| `fishbase` | FishBase | Fishes | 102,703 | 18 | 2026.08 |  |  |
| `sealifebase` | SeaLifeBase | Non-fish marine/aquatic | 134,031 | 27 | 2026.08 |  |  |
| `reptiledb` | Reptile Database | Reptiles | 50,043 | 9 | 2026.07 | CC BY 4.0 | [Uetz et al. 2026](http://www.reptile-database.org) |
| `lcvp` | Leipzig Catalogue of Vascular Plants | Vascular plants | 1,337,891 | 241 | 2026.08 | MIT | [Freiberg et al. 2020](https://doi.org/10.1038/s41597-020-00702-z) |
| `wcvp` | World Checklist of Vascular Plants | Vascular plants | 1,448,984 | 326 | 2026.06 | CC BY 4.0 | [Govaerts et al. 2021](https://doi.org/10.1038/s41597-021-00997-6) |
| `mdd` | Mammal Diversity Database | Mammals | 61,862 | 10 | 2026.08 |  |  |
| `avilist` | AviList Global Avian Checklist | Birds | 40,572 | 8 | 2026.08 |  |  |
| `lpsn` | List of Prokaryotic names with Standing in Nomenclature | Prokaryotes (Bacteria/Archaea) | 44,885 | 12 | 2026.08 |  |  |
| `evc` | EuroVegChecklist | European vegetation units (syntaxa) | 7,542 | 2 | 4 |  | [Mucina et al. 2016](https://doi.org/10.1111/avsc.12257) |
| `vegcz` | Vegetation of the Czech Republic | Czech vegetation units (syntaxa) | 2,258 | 1 | 2026.10 |  | Chytrý M (ed.) 2007-2013 |

The licence of a backbone without one in the table is set by its source;
the `source` link of
[`list_backbones()`](https://gillescolling.com/taxify/reference/list_backbones.md)
leads to it. AlgaeBase, FishBase and SeaLifeBase are licensed for
non-commercial use only.

## Published datasets

Each dataset is attached by its `add_<source>()` function, whose help
page lists its columns and reference. `Rows` counts the rows of the
built dataset, which holds a row under every accepted name any backbone
gives a species, so it is larger than the number of species in the
source. A dataset marked `fixed` is a single release that is never
updated; the others are updated when their source publishes a new
version.

| Dataset | Function | Version | Release | Rows | Licence | Reference |
|:---|:---|:---|:---|---:|:---|:---|
| algae_traits | [`add_algae_traits()`](https://gillescolling.com/taxify/reference/add_algae_traits.md) | 2026.08 | fixed | 3,754 | CC BY 4.0 | [Vranken et al. 2023](https://doi.org/10.5194/essd-15-2711-2023) |
| alien_first_records | [`add_alien_first_records()`](https://gillescolling.com/taxify/reference/add_alien_first_records.md) | 2026.08 | fixed | 340,104 | CC BY 4.0 | [Seebens 2026](https://doi.org/10.5281/zenodo.18759840) |
| alpine_carabids | [`add_alpine_carabids()`](https://gillescolling.com/taxify/reference/add_alpine_carabids.md) | 2026.08 | fixed | 209 | CC0 1.0 | [Chamberlain et al. 2020](https://doi.org/10.1111/jbi.13792) |
| amniote | [`add_amniote()`](https://gillescolling.com/taxify/reference/add_amniote.md) | 2026.08 | fixed | 36,706 | CC0 | [Myhrvold et al. 2015](https://doi.org/10.1890/15-0846R.1) |
| amphibio | [`add_amphibio()`](https://gillescolling.com/taxify/reference/add_amphibio.md) | 2026.08 | fixed | 8,901 | CC BY 4.0 | [Oliveira et al. 2017](https://doi.org/10.1038/sdata.2017.123) |
| anage | [`add_anage()`](https://gillescolling.com/taxify/reference/add_anage.md) | 2026.08 | updated | 11,859 | CC BY | [Tacutu et al. 2018](https://doi.org/10.1093/nar/gkx1042) |
| animaltraits | [`add_animaltraits()`](https://gillescolling.com/taxify/reference/add_animaltraits.md) | 2026.08 | fixed | 5,106 | CC0 | [Herberstein et al. 2022](https://doi.org/10.1038/s41597-022-01364-9) |
| arctic_traits | [`add_arctic_traits()`](https://gillescolling.com/taxify/reference/add_arctic_traits.md) | 2026.08 | fixed | 644 | CC BY-NC 4.0 | [Degen et al. 2018](https://doi.org/10.25365/phaidra.49) |
| arthropod_traits | [`add_arthropod_traits()`](https://gillescolling.com/taxify/reference/add_arthropod_traits.md) | 2026.08 | fixed | 6,822 | CC BY-NC | [Logghe et al. 2025](https://doi.org/10.3897/BDJ.13.e146785) |
| austraits | [`add_austraits()`](https://gillescolling.com/taxify/reference/add_austraits.md) | 2026.08 | fixed | 54,995 | CC BY 4.0 | [Falster et al. 2021](https://doi.org/10.1038/s41597-021-01006-6) |
| avonet | [`add_avonet()`](https://gillescolling.com/taxify/reference/add_avonet.md) | 2026.08 | fixed | 17,205 | CC BY 4.0 | [Tobias et al. 2022](https://doi.org/10.1111/ele.13898) |
| bacdive | [`add_bacdive()`](https://gillescolling.com/taxify/reference/add_bacdive.md) | 2026.08 | fixed | 21,375 | CC BY 4.0 | [Reimer et al. 2022](https://doi.org/10.1093/nar/gkab961) |
| baseflor | [`add_baseflor()`](https://gillescolling.com/taxify/reference/add_baseflor.md) | 2026.08 | fixed | 28,259 | ODbL 1.0 / CC BY-SA 2.0 | Julve 1998 |
| bee_ostwald | [`add_bee_ostwald()`](https://gillescolling.com/taxify/reference/add_bee_ostwald.md) | 2026.08 | fixed | 2,602 | CC BY 4.0 | [Madeleine Ostwald 2024](https://doi.org/10.5281/zenodo.13366989) |
| bet | [`add_bet()`](https://gillescolling.com/taxify/reference/add_bet.md) | 2026.08 | fixed | 3,981 | CC BY-SA 4.0 | [Van Zuijlen et al. 2023](https://doi.org/10.16904/envidat.348) |
| betsi_collembola_body_length | [`add_betsi_collembola_body_length()`](https://gillescolling.com/taxify/reference/add_betsi_collembola_body_length.md) | 2026.08 | fixed | 1,443 | CC BY-NC 4.0 | [Bonfanti 2018](https://doi.org/10.5281/zenodo.1292461) |
| betsi_collembola_traits | [`add_betsi_collembola_traits()`](https://gillescolling.com/taxify/reference/add_betsi_collembola_traits.md) | 2026.08 | fixed | 38 | Extracted trait values (facts); mixed provenance (see meta.json), served for non-commercial scientific reuse (informed-risk, \#42) | [Lu J-Z et al. 2025](https://doi.org/10.1002/eap.70034) |
| betsi_earthworm_traits | [`add_betsi_earthworm_traits()`](https://gillescolling.com/taxify/reference/add_betsi_earthworm_traits.md) | 2026.08 | fixed | 47 | Extracted trait values (facts); BETSI-derived, served for non-commercial scientific reuse (informed-risk, \#42) | [Pelosi et al. 2014](https://doi.org/10.1016/j.apsoil.2013.10.005) |
| beukhof | [`add_beukhof()`](https://gillescolling.com/taxify/reference/add_beukhof.md) | 2026.08 | fixed | 2,138 | CC BY 4.0 | [Beukhof et al. 2019](https://doi.org/10.1594/PANGAEA.900866) |
| bien | [`add_bien()`](https://gillescolling.com/taxify/reference/add_bien.md) | 2026.08 | fixed | 202,121 | CC BY | [Maitner et al. 2017](https://doi.org/10.1111/2041-210X.12861) |
| birdbase | [`add_birdbase()`](https://gillescolling.com/taxify/reference/add_birdbase.md) | 2026.08 | fixed | 18,244 | CC BY 4.0 | [Şekercioğlu et al. 2025](https://doi.org/10.1038/s41597-025-05615-3) |
| blanchard | [`add_blanchard()`](https://gillescolling.com/taxify/reference/add_blanchard.md) | 2026.08 | fixed | 599 | CC0 | [Blanchard 2016](https://doi.org/10.5061/dryad.st6sc) |
| brot | [`add_brot()`](https://gillescolling.com/taxify/reference/add_brot.md) | 2026.08 | fixed | 10,584 | CC BY 4.0 | [G. Pausas 2018](https://doi.org/10.6084/m9.figshare.c.3843841) |
| cefas_btrait | [`add_cefas_btrait()`](https://gillescolling.com/taxify/reference/add_cefas_btrait.md) | 2026.08 | fixed | 1,166 | OGL v3.0 | [Centre for Environment 2022](https://doi.org/10.14466/CefasDataHub.123) |
| chelonians | [`add_chelonians()`](https://gillescolling.com/taxify/reference/add_chelonians.md) | 2026.08 | fixed | 558 | CC BY 4.0 | [Wang et al. 2025](https://doi.org/10.6084/m9.figshare.28828241) |
| chowdhury | [`add_chowdhury()`](https://gillescolling.com/taxify/reference/add_chowdhury.md) | 2026.08 | fixed | 428 | No separate licence stated for the Supporting Information; article is CC BY 4.0. Reuse basis: public scientific supporting data offered as the paper’s trait dataset. | [Chowdhury et al. 2025](https://doi.org/10.1111/ddi.70112) |
| combine | [`add_combine()`](https://gillescolling.com/taxify/reference/add_combine.md) | 2026.08 | fixed | 15,034 | CC0 | [Soria et al. 2021](https://doi.org/10.1002/ecy.3344) |
| combine_imputed | [`add_combine_imputed()`](https://gillescolling.com/taxify/reference/add_combine_imputed.md) | 2026.08 | fixed | 15,034 | CC0 | [Soria et al. 2021](https://doi.org/10.1002/ecy.3344) |
| common_names | [`add_common_names()`](https://gillescolling.com/taxify/reference/add_common_names.md) | 2026.10 | updated | 2,012,878 | CC0 (GBIF, OTT) / public domain (NCBI) | [GBIF Secretariat 2024](https://doi.org/10.15468/39omei) |
| copepod_traits | [`add_copepod_traits()`](https://gillescolling.com/taxify/reference/add_copepod_traits.md) | 2026.08 | fixed | 1,675 | CC BY 3.0 | [Brun et al. 2017](https://doi.org/10.5194/essd-9-99-2017) |
| coral_traits | [`add_coral_traits()`](https://gillescolling.com/taxify/reference/add_coral_traits.md) | 2026.08 | fixed | 1,934 | CC BY 4.0 | [Madin et al. 2016](https://doi.org/10.1038/sdata.2016.17) |
| diaz_traits | [`add_diaz_traits()`](https://gillescolling.com/taxify/reference/add_diaz_traits.md) | 2026.08 | fixed | 111,713 | CC BY 4.0 | [Diaz et al. 2022](https://doi.org/10.1038/s41597-022-01774-9) |
| disperse | [`add_disperse()`](https://gillescolling.com/taxify/reference/add_disperse.md) | 2026.08 | fixed | 564 | CC BY 4.0 | [Sarremejane et al. 2020](https://doi.org/10.6084/m9.figshare.c.5000633) |
| eberswalde | [`add_eberswalde()`](https://gillescolling.com/taxify/reference/add_eberswalde.md) | 2026.08 | fixed | 30 | CC BY-SA 4.0 | [Weiss et al. 2024](https://doi.org/10.48548/pubdata-46) |
| ecoflora | [`add_ecoflora()`](https://gillescolling.com/taxify/reference/add_ecoflora.md) | 2026.08 | fixed | 15,727 | CC BY-NC-SA 4.0 | Fitter 1994 |
| ecomorphosis | [`add_ecomorphosis()`](https://gillescolling.com/taxify/reference/add_ecomorphosis.md) | 2026.08 | fixed | 57 | CC BY 4.0 | [Bonfanti 2022](https://doi.org/10.5281/zenodo.7194559) |
| edwards_phyto | [`add_edwards_phyto()`](https://gillescolling.com/taxify/reference/add_edwards_phyto.md) | 2026.08 | fixed | 243 | CC BY 4.0 | [Edwards et al. 2015](https://doi.org/10.1890/14-2252.1) |
| eive | [`add_eive()`](https://gillescolling.com/taxify/reference/add_eive.md) | 2026.08 | fixed | 44,811 | CC BY 4.0 | [Dengler et al. 2023](https://doi.org/10.3897/VCS.98324) |
| ellers_collembola | [`add_ellers_collembola()`](https://gillescolling.com/taxify/reference/add_ellers_collembola.md) | 2026.08 | fixed | 366 | CC0 1.0 | [Ellers et al. 2018](https://doi.org/10.1111/1365-2656.12838.) |
| elton_traits | [`add_elton_traits()`](https://gillescolling.com/taxify/reference/add_elton_traits.md) | 2026.08 | fixed | 29,052 | CC0 | [Wilman et al. 2014](https://doi.org/10.1890/13-1917.1) |
| epa_freshwater | [`add_epa_freshwater()`](https://gillescolling.com/taxify/reference/add_epa_freshwater.md) | 2026.08 | fixed | 3,081 | Public domain (U.S. Government work) | U.S. Environmental Protection Agency 2012 |
| eupolltrait | [`add_eupolltrait()`](https://gillescolling.com/taxify/reference/add_eupolltrait.md) | 2026.08 | fixed | 3,637 | CC BY 4.0 | [Miličić et al. 2025](https://doi.org/10.5281/zenodo.18032357) |
| eurobat | [`add_eurobat()`](https://gillescolling.com/taxify/reference/add_eurobat.md) | 2026.08 | fixed | 139 | CC BY 4.0 | [Froidevaux et al. 2023](https://doi.org/10.6084/m9.figshare.21777161) |
| euromed_distribution | [`add_euromed_distribution()`](https://gillescolling.com/taxify/reference/add_euromed_distribution.md) | 2026.09 | fixed | 1,594,402 | CC BY-SA | Euro+Med PlantBase |
| faprotax | [`add_faprotax()`](https://gillescolling.com/taxify/reference/add_faprotax.md) | 2026.08 | fixed | 5,391 | BSD-style. Copyright (c) 2025 Stilianos Louca, all rights reserved. Verbatim: ‘Use and redistributions of the FAPROTAX database, including any associated software, with or without modification, are permitted provided that the following conditions are met’ – redistributions must retain the copyright notice, conditions and disclaimer; the author’s name may not be used to endorse derived products; and modification must be clearly indicated. taxifydb reshapes the grouped list into a per-taxon table, which is a modification and is stated as such here. | [Louca et al. 2016](https://doi.org/10.1126/science.aaf4507) |
| finand | [`add_finand()`](https://gillescolling.com/taxify/reference/add_finand.md) | 2026.08 | fixed | 40 | CC BY 4.0 | [Finand 2025](https://doi.org/10.5281/zenodo.17184995) |
| fishbase | [`add_fishbase()`](https://gillescolling.com/taxify/reference/add_fishbase.md) | 2026.08 | updated | 43,578 | CC BY-NC 4.0 | [Froese 2024](https://www.fishbase.org) |
| fishmorph | [`add_fishmorph()`](https://gillescolling.com/taxify/reference/add_fishmorph.md) | 2026.08 | fixed | 11,008 | CC BY 4.0 | [Brosse et al. 2021](https://doi.org/10.1111/geb.13395) |
| fishtraits | [`add_fishtraits()`](https://gillescolling.com/taxify/reference/add_fishtraits.md) | 2026.08 | fixed | 1,144 | Public domain (U.S. Government work) | Frimpong 2009 |
| floraweb | [`add_floraweb()`](https://gillescolling.com/taxify/reference/add_floraweb.md) | 2026.08 | fixed | 22,354 | free use with acknowledgement + citation (BioFresh metadata statement) | Klotz et al. 2002 |
| freshwater_insects_conus | [`add_freshwater_insects_conus()`](https://gillescolling.com/taxify/reference/add_freshwater_insects_conus.md) | 2026.08 | fixed | 1,262 | CC BY 4.0 | [Twardochleb et al. 2021](https://doi.org/10.6073/pasta/8238ea9bc15840844b3a023b6b6ed158) |
| frugivoria | [`add_frugivoria()`](https://gillescolling.com/taxify/reference/add_frugivoria.md) | 2026.10 | fixed | 3,032 | CC BY 4.0 | [Gerstner BE et al. (2023) Frugivoria: a trait database for birds and mammals exhibiting frugivory across contiguous Neotropical moist forests. EDI (edi.1220.5) et al. 1.220.5](https://doi.org/10.6073/pasta/frugivoria) |
| fungal_traits | [`add_fungal_traits()`](https://gillescolling.com/taxify/reference/add_fungal_traits.md) | 2026.08 | fixed | 11,129 | CC BY 4.0 | [Polme et al. 2020](https://doi.org/10.1007/s13225-020-00466-2) |
| fungalroot | [`add_fungalroot()`](https://gillescolling.com/taxify/reference/add_fungalroot.md) | 2026.08 | fixed | 5,647 | CC BY-NC 4.0 | [Soudzilovskaia et al. 2020](https://doi.org/10.1111/nph.16569) |
| funguild | [`add_funguild()`](https://gillescolling.com/taxify/reference/add_funguild.md) | 2026.08 | updated | 18,659 | CC BY 4.0 | [Nguyen et al. 2016](https://doi.org/10.1016/j.funeco.2015.06.006) |
| gidias | [`add_gidias()`](https://gillescolling.com/taxify/reference/add_gidias.md) | 2026.08 | fixed | 19,493 | CC BY 4.0 | [Bacher et al. 2025](https://doi.org/10.1038/s41597-025-05184-5) |
| gift | [`add_gift()`](https://gillescolling.com/taxify/reference/add_gift.md) | 2026.08 | updated | 420,049 | CC BY 4.0 | [Weigelt et al. 2020](https://doi.org/10.1111/jbi.13623) |
| globi | [`add_globi()`](https://gillescolling.com/taxify/reference/add_globi.md) | 2026.08 | fixed | 547,125 | CC BY 4.0 (derived counts; source records carry contributor licenses) | [Poelen et al. 2014](https://doi.org/10.1016/j.ecoinf.2014.08.005) |
| globtherm | [`add_globtherm()`](https://gillescolling.com/taxify/reference/add_globtherm.md) | 2026.08 | fixed | 5,013 | CC0 | [Bennett et al. 2018](https://doi.org/10.1038/sdata.2018.22) |
| glonaf | [`add_glonaf()`](https://gillescolling.com/taxify/reference/add_glonaf.md) | 2026.08 | fixed | 1,543,250 | CC BY 4.0 | [Davis et al. 2025](https://doi.org/10.1002/ecy.70245) |
| griis | [`add_griis()`](https://gillescolling.com/taxify/reference/add_griis.md) | 2026.08 | updated | 437,664 | CC BY 4.0 | [Pagad et al. 2018](https://doi.org/10.1038/sdata.2017.202) |
| groot | [`add_groot()`](https://gillescolling.com/taxify/reference/add_groot.md) | 2026.08 | updated | 26,275 | Free use with data-paper citation (no formal license stated) | [Guerrero-Ramirez NR et al. et al. 2021](https://doi.org/10.1111/geb.13179) |
| gwdd | [`add_gwdd()`](https://gillescolling.com/taxify/reference/add_gwdd.md) | 2026.08 | fixed | 34,850 | CC BY 4.0 | [Fischer et al. 2026](https://doi.org/10.1111/nph.70860) |
| homerange | [`add_homerange()`](https://gillescolling.com/taxify/reference/add_homerange.md) | 2026.08 | fixed | 4,805 | CC0 | [Broekman et al. 2023](https://doi.org/10.5061/dryad.d2547d85x) |
| hosts | [`add_hosts()`](https://gillescolling.com/taxify/reference/add_hosts.md) | 2026.08 | fixed | 22,776 | CC0 | [Robinson et al. 2010](https://data.nhm.ac.uk/dataset/hosts) |
| huang_amph | [`add_huang_amph()`](https://gillescolling.com/taxify/reference/add_huang_amph.md) | 2026.08 | fixed | 5,736 | CC BY 4.0 | [anonymous 2022](https://doi.org/10.6084/m9.figshare.21159229) |
| hydraulics | [`add_hydraulics()`](https://gillescolling.com/taxify/reference/add_hydraulics.md) | 2026.08 | fixed | 6,267 | CC BY 4.0 | [Sanchez-Martinez et al. 2020](https://doi.org/10.1111/ele.13584) |
| imageomics_neon | [`add_imageomics_neon()`](https://gillescolling.com/taxify/reference/add_imageomics_neon.md) | 2026.08 | fixed | 86 | CC BY-SA 4.0 | Fluck et al. 2024 |
| inrae_collembola_traits | [`add_inrae_collembola_traits()`](https://gillescolling.com/taxify/reference/add_inrae_collembola_traits.md) | 2026.08 | fixed | 186 | Extracted trait values (facts); BETSI-derived, served for non-commercial scientific reuse (informed-risk, \#42) | [Joimel S, Chassain C, Artige E, Barda L, Balvay S, Belnou T, Bur T, Cortet J, Coussin-Grellier S, Hedde M et al](https://doi.org/10.15454/UU2FQT) |
| invacost | [`add_invacost()`](https://gillescolling.com/taxify/reference/add_invacost.md) | 2026.08 | fixed | 3,194 | CC BY 4.0 | [Diagne et al. 2020](https://doi.org/10.1038/s41597-020-00586-z) |
| italic | [`add_italic()`](https://gillescolling.com/taxify/reference/add_italic.md) | 2026.08 | fixed | 3,580 | CC BY-SA 4.0 | [Martellos et al. 2023](https://doi.org/10.3390/jof9050556) |
| iucn | [`add_iucn()`](https://gillescolling.com/taxify/reference/add_iucn.md) | 2026.08 | updated | 254,965 | CC BY 4.0 | [IUCN 2025](https://www.iucnredlist.org) |
| kew_cvalues | [`add_kew_cvalues()`](https://gillescolling.com/taxify/reference/add_kew_cvalues.md) | 2026.08 | fixed | 35,469 | CC BY | Pellicer 2020 |
| kew_sid | [`add_kew_sid()`](https://gillescolling.com/taxify/reference/add_kew_sid.md) | 2026.08 | fixed | 106,119 | CC BY 2.0 | [Royal Botanic Gardens Kew 2024](https://ser-sid.org/) |
| leda | [`add_leda()`](https://gillescolling.com/taxify/reference/add_leda.md) | 2026.08 | fixed | 23,748 | Free for academic use | [Kleyer et al. 2008](https://doi.org/10.1111/j.1365-2745.2008.01430.x) |
| leptraits | [`add_leptraits()`](https://gillescolling.com/taxify/reference/add_leptraits.md) | 2026.08 | fixed | 15,323 | CC0 | [Shirey et al. 2022](https://doi.org/10.1038/s41597-022-01473-5) |
| madin | [`add_madin()`](https://gillescolling.com/taxify/reference/add_madin.md) | 2026.08 | fixed | 17,710 | CC BY 4.0 | [Madin et al. 2020](https://doi.org/10.1038/s41597-020-0497-4) |
| marine_distribution |  | 2026.08 | fixed | 2,552,415 | CC BY 4.0 | [WoRMS Editorial Board 2026](https://doi.org/10.14284/170) |
| monograph_collembola_body_length | [`add_monograph_collembola_body_length()`](https://gillescolling.com/taxify/reference/add_monograph_collembola_body_length.md) | 2026.08 | fixed | 577 | Extracted measurements (facts); source monographs copyright their publishers, served for non-commercial scientific reuse (informed-risk, \#42) | Body length |
| nesttrait | [`add_nesttrait()`](https://gillescolling.com/taxify/reference/add_nesttrait.md) | 2026.08 | fixed | 17,413 | CC BY 4.0 | [Chia et al. 2023](https://doi.org/10.1038/s41597-023-02837-1) |
| noddb | [`add_noddb()`](https://gillescolling.com/taxify/reference/add_noddb.md) | 2026.08 | fixed | 857 | CC BY-SA 4.0 | [Tedersoo et al. 2018](https://doi.org/10.1111/jvs.12627) |
| nztd | [`add_nztd()`](https://gillescolling.com/taxify/reference/add_nztd.md) | 2026.08 | fixed | 409 | CC BY 4.0 | [Lam-Gordillo 2023](https://doi.org/10.6084/m9.figshare.21939647) |
| octocoral | [`add_octocoral()`](https://gillescolling.com/taxify/reference/add_octocoral.md) | 2026.08 | fixed | 4,448 | CC BY 4.0 | [Gómez-Gras et al. 2024](https://doi.org/10.5281/zenodo.14228404) |
| odonata | [`add_odonata()`](https://gillescolling.com/taxify/reference/add_odonata.md) | 2026.08 | fixed | 1,748 | CC BY 4.0 | [Waller et al. 2020](https://doi.org/10.5061/dryad.15pm5qc) |
| pantheria | [`add_pantheria()`](https://gillescolling.com/taxify/reference/add_pantheria.md) | 2026.08 | fixed | 13,802 | CC0 | [Jones et al. 2009](https://doi.org/10.1890/08-1494.1) |
| parravicini | [`add_parravicini()`](https://gillescolling.com/taxify/reference/add_parravicini.md) | 2026.08 | fixed | 7,498 | CC BY 4.0 | [Parravicini et al. 2020](https://doi.org/10.1371/journal.pbio.3000702) |
| pelagic | [`add_pelagic()`](https://gillescolling.com/taxify/reference/add_pelagic.md) | 2026.08 | fixed | 772 | CC BY 4.0 | [Gleiber et al. 2022](https://doi.org/10.5683/SP3/0YFJED) |
| phylacine | [`add_phylacine()`](https://gillescolling.com/taxify/reference/add_phylacine.md) | 2026.08 | fixed | 14,477 | CC0 | [Faurby et al. 2018](https://doi.org/10.1002/ecy.2443) |
| plazi_collembola_body_length | [`add_plazi_collembola_body_length()`](https://gillescolling.com/taxify/reference/add_plazi_collembola_body_length.md) | 2026.08 | fixed | 1,056 | CC0 1.0 | Plazi TreatmentBank |
| pottier | [`add_pottier()`](https://gillescolling.com/taxify/reference/add_pottier.md) | 2026.08 | fixed | 929 | CC BY 4.0 | [Pottier et al. 2022](https://doi.org/10.1038/s41597-022-01704-9) |
| quimbayo | [`add_quimbayo()`](https://gillescolling.com/taxify/reference/add_quimbayo.md) | 2026.08 | fixed | 2,614 | Open (ESA Ecology data policy) | [Quimbayo et al. 2021](https://doi.org/10.5281/zenodo.4455016) |
| ramond | [`add_ramond()`](https://gillescolling.com/taxify/reference/add_ramond.md) | 2026.08 | fixed | 1,631 | CC BY 4.0 | [Ramond et al. 2018](https://doi.org/10.17882/51662) |
| repttraits | [`add_repttraits()`](https://gillescolling.com/taxify/reference/add_repttraits.md) | 2026.08 | fixed | 14,553 | CC BY 4.0 | [Oskyrko et al. 2024](https://doi.org/10.1038/s41597-024-03079-5) |
| rimet_phyto | [`add_rimet_phyto()`](https://gillescolling.com/taxify/reference/add_rimet_phyto.md) | 2026.08 | fixed | 1,927 | CC BY 4.0 | [Frédéric 2018](https://doi.org/10.5281/zenodo.1164834) |
| saproxylic | [`add_saproxylic()`](https://gillescolling.com/taxify/reference/add_saproxylic.md) | 2026.08 | fixed | 1,356 | CC0 | [Hagge et al. 2021](https://doi.org/10.5061/dryad.2fqz612p3) |
| sealifebase | [`add_sealifebase()`](https://gillescolling.com/taxify/reference/add_sealifebase.md) | 2026.08 | updated | 126,916 | CC BY-NC 4.0 | [Palomares 2024](https://www.sealifebase.org) |
| sharkipedia | [`add_sharkipedia()`](https://gillescolling.com/taxify/reference/add_sharkipedia.md) | 2026.08 | fixed | 216 | CC BY 4.0 | [Mull et al. 2022](https://doi.org/10.1038/s41597-022-01655-1) |
| sheld | [`add_sheld()`](https://gillescolling.com/taxify/reference/add_sheld.md) | 2026.08 | fixed | 456 | CC BY 4.0 | [Hopper et al. 2023](https://doi.org/10.1038/s41597-023-02635-9) |
| spider_traits | [`add_spider_traits()`](https://gillescolling.com/taxify/reference/add_spider_traits.md) | 2026.08 | fixed | 10,320 | CC BY 4.0 | [Pekar et al. 2021](https://doi.org/10.1093/database/baab064) |
| sworm | [`add_sworm()`](https://gillescolling.com/taxify/reference/add_sworm.md) | 2026.08 | fixed | 346 | CC BY 4.0 | [Phillips et al. 2021](https://doi.org/10.1038/s41597-021-00912-z) |
| tetradensity | [`add_tetradensity()`](https://gillescolling.com/taxify/reference/add_tetradensity.md) | 2026.08 | fixed | 4,711 | CC BY 4.0 | [Santini et al. 2019](https://doi.org/10.6084/m9.figshare.5371633) |
| thermofresh | [`add_thermofresh()`](https://gillescolling.com/taxify/reference/add_thermofresh.md) | 2026.08 | fixed | 1,252 | CC BY 4.0 | [ThermoFresh v1](https://doi.org/10.5281/zenodo.16959762) |
| tree_of_sex | [`add_tree_of_sex()`](https://gillescolling.com/taxify/reference/add_tree_of_sex.md) | 2026.08 | fixed | 54,318 | CC0 | [The Tree of Sex Consortium et al. 2014](https://doi.org/10.1038/sdata.2014.15) |
| usda_fungus_host | [`add_usda_fungus_host()`](https://gillescolling.com/taxify/reference/add_usda_fungus_host.md) | 2026.08 | fixed | 81,263 | U.S. Public Domain | [Farr et al. 2021](https://doi.org/10.15482/USDA.ADC/1524414) |
| useful_plants | [`add_useful_plants()`](https://gillescolling.com/taxify/reference/add_useful_plants.md) | 2026.08 | fixed | 96,022 | CC BY 4.0 | [Diazgranados et al. 2020](https://doi.org/10.5063/F1CV4G34) |
| virion | [`add_virion()`](https://gillescolling.com/taxify/reference/add_virion.md) | 2026.08 | fixed | 10,864 | ODbL-1.0 | [Carlson et al. 2022](https://doi.org/10.1128/mbio.02985-21) |
| wcvp | [`add_wcvp()`](https://gillescolling.com/taxify/reference/add_wcvp.md) | 2026.08 | updated | 4,909,534 | CC BY | [Govaerts et al. 2021](https://doi.org/10.1038/s41597-021-00997-6) |
| zanne | [`add_zanne()`](https://gillescolling.com/taxify/reference/add_zanne.md) | 2026.08 | fixed | 101,237 | CC0 | [Zanne et al. 2014](https://doi.org/10.1038/nature12872) |
| zooplankton | [`add_zooplankton()`](https://gillescolling.com/taxify/reference/add_zooplankton.md) | 2026.08 | fixed | 5,064 | CC BY-SA 4.0 | [Pata 2023](https://doi.org/10.5281/zenodo.8102913) |

A dataset without a function of its own is attached through
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
which reads it as one source of a trait.

## Traits across datasets

[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
gathers one trait from every dataset in the `From` column, in one unit
and one vocabulary.

| Trait | Label | Kind | Unit | Sources | From |
|:---|:---|:---|:---|---:|:---|
| `activity_time` | Diel activity time | categorical | NA | 6 | repttraits, chelonians, quimbayo, combine, pantheria, spider_traits |
| `age_at_first_reproduction` | Age at first reproduction | numeric | yr | 1 | combine |
| `age_at_maturity` | Age at female maturity | numeric | yr | 7 | anage, amniote, amphibio, chelonians, beukhof, fishtraits, sheld |
| `air_breathing` | Air breathing (fish) | categorical | NA | 1 | fishbase |
| `algal_life_cycle` | Life-cycle ploidy phase (algae) | categorical | NA | 1 | algae_traits |
| `algal_substrate` | Attachment substrate (algae) | categorical | NA | 1 | algae_traits |
| `antenna_length` | Antenna length | numeric | mm | 1 | saproxylic |
| `aspect_ratio` | Caudal fin aspect ratio | numeric | index | 2 | beukhof, quimbayo |
| `bark_thickness` | Bark thickness | numeric | mm | 1 | austraits |
| `beak_depth` | Beak depth | numeric | mm | 1 | avonet |
| `beak_length` | Beak length (culmen) | numeric | mm | 1 | avonet |
| `beak_width` | Beak width | numeric | mm | 1 | avonet |
| `bioluminescence` | Bioluminescence (zooplankton) | categorical | NA | 1 | zooplankton |
| `bioturbation` | Bioturbation mode (benthic invertebrate) | categorical | NA | 2 | arctic_traits, nztd |
| `body_elongation` | Body elongation (fish) | numeric | index | 1 | fishmorph |
| `body_lateral_shape` | Body lateral shape (fish) | numeric | index | 1 | fishmorph |
| `body_length` | Body length | numeric | mm | 19 | combine, amniote, repttraits, amphibio, fishbase, sealifebase, huang_amph, pottier, spider_traits, zooplankton, sheld, chowdhury, finand, alpine_carabids, betsi_collembola_body_length, plazi_collembola_body_length, monograph_collembola_body_length, ellers_collembola, betsi_collembola_traits |
| `body_mass` | Body mass | numeric | g | 15 | combine, amniote, pantheria, elton_traits, avonet, anage, phylacine, repttraits, fishbase, sealifebase, frugivoria, pottier, animaltraits, homerange, eurobat |
| `body_shape` | Body shape (fish) | categorical | NA | 3 | beukhof, quimbayo, pelagic |
| `brain_mass` | Brain mass | numeric | g | 2 | combine, animaltraits |
| `bryophyte_life_form` | Bryophyte life form | categorical | NA | 1 | bet |
| `calcification` | Calcification (algae) | categorical | NA | 1 | algae_traits |
| `carapace_length` | Carapace length (turtle) | numeric | mm | 1 | chelonians |
| `caudal_fin_shape` | Caudal fin shape (fish) | categorical | NA | 2 | beukhof, quimbayo |
| `caudal_peduncle_throttling` | Caudal peduncle throttling (fish) | numeric | index | 1 | fishmorph |
| `cell_biovolume` | Cell biovolume (microalgae) | numeric | um3 | 1 | rimet_phyto |
| `cell_length` | Cell length | numeric | um | 2 | rimet_phyto, bacdive |
| `cell_shape` | Cell shape (prokaryote) | categorical | NA | 2 | madin, bacdive |
| `cell_surface_area` | Cell surface area (microalgae) | numeric | um2 | 1 | rimet_phyto |
| `cell_thickness` | Cell thickness (microalgae) | numeric | um | 1 | rimet_phyto |
| `cell_width` | Cell width | numeric | um | 2 | rimet_phyto, bacdive |
| `chromosome_number` | Chromosome number (2n) | numeric | count | 1 | kew_cvalues |
| `climatic_temp_max` | Warmest-month temperature of range | numeric | deg C | 1 | fishtraits |
| `climatic_temp_mean` | Mean annual temperature of range | numeric | deg C | 3 | arthropod_traits, repttraits, hydraulics |
| `climatic_temp_min` | Coldest-month temperature of range | numeric | deg C | 1 | fishtraits |
| `clutch_litter_size` | Clutch or litter size | numeric | offspring per clutch/litter | 10 | amniote, combine, pantheria, anage, repttraits, amphibio, chelonians, birdbase, eurobat, zooplankton |
| `coloniality` | Coloniality | categorical | NA | 2 | coral_traits, octocoral |
| `colony_diameter` | Colony maximum diameter (coral) | numeric | cm | 1 | coral_traits |
| `colony_growth_form` | Colony growth form (octocoral) | categorical | NA | 1 | octocoral |
| `colour_lightness` | Body colour lightness (beetle) | numeric | index | 1 | saproxylic |
| `conservation_status` | IUCN Red List status | categorical | NA | 6 | conservation_status, birdbase, phylacine, quimbayo, pelagic, pottier |
| `corallite_width` | Corallite width (coral) | numeric | mm | 1 | coral_traits |
| `deciduousness` | Leaf deciduousness | categorical | NA | 2 | gift, austraits |
| `depth_max` | Maximum depth | numeric | m | 6 | fishbase, sealifebase, quimbayo, pelagic, coral_traits, octocoral |
| `depth_min` | Minimum depth | numeric | m | 6 | fishbase, sealifebase, quimbayo, pelagic, coral_traits, octocoral |
| `diel_vertical_migration` | Diel vertical migration (zooplankton) | categorical | NA | 1 | zooplankton |
| `diet_breadth` | Diet breadth | numeric | count | 3 | combine, pantheria, birdbase |
| `diet_guild` | Diet guild | categorical | NA | 12 | avonet, elton_traits, repttraits, chelonians, blanchard, parravicini, eurobat, zooplankton, birdbase, arthropod_traits, chowdhury, finand |
| `dispersal_syndrome` | Dispersal syndrome | categorical | NA | 5 | gift, austraits, leda, baseflor, brot |
| `earthworm_ecological_group` | Earthworm ecological group | categorical | NA | 1 | sworm |
| `egg_length` | Egg length | numeric | mm | 3 | amniote, repttraits, chelonians |
| `egg_mass` | Egg mass | numeric | g | 1 | amniote |
| `egg_width` | Egg width | numeric | mm | 3 | amniote, repttraits, chelonians |
| `eive_light` | EIVE light (L) | numeric | 0-10 (EIVE) | 1 | eive |
| `eive_moisture` | EIVE moisture (M) | numeric | 0-10 (EIVE) | 1 | eive |
| `eive_nutrients` | EIVE nutrients (N) | numeric | 0-10 (EIVE) | 1 | eive |
| `eive_reaction` | EIVE reaction (R) | numeric | 0-10 (EIVE) | 1 | eive |
| `eive_temperature` | EIVE temperature (T) | numeric | 0-10 (EIVE) | 1 | eive |
| `elevation_max` | Maximum elevation | numeric | m | 3 | birdbase, repttraits, globtherm |
| `elevation_min` | Minimum elevation | numeric | m | 3 | birdbase, repttraits, globtherm |
| `ellenberg_light` | Ellenberg light (L) | numeric | 1-9 (classic) | 3 | floraweb, ecoflora, bet |
| `ellenberg_moisture` | Ellenberg moisture (F) | numeric | 1-12 (classic) | 3 | floraweb, ecoflora, bet |
| `ellenberg_nitrogen` | Ellenberg nutrients / nitrogen (N) | numeric | 1-9 (classic) | 3 | floraweb, ecoflora, bet |
| `ellenberg_reaction` | Ellenberg reaction (R) | numeric | 1-9 (classic) | 3 | floraweb, ecoflora, bet |
| `ellenberg_salt` | Ellenberg salt (S) | numeric | 0-9 (classic) | 3 | floraweb, ecoflora, baseflor |
| `ellenberg_temperature` | Ellenberg temperature (T) | numeric | 1-9 (classic) | 2 | floraweb, bet |
| `elytra_length` | Elytra length | numeric | mm | 2 | saproxylic, imageomics_neon |
| `elytra_width` | Elytra width | numeric | mm | 1 | imageomics_neon |
| `environmental_impact` | Environmental impact (EICAT) | categorical | NA | 1 | gidias |
| `feeding_guild` | Feeding guild (benthic invertebrate) | categorical | NA | 2 | arctic_traits, nztd |
| `feeding_mode` | Feeding mode (fish) | categorical | NA | 1 | beukhof |
| `flight_mode` | Flight mode (odonate) | categorical | NA | 1 | odonata |
| `flightless` | Flightlessness (bird) | categorical | NA | 1 | birdbase |
| `flower_colour` | Flower colour | categorical | NA | 3 | gift, baseflor, bien |
| `flowering_end` | Flowering end (month) | numeric | month (1-12) | 3 | baseflor, ecoflora, austraits |
| `flowering_start` | Flowering start (month) | numeric | month (1-12) | 3 | baseflor, ecoflora, austraits |
| `foraging_mode` | Foraging mode | categorical | NA | 2 | repttraits, chelonians |
| `forearm_length` | Forearm length | numeric | mm | 3 | combine, pantheria, eurobat |
| `forelimb_length` | Forelimb length | numeric | mm | 1 | huang_amph |
| `freshwater` | Freshwater habitat | categorical | NA | 3 | sealifebase, combine, phylacine |
| `fruit_type` | Fruit type | categorical | NA | 3 | gift, baseflor, austraits |
| `fungal_trophic_mode` | Fungal trophic mode | categorical | NA | 2 | funguild, fungal_traits |
| `gamete_type` | Gamete type (algae) | categorical | NA | 1 | algae_traits |
| `gc_content` | Genome GC content (prokaryote) | numeric | % | 1 | madin |
| `generation_length` | Generation length | numeric | yr | 3 | bet, frugivoria, combine |
| `genome_size` | Genome size (prokaryote) | numeric | bp | 1 | madin |
| `gestation_incubation` | Gestation or incubation length | numeric | days | 4 | anage, combine, pantheria, amniote |
| `gram_stain` | Gram stain (prokaryote) | categorical | NA | 2 | madin, bacdive |
| `growth_form` | Growth form | categorical | NA | 4 | gift, austraits, bien, brot |
| `habitat_breadth` | Habitat breadth | numeric | count | 4 | birdbase, combine, frugivoria, pantheria |
| `hand_wing_index` | Hand-wing index | numeric | index | 1 | avonet |
| `head_length` | Head length | numeric | mm | 2 | huang_amph, saproxylic |
| `head_width` | Head width | numeric | mm | 2 | huang_amph, saproxylic |
| `hindlimb_length` | Hindlimb length | numeric | mm | 1 | huang_amph |
| `home_range` | Home range | numeric | km2 | 3 | combine, homerange, pantheria |
| `huber_value` | Huber value | numeric | index (m2/m2) | 2 | hydraulics, austraits |
| `hunting_guild` | Hunting guild (spider) | categorical | NA | 1 | spider_traits |
| `hydraulic_safety_margin` | Hydraulic safety margin | numeric | MPa | 1 | hydraulics |
| `incubation_period` | Egg incubation period | numeric | days | 2 | amniote, chelonians |
| `interbirth_interval` | Interbirth or inter-litter interval | numeric | yr | 4 | pantheria, combine, amniote, anage |
| `itd` | Inter-tegular distance (bee body size) | numeric | mm | 2 | bee_ostwald, eupolltrait |
| `kipps_distance` | Kipp’s distance | numeric | mm | 1 | avonet |
| `larval_development_mode` | Larval development mode | categorical | NA | 1 | coral_traits |
| `larval_nutrition` | Larval nutrition (bee) | categorical | NA | 1 | eupolltrait |
| `ldmc` | Leaf dry matter content | numeric | mg/g | 4 | leda, gift, brot, diaz_traits |
| `leaf_area` | Leaf area | numeric | mm2 | 3 | austraits, bien, brot |
| `leaf_length` | Leaf length | numeric | mm | 1 | austraits |
| `leaf_lifespan` | Leaf lifespan | numeric | months | 3 | austraits, brot, bien |
| `leaf_n` | Leaf nitrogen per dry mass | numeric | mg/g | 2 | austraits, bien |
| `leaf_p` | Leaf phosphorus per dry mass | numeric | mg/g | 2 | austraits, bien |
| `leaf_specific_conductivity` | Leaf specific hydraulic conductivity | numeric | kg m-1 s-1 MPa-1 | 1 | hydraulics |
| `leaf_thickness` | Leaf thickness | numeric | mm | 2 | bien, gift |
| `leaf_type` | Leaf type | categorical | NA | 2 | austraits, diaz_traits |
| `leaf_width` | Leaf width | numeric | mm | 1 | austraits |
| `lecty` | Pollen host breadth (bee lecty) | categorical | NA | 1 | eupolltrait |
| `lichen_growth_form` | Lichen growth form (thallus) | categorical | NA | 1 | italic |
| `life_form` | Raunkiaer life form | categorical | NA | 3 | gift, ecoflora, floraweb |
| `life_history` | Life history | categorical | NA | 2 | gift, austraits |
| `linear_extension_rate` | Coral linear extension rate | numeric | mm/yr | 1 | coral_traits |
| `living_habit` | Living habit (benthic invertebrate) | categorical | NA | 2 | arctic_traits, nztd |
| `longevity` | Maximum longevity | numeric | yr | 11 | anage, amniote, combine, pantheria, repttraits, chelonians, amphibio, beukhof, fishtraits, eurobat, sheld |
| `male_maturity` | Age at male maturity | numeric | yr | 3 | anage, amniote, combine |
| `marine` | Marine habitat | categorical | NA | 3 | sealifebase, combine, phylacine |
| `mate_guarding` | Mate guarding (odonate) | categorical | NA | 1 | odonata |
| `metabolic_rate` | Metabolic rate | numeric | W | 2 | anage, animaltraits |
| `migration` | Migratory behaviour (bird) | categorical | NA | 1 | avonet |
| `min_water_potential` | Minimum midday water potential | numeric | MPa | 1 | hydraulics |
| `motility` | Motility (prokaryote) | categorical | NA | 2 | madin, bacdive |
| `mouth_position` | Mouth position (fish) | categorical | NA | 1 | quimbayo |
| `mycorrhizal_type` | Mycorrhizal type | categorical | NA | 1 | fungalroot |
| `neonate_mass` | Neonate body mass | numeric | g | 4 | amniote, combine, pantheria, anage |
| `nest_attachment` | Nest attachment (birds) | categorical | NA | 1 | nesttrait |
| `nest_site` | Nest site (birds) | categorical | NA | 1 | nesttrait |
| `nest_structure` | Nest structure (birds) | categorical | NA | 1 | nesttrait |
| `nesting_strategy` | Nesting strategy (bee) | categorical | NA | 1 | eupolltrait |
| `nitrogen_fixation` | Root-nodule nitrogen fixation | categorical | NA | 1 | noddb |
| `optimal_growth_ph` | Optimal growth pH (prokaryote) | numeric | pH | 2 | madin, bacdive |
| `optimal_growth_temperature` | Optimal growth temperature (prokaryote) | numeric | deg C | 2 | madin, bacdive |
| `oral_gape_position` | Oral gape position (fish) | numeric | index | 1 | fishmorph |
| `oxygen_metabolism` | Oxygen metabolism (prokaryote) | categorical | NA | 2 | madin, bacdive |
| `p50` | Xylem embolism resistance (P50) | numeric | MPa | 3 | hydraulics, austraits, brot |
| `parental_care` | Parental care (fish) | categorical | NA | 1 | beukhof |
| `pectoral_fin_position` | Pectoral fin position (fish) | numeric | index | 1 | fishmorph |
| `pectoral_fin_size` | Pectoral fin size (fish) | numeric | index | 1 | fishmorph |
| `photobiont` | Lichen photobiont | categorical | NA | 1 | italic |
| `photosynthetic_pathway` | Photosynthetic pathway | categorical | NA | 3 | gift, austraits, ecoflora |
| `plant_height` | Plant height | numeric | m | 5 | gift, diaz, austraits, bien, brot |
| `plant_lifespan` | Whole-plant lifespan | numeric | yr | 3 | bien, gift, austraits |
| `pollination_vector` | Pollination vector | categorical | NA | 4 | baseflor, ecoflora, floraweb, austraits |
| `polyp_retractability` | Polyp retractability | categorical | NA | 1 | octocoral |
| `population_density` | Population density | numeric | individuals/km2 | 3 | pantheria, combine, tetradensity |
| `primary_habitat` | Primary habitat | categorical | NA | 3 | birdbase, chowdhury, finand |
| `pronotum_length` | Pronotum length | numeric | mm | 1 | saproxylic |
| `range_size` | Geographic range size | numeric | km2 | 3 | avonet, chelonians, coral_traits |
| `relative_eye_size` | Relative eye size (fish) | numeric | index | 1 | fishmorph |
| `relative_maxillary_length` | Relative maxillary length (fish) | numeric | index | 1 | fishmorph |
| `reproductive_frequency` | Litters or clutches per year | numeric | per year | 6 | amniote, combine, anage, pantheria, repttraits, chelonians |
| `reproductive_mode` | Reproductive (parity) mode | categorical | NA | 2 | repttraits, sharkipedia |
| `reproductive_strategy` | Reproductive strategy (sexual / asexual) | categorical | NA | 1 | italic |
| `resprouting` | Resprouting after fire | categorical | NA | 2 | austraits, brot |
| `root_diameter` | Root diameter | numeric | mm | 2 | groot, austraits |
| `root_dry_matter_content` | Root dry matter content | numeric | g/g | 2 | groot, austraits |
| `root_mass_fraction` | Root mass fraction | numeric | g/g | 2 | groot, austraits |
| `root_mycorrhizal_colonization` | Root mycorrhizal colonization | numeric | percent | 1 | groot |
| `root_n_concentration` | Root nitrogen concentration | numeric | mg/g | 2 | groot, austraits |
| `root_tissue_density` | Root tissue density | numeric | g/cm3 | 1 | groot |
| `rooting_depth` | Rooting depth | numeric | m | 2 | groot, brot |
| `sapwood_conductivity` | Sapwood specific hydraulic conductivity | numeric | kg m-1 s-1 MPa-1 | 2 | hydraulics, austraits |
| `secondary1` | First-secondary length | numeric | mm | 1 | avonet |
| `seed_length` | Seed length | numeric | mm | 4 | austraits, leda, gift, bien |
| `seed_mass` | Seed mass | numeric | mg | 8 | diaz, gift, austraits, bien, brot, ecoflora, kew_sid, leda |
| `self_compatibility` | Self-compatibility | categorical | NA | 1 | tree_of_sex |
| `serotiny` | Serotiny | categorical | NA | 1 | austraits |
| `sexual_system` | Sexual system | categorical | NA | 6 | tree_of_sex, austraits, bet, coral_traits, octocoral, sheld |
| `shoot_length` | Shoot length | numeric | mm | 1 | bet |
| `skeletal_rigidity` | Skeletal rigidity (octocoral) | categorical | NA | 1 | octocoral |
| `sla` | Specific leaf area | numeric | mm2/mg | 4 | leda, gift, bien, brot |
| `sociality` | Sociality (bee) | categorical | NA | 1 | eupolltrait |
| `socioeconomic_impact` | Socio-economic impact (SEICAT) | categorical | NA | 1 | gidias |
| `soil_seed_bank` | Soil seed-bank persistence | categorical | NA | 2 | austraits, brot |
| `specific_root_area` | Specific root area | numeric | cm2/g | 1 | groot |
| `specific_root_length` | Specific root length | numeric | m/g | 2 | groot, austraits |
| `spore_diameter` | Spore diameter | numeric | um | 1 | bet |
| `sporulation` | Sporulation (prokaryote) | categorical | NA | 1 | madin |
| `substrate` | Substrate | categorical | NA | 2 | italic, bet |
| `substrate_attachment` | Substrate attachment | categorical | NA | 1 | coral_traits |
| `tail_length` | Tail length | numeric | mm | 1 | avonet |
| `tarsus_length` | Tarsus length | numeric | mm | 1 | avonet |
| `teat_number` | Teat or nipple number | numeric | count | 2 | pantheria, combine |
| `territoriality` | Territoriality (odonate) | categorical | NA | 1 | odonata |
| `thermal_max` | Upper thermal limit | numeric | deg C | 3 | globtherm, pottier, thermofresh |
| `thermal_min` | Lower thermal limit | numeric | deg C | 2 | globtherm, thermofresh |
| `tongue_length` | Tongue length (bee) | numeric | mm | 2 | bee_ostwald, eupolltrait |
| `trophic_level` | Trophic level | numeric | trophic level (~1-5) | 6 | fishbase, beukhof, quimbayo, pelagic, arctic_traits, sealifebase |
| `turgor_loss_point` | Leaf turgor loss point | numeric | MPa | 1 | austraits |
| `venomous` | Venomous (reptile) | categorical | NA | 1 | repttraits |
| `vertical_eye_position` | Vertical eye position (fish) | numeric | index | 1 | fishmorph |
| `voltinism` | Voltinism (generations per year) | numeric | per year | 2 | arthropod_traits, eupolltrait |
| `von_bertalanffy_k` | Von Bertalanffy growth coefficient (K) | numeric | per yr | 2 | beukhof, sharkipedia |
| `von_bertalanffy_linf` | Von Bertalanffy asymptotic length (Linf) | numeric | cm | 2 | beukhof, sharkipedia |
| `vulnerability` | Vulnerability to fishing | numeric | 0-100 index | 3 | fishbase, sealifebase, quimbayo |
| `water_clarity` | Water clarity preference | categorical | NA | 2 | coral_traits, octocoral |
| `wave_exposure` | Wave exposure preference | categorical | NA | 2 | coral_traits, octocoral |
| `weaning_age` | Weaning age | numeric | days | 3 | amniote, anage, pantheria |
| `web_building` | Web building (spider) | categorical | NA | 1 | spider_traits |
| `wing_length` | Wing length | numeric | mm | 2 | avonet, saproxylic |
| `wing_morph` | Wing morphology | categorical | NA | 3 | chowdhury, finand, alpine_carabids |
| `wingspan` | Wingspan (butterfly) | numeric | mm | 1 | leptraits |
| `wood_density` | Wood density | numeric | g/cm3 | 5 | gwdd, austraits, bien, gift, leda |
| `woodiness` | Woodiness | categorical | NA | 4 | zanne, gift, austraits, bien |
| `zooxanthellate` | Zooxanthellate symbiosis (coral) | categorical | NA | 2 | coral_traits, octocoral |
