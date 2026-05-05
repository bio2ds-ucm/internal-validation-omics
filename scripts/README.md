# `scripts/` — Analysis pipeline

This folder contains numbered scripts that reproduce the full benchmark study presented in the paper. Scripts must be run **in order**.

## Pipeline

| Script | Purpose | Approx. runtime |
|---|---|---|
| `00-setup.R` | Load libraries, define paths, set global seeds | < 1 min |
| `01-data-preparation.R` | Load and preprocess MMDx-Kidney and SCAN-B datasets | minutes |
| `02-generate-scenarios.R` | Generate three discrimination scenarios + 100 training subsets per scenario | minutes |
| `03-run-experiment.R` | **Main loop**: fit LASSO + apply 5 validation strategies × all scenarios × all training subsets | **hours/days** (HPC needed) |
| `04-collect-results.R` | Consolidate all intermediate results into tidy data frames | minutes |
| `05-figures-main.R` | Generate Figures 1–5 of the paper | < 10 min |
| `06-figures-supplementary.R` | Generate Supplementary Figures S1–S7 | < 10 min |
| `07-tables.R` | Generate Table 1 of the paper | < 5 min |

## How to run

For a small-scale local run (with reduced parameters), execute scripts in order:

```bash
Rscript scripts/00-setup.R
Rscript scripts/01-data-preparation.R
Rscript scripts/02-generate-scenarios.R
Rscript scripts/03-run-experiment.R
Rscript scripts/04-collect-results.R
Rscript scripts/05-figures-main.R
Rscript scripts/06-figures-supplementary.R
Rscript scripts/07-tables.R
```

For full reproduction (with the same parameters as the paper), launch each `03-run-experiment.R` call in parallel on a multi-core machine, e.g. with `nohup`:

```bash
nohup Rscript scripts/03-run-experiment.R mmdx-kidney excellent > mmdx-excellent.log 2>&1 &
nohup Rscript scripts/03-run-experiment.R mmdx-kidney moderate  > mmdx-moderate.log 2>&1 &
# ...etc.
```

## Conventions

- Each script is **self-contained** and can be run independently as long as previous scripts have been executed.
- Use `here::here()` (package `here`) for all paths — never `setwd()` or absolute paths.
- Source reusable functions from `R/` at the top of each script:
  ```r
  library(here)
  source(here("R", "validation-strategies.R"))
  ```
- Save intermediate outputs to `results/intermediate/` so the next script can read them.
- Each script has a header documenting:
  - Author and date
  - Brief description
  - Inputs (files needed)
  - Outputs (files generated)
  - Approximate runtime
