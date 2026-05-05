# =============================================================================
# 01-data-preparation.R
# =============================================================================
#
# Author:      [Melina Peressini, Silvia Pineda]
# Date:        YYYY-MM-DD
# Description: Loads raw transcriptomic data for the two cohorts and applies
#              standard preprocessing (normalization, log-transformation,
#              gene filtering). Saves harmonized datasets ready for the
#              experiment.
#
# Inputs:
#   - data/raw/mmdx-kidney/...       (see data/README.md for access)
#   - data/raw/scan-b/...
#
# Outputs:
#   - data/processed/mmdx-kidney.rds  (list with X = matrix, y = outcome)
#   - data/processed/scan-b.rds
#
# Runtime:     a few minutes
#
# =============================================================================

source(here::here("scripts", "00-setup.R"))


# ---- MMDx-Kidney -------------------------------------------------------------

message("Preprocessing MMDx-Kidney...")

# mmdx <- load_mmdx_kidney(file.path(PATHS$data_raw, "mmdx-kidney"))
# saveRDS(mmdx, file.path(PATHS$data_processed, "mmdx-kidney.rds"))

# Brief summary
# message("MMDx-Kidney: ", nrow(mmdx$X), " samples, ", ncol(mmdx$X), " genes")
# message("Outcome distribution: ", paste(table(mmdx$y), collapse = " / "))


# ---- SCAN-B ------------------------------------------------------------------

message("Preprocessing SCAN-B...")

# scanb <- load_scan_b(file.path(PATHS$data_raw, "scan-b"))
# saveRDS(scanb, file.path(PATHS$data_processed, "scan-b.rds"))

# message("SCAN-B: ", nrow(scanb$X), " samples, ", ncol(scanb$X), " genes")
# message("Outcome distribution: ", paste(table(scanb$y), collapse = " / "))


message("Data preparation complete.")
