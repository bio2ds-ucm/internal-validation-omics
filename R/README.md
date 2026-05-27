# `R/` — Functions and global parameters

This folder contains code that is **sourced** by the pipeline scripts but is not executed standalone. It centralizes the reusable parts of the analysis.

## Files

| File | Purpose |
|---|---|
| `global_parameters.R` | Experiment-wide settings: master seed, number of simulations (`nsim`), training set size (`nsubjects_train`), LASSO lambda grid length, *k* values for k-fold CV, repetitions, number of bootstrap samples (`nboot`), and number of cores for parallelization (`ncores`). |
| `required_functions.R` | All the core machinery of the experiment: LASSO grid construction (`lasso_grid_search`), model fitting with internal tuning (`model_fitting`), performance metrics including AUC and calibration slope (`performance`), repeated k-fold CV (`repeated_cv`), bootstrap variants — regular, .632, .632+ (`bootstrap`), tuning performance evaluation across all strategies (`tuning_performance`), and the main pipeline functions (`fitting_and_validation` and its parallel version `fitting_and_validation_mclapply`). |

## How they are used

Pipeline scripts in `../scripts/` source these files at the top:

```r
library(here)
source(here::here("R", "required_functions.R"))
source(here::here("R", "global_parameters.R"))
```

## Adjusting parameters

If you want to run the experiment with different settings (e.g., fewer simulations for a quick test), edit `global_parameters.R` before running the execution scripts:

- `nsim` — number of simulations per scenario.
- `ncores` — adjust to your hardware (default: 50). Reduce on smaller machines.
- `nboot` — bootstrap replicates.
- `seed` — master seed for reproducibility.
