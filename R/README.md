# `R/` — Reusable functions

This folder contains reusable R functions sourced by the analysis scripts in [`../scripts/`](../scripts/). Functions here implement the core building blocks of the validation experiment.

## Files

| File | Purpose |
|---|---|
| `load-data.R` | Functions to load and harmonize the MMDx-Kidney and SCAN-B datasets |
| `generate-scenarios.R` | Outcome-permutation functions to generate the three discrimination scenarios (excellent, moderate, null) |
| `validation-strategies.R` | Implementations of the five validation strategies (20-rep 5-fold CV, 10-rep 10-fold CV, regular BS, .632 BS, .632+ BS) |
| `lasso-fit.R` | Wrappers around `glmnet`/`caret` for LASSO logistic regression with hyperparameter tuning |
| `metrics.R` | AUC and calibration slope (Firth's) computation |
| `plotting-utils.R` | Shared plot styling, color palettes, and helpers |

## Convention

- One topic per file.
- Each function should have a roxygen-style header documenting parameters and return value:
  ```r
  #' Generate a permutation-based discrimination scenario
  #'
  #' @param y Numeric outcome vector (0/1)
  #' @param prop_permuted Proportion of samples whose outcome is shuffled (0, 0.3, or 1)
  #' @param seed Optional integer seed for reproducibility
  #' @return Permuted outcome vector of the same length as y
  generate_scenario <- function(y, prop_permuted, seed = NULL) {
    # ...
  }
  ```
- Source these functions from scripts using `here::here()`:
  ```r
  source(here::here("R", "validation-strategies.R"))
  ```

## What does NOT go here

- Executable analysis pipelines → those go in [`../scripts/`](../scripts/) and are numbered.
- Data → goes in [`../data/`](../data/) (or external storage for raw data).
