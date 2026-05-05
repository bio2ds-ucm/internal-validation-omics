# =============================================================================
# 04-collect-results.R
# =============================================================================
#
# Author:      [Melina Peressini, Silvia Pineda]
# Date:        YYYY-MM-DD
# Description: Reads all intermediate results from script 03 and consolidates
#              them into tidy data frames ready for figure and table generation.
#
# Inputs:
#   - results/intermediate/experiment-results-{dataset}-{scenario}.rds
#       (one file per dataset x scenario combination)
#
# Outputs:
#   - results/intermediate/results-tidy.rds
#       Tidy data frame with one row per (dataset, scenario, training_subset,
#       tuning_strategy, validation_strategy) combination, including:
#         - estimated AUC and calibration slope
#         - true AUC and slope (on independent eval set)
#         - bias (estimate − truth)
#         - number of selected genes
#         - proportion of weakly informative genes
#
# Runtime:     a few minutes
#
# =============================================================================

source(here::here("scripts", "00-setup.R"))


# ---- Combine all experiment files into one tidy data frame ------------------

# datasets  <- c("mmdx-kidney", "scan-b")
# scenarios <- names(EXPERIMENT_PARAMS$scenarios)
#
# all_results <- list()
#
# for (ds in datasets) {
#   for (sc in scenarios) {
#     file <- file.path(PATHS$results_inter,
#                       paste0("experiment-results-", ds, "-", sc, ".rds"))
#     if (!file.exists(file)) {
#       warning("Missing: ", file); next
#     }
#     raw <- readRDS(file)
#     # ... (transform raw nested list into long tidy data frame)
#     all_results[[paste(ds, sc)]] <- tidy_results(raw, ds, sc)
#   }
# }
#
# tidy_df <- dplyr::bind_rows(all_results)
# saveRDS(tidy_df, file.path(PATHS$results_inter, "results-tidy.rds"))

message("Results consolidated into tidy form.")
