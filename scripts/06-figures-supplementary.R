# =============================================================================
# 06-figures-supplementary.R
# =============================================================================
#
# Author:      [Melina Peressini, Silvia Pineda]
# Date:        YYYY-MM-DD
# Description: Generates the supplementary figures of the paper (S1–S7),
#              mostly mirroring the main analyses on the SCAN-B dataset and
#              additional sensitivity analyses.
#
#   Figure S1 — Characterization of MMDx-Kidney scenarios (UMAP, AUC, DE)
#   Figure S2 — Characterization of SCAN-B scenarios
#   Figure S3 — SCAN-B equivalent of Figure 3 (tuning complexity)
#   Figure S4 — SCAN-B equivalent of Figure 4 (tuning performance)
#   Figure S5 — Apparent AUC and additional bias plots
#   Figure S6 — Calibration slope estimation (additional detail)
#   Figure S7 — Sensitivity / variability metrics
#
# Inputs:
#   - results/intermediate/results-tidy.rds
#
# Outputs:
#   - results/figures/supplementary/figS01-...{pdf,png}
#   - ...
#
# Runtime:     < 10 minutes
#
# =============================================================================

source(here::here("scripts", "00-setup.R"))

# Use save_figure(..., subdir = "supplementary") to keep these in their own folder.

# ...

message("Supplementary figures generated.")
