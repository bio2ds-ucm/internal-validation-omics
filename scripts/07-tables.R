# =============================================================================
# 07-tables.R
# =============================================================================
#
# Author:      [Melina Peressini, Silvia Pineda]
# Date:        YYYY-MM-DD
# Description: Generates the main and supplementary tables of the paper.
#
#   Table 1 — Characterization of datasets and scenarios:
#               sample size, outcome distribution, % differentially expressed
#               genes (FDR < 0.05), % weakly informative genes, median AUC
#
# Inputs:
#   - data/processed/{mmdx-kidney,scan-b}.rds
#   - results/intermediate/scenarios-{mmdx-kidney,scan-b}.rds
#   - results/intermediate/results-tidy.rds
#
# Outputs:
#   - results/tables/table01-dataset-characterization.csv
#
# Runtime:     < 5 minutes
#
# =============================================================================

source(here::here("scripts", "00-setup.R"))

# Compute % DE genes per scenario (limma) and combine with descriptive stats.

# ...

# write.csv(table1, file.path(PATHS$results_tables, "table01-dataset-characterization.csv"),
#           row.names = FALSE)

message("Tables generated.")
