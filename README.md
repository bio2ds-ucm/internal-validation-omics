# Internal validation strategies for high-dimensional transcriptomic prediction modeling

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Status: in preparation](https://img.shields.io/badge/status-in%20preparation-orange)](#)

> Code and analysis pipeline accompanying the paper:
>
> **Peressini, M, Calviño, A,Zugazagoitia, J, Pineda , S.**\* Internal validation strategies for high-dimensional transcriptomic prediction modeling: a comparative study using real-world data*. Submitted to* Bioinformatics\*, 2026.
>
> *Title and authors are provisional and will be updated upon submission.*

------------------------------------------------------------------------

## 📋 Overview

This repository contains the R code for a benchmark study of internal validation strategies (repeated *k*-fold cross-validation and bootstrap variants) applied to LASSO logistic regression in ultra-high dimensional (p≫n) transcriptomic settings.

The study compares five resampling-based validation strategies — 20-rep 5-fold CV, 10-rep 10-fold CV, regular bootstrap, .632 bootstrap, and .632+ bootstrap — across three discrimination scenarios (excellent, moderate, null) and two real-world transcriptomic datasets, evaluating both performance estimation (AUC, calibration slope) and the impact of validation choice on hyperparameter tuning.

> ⚠️ This README is preliminary. It will be updated with full abstract and results summary upon submission.

## 👥 Authors

-   **Melina Peressini** — Hospital Universitario 12 de Octubre Research Institute · Faculty of Statistical Studies, Universidad Complutense de Madrid · BIO2DS-UCM · [ORCID](https://orcid.org/XXXX-XXXX-XXXX-XXXX)

This work was carried out within the [BIO2DS-UCM](https://github.com/bio2ds-ucm) research group (Biomedical Data Science and Biostatistics, Universidad Complutense de Madrid).

## 📁 Repository structure

```         
.
├── R/              # Reusable R functions sourced by scripts
├── scripts/        # Numbered scripts that reproduce the study
├── data/           # Documentation on how to obtain MMDx-Kidney and SCAN-B
├── results/        # Output of the analyses (figures, tables, intermediate files)
├── README.md       # This file
├── CITATION.cff    # Machine-readable citation metadata
├── LICENSE         # MIT License
└── .gitignore
```

See the README inside each subfolder for details on what goes there.

## 🔬 Datasets

This study uses two publicly described transcriptomic cohorts:

-   **MMDx-Kidney** — microarray gene expression from kidney transplant biopsies (NCT01299168, NCT04239703).
-   **SCAN-B** — RNA-sequencing from invasive primary breast cancer tumors (NCT02306096).

See [`data/README.md`](data/README.md) for access instructions.

## ⚙️ Requirements

-   **R version 4.4.1** (the version used for the paper).
-   R packages: `glmnet`, `caret`, `pROC`, `logistf`, `limma`, `here`, `dplyr`, `tidyr`, `ggplot2`.

To install:

``` r
install.packages(c("glmnet", "caret", "pROC", "logistf",
                   "here", "dplyr", "tidyr", "ggplot2"))
# limma comes from Bioconductor:
if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("limma")
```

The exact session info used to produce the results is recorded in `results/session-info.txt` after running `scripts/00-setup.R`.

## 🚀 How to reproduce the analysis

The full experiment is **computationally heavy** (≈ 1500 LASSO fits with nested tuning per dataset) and was run on a multi-core workstation. Plan for several hours per (dataset × scenario) combination.

To run the pipeline end-to-end:

``` bash
# 1. Clone the repo
git clone https://github.com/bio2ds-ucm/paper-bioinformatics-2026.git
cd paper-bioinformatics-2026

# 2. (After obtaining the data — see data/README.md)
#    Run the scripts in order:

Rscript scripts/00-setup.R
Rscript scripts/01-data-preparation.R
Rscript scripts/02-generate-scenarios.R
Rscript scripts/03-run-experiment.R mmdx-kidney excellent
Rscript scripts/03-run-experiment.R mmdx-kidney moderate
Rscript scripts/03-run-experiment.R mmdx-kidney null
Rscript scripts/03-run-experiment.R scan-b excellent
Rscript scripts/03-run-experiment.R scan-b moderate
Rscript scripts/03-run-experiment.R scan-b null
Rscript scripts/04-collect-results.R
Rscript scripts/05-figures-main.R
Rscript scripts/06-figures-supplementary.R
Rscript scripts/07-tables.R
```

Each `03-run-experiment.R` call can be launched in parallel (one per terminal or via `nohup`) on a multi-core machine.

## 📊 Results

After running the full pipeline, all figures and tables of the paper will be generated under `results/figures/` and `results/tables/`. Intermediate model fits and predictions are stored under `results/intermediate/` (not committed to Git due to size).

## 📜 How to cite

If you use this code, please cite both the paper and the software archive (DOI to be added once the Zenodo release is created):

``` bibtex
@article{peressini2026validation,
  title   = {Internal validation strategies for high-dimensional transcriptomic prediction modeling},
  author  = {Peressini, M, Calviño, A, Zugazagoitia, J, Pineda , S.},
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
  url       = {https://github.com/bio2ds-ucm/paper-bioinformatics-2026}
}
```

See [`CITATION.cff`](CITATION.cff) for machine-readable citation metadata.

## 📄 License

This code is released under the [MIT License](LICENSE).

## 📬 Contact

For questions about the code, please [open an issue](https://github.com/bio2ds-ucm/paper-bioinformatics-2026/issues) in this repository or contact:

-   Melina Peressini -
-   Silvia Pineda San Juan — [sipineda\@ucm.es](mailto:sipineda@ucm.es)

------------------------------------------------------------------------

<sub>Maintained by the [BIO2DS-UCM](https://github.com/bio2ds-ucm) research group · Universidad Complutense de Madrid</sub>
