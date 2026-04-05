# Enrichment TODO

## Ready to implement

| Name | Source | Species | Format | License | Type | Notes |
|---|---|---|---|---|---|---|
| LepTraits 1.0 | Figshare (Shirey et al. 2022) | 12,448 butterflies | CSV, CC0 | CC0 | Simple | Global coverage. Traits: wingspan, voltinism, habitat affinity, host plants, diapause stage. `consensus/consensus.csv` is species-level. DOI: 10.6084/m9.figshare.c.5899187.v1 |
| AnimalTraits | Zenodo (Hébert et al. 2022) | ~2,000 species (~1,700 arthropods) | CSV, CC0 | CC0 | Simple | Body mass, metabolic rate, brain size. Individual-level observations → aggregate to species means in parse function. Replaces "Brose body sizes" — GATEWAy is interaction-level, not species-level. URL: https://zenodo.org/record/6468938/files/observations.csv?download=1. DOI: 10.1038/s41597-022-01364-9 |
| NW European Arthropods | Zenodo (Logghe et al. 2025) | 4,874 arthropods | Darwin Core CSV | CC-BY-NC | Simple | 28 traits: body size, fecundity, voltinism, dispersal, feeding guild, thermal niche, habitat. 10 orders. Regional (NW Europe). CC-BY-NC is fine for open-source redistribution. DOI: 10.3897/BDJ.13.e146785 |


## Restricted access (cannot redistribute)

| Name | Source | Species | Access restriction | Notes |
|---|---|---|---|---|
| GlobalAnts (GABI) | globalants.org (Parr et al. 2017) | ~9,056 ants | Data sharing agreement required (TRY-like model) | Morphological + ecological traits. Cannot bundle as pre-built .vtr. |
| Carabids.org | carabids.org (Homburg et al. 2014) | ~3,400 carabid beetles | No license stated, "Copyright © 2012-2021 CARABIDS.ORG" = all rights reserved by default | Body size, wing development, diet, habitat. Free registration but no redistribution rights. No API. |
| GATEWAy (Brose) | iDiv (Brose 2018) | 5,736 species | License unclear | Interaction-level data (predator-prey pairs), NOT species-level. Wrong format for enrichment. |

## Possible alternatives for restricted datasets

- **Ants:** GABI distribution data on Dryad (CC0, 10.5061/dryad.jm63xsjh6) has occurrence records but no traits.
- **Carabids:** van der Plas et al. 2017 on Dryad (CC0, 10.5061/dryad.53ds2) has 120 Dutch carabid species with body/antenna/femur/eye measurements — too small to be useful standalone.
