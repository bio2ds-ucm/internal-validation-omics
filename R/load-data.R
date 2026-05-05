# =============================================================================
# load-data.R
# =============================================================================
#
# Functions to load and harmonize the two transcriptomic datasets used in the
# study: MMDx-Kidney (microarray) and SCAN-B (RNA-sequencing).
#
# Both functions return a list with two elements:
#   - X: a numeric expression matrix (samples x genes), already preprocessed
#   - y: a binary outcome vector (0/1) of length nrow(X)
#
# =============================================================================


#' Load the MMDx-Kidney dataset
#'
#' Loads preprocessed gene expression data and binary outcome (rejection vs
#' non-rejection) for the MMDx-Kidney cohort.
#'
#' @param path Path to the preprocessed MMDx-Kidney data file
#' @return A list with elements `X` (expression matrix) and `y` (binary outcome)
load_mmdx_kidney <- function(path) {
  # TODO: implement
}


#' Load the SCAN-B dataset
#'
#' Loads preprocessed gene expression data and binary outcome (Luminal A vs
#' non-Luminal A) for the SCAN-B cohort.
#'
#' @param path Path to the preprocessed SCAN-B data file
#' @return A list with elements `X` (expression matrix) and `y` (binary outcome)
load_scan_b <- function(path) {
  # TODO: implement
}
