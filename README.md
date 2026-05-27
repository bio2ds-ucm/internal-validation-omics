# Internal validation strategies for high-dimensional transcriptomic prediction modeling in Ultra-High Dimensional Transcriptomic Settings

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: in preparation](https://img.shields.io/badge/status-in%20preparation-orange)](#)

> Code and analysis pipeline accompanying the paper:
>
> **Peressini M., Calviño A, Medrano E, Zugazagoitia J, Pineda, S.** *Internal Validation Strategies for LASSO Prediction Models in Ultra-High Dimensional Transcriptomic Settings: A Real-Data-Based Simulation Study*. Submitted to *Bioinformatics*, 2026.
>

---

## 📋 Overview

This repository contains the R code for a benchmark study of internal validation strategies (repeated *k*-fold cross-validation and bootstrap variants) applied to LASSO logistic regression in ultra-high dimensional (p≫n) transcriptomic settings.

The study compares five resampling-based validation strategies — 20-rep 5-fold CV, 10-rep 10-fold CV, regular bootstrap, .632 bootstrap, and .632+ bootstrap — across three discrimination scenarios (excellent, moderate, null) and two real-world transcriptomic datasets, evaluating both performance estimation (AUC, calibration slope) and the impact of validation choice on hyperparameter tuning.

> ⚠️ This README is preliminary. It will be updated with full abstract and results summary upon submission.

## 👥 Authors

- **Melina Peressini** — Hospital Universitario 12 de Octubre Research Institute · Faculty of Statistical Studies, Universidad Complutense de Madrid · BIO2DS-UCM · [ORCID](https://orcid.org/XXXX-XXXX-XXXX-XXXX)
  
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
| MMDx-Kidney | [GSE275126](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE275126) | Microarray (Affymetrix PrimeView) | Kidney transplant rejection (yes/no) | ~5,000 |
| SCAN-B | [GSE202203](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202203) | RNA-seq | Breast cancer Luminal A subtype (yes/no) | 2,854 |

See [`data/README.md`](data/README.md) for download and preprocessing instructions.

## ⚙️ Requirements

- **R version 4.4.1** (the version used for the paper).
- R packages used in the pipeline:
  - Core analysis: `glmnet`, `caret`, `pROC`, `logistf`, `furrr`, `future`, `parallel`
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

The full experiment is **computationally heavy** (≈ 1500 LASSO fits with nested tuning per dataset). It was run on a multi-core workstation with 50 cores (`ncores = 50` in `R/global_parameters.R` — adjust to your hardware). Plan for several hours per (dataset × scenario) combination.

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
  title   = {Internal validation strategies for high-dimensional transcriptomic prediction modeling},
  author  = {Peressini M., Calviño A, Medrano E, Zugazagoitia J, Pineda, S.},
  journal = {Bioinformatics},
  year    = {2026},
  doi     = {[DOI]}
}

@software{peressini2026code,
  author    = {Peressini, Melina},
  title     = {Code for: Internal validation strategies for high-dimensional transcriptomic prediction modeling},
  year      = {2026},
  publisher = {Zenodo},
  doi       = {[Zenodo DOI]},
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
