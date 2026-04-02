---
name: taxify package
description: New R package for unified offline taxonomic name matching — combines taxize multi-backend approach with WorldFlora offline design, adds hybrid support and encoding resilience
type: project
---

taxify: R package for offline taxonomic name matching with multiple backends (WFO, COL, GBIF backbone), unified output, hybrid-native parsing, and encoding resilience.

**Why:** taxize was removed from CRAN (Oct 2024) due to API dependency rot. WorldFlora is CRAN-stable but WFO-only and painful in practice (hybrid hacks, manual encoding fixes, batch splitting — see ASAAS EVA pipeline on J: drive at `/j/Phd Local/Gilles_paper2/Data/ASAAS/Data prep/05_Taxa_WFO/`). Neither package solves the full problem.

**How to apply:** Plan lives at `C:\Users\Gilles Colling\Documents\dev\taxify\plan.md`. Key design: offline Darwin Core snapshots, pluggable backend interface (S3 generics), name parser that handles hybrids at tokenizer level, cleaning pipeline for mojibake/qualifiers, fallback chain across backends.
