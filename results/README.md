# `results/` — Outputs

Auto-generated outputs from running the analysis pipeline. Three subfolders:

| Subfolder        | What it contains                                       | Tracked by Git? |
|------------------|--------------------------------------------------------|-----------------|
| `intermediate/`  | Fitted models, predictions, tidy results data frames   | ❌ gitignored (heavy, reproducible) |
| `figures/`       | PDF and PNG figures of the paper                       | ✅ tracked      |
| `tables/`        | CSV tables of the paper                                | ✅ tracked      |

## Why `intermediate/` is gitignored

The intermediate results contain ≈ 3000 fitted LASSO models per dataset plus their predictions. These files can total several GB and are fully reproducible from the input data via `scripts/03-run-experiment.R`. Tracking them in Git would bloat the repository and slow down clones with no benefit.

If reviewers or collaborators need to inspect specific intermediate files, they can be shared on demand or deposited separately on Zenodo / OSF.

## Final outputs

The figures and tables in `figures/` and `tables/` ARE tracked, so anyone cloning the repo can immediately see the final results without re-running the heavy pipeline.

## Convention

- Save figures as both `.pdf` (vector, for the paper) and `.png` (preview, for GitHub web view).
- Use sensible filenames: `fig01-study-design.pdf`, `figS01-mmdx-characterization.pdf`, `table01-dataset-characterization.csv`.
- Use the helper `save_figure()` from `R/plotting-utils.R` to ensure both formats are saved consistently.
