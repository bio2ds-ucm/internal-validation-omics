# `results/` — Outputs

Auto-generated outputs from running the analysis pipeline.

## Structure

```
results/
├── intermediate/   # Simulated data and results from the fitted LASSO models across the 100 simulations (gitignored)
├── figures/        # TIFF figures of the paper (tracked)
└── tables/         # XLSX supplementary tables (tracked)
```

## Why `intermediate/` is gitignored

The intermediate results contain `.rds` and `.RData` files corresponding to the simulated data and results from the 400 fitted LASSO models across the 100 simulations, including coefficients and performance values, per (dataset × scenario) combination. These files can total several GB and are fully reproducible from the input data via the scripts under `../scripts/`. Tracking them in Git would bloat the repository without benefit.

Examples of files written to `intermediate/`:

- `GSE275126_processed_data.rds` — preprocessed dataset
- `GSE275126_data_sim_scenarios.rds` — generated scenarios
- `GSE275126_scenario{1,2,3}_results.rds` — main experiment outputs
- `GSE275126_UMAP.rds`, `GSE275126_DGE_analysis.rds`
- `GSE275126_binded_results.RData` — consolidated results
- (and analogous files for `GSE202203`)

## Final outputs

The figures (TIFF) and tables (XLSX) in `figures/` and `tables/` ARE tracked, so anyone cloning the repo can immediately see the final results without re-running the heavy pipeline.

### Figures expected

After running `scripts/9_Figure_generation.R` twice (once per dataset), this folder will contain:

- `Figure_3.tiff`, `Figure_4.tiff`, `Figure_5.tiff`, `Figure_6.tiff` — main paper figures (Figs 3-6).
- `Figure_S1.tiff` to `Figure_S12.tiff` — supplementary figures.

> Note: Figures 1 and 2 of the paper are conceptual diagrams (study design and validation strategies) composed externally.

### Tables expected

- `Supp_File_auc_MMDx-Kidney dataset.xlsx`, `Supp_File_auc_SCAN-B dataset.xlsx`
- `Supp_File_slope_MMDx-Kidney dataset.xlsx`, `Supp_File_slope_SCAN-B dataset.xlsx`

> Note: Supplementary File of the paper combines the results from these four tables into a single file, with each table on a separate sheet.

