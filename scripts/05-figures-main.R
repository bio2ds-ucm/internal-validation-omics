# =============================================================================
# 05-figures-main.R
# =============================================================================
#
# Author:      [Melina Peressini, Silvia Pineda]
# Date:        YYYY-MM-DD
# Description: Generates the five main figures of the paper.
#
#   Figure 1 — Study design diagram (scenarios + workflow)
#   Figure 2 — Schematic of validation strategies
#   Figure 3 — Tuning impact: model complexity & gene selection (MMDx-Kidney)
#   Figure 4 — Tuning impact: AUC & calibration on evaluation data
#   Figure 5 — Performance estimation accuracy (AUC bias)
#
# Inputs:
#   - results/intermediate/results-tidy.rds
#
# Outputs:
#   - results/figures/fig01-study-design.{pdf,png}
#   - results/figures/fig02-validation-strategies.{pdf,png}
#   - results/figures/fig03-tuning-complexity.{pdf,png}
#   - results/figures/fig04-tuning-performance.{pdf,png}
#   - results/figures/fig05-auc-bias.{pdf,png}
#
# Runtime:     < 10 minutes
#
# =============================================================================

source(here::here("scripts", "00-setup.R"))

# results <- readRDS(file.path(PATHS$results_inter, "results-tidy.rds"))


# ---- Figure 1: Study design diagram ------------------------------------------
# (Often hand-drawn or composed externally; placeholder here)

# ...


# ---- Figure 2: Validation strategies schematic ------------------------------
# (Schematic figure; placeholder)

# ...


# ---- Figure 3: Tuning impact on model complexity ----------------------------

# fig3 <- results |>
#   dplyr::filter(dataset == "mmdx-kidney") |>
#   ggplot2::ggplot(...) +
#   ggplot2::geom_boxplot(...) +
#   ggplot2::scale_color_manual(values = strategy_colors) +
#   theme_paper()
#
# save_figure(fig3, "fig03-tuning-complexity", width = 10, height = 5)


# ---- Figure 4: Tuning impact on evaluation performance ----------------------

# ...
# save_figure(fig4, "fig04-tuning-performance", width = 10, height = 5)


# ---- Figure 5: AUC bias by validation strategy ------------------------------

# ...
# save_figure(fig5, "fig05-auc-bias", width = 10, height = 5)


message("Main figures generated.")
