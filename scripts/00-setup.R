# =============================================================================
# 00-setup.R
# =============================================================================
#
# Author:      [Melina Peressini, Silvia Pineda]
# Date:        YYYY-MM-DD
# Description: Global setup. Loads required libraries, defines common paths,
#              sets the master random seed, and creates output directories.
#              Sourced by all subsequent scripts.
#
# Inputs:      None
# Outputs:     None (sets up the R session)
# Runtime:     < 1 minute
#
# =============================================================================

# ---- Required libraries ------------------------------------------------------

suppressPackageStartupMessages({
  library(here)
  library(glmnet)
  library(caret)
  library(pROC)
  library(logistf)
  library(limma)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  # library(future)        # for parallel execution
  # library(future.apply)  # parallel apply functions
})


# ---- Master seed -------------------------------------------------------------

# All random operations downstream should respect this seed for full
# reproducibility of the paper's results.
GLOBAL_SEED <- 20260101


# ---- Paths -------------------------------------------------------------------

PATHS <- list(
  data_raw         = here("data", "raw"),
  data_processed   = here("data", "processed"),
  results_inter    = here("results", "intermediate"),
  results_figures  = here("results", "figures"),
  results_tables   = here("results", "tables"),
  R                = here("R")
)


# ---- Create output directories if they don't exist ---------------------------

for (p in c(PATHS$results_inter, PATHS$results_figures, PATHS$results_tables)) {
  dir.create(p, showWarnings = FALSE, recursive = TRUE)
}


# ---- Source reusable functions -----------------------------------------------

source(here("R", "load-data.R"))
source(here("R", "generate-scenarios.R"))
source(here("R", "validation-strategies.R"))
source(here("R", "lasso-fit.R"))
source(here("R", "metrics.R"))
source(here("R", "plotting-utils.R"))


# ---- Experimental parameters -------------------------------------------------

# These match the paper's main experiment. For local testing, override them
# in the calling script (e.g. by setting B_TRAINING <- 5, B_BOOTSTRAP <- 10).

EXPERIMENT_PARAMS <- list(
  n_train       = 100,                          # training set size
  B_training    = 100,                          # number of training subsets per scenario
  scenarios     = c(
    excellent   = 0,                            # proportion permuted
    moderate    = 0.30,
    null        = 1.00
  ),
  B_bootstrap   = 100,                          # bootstrap replicates per BS strategy
  cv_repeats_5  = 20,                           # repetitions for 5-fold CV
  cv_repeats_10 = 10,                           # repetitions for 10-fold CV
  n_lambda      = 100                           # LASSO lambda grid size
)


# ---- Session info (for reproducibility) --------------------------------------

# Saved on first run; used to track the environment that produced the results.
session_info_path <- file.path(PATHS$results_inter, "session-info.txt")
if (!file.exists(session_info_path)) {
  capture.output(sessionInfo(), file = session_info_path)
}

message("Setup complete. Master seed: ", GLOBAL_SEED)
