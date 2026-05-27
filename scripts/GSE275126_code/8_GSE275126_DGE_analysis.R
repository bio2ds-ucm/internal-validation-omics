# DESCRIPTION:
# GSE275126 data
# Differential gene expression analysis using limma-trend workflow

# LIBRARIES ----
library(here)
library(dplyr)
library(tibble)
library(limma)
library(ggplot2)

# LOAD OBJECT WITH DATA FOR ALL SCENARIOS ----
data_list <- readRDS(here::here("results", "intermediate", "GSE275126_data_sim_scenarios.rds"))

# SELECT DATA TO USE ----

expr_mat <- data_list$expr_mat |>
  t()

metadata <- lapply(1:3, FUN = function(ind){
  tibble(group = data_list$y_vector[[ind]])})

# Remove object
rm(data_list)

# LIMMA-TREND 

# Create list to save results for each scenario
limma_list <-  vector("list", length = 3)

scenario_ind <- 1:3

# Loop over scenario index
for(ind in scenario_ind){
  
  # Design
  design <- model.matrix(~ 1 + group, 
                         data = metadata[[ind]])

  # Fit linear model
  fit <- lmFit(expr_mat, design)
  fit <- eBayes(fit, trend = TRUE)
  
  # Table with results
  fit_res <- topTable(fit, n = Inf, p = 1) |>
    mutate(scenario = paste("scenario", ind)) |>
    rownames_to_column(var = "gene")
  
  # Save results in list
  limma_list[[ind]] <- fit_res
}

# Bind results
limma_df <- limma_list |>
  bind_rows()

# SAVE RESULTS ----
saveRDS(limma_df,
        here::here("results", "intermediate", "GSE275126_DGE_analysis.rds"))