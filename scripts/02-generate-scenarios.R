# =============================================================================
# 02-generate-scenarios.R
# =============================================================================
#
# Author:      [Melina Peressini, Silvia Pineda]
# Date:        YYYY-MM-DD
# Description: Generates the three discrimination scenarios (excellent, moderate,
#              null) by permuting outcome values, and the 100 training subsets
#              of size n=100 used in the experiment.
#
# Inputs:
#   - data/processed/mmdx-kidney.rds
#   - data/processed/scan-b.rds
#
# Outputs:
#   - results/intermediate/scenarios-mmdx-kidney.rds
#   - results/intermediate/scenarios-scan-b.rds
#       Each is a nested list:
#         scenarios -> training_subsets -> { y_permuted, train_idx }
#
# Runtime:     a few minutes
#
# =============================================================================

source(here::here("scripts", "00-setup.R"))


# ---- Helper to build all scenarios for one dataset ---------------------------

# build_all_scenarios <- function(data, dataset_name) {
#
#   set.seed(GLOBAL_SEED)
#
#   scenarios <- lapply(EXPERIMENT_PARAMS$scenarios, function(prop) {
#
#     # 1. permute the outcome at this proportion
#     y_perm <- generate_scenario(data$y, prop_permuted = prop)
#
#     # 2. generate B training subsets
#     train_idx_list <- generate_training_subsets(
#       n_total = nrow(data$X),
#       n_train = EXPERIMENT_PARAMS$n_train,
#       B       = EXPERIMENT_PARAMS$B_training
#     )
#
#     list(y_permuted = y_perm, train_idx = train_idx_list)
#   })
#
#   names(scenarios) <- names(EXPERIMENT_PARAMS$scenarios)
#   scenarios
# }


# ---- MMDx-Kidney -------------------------------------------------------------

# mmdx <- readRDS(file.path(PATHS$data_processed, "mmdx-kidney.rds"))
# scenarios_mmdx <- build_all_scenarios(mmdx, "mmdx-kidney")
# saveRDS(scenarios_mmdx, file.path(PATHS$results_inter, "scenarios-mmdx-kidney.rds"))


# ---- SCAN-B ------------------------------------------------------------------

# scanb <- readRDS(file.path(PATHS$data_processed, "scan-b.rds"))
# scenarios_scanb <- build_all_scenarios(scanb, "scan-b")
# saveRDS(scenarios_scanb, file.path(PATHS$results_inter, "scenarios-scan-b.rds"))


message("Scenarios generated.")
