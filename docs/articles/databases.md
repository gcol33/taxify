# Databases: every backbone, enrichment, and trait

taxify resolves names against local taxonomic **backbones** and joins
external **enrichment** datasets that carry **traits**. This page lists
all three, straight from the manifest this version ships. In an R
session, the same content is one call away:

``` r

taxify_databases()   # backbones + enrichments in one frame
list_backbones()     # the taxonomic backbones
list_enrichments()   # the trait / status datasets
list_traits()        # the cross-source trait vocabulary add_trait() draws on
```

## Taxonomic backbones

Each is a pre-built `.vtr` downloaded once and matched locally. Pass
several to
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md) and
they form a fallback chain.

| Backbone | Scope | Names | MB | Version |  |
|:---|:---|---:|---:|:---|:---|
| wfo | Vascular plants | 1,638,552 | 726 | 2026.08 | [source](https://www.worldfloraonline.org/) |
| col | All kingdoms | 5,302,873 | 1,875 | 2026.08 | [source](https://www.catalogueoflife.org/) |
| colxr | All kingdoms | 7,871,065 | 1,491 | 2026.08 | [source](https://www.catalogueoflife.org/) |
| gbif | All kingdoms | 6,404,001 | 1,555 | 2026.08 | [source](https://www.gbif.org/) |
| itis | US focus, freshwater/marine | 993,346 | 195 | 2026.08 | [source](https://www.itis.gov) |
| ncbi | All life | 2,848,102 | 506 | 2026.08 | [source](https://www.ncbi.nlm.nih.gov/taxonomy) |
| ott | All life (synthetic) | 3,690,217 | 728 | 2026.08 | [source](https://opentreeoflife.github.io/) |
| worms | Marine/aquatic | 1,562,065 | 298 | 2026.08 | [source](https://www.marinespecies.org/) |
| euromed | European/Mediterranean plants | 146,922 | 33 | 2026.08 | [source](https://europlusmed.org/) |
| fungorum | Fungi | 315,037 | 68 | 2026.08 | [source](https://www.speciesfungorum.org/) |
| algaebase | Algae | 172,351 | 34 | 2026.08 | [source](https://www.algaebase.org/) |
| fishbase | Fishes | 102,703 | 18 | 2026.08 | [source](https://www.fishbase.org/) |
| sealifebase | Non-fish marine/aquatic | 134,031 | 27 | 2026.08 | [source](https://www.sealifebase.org/) |
| reptiledb | Reptiles | 50,043 | 9 | 2026.07 | [source](http://www.reptile-database.org/) |
| lcvp | Vascular plants | 1,337,891 | 241 | 2026.08 | [source](https://github.com/idiv-biodiversity/LCVP) |
| wcvp | Vascular plants | 1,448,984 | 295 | 2026.08 | [source](https://powo.science.kew.org/) |
| mdd | Mammals | 61,862 | 10 | 2026.08 | [source](https://www.mammaldiversity.org/) |
| avilist | Birds | 40,572 | 8 | 2026.08 | [source](https://www.avilist.org/) |
| lpsn | Prokaryotes (Bacteria/Archaea) | 44,885 | 12 | 2026.08 | [source](https://lpsn.dsmz.de) |

## Enrichment datasets

Each `add_<source>()` door joins one dataset to a
[`taxify()`](https://gillescolling.com/taxify/reference/taxify.md)
result on the accepted name.
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
gathers a single trait across every source that carries it. Browse a
dataset’s columns in R with `enrichment_cols("<name>")`.

| Enrichment | Version | Rows | Columns |  |
|:---|:---|---:|---:|:---|
| algae_traits | 2026.08 | 2,979 | 47 | [source](https://mda.vliz.be/download.php?file=VLIZ_00000308_62bf06138859e409561556) |
| alien_first_records | 2026.08 | 82,684 | 20 | [source](https://zenodo.org/records/10039630/files/GlobalAlienSpeciesFirstRecordDatabase_v3.1_freedata.xlsx) |
| alpine_carabids | 2026.08 | 213 | 2 | [source](https://doi.org/10.5061/dryad.fn2z34tq1) |
| amniote | 2026.08 | 23,651 | 34 | [source](https://ndownloader.figshare.com/files/8067269) |
| amphibio | 2026.08 | 7,805 | 35 | [source](https://ndownloader.figshare.com/files/8828578) |
| anage | 2026.08 | 5,080 | 29 | [source](https://genomics.senescence.info/species/dataset.zip) |
| animaltraits | 2026.08 | 2,240 | 41 | [source](https://zenodo.org/record/6468938/files/observations.csv?download=1) |
| arctic_traits | 2026.08 | 460 | 20 | [source](https://phaidra.univie.ac.at/api/object/o:861474/octets) |
| arthropod_traits | 2026.08 | 5,338 | 28 | [source](https://ipt.biodiversity.be/archive.do?r=arthropod-trait-dataset&v=1.1) |
| austraits | 2026.08 | 36,039 | 530 | [source](https://zenodo.org/api/records/15718081/files/austraits-7.0.0.zip/content) |
| avonet | 2026.08 | 12,543 | 36 | [source](https://ndownloader.figshare.com/files/34480856) |
| bacdive | 2026.08 | 19,918 | 8 | [source](https://github.com/gcol33/taxifydb/releases/download/crawl-snapshots-2026.07/bacdive.jsonl.gz) |
| baseflor | 2026.08 | 9,021 | 55 | [source](http://web.archive.org/web/20231002005253id_/https://philippe.julve.pagesperso-orange.fr/baseflor.xlsx) |
| bee_ostwald | 2026.08 | 2,053 | 14 | [source](https://zenodo.org/records/13366989/files/Sup%20Table%204%20Morphological%20Dataset%20Revised.csv?download=1) |
| bet | 2026.08 | 2,045 | 97 | [source](https://www.envidat.ch/dataset/4865a082-169d-40d1-920b-fc20ad0acad2/resource/d2d2f958-051c-4638-a808-88547cc64d92/download/betdata.txt) |
| betsi_collembola_body_length | 2026.08 | 1,374 | 5 | [source](https://zenodo.org/api/records/1292461/files/BETSI_Trait%20data%20request_Collembola_Body%20length_01062017.xlsx/content) |
| betsi_collembola_traits | 2026.08 | 34 | 9 | [source](https://doi.org/10.1002/eap.70034) |
| betsi_earthworm_traits | 2026.08 | 13 | 22 | [source](https://doi.org/10.1016/j.apsoil.2013.10.005) |
| beukhof | 2026.08 | 1,796 | 37 | [source](https://doi.pangaea.de/10.1594/PANGAEA.900866?format=textfile) |
| bien | 2026.08 | 122,749 | 52 | [source](https://bien.nceas.ucsb.edu) |
| birdbase | 2026.08 | 13,174 | 95 | [source](https://ndownloader.figshare.com/files/55634729) |
| blanchard | 2026.08 | 334 | 19 | [source](https://doi.org/10.5061/dryad.st6sc) |
| brot | 2026.08 | 3,045 | 44 | [source](https://api.figshare.com/v2/articles/5280868) |
| cefas_btrait | 2026.08 | 951 | 10 | [source](https://data-api.cefas.co.uk/api/export/11935?format=csv) |
| chelonians | 2026.08 | 363 | 79 | [source](https://ndownloader.figshare.com/files/53840531) |
| chowdhury | 2026.08 | 415 | 10 | [source](https://onlinelibrary.wiley.com/doi/10.1111/ddi.70112) |
| combine | 2026.08 | 7,027 | 57 | [source](https://ndownloader.figshare.com/files/27703263) |
| combine_imputed | 2026.08 | 7,027 | 69 | [source](https://ndownloader.figshare.com/files/27703266) |
| common_names | 2026.08 | 713,596 | 3 | [source](https://hosted-datasets.gbif.org/datasets/backbone/current/backbone.zip%20;%20https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz%20;%20https://files.opentreeoflife.org/ott/ott3.7.3/ott3.7.3.tgz) |
| copepod_traits | 2026.08 | 1,524 | 17 | [source](https://store.pangaea.de/Publications/BrunP-etal_2016/Brun-etal_2016_Copepode_trait.xlsx) |
| coral_traits | 2026.08 | 1,828 | 107 | [source](https://ndownloader.figshare.com/files/3678603) |
| diaz_traits | 2026.08 | 54,002 | 29 | [source](https://raw.githubusercontent.com/kydahl/biodiv-hotspots/main/data/raw/Trait_data_TRY_Diaz_2022/Dataset/Species_mean_traits.xlsx) |
| disperse | 2026.08 | 465 | 12 | [source](https://api.figshare.com/v2/articles/12417251) |
| eberswalde | 2026.08 | 30 | 8 | [source](https://pubdata.leuphana.de/server/api/core/bitstreams/1abc1f9b-d416-4ec8-8139-a3730724e77c/content) |
| ecoflora | 2026.08 | 3,243 | 18 | [source](https://github.com/gcol33/taxifydb/releases/download/scrape-snapshots-2026.06/ecoflora_raw_2026-06-23.csv) |
| ecomorphosis | 2026.08 | 49 | 3 | [source](https://zenodo.org/api/records/7194559/files/Annex_ASE_Online_db.xlsx/content) |
| edwards_phyto | 2026.08 | 177 | 33 | [source](https://esapubs.org/archive/ecol/E096/202/) |
| eive | 2026.08 | 17,876 | 18 | [source](https://zenodo.org/records/7534792/files/EIVE_Paper_1.0_SM_08.xlsx?download=1) |
| ellers_collembola | 2026.08 | 314 | 6 | [source](https://zenodo.org/api/records/4934993/files/Collembola_trait_data.csv/content) |
| elton_traits | 2026.08 | 17,839 | 48 | [source](https://ndownloader.figshare.com/files/5631081) |
| epa_freshwater | 2026.08 | 2,782 | 9 | [source](https://ofmpub.epa.gov/eims/eimscomm.getfile?p_download_id=526642) |
| eupolltrait | 2026.08 | 3,271 | 39 | [source](https://zenodo.org/api/records/18032357) |
| eurobat | 2026.08 | 52 | 62 | [source](https://api.figshare.com/v2/articles/21777161) |
| faprotax | 2026.08 | 4,967 | 2 | [source](https://pages.uoregon.edu/slouca/LoucaLab/archive/FAPROTAX/SECTION_Download/MODULE_Downloads/CLASS_Latest%20release/UNIT_FAPROTAX_1.2.12/FAPROTAX_1.2.12.zip) |
| finand | 2026.08 | 40 | 5 | [source](https://zenodo.org/api/records/17184995/files/Species_traits_zenodo.xlsx/content) |
| fishbase | 2026.08 | 37,906 | 239 | [source](https://fishbase.ropensci.org) |
| fishmorph | 2026.08 | 9,160 | 15 | [source](https://ndownloader.figshare.com/files/28672242) |
| fishtraits | 2026.08 | 883 | 28 | [source](https://www.sciencebase.gov/catalog/file/get/5a7c6e8ce4b00f54eb2318c0?name=FishTraits_14.3.xls) |
| floraweb | 2026.08 | 5,964 | 59 | [source](https://github.com/gcol33/taxifydb/releases/download/scrape-snapshots-2026.06/floraweb_raw_2026-06-24.csv) |
| freshwater_insects_conus | 2026.08 | 1,033 | 14 | [source](https://pasta.lternet.edu/package/data/eml/edi/481/5/3a88bfdfefcfe6dcafb27afd3ce4e90c) |
| frugivoria | 2026.08 | 1,954 | 60 | [source](https://pasta.lternet.edu/package/data/eml/edi/1220/5/) |
| fungal_traits | 2026.08 | 11,058 | 24 | [source](https://static-content.springer.com/esm/art%3A10.1007%2Fs13225-020-00466-2/MediaObjects/13225_2020_466_MOESM4_ESM.xlsx) |
| fungalroot | 2026.08 | 4,203 | 18 | [source](https://orphans.gbif.org/EE/744edc21-8dd2-474e-8a0b-b8c3d56a3c2d.232.zip) |
| funguild | 2026.08 | 16,104 | 9 | [source](http://www.stbates.org/funguild_db_2.php) |
| gidias | 2026.08 | 6,219 | 15 | [source](https://ndownloader.figshare.com/files/53894801) |
| gift | 2026.08 | 290,605 | 109 | [source](https://gift.uni-goettingen.de) |
| globi | 2026.08 | 543,692 | 3 | [source](https://github.com/gcol33/taxifydb/releases/download/crawl-snapshots-2026.07/globi_edges.tsv.gz) |
| globtherm | 2026.08 | 2,393 | 42 | [source](https://doi.org/10.5061/dryad.1cv08) |
| glonaf | 2026.08 | 10,238 | 9 | [source](https://zenodo.org/api/records/13235357) |
| griis | 2026.08 | 114,186 | 15 | [source](https://zenodo.org/records/6348164/files/GRIIS%20-%20Country%20Compendium%20V1_0.csv?download=1) |
| groot | 2026.08 | 7,708 | 38 | [source](https://raw.githubusercontent.com/GRooT-Database/GRooT-Data/master/DataFiles/GRooTAggregateSpeciesVersion.zip) |
| gwdd | 2026.08 | 18,922 | 15 | [source](https://zenodo.org/api/records/18262736/files/gwddagg_v2.2_species.csv/content) |
| homerange | 2026.08 | 1,091 | 35 | [source](https://doi.org/10.5061/dryad.d2547d85x) |
| hosts | 2026.08 | 19,087 | 2 | [source](https://data.nhm.ac.uk/dataset/hosts-a-database-of-the-world-s-lepidopteran-hostplants) |
| huang_amph | 2026.08 | 4,776 | 85 | [source](https://api.figshare.com/v2/articles/21159229) |
| hydraulics | 2026.08 | 2,318 | 7 | [source](https://ndownloader.figshare.com/files/23745155) |
| imageomics_neon | 2026.08 | 79 | 3 | [source](https://huggingface.co/datasets/imageomics/2018-NEON-beetles/resolve/main/BeetleMeasurements.csv) |
| inrae_collembola_traits | 2026.08 | 160 | 16 | [source](https://doi.org/10.15454/UU2FQT%20;%20https://doi.org/10.15454/UCYSLH) |
| invacost | 2026.08 | 927 | 3 | [source](https://ndownloader.figshare.com/files/33669518) |
| italic | 2026.08 | 3,580 | 4 | [source](https://github.com/gcol33/taxifydb/releases/download/crawl-snapshots-2026.07/italic.jsonl) |
| iucn | 2026.08 | 192,708 | 1 | [source](https://hosted-datasets.gbif.org/datasets/iucn/iucn-latest.zip) |
| kew_cvalues | 2026.08 | 14,259 | 14 | [source](https://cvalues.science.kew.org/search) |
| kew_sid | 2026.08 | 52,156 | 7 | [source](https://ser-sid.org/) |
| leda | 2026.08 | 14,834 | 25 | [source](https://uol.de/f/5/inst/biologie/ag/landeco/download/LEDA/Data_files/) |
| leptraits | 2026.08 | 13,594 | 40 | [source](https://raw.githubusercontent.com/RiesLabGU/LepTraits/main/consensus/consensus.csv) |
| madin | 2026.08 | 16,771 | 76 | [source](https://raw.githubusercontent.com/bacteria-archaea-traits/bacteria-archaea-traits/master/output/condensed_species_NCBI.csv) |
| marine_distribution | 2026.08 | 1,941,227 | 4 | [source](https://github.com/gcol33/taxifydb/releases/download/marine-snapshots-2026.07/worms_distributions.jsonl%20;%20https://github.com/gcol33/taxifydb/releases/download/marine-snapshots-2026.07/mrgid_meow.tsv) |
| monograph_collembola_body_length | 2026.08 | 534 | 5 | [source](https://github.com/gcol33/taxifydb/releases/download/monograph-snapshots-2026.08/collembola_monograph_bodylength_2026-08-05.csv) |
| nesttrait | 2026.08 | 12,721 | 34 | [source](https://zenodo.org/records/10128906/files/NestTrait_v2.csv?download=1) |
| noddb | 2026.08 | 852 | 9 | [source](https://s3.hpc.ut.ee/plutof-public/original/3094fbed-e384-457d-af3f-694ef97e8df8.xlsx) |
| nztd | 2026.08 | 321 | 18 | [source](https://api.figshare.com/v2/articles/21939647) |
| octocoral | 2026.08 | 3,638 | 127 | [source](https://zenodo.org/records/14228404/files/OctocoralTraits_v2_2.zip?download=1) |
| odonata | 2026.08 | 1,486 | 36 | [source](https://doi.org/10.5061/dryad.15pm5qc) |
| pantheria | 2026.08 | 6,152 | 53 | [source](https://esapubs.org/archive/ecol/E090/184/PanTHERIA_1-0_WR05_Aug2008.txt) |
| parravicini | 2026.08 | 6,934 | 34 | [source](https://raw.githubusercontent.com/valerianoparravicini/Trophic_Fish_2020/master/data/converted_experts_classification.csv) |
| pelagic | 2026.08 | 592 | 57 | [source](https://borealisdata.ca/api/datasets/:persistentId?persistentId=doi:10.5683/SP3/0YFJED) |
| phylacine | 2026.08 | 6,603 | 24 | [source](https://raw.githubusercontent.com/MegaPast2Future/PHYLACINE_1.2/master/Data/Traits/Trait_data.csv) |
| plazi_collembola_body_length | 2026.08 | 1,049 | 5 | [source](https://api.gbif.org/v1/dataset/search?publishingOrg=7ce8aef0-9e92-11dc-8738-b8a03c50a862&taxonKey=10713444) |
| pottier | 2026.08 | 667 | 77 | [source](https://zenodo.org/api/records/6565454) |
| quimbayo | 2026.08 | 2,297 | 60 | [source](https://zenodo.org/api/records/4455016) |
| ramond | 2026.08 | 1,217 | 32 | [source](https://www.seanoe.org/data/00405/51662/) |
| repttraits | 2026.08 | 12,203 | 47 | [source](https://ndownloader.figshare.com/files/45408133) |
| rimet_phyto | 2026.08 | 1,493 | 62 | [source](https://zenodo.org/records/1164834/files/Appendix-1-Phytoplankton%20metrics%20database-revised.xlsx?download=1) |
| saproxylic | 2026.08 | 1,268 | 57 | [source](https://doi.org/10.5061/dryad.2fqz612p3) |
| sealifebase | 2026.08 | 117,663 | 250 | [source](https://sealifebase.ropensci.org) |
| sharkipedia | 2026.08 | 179 | 52 | [source](https://zenodo.org/records/6656525/files/Sharkipedia-Traits-v1.0-22-01-25.csv?download=1) |
| sheld | 2026.08 | 314 | 105 | [source](https://api.figshare.com/v2/articles/24115998) |
| spider_traits | 2026.08 | 9,346 | 11 | [source](https://spidertraits.sci.muni.cz/backend/data/export/csv/family/*/genus/*/species/*/original-name/*/trait-category/*/trait/*/method/*/location/*/country/*/dataset/*/authors/*/reference/*/row-link/*) |
| sworm | 2026.08 | 214 | 1 | [source](https://idata.idiv.de/ddm/Data/DownloadZip/1880?version=4881) |
| tetradensity | 2026.08 | 1,935 | 16 | [source](https://api.figshare.com/v2/articles/5371633) |
| thermofresh | 2026.08 | 750 | 5 | [source](https://zenodo.org/api/records/14056760/files/hsbayat%2FFreshwater_thermtol_db-data.zip/content) |
| tree_of_sex | 2026.08 | 40,575 | 68 | [source](https://doi.org/10.5061/dryad.v1908) |
| usda_fungus_host | 2026.08 | 73,592 | 2 | [source](https://api.figshare.com/v2/articles/24855585) |
| useful_plants | 2026.08 | 43,743 | 11 | [source](https://knb.ecoinformatics.org/knb/d1/mn/v2/object/urn:uuid:e576e4b7-845a-422a-8472-b5eb078e08eb) |
| virion | 2026.08 | 4,547 | 4 | [source](https://zenodo.org/api/records/21636520) |
| wcvp | 2026.08 | 2,190,037 | 29 | [source](https://sftp.kew.org/pub/data-repositories/WCVP/wcvp.zip) |
| zanne | 2026.08 | 56,091 | 2 | [source](https://raw.githubusercontent.com/ejedwards/reanalysis_zanne2014/master/dryad/GlobalWoodinessDatabase.csv) |
| zooplankton | 2026.08 | 4,233 | 86 | [source](https://zenodo.org/api/records/8102913) |

## Cross-source traits

Name one trait;
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
finds and harmonizes it from the sources below.

| Trait | Label | Kind | Unit | Sources | From |
|:---|:---|:---|:---|---:|:---|
| activity_time | Diel activity time | categorical | NA | 6 | repttraits, chelonians, quimbayo, combine, pantheria, spider_traits |
| age_at_first_reproduction | Age at first reproduction | numeric | yr | 1 | combine |
| age_at_maturity | Age at female maturity | numeric | yr | 7 | anage, amniote, amphibio, chelonians, beukhof, fishtraits, sheld |
| air_breathing | Air breathing (fish) | categorical | NA | 1 | fishbase |
| algal_life_cycle | Life-cycle ploidy phase (algae) | categorical | NA | 1 | algae_traits |
| algal_substrate | Attachment substrate (algae) | categorical | NA | 1 | algae_traits |
| antenna_length | Antenna length | numeric | mm | 1 | saproxylic |
| aspect_ratio | Caudal fin aspect ratio | numeric | index | 2 | beukhof, quimbayo |
| bark_thickness | Bark thickness | numeric | mm | 1 | austraits |
| beak_depth | Beak depth | numeric | mm | 1 | avonet |
| beak_length | Beak length (culmen) | numeric | mm | 1 | avonet |
| beak_width | Beak width | numeric | mm | 1 | avonet |
| bioluminescence | Bioluminescence (zooplankton) | categorical | NA | 1 | zooplankton |
| bioturbation | Bioturbation mode (benthic invertebrate) | categorical | NA | 2 | arctic_traits, nztd |
| body_elongation | Body elongation (fish) | numeric | index | 1 | fishmorph |
| body_lateral_shape | Body lateral shape (fish) | numeric | index | 1 | fishmorph |
| body_length | Body length | numeric | mm | 19 | combine, amniote, repttraits, amphibio, fishbase, sealifebase, huang_amph, pottier, spider_traits, zooplankton, sheld, chowdhury, finand, alpine_carabids, betsi_collembola_body_length, plazi_collembola_body_length, monograph_collembola_body_length, ellers_collembola, betsi_collembola_traits |
| body_mass | Body mass | numeric | g | 15 | combine, amniote, pantheria, elton_traits, avonet, anage, phylacine, repttraits, fishbase, sealifebase, frugivoria, pottier, animaltraits, homerange, eurobat |
| body_shape | Body shape (fish) | categorical | NA | 3 | beukhof, quimbayo, pelagic |
| brain_mass | Brain mass | numeric | g | 2 | combine, animaltraits |
| bryophyte_life_form | Bryophyte life form | categorical | NA | 1 | bet |
| calcification | Calcification (algae) | categorical | NA | 1 | algae_traits |
| carapace_length | Carapace length (turtle) | numeric | mm | 1 | chelonians |
| caudal_fin_shape | Caudal fin shape (fish) | categorical | NA | 2 | beukhof, quimbayo |
| caudal_peduncle_throttling | Caudal peduncle throttling (fish) | numeric | index | 1 | fishmorph |
| cell_biovolume | Cell biovolume (microalgae) | numeric | um3 | 1 | rimet_phyto |
| cell_length | Cell length | numeric | um | 2 | rimet_phyto, bacdive |
| cell_shape | Cell shape (prokaryote) | categorical | NA | 2 | madin, bacdive |
| cell_surface_area | Cell surface area (microalgae) | numeric | um2 | 1 | rimet_phyto |
| cell_thickness | Cell thickness (microalgae) | numeric | um | 1 | rimet_phyto |
| cell_width | Cell width | numeric | um | 2 | rimet_phyto, bacdive |
| chromosome_number | Chromosome number (2n) | numeric | count | 1 | kew_cvalues |
| climatic_temp_max | Warmest-month temperature of range | numeric | deg C | 1 | fishtraits |
| climatic_temp_mean | Mean annual temperature of range | numeric | deg C | 3 | arthropod_traits, repttraits, hydraulics |
| climatic_temp_min | Coldest-month temperature of range | numeric | deg C | 1 | fishtraits |
| clutch_litter_size | Clutch or litter size | numeric | offspring per clutch/litter | 10 | amniote, combine, pantheria, anage, repttraits, amphibio, chelonians, birdbase, eurobat, zooplankton |
| coloniality | Coloniality | categorical | NA | 2 | coral_traits, octocoral |
| colony_diameter | Colony maximum diameter (coral) | numeric | cm | 1 | coral_traits |
| colony_growth_form | Colony growth form (octocoral) | categorical | NA | 1 | octocoral |
| colour_lightness | Body colour lightness (beetle) | numeric | index | 1 | saproxylic |
| conservation_status | IUCN Red List status | categorical | NA | 6 | conservation_status, birdbase, phylacine, quimbayo, pelagic, pottier |
| corallite_width | Corallite width (coral) | numeric | mm | 1 | coral_traits |
| deciduousness | Leaf deciduousness | categorical | NA | 2 | gift, austraits |
| depth_max | Maximum depth | numeric | m | 6 | fishbase, sealifebase, quimbayo, pelagic, coral_traits, octocoral |
| depth_min | Minimum depth | numeric | m | 6 | fishbase, sealifebase, quimbayo, pelagic, coral_traits, octocoral |
| diel_vertical_migration | Diel vertical migration (zooplankton) | categorical | NA | 1 | zooplankton |
| diet_breadth | Diet breadth | numeric | count | 3 | combine, pantheria, birdbase |
| diet_guild | Diet guild | categorical | NA | 12 | avonet, elton_traits, repttraits, chelonians, blanchard, parravicini, eurobat, zooplankton, birdbase, arthropod_traits, chowdhury, finand |
| dispersal_syndrome | Dispersal syndrome | categorical | NA | 5 | gift, austraits, leda, baseflor, brot |
| earthworm_ecological_group | Earthworm ecological group | categorical | NA | 1 | sworm |
| egg_length | Egg length | numeric | mm | 3 | amniote, repttraits, chelonians |
| egg_mass | Egg mass | numeric | g | 1 | amniote |
| egg_width | Egg width | numeric | mm | 3 | amniote, repttraits, chelonians |
| eive_light | EIVE light (L) | numeric | 0-10 (EIVE) | 1 | eive |
| eive_moisture | EIVE moisture (M) | numeric | 0-10 (EIVE) | 1 | eive |
| eive_nutrients | EIVE nutrients (N) | numeric | 0-10 (EIVE) | 1 | eive |
| eive_reaction | EIVE reaction (R) | numeric | 0-10 (EIVE) | 1 | eive |
| eive_temperature | EIVE temperature (T) | numeric | 0-10 (EIVE) | 1 | eive |
| elevation_max | Maximum elevation | numeric | m | 3 | birdbase, repttraits, globtherm |
| elevation_min | Minimum elevation | numeric | m | 3 | birdbase, repttraits, globtherm |
| ellenberg_light | Ellenberg light (L) | numeric | 1-9 (classic) | 3 | floraweb, ecoflora, bet |
| ellenberg_moisture | Ellenberg moisture (F) | numeric | 1-12 (classic) | 3 | floraweb, ecoflora, bet |
| ellenberg_nitrogen | Ellenberg nutrients / nitrogen (N) | numeric | 1-9 (classic) | 3 | floraweb, ecoflora, bet |
| ellenberg_reaction | Ellenberg reaction (R) | numeric | 1-9 (classic) | 3 | floraweb, ecoflora, bet |
| ellenberg_salt | Ellenberg salt (S) | numeric | 0-9 (classic) | 3 | floraweb, ecoflora, baseflor |
| ellenberg_temperature | Ellenberg temperature (T) | numeric | 1-9 (classic) | 2 | floraweb, bet |
| elytra_length | Elytra length | numeric | mm | 2 | saproxylic, imageomics_neon |
| elytra_width | Elytra width | numeric | mm | 1 | imageomics_neon |
| environmental_impact | Environmental impact (EICAT) | categorical | NA | 1 | gidias |
| feeding_guild | Feeding guild (benthic invertebrate) | categorical | NA | 2 | arctic_traits, nztd |
| feeding_mode | Feeding mode (fish) | categorical | NA | 1 | beukhof |
| flight_mode | Flight mode (odonate) | categorical | NA | 1 | odonata |
| flightless | Flightlessness (bird) | categorical | NA | 1 | birdbase |
| flower_colour | Flower colour | categorical | NA | 3 | gift, baseflor, bien |
| flowering_end | Flowering end (month) | numeric | month (1-12) | 3 | baseflor, ecoflora, austraits |
| flowering_start | Flowering start (month) | numeric | month (1-12) | 3 | baseflor, ecoflora, austraits |
| foraging_mode | Foraging mode | categorical | NA | 2 | repttraits, chelonians |
| forearm_length | Forearm length | numeric | mm | 3 | combine, pantheria, eurobat |
| forelimb_length | Forelimb length | numeric | mm | 1 | huang_amph |
| freshwater | Freshwater habitat | categorical | NA | 3 | sealifebase, combine, phylacine |
| fruit_type | Fruit type | categorical | NA | 3 | gift, baseflor, austraits |
| fungal_trophic_mode | Fungal trophic mode | categorical | NA | 2 | funguild, fungal_traits |
| gamete_type | Gamete type (algae) | categorical | NA | 1 | algae_traits |
| gc_content | Genome GC content (prokaryote) | numeric | % | 1 | madin |
| generation_length | Generation length | numeric | yr | 3 | bet, frugivoria, combine |
| genome_size | Genome size (prokaryote) | numeric | bp | 1 | madin |
| gestation_incubation | Gestation or incubation length | numeric | days | 4 | anage, combine, pantheria, amniote |
| gram_stain | Gram stain (prokaryote) | categorical | NA | 2 | madin, bacdive |
| growth_form | Growth form | categorical | NA | 4 | gift, austraits, bien, brot |
| habitat_breadth | Habitat breadth | numeric | count | 4 | birdbase, combine, frugivoria, pantheria |
| hand_wing_index | Hand-wing index | numeric | index | 1 | avonet |
| head_length | Head length | numeric | mm | 2 | huang_amph, saproxylic |
| head_width | Head width | numeric | mm | 2 | huang_amph, saproxylic |
| hindlimb_length | Hindlimb length | numeric | mm | 1 | huang_amph |
| home_range | Home range | numeric | km2 | 3 | combine, homerange, pantheria |
| huber_value | Huber value | numeric | index (m2/m2) | 2 | hydraulics, austraits |
| hunting_guild | Hunting guild (spider) | categorical | NA | 1 | spider_traits |
| hydraulic_safety_margin | Hydraulic safety margin | numeric | MPa | 1 | hydraulics |
| incubation_period | Egg incubation period | numeric | days | 2 | amniote, chelonians |
| interbirth_interval | Interbirth or inter-litter interval | numeric | yr | 4 | pantheria, combine, amniote, anage |
| itd | Inter-tegular distance (bee body size) | numeric | mm | 2 | bee_ostwald, eupolltrait |
| kipps_distance | Kipp’s distance | numeric | mm | 1 | avonet |
| larval_development_mode | Larval development mode | categorical | NA | 1 | coral_traits |
| larval_nutrition | Larval nutrition (bee) | categorical | NA | 1 | eupolltrait |
| ldmc | Leaf dry matter content | numeric | mg/g | 4 | leda, gift, brot, diaz_traits |
| leaf_area | Leaf area | numeric | mm2 | 3 | austraits, bien, brot |
| leaf_length | Leaf length | numeric | mm | 1 | austraits |
| leaf_lifespan | Leaf lifespan | numeric | months | 3 | austraits, brot, bien |
| leaf_n | Leaf nitrogen per dry mass | numeric | mg/g | 2 | austraits, bien |
| leaf_p | Leaf phosphorus per dry mass | numeric | mg/g | 2 | austraits, bien |
| leaf_specific_conductivity | Leaf specific hydraulic conductivity | numeric | kg m-1 s-1 MPa-1 | 1 | hydraulics |
| leaf_thickness | Leaf thickness | numeric | mm | 2 | bien, gift |
| leaf_type | Leaf type | categorical | NA | 2 | austraits, diaz_traits |
| leaf_width | Leaf width | numeric | mm | 1 | austraits |
| lecty | Pollen host breadth (bee lecty) | categorical | NA | 1 | eupolltrait |
| lichen_growth_form | Lichen growth form (thallus) | categorical | NA | 1 | italic |
| life_form | Raunkiaer life form | categorical | NA | 3 | gift, ecoflora, floraweb |
| life_history | Life history | categorical | NA | 2 | gift, austraits |
| linear_extension_rate | Coral linear extension rate | numeric | mm/yr | 1 | coral_traits |
| living_habit | Living habit (benthic invertebrate) | categorical | NA | 2 | arctic_traits, nztd |
| longevity | Maximum longevity | numeric | yr | 11 | anage, amniote, combine, pantheria, repttraits, chelonians, amphibio, beukhof, fishtraits, eurobat, sheld |
| male_maturity | Age at male maturity | numeric | yr | 3 | anage, amniote, combine |
| marine | Marine habitat | categorical | NA | 3 | sealifebase, combine, phylacine |
| mate_guarding | Mate guarding (odonate) | categorical | NA | 1 | odonata |
| metabolic_rate | Metabolic rate | numeric | W | 2 | anage, animaltraits |
| migration | Migratory behaviour (bird) | categorical | NA | 1 | avonet |
| min_water_potential | Minimum midday water potential | numeric | MPa | 1 | hydraulics |
| motility | Motility (prokaryote) | categorical | NA | 2 | madin, bacdive |
| mouth_position | Mouth position (fish) | categorical | NA | 1 | quimbayo |
| mycorrhizal_type | Mycorrhizal type | categorical | NA | 1 | fungalroot |
| neonate_mass | Neonate body mass | numeric | g | 4 | amniote, combine, pantheria, anage |
| nest_attachment | Nest attachment (birds) | categorical | NA | 1 | nesttrait |
| nest_site | Nest site (birds) | categorical | NA | 1 | nesttrait |
| nest_structure | Nest structure (birds) | categorical | NA | 1 | nesttrait |
| nesting_strategy | Nesting strategy (bee) | categorical | NA | 1 | eupolltrait |
| nitrogen_fixation | Root-nodule nitrogen fixation | categorical | NA | 1 | noddb |
| optimal_growth_ph | Optimal growth pH (prokaryote) | numeric | pH | 2 | madin, bacdive |
| optimal_growth_temperature | Optimal growth temperature (prokaryote) | numeric | deg C | 2 | madin, bacdive |
| oral_gape_position | Oral gape position (fish) | numeric | index | 1 | fishmorph |
| oxygen_metabolism | Oxygen metabolism (prokaryote) | categorical | NA | 2 | madin, bacdive |
| p50 | Xylem embolism resistance (P50) | numeric | MPa | 3 | hydraulics, austraits, brot |
| parental_care | Parental care (fish) | categorical | NA | 1 | beukhof |
| pectoral_fin_position | Pectoral fin position (fish) | numeric | index | 1 | fishmorph |
| pectoral_fin_size | Pectoral fin size (fish) | numeric | index | 1 | fishmorph |
| photobiont | Lichen photobiont | categorical | NA | 1 | italic |
| photosynthetic_pathway | Photosynthetic pathway | categorical | NA | 3 | gift, austraits, ecoflora |
| plant_height | Plant height | numeric | m | 5 | gift, diaz, austraits, bien, brot |
| plant_lifespan | Whole-plant lifespan | numeric | yr | 3 | bien, gift, austraits |
| pollination_vector | Pollination vector | categorical | NA | 4 | baseflor, ecoflora, floraweb, austraits |
| polyp_retractability | Polyp retractability | categorical | NA | 1 | octocoral |
| population_density | Population density | numeric | individuals/km2 | 3 | pantheria, combine, tetradensity |
| primary_habitat | Primary habitat | categorical | NA | 3 | birdbase, chowdhury, finand |
| pronotum_length | Pronotum length | numeric | mm | 1 | saproxylic |
| range_size | Geographic range size | numeric | km2 | 3 | avonet, chelonians, coral_traits |
| relative_eye_size | Relative eye size (fish) | numeric | index | 1 | fishmorph |
| relative_maxillary_length | Relative maxillary length (fish) | numeric | index | 1 | fishmorph |
| reproductive_frequency | Litters or clutches per year | numeric | per year | 6 | amniote, combine, anage, pantheria, repttraits, chelonians |
| reproductive_mode | Reproductive (parity) mode | categorical | NA | 2 | repttraits, sharkipedia |
| reproductive_strategy | Reproductive strategy (sexual / asexual) | categorical | NA | 1 | italic |
| resprouting | Resprouting after fire | categorical | NA | 2 | austraits, brot |
| root_diameter | Root diameter | numeric | mm | 2 | groot, austraits |
| root_dry_matter_content | Root dry matter content | numeric | g/g | 2 | groot, austraits |
| root_mass_fraction | Root mass fraction | numeric | g/g | 2 | groot, austraits |
| root_mycorrhizal_colonization | Root mycorrhizal colonization | numeric | percent | 1 | groot |
| root_n_concentration | Root nitrogen concentration | numeric | mg/g | 2 | groot, austraits |
| root_tissue_density | Root tissue density | numeric | g/cm3 | 1 | groot |
| rooting_depth | Rooting depth | numeric | m | 2 | groot, brot |
| sapwood_conductivity | Sapwood specific hydraulic conductivity | numeric | kg m-1 s-1 MPa-1 | 2 | hydraulics, austraits |
| secondary1 | First-secondary length | numeric | mm | 1 | avonet |
| seed_length | Seed length | numeric | mm | 4 | austraits, leda, gift, bien |
| seed_mass | Seed mass | numeric | mg | 7 | diaz, gift, austraits, bien, brot, ecoflora, kew_sid |
| self_compatibility | Self-compatibility | categorical | NA | 1 | tree_of_sex |
| serotiny | Serotiny | categorical | NA | 1 | austraits |
| sexual_system | Sexual system | categorical | NA | 6 | tree_of_sex, austraits, bet, coral_traits, octocoral, sheld |
| shoot_length | Shoot length | numeric | mm | 1 | bet |
| skeletal_rigidity | Skeletal rigidity (octocoral) | categorical | NA | 1 | octocoral |
| sla | Specific leaf area | numeric | mm2/mg | 4 | leda, gift, bien, brot |
| sociality | Sociality (bee) | categorical | NA | 1 | eupolltrait |
| socioeconomic_impact | Socio-economic impact (SEICAT) | categorical | NA | 1 | gidias |
| soil_seed_bank | Soil seed-bank persistence | categorical | NA | 2 | austraits, brot |
| specific_root_area | Specific root area | numeric | cm2/g | 1 | groot |
| specific_root_length | Specific root length | numeric | m/g | 2 | groot, austraits |
| spore_diameter | Spore diameter | numeric | um | 1 | bet |
| sporulation | Sporulation (prokaryote) | categorical | NA | 1 | madin |
| substrate | Substrate | categorical | NA | 2 | italic, bet |
| substrate_attachment | Substrate attachment | categorical | NA | 1 | coral_traits |
| tail_length | Tail length | numeric | mm | 1 | avonet |
| tarsus_length | Tarsus length | numeric | mm | 1 | avonet |
| teat_number | Teat or nipple number | numeric | count | 2 | pantheria, combine |
| territoriality | Territoriality (odonate) | categorical | NA | 1 | odonata |
| thermal_max | Upper thermal limit | numeric | deg C | 3 | globtherm, pottier, thermofresh |
| thermal_min | Lower thermal limit | numeric | deg C | 2 | globtherm, thermofresh |
| tongue_length | Tongue length (bee) | numeric | mm | 2 | bee_ostwald, eupolltrait |
| trophic_level | Trophic level | numeric | trophic level (~1-5) | 6 | fishbase, beukhof, quimbayo, pelagic, arctic_traits, sealifebase |
| turgor_loss_point | Leaf turgor loss point | numeric | MPa | 1 | austraits |
| venomous | Venomous (reptile) | categorical | NA | 1 | repttraits |
| vertical_eye_position | Vertical eye position (fish) | numeric | index | 1 | fishmorph |
| voltinism | Voltinism (generations per year) | numeric | per year | 2 | arthropod_traits, eupolltrait |
| von_bertalanffy_k | Von Bertalanffy growth coefficient (K) | numeric | per yr | 2 | beukhof, sharkipedia |
| von_bertalanffy_linf | Von Bertalanffy asymptotic length (Linf) | numeric | cm | 2 | beukhof, sharkipedia |
| vulnerability | Vulnerability to fishing | numeric | 0-100 index | 3 | fishbase, sealifebase, quimbayo |
| water_clarity | Water clarity preference | categorical | NA | 2 | coral_traits, octocoral |
| wave_exposure | Wave exposure preference | categorical | NA | 2 | coral_traits, octocoral |
| weaning_age | Weaning age | numeric | days | 3 | amniote, anage, pantheria |
| web_building | Web building (spider) | categorical | NA | 1 | spider_traits |
| wing_length | Wing length | numeric | mm | 2 | avonet, saproxylic |
| wing_morph | Wing morphology | categorical | NA | 3 | chowdhury, finand, alpine_carabids |
| wingspan | Wingspan (butterfly) | numeric | mm | 1 | leptraits |
| wood_density | Wood density | numeric | g/cm3 | 5 | gwdd, austraits, bien, gift, leda |
| woodiness | Woodiness | categorical | NA | 4 | zanne, gift, austraits, bien |
| zooxanthellate | Zooxanthellate symbiosis (coral) | categorical | NA | 2 | coral_traits, octocoral |
