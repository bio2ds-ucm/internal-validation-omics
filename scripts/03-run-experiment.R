# =============================================================================
# 03-run-experiment.R
# =============================================================================
#
# Author:      [Melina Peressini, Silvia Pineda]
# Date:        YYYY-MM-DD
# Description: MAIN EXPERIMENT. For each dataset, scenario, and training subset,
#              fits LASSO under each tuning strategy and evaluates each of the
#              five validation strategies. Saves all intermediate results.
#
# Inputs:
#   - results/intermediate/scenarios-mmdx-kidney.rds
#   - results/intermediate/scenarios-scan-b.rds
#   - data/processed/{mmdx-kidney,scan-b}.rds
#
# Outputs:
#   - results/intermediate/experiment-results-{dataset}-{scenario}.rds
#       For each combination, a list per training subset with:
#         - fitted models per tuning strategy
#         - selected genes per tuning strategy
#         - performance estimates from each of the 5 validation strategies
#         - true performance on the independent evaluation set
#
# Runtime:     HOURS / DAYS depending on hardware. Run on a multi-core
#              workstation. Each (dataset, scenario) call can be launched
#              in parallel via nohup or separate terminals.
#
# Usage:       Rscript scripts/03-run-experiment.R <dataset> <scenario>
#
#              dataset  : "mmdx-kidney" or "scan-b"
#              scenario : "excellent", "moderate", or "null"
#
#              Example: Rscript scripts/03-run-experiment.R mmdx-kidney moderate
#
# =============================================================================

source(here::here("scripts", "00-setup.R"))


# ---- Parse command-line arguments --------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: Rscript 03-run-experiment.R <dataset> <scenario>")
}

dataset_name  <- args[1]   # "mmdx-kidney" or "scan-b"
scenario_name <- args[2]   # "excellent", "moderate", or "null"

stopifnot(dataset_name  %in% c("mmdx-kidney", "scan-b"))
stopifnot(scenario_name %in% c("excellent",   "moderate", "null"))


# ---- Load data and scenarios -------------------------------------------------

# data       <- readRDS(file.path(PATHS$data_processed, paste0(dataset_name, ".rds")))
# scenarios  <- readRDS(file.path(PATHS$results_inter, paste0("scenarios-", dataset_name, ".rds")))
# this_scenario <- scenarios[[scenario_name]]


# ---- Tuning strategies to evaluate -------------------------------------------

tuning_strategies <- c(
  "cv"     = "Repeated 5-fold CV (5 reps)",
  "bs"     = "Regular bootstrap (B=100)",
  "bs632"  = ".632 bootstrap (B=100)"
)


# ---- Validation strategies to evaluate ---------------------------------------

# All 5 strategies are applied to evaluate each fitted model.
validation_strategies <- c("rep5cv", "rep10cv", "bs", "bs632", "bs632plus")


# ---- Main loop ---------------------------------------------------------------

# results <- vector("list", EXPERIMENT_PARAMS$B_training)
#
# for (b in seq_len(EXPERIMENT_PARAMS$B_training)) {
#
#   message("[", dataset_name, " / ", scenario_name, "] Training subset ", b, "/", EXPERIMENT_PARAMS$B_training)
#
#   train_idx  <- this_scenario$train_idx[[b]]
#   X_train    <- data$X[train_idx, ]
#   y_train    <- this_scenario$y_permuted[train_idx]
#   X_eval     <- data$X[-train_idx, ]
#   y_eval     <- this_scenario$y_permuted[-train_idx]
#
#   subset_results <- list()
#
#   # 1. Fit LASSO under each tuning strategy
#   for (tune in names(tuning_strategies)) {
#     fit <- fit_lasso(X_train, y_train, tune_strategy = tune, seed = GLOBAL_SEED + b)
#
#     # 2. Apply each validation strategy to estimate performance
#     val_estimates <- list()
#     for (val in validation_strategies) {
#       val_estimates[[val]] <- evaluate_with_strategy(fit, X_train, y_train, val)
#     }
#
#     # 3. True performance on independent eval set
#     true_perf <- list(
#       auc   = compute_auc(y_eval, predict_lasso(fit, X_eval)),
#       slope = compute_calibration_slope(y_eval, predict_lasso(fit, X_eval))
#     )
#
#     subset_results[[tune]] <- list(
#       selected_genes  = get_selected_genes(fit),
#       val_estimates   = val_estimates,
#       true_perf       = true_perf
#     )
#   }
#
#   results[[b]] <- subset_results
# }
#
# saveRDS(results,
#         file.path(PATHS$results_inter,
#                   paste0("experiment-results-", dataset_name, "-", scenario_name, ".rds")))


message("Experiment finished for ", dataset_name, " / ", scenario_name, ".")
