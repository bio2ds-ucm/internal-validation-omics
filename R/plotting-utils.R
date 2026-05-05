# =============================================================================
# plotting-utils.R
# =============================================================================
#
# Shared plotting helpers, color palettes and ggplot2 themes used across
# all figures of the paper, to ensure a consistent visual style.
#
# =============================================================================

# Color palette for validation strategies
# (consistent across all figures of the paper)
strategy_colors <- c(
  "20-rep 5-fold CV"   = "#1f77b4",   # blue
  "10-rep 10-fold CV"  = "#17becf",   # light blue
  "Regular BS"         = "#d62728",   # red
  ".632 BS"            = "#ff7f0e",   # orange
  ".632+ BS"           = "#9467bd"    # purple
)

# Color palette for discrimination scenarios
scenario_colors <- c(
  "Excellent" = "#2ca02c",   # green
  "Moderate"  = "#bcbd22",   # olive
  "Null"      = "#8c564b"    # brown
)


#' Standard ggplot2 theme for paper figures
#'
#' @param base_size Base font size (default: 11 for paper, 14 for slides)
#' @return A ggplot2 theme object
theme_paper <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(fill = "grey95", color = NA),
      legend.position = "bottom"
    )
}


#' Save a figure as both PDF (vector for paper) and PNG (preview for GitHub)
#'
#' @param plot A ggplot2 object
#' @param filename Base filename without extension
#' @param width Width in inches
#' @param height Height in inches
#' @param subdir Subdirectory under results/figures/ (default: NULL)
save_figure <- function(plot, filename, width = 7, height = 5, subdir = NULL) {
  base_dir <- here::here("results", "figures")
  if (!is.null(subdir)) base_dir <- file.path(base_dir, subdir)
  dir.create(base_dir, showWarnings = FALSE, recursive = TRUE)

  ggplot2::ggsave(file.path(base_dir, paste0(filename, ".pdf")),
                  plot, width = width, height = height)
  ggplot2::ggsave(file.path(base_dir, paste0(filename, ".png")),
                  plot, width = width, height = height, dpi = 300)
}
