# List the traits available to add_trait()

Returns the traits that
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md)
can attach across sources, with their kind, canonical unit, and the
number and names of contributing sources.

## Usage

``` r
list_traits()
```

## Value

A data.frame with one row per trait:

- trait:

  The trait name to pass to
  [`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md).

- label:

  Human-readable label.

- kind:

  `"numeric"` or `"categorical"`.

- unit:

  Canonical unit for numeric traits, `NA` for categorical.

- n_sources:

  Number of sources providing the trait.

- sources:

  Comma-separated source names.

## See also

[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)

Other Traits across sources:
[`add_trait()`](https://gillescolling.com/taxify/reference/add_trait.md),
[`trait_info()`](https://gillescolling.com/taxify/reference/trait_info.md)

## Examples

``` r
list_traits()
#>                             trait                                    label
#> 1                    plant_height                             Plant height
#> 2                       seed_mass                                Seed mass
#> 3                             sla                       Specific leaf area
#> 4                    wood_density                             Wood density
#> 5                       leaf_area                                Leaf area
#> 6                     leaf_length                              Leaf length
#> 7                      leaf_width                               Leaf width
#> 8                          leaf_n               Leaf nitrogen per dry mass
#> 9                          leaf_p             Leaf phosphorus per dry mass
#> 10                 leaf_thickness                           Leaf thickness
#> 11                  leaf_lifespan                            Leaf lifespan
#> 12                 plant_lifespan                     Whole-plant lifespan
#> 13                      body_mass                                Body mass
#> 14                      longevity                        Maximum longevity
#> 15                  trophic_level                            Trophic level
#> 16             clutch_litter_size                    Clutch or litter size
#> 17                age_at_maturity                   Age at female maturity
#> 18                  male_maturity                     Age at male maturity
#> 19           gestation_incubation           Gestation or incubation length
#> 20              incubation_period                    Egg incubation period
#> 21                    body_length                              Body length
#> 22                   elytra_width                             Elytra width
#> 23                 metabolic_rate                           Metabolic rate
#> 24                     brain_mass                               Brain mass
#> 25         reproductive_frequency             Litters or clutches per year
#> 26            interbirth_interval      Interbirth or inter-litter interval
#> 27                    teat_number                    Teat or nipple number
#> 28             population_density                       Population density
#> 29                   neonate_mass                        Neonate body mass
#> 30                       egg_mass                                 Egg mass
#> 31                     egg_length                               Egg length
#> 32                      egg_width                                Egg width
#> 33                flowering_start                  Flowering start (month)
#> 34                  flowering_end                    Flowering end (month)
#> 35                    resprouting                   Resprouting after fire
#> 36                       serotiny                                 Serotiny
#> 37                 soil_seed_bank               Soil seed-bank persistence
#> 38                            p50          Xylem embolism resistance (P50)
#> 39              turgor_loss_point                   Leaf turgor loss point
#> 40           sapwood_conductivity  Sapwood specific hydraulic conductivity
#> 41     leaf_specific_conductivity     Leaf specific hydraulic conductivity
#> 42                    huber_value                              Huber value
#> 43            min_water_potential           Minimum midday water potential
#> 44        hydraulic_safety_margin                  Hydraulic safety margin
#> 45                 bark_thickness                           Bark thickness
#> 46             self_compatibility                       Self-compatibility
#> 47                ellenberg_light                      Ellenberg light (L)
#> 48          ellenberg_temperature                Ellenberg temperature (T)
#> 49             ellenberg_moisture                   Ellenberg moisture (F)
#> 50             ellenberg_reaction                   Ellenberg reaction (R)
#> 51             ellenberg_nitrogen       Ellenberg nutrients / nitrogen (N)
#> 52                 ellenberg_salt                       Ellenberg salt (S)
#> 53                     eive_light                           EIVE light (L)
#> 54               eive_temperature                     EIVE temperature (T)
#> 55                  eive_moisture                        EIVE moisture (M)
#> 56                  eive_reaction                        EIVE reaction (R)
#> 57                 eive_nutrients                       EIVE nutrients (N)
#> 58                      woodiness                                Woodiness
#> 59           environmental_impact             Environmental impact (EICAT)
#> 60           socioeconomic_impact           Socio-economic impact (SEICAT)
#> 61         photosynthetic_pathway                   Photosynthetic pathway
#> 62                    growth_form                              Growth form
#> 63                      life_form                      Raunkiaer life form
#> 64             dispersal_syndrome                       Dispersal syndrome
#> 65             pollination_vector                       Pollination vector
#> 66                   life_history                             Life history
#> 67                  flower_colour                            Flower colour
#> 68                     fruit_type                               Fruit type
#> 69                     diet_guild                               Diet guild
#> 70                     wing_morph                          Wing morphology
#> 71                  activity_time                       Diel activity time
#> 72                  foraging_mode                            Foraging mode
#> 73                      migration               Migratory behaviour (bird)
#> 74                     flightless                    Flightlessness (bird)
#> 75                       venomous                       Venomous (reptile)
#> 76                      sociality                          Sociality (bee)
#> 77                          lecty          Pollen host breadth (bee lecty)
#> 78               nesting_strategy                   Nesting strategy (bee)
#> 79                 territoriality                 Territoriality (odonate)
#> 80                  mate_guarding                  Mate guarding (odonate)
#> 81                    flight_mode                    Flight mode (odonate)
#> 82                     gram_stain                  Gram stain (prokaryote)
#> 83              oxygen_metabolism           Oxygen metabolism (prokaryote)
#> 84                     cell_shape                  Cell shape (prokaryote)
#> 85                       motility                    Motility (prokaryote)
#> 86                    sporulation                 Sporulation (prokaryote)
#> 87            fungal_trophic_mode                      Fungal trophic mode
#> 88               larval_nutrition                   Larval nutrition (bee)
#> 89                  calcification                    Calcification (algae)
#> 90                    gamete_type                      Gamete type (algae)
#> 91               algal_life_cycle          Life-cycle ploidy phase (algae)
#> 92                algal_substrate             Attachment substrate (algae)
#> 93                   bioturbation Bioturbation mode (benthic invertebrate)
#> 94                   living_habit      Living habit (benthic invertebrate)
#> 95                  feeding_guild     Feeding guild (benthic invertebrate)
#> 96              skeletal_rigidity            Skeletal rigidity (octocoral)
#> 97             colony_growth_form           Colony growth form (octocoral)
#> 98                      depth_min                            Minimum depth
#> 99                      depth_max                            Maximum depth
#> 100                 elevation_min                        Minimum elevation
#> 101                 elevation_max                        Maximum elevation
#> 102                    home_range                               Home range
#> 103                    range_size                    Geographic range size
#> 104               habitat_breadth                          Habitat breadth
#> 105             generation_length                        Generation length
#> 106                   weaning_age                              Weaning age
#> 107                          ldmc                  Leaf dry matter content
#> 108                   seed_length                              Seed length
#> 109                 vulnerability                 Vulnerability to fishing
#> 110                           itd   Inter-tegular distance (bee body size)
#> 111                 tongue_length                      Tongue length (bee)
#> 112                  diet_breadth                             Diet breadth
#> 113                  aspect_ratio                  Caudal fin aspect ratio
#> 114               body_elongation                   Body elongation (fish)
#> 115         vertical_eye_position             Vertical eye position (fish)
#> 116             relative_eye_size                 Relative eye size (fish)
#> 117            oral_gape_position                Oral gape position (fish)
#> 118     relative_maxillary_length         Relative maxillary length (fish)
#> 119            body_lateral_shape                Body lateral shape (fish)
#> 120         pectoral_fin_position             Pectoral fin position (fish)
#> 121             pectoral_fin_size                 Pectoral fin size (fish)
#> 122    caudal_peduncle_throttling        Caudal peduncle throttling (fish)
#> 123                   head_length                              Head length
#> 124                    head_width                               Head width
#> 125               forelimb_length                          Forelimb length
#> 126               hindlimb_length                          Hindlimb length
#> 127                forearm_length                           Forearm length
#> 128                 elytra_length                            Elytra length
#> 129                antenna_length                           Antenna length
#> 130               pronotum_length                          Pronotum length
#> 131                   cell_length                              Cell length
#> 132                    cell_width                               Cell width
#> 133                cell_biovolume              Cell biovolume (microalgae)
#> 134                cell_thickness              Cell thickness (microalgae)
#> 135             cell_surface_area           Cell surface area (microalgae)
#> 136               colony_diameter          Colony maximum diameter (coral)
#> 137               corallite_width                  Corallite width (coral)
#> 138               carapace_length                 Carapace length (turtle)
#> 139              colour_lightness           Body colour lightness (beetle)
#> 140                     voltinism         Voltinism (generations per year)
#> 141    optimal_growth_temperature  Optimal growth temperature (prokaryote)
#> 142                   genome_size                 Genome size (prokaryote)
#> 143             chromosome_number                   Chromosome number (2n)
#> 144             optimal_growth_ph           Optimal growth pH (prokaryote)
#> 145                    gc_content           Genome GC content (prokaryote)
#> 146           conservation_status                     IUCN Red List status
#> 147                    body_shape                        Body shape (fish)
#> 148              caudal_fin_shape                  Caudal fin shape (fish)
#> 149                  feeding_mode                      Feeding mode (fish)
#> 150                mouth_position                    Mouth position (fish)
#> 151                 air_breathing                     Air breathing (fish)
#> 152                 parental_care                     Parental care (fish)
#> 153                 sexual_system                            Sexual system
#> 154             reproductive_mode               Reproductive (parity) mode
#> 155            lichen_growth_form             Lichen growth form (thallus)
#> 156                     substrate                                Substrate
#> 157                    photobiont                        Lichen photobiont
#> 158         reproductive_strategy Reproductive strategy (sexual / asexual)
#> 159                     leaf_type                                Leaf type
#> 160                 deciduousness                       Leaf deciduousness
#> 161                        marine                           Marine habitat
#> 162                    freshwater                       Freshwater habitat
#> 163                   coloniality                              Coloniality
#> 164                 wave_exposure                 Wave exposure preference
#> 165                 water_clarity                 Water clarity preference
#> 166                zooxanthellate         Zooxanthellate symbiosis (coral)
#> 167                   wing_length                              Wing length
#> 168                      wingspan                     Wingspan (butterfly)
#> 169                   beak_length                     Beak length (culmen)
#> 170               hand_wing_index                          Hand-wing index
#> 171             von_bertalanffy_k   Von Bertalanffy growth coefficient (K)
#> 172          von_bertalanffy_linf Von Bertalanffy asymptotic length (Linf)
#> 173                   thermal_max                      Upper thermal limit
#> 174                   thermal_min                      Lower thermal limit
#> 175            climatic_temp_mean         Mean annual temperature of range
#> 176             nitrogen_fixation            Root-nodule nitrogen fixation
#> 177    earthworm_ecological_group               Earthworm ecological group
#> 178             climatic_temp_min       Coldest-month temperature of range
#> 179             climatic_temp_max       Warmest-month temperature of range
#> 180                    beak_width                               Beak width
#> 181                    beak_depth                               Beak depth
#> 182                 tarsus_length                            Tarsus length
#> 183                   tail_length                              Tail length
#> 184                    secondary1                   First-secondary length
#> 185                kipps_distance                          Kipp's distance
#> 186                 root_diameter                            Root diameter
#> 187          specific_root_length                     Specific root length
#> 188            specific_root_area                       Specific root area
#> 189           root_tissue_density                      Root tissue density
#> 190            root_mass_fraction                       Root mass fraction
#> 191       root_dry_matter_content                  Root dry matter content
#> 192          root_n_concentration              Root nitrogen concentration
#> 193                 rooting_depth                            Rooting depth
#> 194 root_mycorrhizal_colonization            Root mycorrhizal colonization
#> 195     age_at_first_reproduction                Age at first reproduction
#> 196                 hunting_guild                   Hunting guild (spider)
#> 197                  web_building                    Web building (spider)
#> 198               bioluminescence            Bioluminescence (zooplankton)
#> 199       diel_vertical_migration    Diel vertical migration (zooplankton)
#> 200                nest_structure                   Nest structure (birds)
#> 201                     nest_site                        Nest site (birds)
#> 202               nest_attachment                  Nest attachment (birds)
#> 203              mycorrhizal_type                         Mycorrhizal type
#> 204           bryophyte_life_form                      Bryophyte life form
#> 205                  shoot_length                             Shoot length
#> 206                spore_diameter                           Spore diameter
#> 207       larval_development_mode                  Larval development mode
#> 208          substrate_attachment                     Substrate attachment
#> 209         linear_extension_rate              Coral linear extension rate
#> 210          polyp_retractability                     Polyp retractability
#> 211               primary_habitat                          Primary habitat
#>            kind                        unit n_sources
#> 1       numeric                           m         5
#> 2       numeric                          mg         8
#> 3       numeric                      mm2/mg         4
#> 4       numeric                       g/cm3         5
#> 5       numeric                         mm2         3
#> 6       numeric                          mm         1
#> 7       numeric                          mm         1
#> 8       numeric                        mg/g         2
#> 9       numeric                        mg/g         2
#> 10      numeric                          mm         2
#> 11      numeric                      months         3
#> 12      numeric                          yr         3
#> 13      numeric                           g        15
#> 14      numeric                          yr        11
#> 15      numeric        trophic level (~1-5)         6
#> 16      numeric offspring per clutch/litter        10
#> 17      numeric                          yr         7
#> 18      numeric                          yr         3
#> 19      numeric                        days         4
#> 20      numeric                        days         2
#> 21      numeric                          mm        19
#> 22      numeric                          mm         1
#> 23      numeric                           W         2
#> 24      numeric                           g         2
#> 25      numeric                    per year         6
#> 26      numeric                          yr         4
#> 27      numeric                       count         2
#> 28      numeric             individuals/km2         3
#> 29      numeric                           g         4
#> 30      numeric                           g         1
#> 31      numeric                          mm         3
#> 32      numeric                          mm         3
#> 33      numeric                month (1-12)         3
#> 34      numeric                month (1-12)         3
#> 35  categorical                        <NA>         2
#> 36  categorical                        <NA>         1
#> 37  categorical                        <NA>         2
#> 38      numeric                         MPa         3
#> 39      numeric                         MPa         1
#> 40      numeric            kg m-1 s-1 MPa-1         2
#> 41      numeric            kg m-1 s-1 MPa-1         1
#> 42      numeric               index (m2/m2)         2
#> 43      numeric                         MPa         1
#> 44      numeric                         MPa         1
#> 45      numeric                          mm         1
#> 46  categorical                        <NA>         1
#> 47      numeric               1-9 (classic)         3
#> 48      numeric               1-9 (classic)         2
#> 49      numeric              1-12 (classic)         3
#> 50      numeric               1-9 (classic)         3
#> 51      numeric               1-9 (classic)         3
#> 52      numeric               0-9 (classic)         3
#> 53      numeric                 0-10 (EIVE)         1
#> 54      numeric                 0-10 (EIVE)         1
#> 55      numeric                 0-10 (EIVE)         1
#> 56      numeric                 0-10 (EIVE)         1
#> 57      numeric                 0-10 (EIVE)         1
#> 58  categorical                        <NA>         4
#> 59  categorical                        <NA>         1
#> 60  categorical                        <NA>         1
#> 61  categorical                        <NA>         3
#> 62  categorical                        <NA>         4
#> 63  categorical                        <NA>         3
#> 64  categorical                        <NA>         5
#> 65  categorical                        <NA>         4
#> 66  categorical                        <NA>         2
#> 67  categorical                        <NA>         3
#> 68  categorical                        <NA>         3
#> 69  categorical                        <NA>        12
#> 70  categorical                        <NA>         3
#> 71  categorical                        <NA>         6
#> 72  categorical                        <NA>         2
#> 73  categorical                        <NA>         1
#> 74  categorical                        <NA>         1
#> 75  categorical                        <NA>         1
#> 76  categorical                        <NA>         1
#> 77  categorical                        <NA>         1
#> 78  categorical                        <NA>         1
#> 79  categorical                        <NA>         1
#> 80  categorical                        <NA>         1
#> 81  categorical                        <NA>         1
#> 82  categorical                        <NA>         2
#> 83  categorical                        <NA>         2
#> 84  categorical                        <NA>         2
#> 85  categorical                        <NA>         2
#> 86  categorical                        <NA>         1
#> 87  categorical                        <NA>         2
#> 88  categorical                        <NA>         1
#> 89  categorical                        <NA>         1
#> 90  categorical                        <NA>         1
#> 91  categorical                        <NA>         1
#> 92  categorical                        <NA>         1
#> 93  categorical                        <NA>         2
#> 94  categorical                        <NA>         2
#> 95  categorical                        <NA>         2
#> 96  categorical                        <NA>         1
#> 97  categorical                        <NA>         1
#> 98      numeric                           m         6
#> 99      numeric                           m         6
#> 100     numeric                           m         3
#> 101     numeric                           m         3
#> 102     numeric                         km2         3
#> 103     numeric                         km2         3
#> 104     numeric                       count         4
#> 105     numeric                          yr         3
#> 106     numeric                        days         3
#> 107     numeric                        mg/g         4
#> 108     numeric                          mm         4
#> 109     numeric                 0-100 index         3
#> 110     numeric                          mm         2
#> 111     numeric                          mm         2
#> 112     numeric                       count         3
#> 113     numeric                       index         2
#> 114     numeric                       index         1
#> 115     numeric                       index         1
#> 116     numeric                       index         1
#> 117     numeric                       index         1
#> 118     numeric                       index         1
#> 119     numeric                       index         1
#> 120     numeric                       index         1
#> 121     numeric                       index         1
#> 122     numeric                       index         1
#> 123     numeric                          mm         2
#> 124     numeric                          mm         2
#> 125     numeric                          mm         1
#> 126     numeric                          mm         1
#> 127     numeric                          mm         3
#> 128     numeric                          mm         2
#> 129     numeric                          mm         1
#> 130     numeric                          mm         1
#> 131     numeric                          um         2
#> 132     numeric                          um         2
#> 133     numeric                         um3         1
#> 134     numeric                          um         1
#> 135     numeric                         um2         1
#> 136     numeric                          cm         1
#> 137     numeric                          mm         1
#> 138     numeric                          mm         1
#> 139     numeric                       index         1
#> 140     numeric                    per year         2
#> 141     numeric                       deg C         2
#> 142     numeric                          bp         1
#> 143     numeric                       count         1
#> 144     numeric                          pH         2
#> 145     numeric                           %         1
#> 146 categorical                        <NA>         6
#> 147 categorical                        <NA>         3
#> 148 categorical                        <NA>         2
#> 149 categorical                        <NA>         1
#> 150 categorical                        <NA>         1
#> 151 categorical                        <NA>         1
#> 152 categorical                        <NA>         1
#> 153 categorical                        <NA>         6
#> 154 categorical                        <NA>         2
#> 155 categorical                        <NA>         1
#> 156 categorical                        <NA>         2
#> 157 categorical                        <NA>         1
#> 158 categorical                        <NA>         1
#> 159 categorical                        <NA>         2
#> 160 categorical                        <NA>         2
#> 161 categorical                        <NA>         3
#> 162 categorical                        <NA>         3
#> 163 categorical                        <NA>         2
#> 164 categorical                        <NA>         2
#> 165 categorical                        <NA>         2
#> 166 categorical                        <NA>         2
#> 167     numeric                          mm         2
#> 168     numeric                          mm         1
#> 169     numeric                          mm         1
#> 170     numeric                       index         1
#> 171     numeric                      per yr         2
#> 172     numeric                          cm         2
#> 173     numeric                       deg C         3
#> 174     numeric                       deg C         2
#> 175     numeric                       deg C         3
#> 176 categorical                        <NA>         1
#> 177 categorical                        <NA>         1
#> 178     numeric                       deg C         1
#> 179     numeric                       deg C         1
#> 180     numeric                          mm         1
#> 181     numeric                          mm         1
#> 182     numeric                          mm         1
#> 183     numeric                          mm         1
#> 184     numeric                          mm         1
#> 185     numeric                          mm         1
#> 186     numeric                          mm         2
#> 187     numeric                         m/g         2
#> 188     numeric                       cm2/g         1
#> 189     numeric                       g/cm3         1
#> 190     numeric                         g/g         2
#> 191     numeric                         g/g         2
#> 192     numeric                        mg/g         2
#> 193     numeric                           m         2
#> 194     numeric                     percent         1
#> 195     numeric                          yr         1
#> 196 categorical                        <NA>         1
#> 197 categorical                        <NA>         1
#> 198 categorical                        <NA>         1
#> 199 categorical                        <NA>         1
#> 200 categorical                        <NA>         1
#> 201 categorical                        <NA>         1
#> 202 categorical                        <NA>         1
#> 203 categorical                        <NA>         1
#> 204 categorical                        <NA>         1
#> 205     numeric                          mm         1
#> 206     numeric                          um         1
#> 207 categorical                        <NA>         1
#> 208 categorical                        <NA>         1
#> 209     numeric                       mm/yr         1
#> 210 categorical                        <NA>         1
#> 211 categorical                        <NA>         3
#>                                                                                                                                                                                                                                                                                                 sources
#> 1                                                                                                                                                                                                                                                                     gift, diaz, austraits, bien, brot
#> 2                                                                                                                                                                                                                                            diaz, gift, austraits, bien, brot, ecoflora, kew_sid, leda
#> 3                                                                                                                                                                                                                                                                                leda, gift, bien, brot
#> 4                                                                                                                                                                                                                                                                     gwdd, austraits, bien, gift, leda
#> 5                                                                                                                                                                                                                                                                                 austraits, bien, brot
#> 6                                                                                                                                                                                                                                                                                             austraits
#> 7                                                                                                                                                                                                                                                                                             austraits
#> 8                                                                                                                                                                                                                                                                                       austraits, bien
#> 9                                                                                                                                                                                                                                                                                       austraits, bien
#> 10                                                                                                                                                                                                                                                                                           bien, gift
#> 11                                                                                                                                                                                                                                                                                austraits, brot, bien
#> 12                                                                                                                                                                                                                                                                                bien, gift, austraits
#> 13                                                                                                                                        combine, amniote, pantheria, elton_traits, avonet, anage, phylacine, repttraits, fishbase, sealifebase, frugivoria, pottier, animaltraits, homerange, eurobat
#> 14                                                                                                                                                                                            anage, amniote, combine, pantheria, repttraits, chelonians, amphibio, beukhof, fishtraits, eurobat, sheld
#> 15                                                                                                                                                                                                                                     fishbase, beukhof, quimbayo, pelagic, arctic_traits, sealifebase
#> 16                                                                                                                                                                                                 amniote, combine, pantheria, anage, repttraits, amphibio, chelonians, birdbase, eurobat, zooplankton
#> 17                                                                                                                                                                                                                                     anage, amniote, amphibio, chelonians, beukhof, fishtraits, sheld
#> 18                                                                                                                                                                                                                                                                              anage, amniote, combine
#> 19                                                                                                                                                                                                                                                                   anage, combine, pantheria, amniote
#> 20                                                                                                                                                                                                                                                                                  amniote, chelonians
#> 21  combine, amniote, repttraits, amphibio, fishbase, sealifebase, huang_amph, pottier, spider_traits, zooplankton, sheld, chowdhury, finand, alpine_carabids, betsi_collembola_body_length, plazi_collembola_body_length, monograph_collembola_body_length, ellers_collembola, betsi_collembola_traits
#> 22                                                                                                                                                                                                                                                                                      imageomics_neon
#> 23                                                                                                                                                                                                                                                                                  anage, animaltraits
#> 24                                                                                                                                                                                                                                                                                combine, animaltraits
#> 25                                                                                                                                                                                                                                           amniote, combine, anage, pantheria, repttraits, chelonians
#> 26                                                                                                                                                                                                                                                                   pantheria, combine, amniote, anage
#> 27                                                                                                                                                                                                                                                                                   pantheria, combine
#> 28                                                                                                                                                                                                                                                                     pantheria, combine, tetradensity
#> 29                                                                                                                                                                                                                                                                   amniote, combine, pantheria, anage
#> 30                                                                                                                                                                                                                                                                                              amniote
#> 31                                                                                                                                                                                                                                                                      amniote, repttraits, chelonians
#> 32                                                                                                                                                                                                                                                                      amniote, repttraits, chelonians
#> 33                                                                                                                                                                                                                                                                        baseflor, ecoflora, austraits
#> 34                                                                                                                                                                                                                                                                        baseflor, ecoflora, austraits
#> 35                                                                                                                                                                                                                                                                                      austraits, brot
#> 36                                                                                                                                                                                                                                                                                            austraits
#> 37                                                                                                                                                                                                                                                                                      austraits, brot
#> 38                                                                                                                                                                                                                                                                          hydraulics, austraits, brot
#> 39                                                                                                                                                                                                                                                                                            austraits
#> 40                                                                                                                                                                                                                                                                                hydraulics, austraits
#> 41                                                                                                                                                                                                                                                                                           hydraulics
#> 42                                                                                                                                                                                                                                                                                hydraulics, austraits
#> 43                                                                                                                                                                                                                                                                                           hydraulics
#> 44                                                                                                                                                                                                                                                                                           hydraulics
#> 45                                                                                                                                                                                                                                                                                            austraits
#> 46                                                                                                                                                                                                                                                                                          tree_of_sex
#> 47                                                                                                                                                                                                                                                                              floraweb, ecoflora, bet
#> 48                                                                                                                                                                                                                                                                                        floraweb, bet
#> 49                                                                                                                                                                                                                                                                              floraweb, ecoflora, bet
#> 50                                                                                                                                                                                                                                                                              floraweb, ecoflora, bet
#> 51                                                                                                                                                                                                                                                                              floraweb, ecoflora, bet
#> 52                                                                                                                                                                                                                                                                         floraweb, ecoflora, baseflor
#> 53                                                                                                                                                                                                                                                                                                 eive
#> 54                                                                                                                                                                                                                                                                                                 eive
#> 55                                                                                                                                                                                                                                                                                                 eive
#> 56                                                                                                                                                                                                                                                                                                 eive
#> 57                                                                                                                                                                                                                                                                                                 eive
#> 58                                                                                                                                                                                                                                                                         zanne, gift, austraits, bien
#> 59                                                                                                                                                                                                                                                                                               gidias
#> 60                                                                                                                                                                                                                                                                                               gidias
#> 61                                                                                                                                                                                                                                                                            gift, austraits, ecoflora
#> 62                                                                                                                                                                                                                                                                          gift, austraits, bien, brot
#> 63                                                                                                                                                                                                                                                                             gift, ecoflora, floraweb
#> 64                                                                                                                                                                                                                                                                gift, austraits, leda, baseflor, brot
#> 65                                                                                                                                                                                                                                                              baseflor, ecoflora, floraweb, austraits
#> 66                                                                                                                                                                                                                                                                                      gift, austraits
#> 67                                                                                                                                                                                                                                                                                 gift, baseflor, bien
#> 68                                                                                                                                                                                                                                                                            gift, baseflor, austraits
#> 69                                                                                                                                                            avonet, elton_traits, repttraits, chelonians, blanchard, parravicini, eurobat, zooplankton, birdbase, arthropod_traits, chowdhury, finand
#> 70                                                                                                                                                                                                                                                                   chowdhury, finand, alpine_carabids
#> 71                                                                                                                                                                                                                                  repttraits, chelonians, quimbayo, combine, pantheria, spider_traits
#> 72                                                                                                                                                                                                                                                                               repttraits, chelonians
#> 73                                                                                                                                                                                                                                                                                               avonet
#> 74                                                                                                                                                                                                                                                                                             birdbase
#> 75                                                                                                                                                                                                                                                                                           repttraits
#> 76                                                                                                                                                                                                                                                                                          eupolltrait
#> 77                                                                                                                                                                                                                                                                                          eupolltrait
#> 78                                                                                                                                                                                                                                                                                          eupolltrait
#> 79                                                                                                                                                                                                                                                                                              odonata
#> 80                                                                                                                                                                                                                                                                                              odonata
#> 81                                                                                                                                                                                                                                                                                              odonata
#> 82                                                                                                                                                                                                                                                                                       madin, bacdive
#> 83                                                                                                                                                                                                                                                                                       madin, bacdive
#> 84                                                                                                                                                                                                                                                                                       madin, bacdive
#> 85                                                                                                                                                                                                                                                                                       madin, bacdive
#> 86                                                                                                                                                                                                                                                                                                madin
#> 87                                                                                                                                                                                                                                                                              funguild, fungal_traits
#> 88                                                                                                                                                                                                                                                                                          eupolltrait
#> 89                                                                                                                                                                                                                                                                                         algae_traits
#> 90                                                                                                                                                                                                                                                                                         algae_traits
#> 91                                                                                                                                                                                                                                                                                         algae_traits
#> 92                                                                                                                                                                                                                                                                                         algae_traits
#> 93                                                                                                                                                                                                                                                                                  arctic_traits, nztd
#> 94                                                                                                                                                                                                                                                                                  arctic_traits, nztd
#> 95                                                                                                                                                                                                                                                                                  arctic_traits, nztd
#> 96                                                                                                                                                                                                                                                                                            octocoral
#> 97                                                                                                                                                                                                                                                                                            octocoral
#> 98                                                                                                                                                                                                                                    fishbase, sealifebase, quimbayo, pelagic, coral_traits, octocoral
#> 99                                                                                                                                                                                                                                    fishbase, sealifebase, quimbayo, pelagic, coral_traits, octocoral
#> 100                                                                                                                                                                                                                                                                     birdbase, repttraits, globtherm
#> 101                                                                                                                                                                                                                                                                     birdbase, repttraits, globtherm
#> 102                                                                                                                                                                                                                                                                       combine, homerange, pantheria
#> 103                                                                                                                                                                                                                                                                    avonet, chelonians, coral_traits
#> 104                                                                                                                                                                                                                                                            birdbase, combine, frugivoria, pantheria
#> 105                                                                                                                                                                                                                                                                            bet, frugivoria, combine
#> 106                                                                                                                                                                                                                                                                           amniote, anage, pantheria
#> 107                                                                                                                                                                                                                                                                       leda, gift, brot, diaz_traits
#> 108                                                                                                                                                                                                                                                                         austraits, leda, gift, bien
#> 109                                                                                                                                                                                                                                                                     fishbase, sealifebase, quimbayo
#> 110                                                                                                                                                                                                                                                                            bee_ostwald, eupolltrait
#> 111                                                                                                                                                                                                                                                                            bee_ostwald, eupolltrait
#> 112                                                                                                                                                                                                                                                                        combine, pantheria, birdbase
#> 113                                                                                                                                                                                                                                                                                   beukhof, quimbayo
#> 114                                                                                                                                                                                                                                                                                           fishmorph
#> 115                                                                                                                                                                                                                                                                                           fishmorph
#> 116                                                                                                                                                                                                                                                                                           fishmorph
#> 117                                                                                                                                                                                                                                                                                           fishmorph
#> 118                                                                                                                                                                                                                                                                                           fishmorph
#> 119                                                                                                                                                                                                                                                                                           fishmorph
#> 120                                                                                                                                                                                                                                                                                           fishmorph
#> 121                                                                                                                                                                                                                                                                                           fishmorph
#> 122                                                                                                                                                                                                                                                                                           fishmorph
#> 123                                                                                                                                                                                                                                                                              huang_amph, saproxylic
#> 124                                                                                                                                                                                                                                                                              huang_amph, saproxylic
#> 125                                                                                                                                                                                                                                                                                          huang_amph
#> 126                                                                                                                                                                                                                                                                                          huang_amph
#> 127                                                                                                                                                                                                                                                                         combine, pantheria, eurobat
#> 128                                                                                                                                                                                                                                                                         saproxylic, imageomics_neon
#> 129                                                                                                                                                                                                                                                                                          saproxylic
#> 130                                                                                                                                                                                                                                                                                          saproxylic
#> 131                                                                                                                                                                                                                                                                                rimet_phyto, bacdive
#> 132                                                                                                                                                                                                                                                                                rimet_phyto, bacdive
#> 133                                                                                                                                                                                                                                                                                         rimet_phyto
#> 134                                                                                                                                                                                                                                                                                         rimet_phyto
#> 135                                                                                                                                                                                                                                                                                         rimet_phyto
#> 136                                                                                                                                                                                                                                                                                        coral_traits
#> 137                                                                                                                                                                                                                                                                                        coral_traits
#> 138                                                                                                                                                                                                                                                                                          chelonians
#> 139                                                                                                                                                                                                                                                                                          saproxylic
#> 140                                                                                                                                                                                                                                                                       arthropod_traits, eupolltrait
#> 141                                                                                                                                                                                                                                                                                      madin, bacdive
#> 142                                                                                                                                                                                                                                                                                               madin
#> 143                                                                                                                                                                                                                                                                                         kew_cvalues
#> 144                                                                                                                                                                                                                                                                                      madin, bacdive
#> 145                                                                                                                                                                                                                                                                                               madin
#> 146                                                                                                                                                                                                                                conservation_status, birdbase, phylacine, quimbayo, pelagic, pottier
#> 147                                                                                                                                                                                                                                                                          beukhof, quimbayo, pelagic
#> 148                                                                                                                                                                                                                                                                                   beukhof, quimbayo
#> 149                                                                                                                                                                                                                                                                                             beukhof
#> 150                                                                                                                                                                                                                                                                                            quimbayo
#> 151                                                                                                                                                                                                                                                                                            fishbase
#> 152                                                                                                                                                                                                                                                                                             beukhof
#> 153                                                                                                                                                                                                                                         tree_of_sex, austraits, bet, coral_traits, octocoral, sheld
#> 154                                                                                                                                                                                                                                                                             repttraits, sharkipedia
#> 155                                                                                                                                                                                                                                                                                              italic
#> 156                                                                                                                                                                                                                                                                                         italic, bet
#> 157                                                                                                                                                                                                                                                                                              italic
#> 158                                                                                                                                                                                                                                                                                              italic
#> 159                                                                                                                                                                                                                                                                              austraits, diaz_traits
#> 160                                                                                                                                                                                                                                                                                     gift, austraits
#> 161                                                                                                                                                                                                                                                                     sealifebase, combine, phylacine
#> 162                                                                                                                                                                                                                                                                     sealifebase, combine, phylacine
#> 163                                                                                                                                                                                                                                                                             coral_traits, octocoral
#> 164                                                                                                                                                                                                                                                                             coral_traits, octocoral
#> 165                                                                                                                                                                                                                                                                             coral_traits, octocoral
#> 166                                                                                                                                                                                                                                                                             coral_traits, octocoral
#> 167                                                                                                                                                                                                                                                                                  avonet, saproxylic
#> 168                                                                                                                                                                                                                                                                                           leptraits
#> 169                                                                                                                                                                                                                                                                                              avonet
#> 170                                                                                                                                                                                                                                                                                              avonet
#> 171                                                                                                                                                                                                                                                                                beukhof, sharkipedia
#> 172                                                                                                                                                                                                                                                                                beukhof, sharkipedia
#> 173                                                                                                                                                                                                                                                                     globtherm, pottier, thermofresh
#> 174                                                                                                                                                                                                                                                                              globtherm, thermofresh
#> 175                                                                                                                                                                                                                                                            arthropod_traits, repttraits, hydraulics
#> 176                                                                                                                                                                                                                                                                                               noddb
#> 177                                                                                                                                                                                                                                                                                               sworm
#> 178                                                                                                                                                                                                                                                                                          fishtraits
#> 179                                                                                                                                                                                                                                                                                          fishtraits
#> 180                                                                                                                                                                                                                                                                                              avonet
#> 181                                                                                                                                                                                                                                                                                              avonet
#> 182                                                                                                                                                                                                                                                                                              avonet
#> 183                                                                                                                                                                                                                                                                                              avonet
#> 184                                                                                                                                                                                                                                                                                              avonet
#> 185                                                                                                                                                                                                                                                                                              avonet
#> 186                                                                                                                                                                                                                                                                                    groot, austraits
#> 187                                                                                                                                                                                                                                                                                    groot, austraits
#> 188                                                                                                                                                                                                                                                                                               groot
#> 189                                                                                                                                                                                                                                                                                               groot
#> 190                                                                                                                                                                                                                                                                                    groot, austraits
#> 191                                                                                                                                                                                                                                                                                    groot, austraits
#> 192                                                                                                                                                                                                                                                                                    groot, austraits
#> 193                                                                                                                                                                                                                                                                                         groot, brot
#> 194                                                                                                                                                                                                                                                                                               groot
#> 195                                                                                                                                                                                                                                                                                             combine
#> 196                                                                                                                                                                                                                                                                                       spider_traits
#> 197                                                                                                                                                                                                                                                                                       spider_traits
#> 198                                                                                                                                                                                                                                                                                         zooplankton
#> 199                                                                                                                                                                                                                                                                                         zooplankton
#> 200                                                                                                                                                                                                                                                                                           nesttrait
#> 201                                                                                                                                                                                                                                                                                           nesttrait
#> 202                                                                                                                                                                                                                                                                                           nesttrait
#> 203                                                                                                                                                                                                                                                                                          fungalroot
#> 204                                                                                                                                                                                                                                                                                                 bet
#> 205                                                                                                                                                                                                                                                                                                 bet
#> 206                                                                                                                                                                                                                                                                                                 bet
#> 207                                                                                                                                                                                                                                                                                        coral_traits
#> 208                                                                                                                                                                                                                                                                                        coral_traits
#> 209                                                                                                                                                                                                                                                                                        coral_traits
#> 210                                                                                                                                                                                                                                                                                           octocoral
#> 211                                                                                                                                                                                                                                                                         birdbase, chowdhury, finand
```
