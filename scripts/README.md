# `scripts/` — Analysis pipeline

This folder contains the numbered scripts that reproduce the full study. The pipeline is split into two parallel sub-pipelines (one per dataset) plus a shared figure-generation script.

## Structure

```
scripts/
├── GSE275126_code/                # MMDx-Kidney pipeline (microarray)
│   ├── 1_GSE275126_data_processing.R
│   ├── 2_GSE275126_simulated_scenarios.R
│   ├── 3_GSE275126_execution_scenario1.R
│   ├── 4_GSE275126_execution_scenario2.R
│   ├── 5_GSE275126_execution_scenario3.R
│   ├── 6_GSE275126_UMAP.R
│   ├── 7_GSE275126_compute_estimates.R
│   └── 8_GSE275126_DGE_analysis.R
├── GSE202203_code/                # SCAN-B pipeline (RNA-seq)
│   └── (same 8 numbered scripts)
└── 9_Figure_generation.R          # Shared figure and table generation
```

## Pipeline stages (per dataset)

| Stage | Script | Purpose | Runtime |
|---|---|---|---|
| 1 | `1_*_data_processing.R` | Download from GEO + preprocess (normalize, transform). For MMDx-Kidney: RMA on CEL files. For SCAN-B: upper-quartile normalization and VST transformation on raw counts. | minutes |
| 2 | `2_*_simulated_scenarios.R` | Generate the three discrimination scenarios by permuting the outcome in 0% / 30% / 100% of samples. | minutes |
| 3–5 | `3_*_execution_scenarioX.R` | **Heavy:** run the experiment for each scenario (400 LASSO fits with nested tuning, evaluated under 5 validation strategies). Can be run in parallel. | **days** |
| 6 | `6_*_UMAP.R` | UMAP for dataset characterization (Supplementary Figures S1, S2). | minutes |
| 7 | `7_*_compute_estimates.R` | Consolidate scenario results into tidy data frames for figure generation. | minutes |
| 8 | `8_*_DGE_analysis.R` | Differential gene expression analysis with limma-trend for dataset characterization and identification of weakly informative genes. | minutes |

## Final stage (shared)

| Script | Purpose |
|---|---|
| `9_Figure_generation.R` | Generates all figures (Figs 1–6, S1–S12) and tables for Supplementary File. **Must be run twice** — once for each dataset — by editing the `dataset` variable at the top of the script. |

## Execution order

For full reproduction:

1. Run stages 1–8 for `GSE275126` and `GSE202203` (the two sub-pipelines can be run in parallel).
2. Within each sub-pipeline, scripts must be run in numerical order (1 → 8). Scripts 3, 4, 5 can be parallelized.
3. Run `9_Figure_generation.R` twice (once per dataset).

See the main [`../README.md`](../README.md) for the complete command sequence.

## Parallelization

The experiment is computationally heavy. Parallelization is used:

- **Within R**: `fitting_and_validation()` (in `R/required_functions.R`) uses `furrr`/`future` to parallelize the simulations across cores. Adjust `ncores` in `R/global_parameters.R` (default: 50) to your hardware.
- **Across scripts**: scripts 3, 4, 5 (the three scenario executions per dataset) are independent and can be launched in separate terminals or via `nohup` to run in parallel.

## Inputs and outputs

- **Inputs**: raw data files in `data/raw/` (see [`../data/README.md`](../data/README.md) for how to obtain them).
- **Intermediate outputs**: written to `results/intermediate/` (not tracked by Git).
- **Final outputs**: figures (TIFF) in `results/figures/`, tables (XLSX) in `results/tables/`.

All paths in the scripts use `here::here()`, so the pipeline works regardless of where the repository is cloned, as long as the user opens it as an RStudio project or runs the scripts from the project root.
