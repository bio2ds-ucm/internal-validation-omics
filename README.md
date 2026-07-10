# Internal Validation Strategies for LASSO Prediction Models in Ultra-High Dimensional Transcriptomic Settings: A Real-Data-Based Simulation Study

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20443008.svg)](https://doi.org/10.5281/zenodo.20443008)

> Code and analysis pipeline accompanying the paper:
>
> **Peressini M., Calviño A, Medrano E, Zugazagoitia J, Pineda, S.** *Internal Validation Strategies for LASSO Prediction Models in Ultra-High Dimensional Transcriptomic Settings: A Real-Data-Based Simulation Study*. Submitted to *BMC Bioinformatics*, 2026.
>

---

## 📋 Overview

This repository contains the R code for a benchmark study of internal validation strategies (repeated *K*-fold cross-validation and bootstrap variants) applied to LASSO logistic regression in ultra-high dimensional (p ≫ n) transcriptomic settings.

## 📋 Abstract

Motivation: Resampling-based internal validation strategies are routinely used for hyperparameter tuning and post-development performance estimation in penalized regression. However, their behaviour in ultra-high dimensional transcriptomic settings (p≫n) remains poorly understood, and evidence from large real-world datasets is lacking.

Results: Using two large transcriptomic datasets (MMDx-Kidney, n = 5 086; SCAN-B, n = 2 854) as reference populations to benchmark estimates against true performance, we evaluated repeated K-fold cross-validation (20-repeated 5-fold and 10-repeated 10-fold), regular bootstrap, .632 bootstrap and .632+ bootstrap for LASSO logistic prediction models. We defined three scenarios of varying signal-to-noise (excellent, moderate and null discrimination) by permuting outcome labels, then sampled 100 training sets of size 100 per scenario and estimated true performance on the large held-out data. Regular and .632 bootstrap systematically overestimated discrimination (AUC), with bias amplified under weaker signal and when used for tuning, where they promoted more complex models enriched in weakly informative genes. The .632+ bootstrap was the most accurate bootstrap variant, with lower bias and greater robustness, though it occasionally underestimated performance. Repeated K-fold cross-validation showed the lowest bias and produced sparser models. All strategies showed substantial variability, and reliable calibration slope estimation was not feasible in p≫n settings. We recommend repeated K-fold cross-validation as the default approach and emphasize reporting uncertainty measures alongside point estimates.

## 👥 Authors

- **Melina Peressini** — Instituto de Investigación Sanitaria Hospital 12 de Octubre (imas12) · Faculty of Statistical Studies, Universidad Complutense de Madrid · BIO2DS-UCM · [ORCID](https://orcid.org/my-orcid?orcid=0009-0008-7844-2067)
  
This work was carried out within the [BIO2DS-UCM](https://github.com/bio2ds-ucm) research group (Biomedical Data Science and Biostatistics, Universidad Complutense de Madrid).

## 📁 Repository structure

```
.
├── R/                          # Reusable R functions and global parameters
│   ├── global_parameters.R     # Experiment-wide settings (seed, n_train, etc.)
│   └── required_functions.R    # Core machinery (LASSO, CV, bootstrap, metrics)
├── scripts/                    # Numbered pipeline scripts (run in order)
│   ├── GSE275126_code/         # Pipeline for MMDx-Kidney (microarray)
│   ├── GSE202203_code/         # Pipeline for SCAN-B (RNA-seq)
│   └── 9_Figure_generation.R   # Final figures and tables of the paper
├── data/                       # Documentation on how to obtain the datasets
├── results/
│   ├── intermediate/           # Fitted models and intermediate outputs (gitignored)
│   ├── figures/                # Paper figures (TIFF)
│   └── tables/                 # Supplementary tables (XLSX)
├── README.md
├── CITATION.cff                # Machine-readable citation metadata
├── LICENSE                     # MIT License
└── .gitignore
```

See the README inside each subfolder for details on what goes there.

## 🔬 Datasets

This study uses two publicly available transcriptomic cohorts from GEO:

| Dataset | GEO accession | Technology | Outcome | n samples |
|---|---|---|---|---|
| MMDx-Kidney | [GSE275126](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE275126) | Microarray (Affymetrix PrimeView) | Kidney transplant rejection (yes/no) | 5,086 |
| SCAN-B | [GSE202203](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202203) | RNA-seq | Breast cancer Luminal A subtype (yes/no) | 2,854 |

See [`data/README.md`](data/README.md) for download and preprocessing instructions.

## ⚙️ Requirements

- **R version 4.4.1** (the version used for the paper).
- R packages used in the pipeline:
  - Core analysis: `glmnet`, `caret`, `pROC`, `logistf`, `furrr`, `future`
  - Data wrangling: `dplyr`, `tibble`, `tidyr`, `stringr`, `tidyverse`, `data.table`
  - Plotting: `ggplot2`, `ggdist`, `ggplotify`, `cowplot`, `scales`
  - Bioinformatics (data processing): `GEOquery`, `affy`, `primeviewhsentrezgcdf` (Bioconductor) for microarray; `EDASeq`, `edgeR`, `DESeq2`, `limma` (Bioconductor) for RNA-seq
  - Other: `here`, `openxlsx`, `Seurat`, `uwot`

To install:

```r
install.packages(c("glmnet", "caret", "pROC", "logistf", "furrr", "future",
                   "dplyr", "tibble", "tidyr", "stringr", "tidyverse", "data.table",
                   "ggplot2", "ggdist", "ggplotify", "cowplot", "scales",
                   "here", "openxlsx", "Seurat", "uwot"))

# Bioconductor packages:
if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install(c("GEOquery", "affy", "primeviewhsentrezgcdf",
                       "EDASeq", "edgeR", "DESeq2", "limma"))
```

## 🚀 How to reproduce the analysis

The full experiment is **computationally heavy**. It was run on a multi-core workstation with 50 cores (`ncores = 50` in `R/global_parameters.R` — adjust to your hardware). Plan for several days per (dataset × scenario) combination.

Run the pipeline in order. For each dataset:

```bash
# After obtaining the data — see data/README.md

# 1. Process raw data
Rscript scripts/GSE275126_code/1_GSE275126_data_processing.R
Rscript scripts/GSE202203_code/1_GSE202203_data_processing.R

# 2. Generate simulated scenarios (outcome permutation)
Rscript scripts/GSE275126_code/2_GSE275126_simulated_scenarios.R
Rscript scripts/GSE202203_code/2_GSE202203_simulated_scenarios.R

# 3-5. Run main experiment for each scenario (the heavy part — can be parallelized)
Rscript scripts/GSE275126_code/3_GSE275126_execution_scenario1.R
Rscript scripts/GSE275126_code/4_GSE275126_execution_scenario2.R
Rscript scripts/GSE275126_code/5_GSE275126_execution_scenario3.R
Rscript scripts/GSE202203_code/3_GSE202203_execution_scenario1.R
Rscript scripts/GSE202203_code/4_GSE202203_execution_scenario2.R
Rscript scripts/GSE202203_code/5_GSE202203_execution_scenario3.R

# 6. UMAP for dataset characterization
Rscript scripts/GSE275126_code/6_GSE275126_UMAP.R
Rscript scripts/GSE202203_code/6_GSE202203_UMAP.R

# 7. Consolidate scenario results
Rscript scripts/GSE275126_code/7_GSE275126_compute_estimates.R
Rscript scripts/GSE202203_code/7_GSE202203_compute_estimates.R

# 8. Differential expression analysis (for characterization)
Rscript scripts/GSE275126_code/8_GSE275126_DGE_analysis.R
Rscript scripts/GSE202203_code/8_GSE202203_DGE_analysis.R

# 9. Generate figures (RUN TWICE — once per dataset, see note in the script)
Rscript scripts/9_Figure_generation.R
```

The execution scripts (3, 4, 5) can be launched in parallel (e.g., one per terminal or via `nohup`) since they are independent of each other.

## 📊 Results

After running the full pipeline, all figures and tables of the paper will be generated under `results/figures/` (TIFF) and `results/tables/` (XLSX). Intermediate results (fitted LASSO models, predictions, etc.) are stored under `results/intermediate/` and are not committed to Git due to size — they are fully reproducible from the input data via the scripts above.

## 📜 How to cite

If you use this code, please cite both the paper and the software archive (DOI to be added once the Zenodo release is created):

```bibtex
@article{peressini2026validation,
  title   = {Internal Validation Strategies for LASSO Prediction Models in Ultra-High Dimensional Transcriptomic Settings: A Real-Data-Based Simulation Study},
  author  = {Peressini M., Calviño A, Medrano E, Zugazagoitia J, Pineda, S.},
  journal = {Bioinformatics},
  year    = {2026},
  doi     = {[DOI]}
}

@software{peressini2026code,
  author    = {Peressini, Melina},
  title     = {Code for: Internal Validation Strategies for LASSO Prediction Models in Ultra-High Dimensional Transcriptomic Settings: A Real-Data-Based Simulation Study},
  year      = {2026},
  publisher = {Zenodo},
  doi       = {10.5281/zenodo.20610890},
  url       = {https://github.com/bio2ds-ucm/internal-validation-omics}
}
```

See [`CITATION.cff`](CITATION.cff) for machine-readable citation metadata.

## 📄 License

This code is released under the [MIT License](LICENSE).

## 📬 Contact

For questions about the code, please [open an issue](https://github.com/bio2ds-ucm/internal-validation-omics/issues) in this repository or contact:

- Melina Peressini - [mperessi@ucm.es](mailto:mperessi@ucm.es)
- Silvia Pineda — [sipineda@ucm.es](mailto:sipineda@ucm.es)
---

<sub>Maintained by the [BIO2DS-UCM](https://github.com/bio2ds-ucm) research group · Universidad Complutense de Madrid</sub>
