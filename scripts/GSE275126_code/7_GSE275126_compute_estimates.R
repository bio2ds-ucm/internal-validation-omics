# LIBRARIES ----
library(here)
library(dplyr)
library(tidyr)
library(stringr)

# LOAD RESULTS ----
scenario_1 <- readRDS(here::here("results", "intermediate", "GSE275126_scenario1_results.rds"))
scenario_2 <- readRDS(here::here("results", "intermediate", "GSE275126_scenario2_results.rds"))
scenario_3 <- readRDS(here::here("results", "intermediate", "GSE275126_scenario3_results.rds"))

scenario_list <- list(scenario_1 = scenario_1,
                      scenario_2 = scenario_2,
                      scenario_3 = scenario_3)

outcome_frac <- c(0, 0.3, 1)

# BIND RESULTS ----

# 1. Model coefficients  ----
coef_res_list <- lapply(1:length(scenario_list), FUN = function(ind){
  
  coef_res_list  <- lapply(1:length(scenario_list[[ind]]), FUN = function(x){
    scenario_list[[ind]][[x]]$coefs
  })
  
  coef_res <- Reduce(Matrix::rbind2, coef_res_list) |>
    as.matrix() |>
    as_tibble() |>
    mutate(scenario = paste("scenario", ind),
           outcome_frac = outcome_frac[ind])
  
  coef_res
})

coef_res <- coef_res_list |>
  bind_rows()

coef_res <- coef_res |>
  mutate(outcome_frac = outcome_frac |>
           factor(levels = c(0, 0.3, 1),
                  labels = c("excellent discrimination", 
                             "moderate discrimination", 
                             "null discrimination"),
                  ordered = TRUE))

# 2. Validation results ----

val_res_list <- lapply(1:length(scenario_list), FUN = function(ind){
  
  val_res_list  <- lapply(1:length(scenario_list[[ind]]), FUN = function(x){
    scenario_list[[ind]][[x]]$results
  })
  
  val_res <- val_res_list |>
    bind_rows() |>
    mutate(scenario = paste("scenario", ind),
           outcome_frac = outcome_frac[ind])
  
  val_res
})

val_res <- val_res_list |>
  bind_rows()

val_res <- val_res |>
  mutate(discrimination_scenario = recode(scenario,
                                          `scenario 1` = "excellent discrimination scenario \n(original dataset)",
                                          `scenario 2` = "moderate discrimination scenario",
                                          `scenario 3` = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario \n(original dataset)",
                             "moderate discrimination scenario",
                             "null discrimination scenario")),
         tuning_method = recode(tuning_method,
                                `10rep_10fold` = "tuning: 10-rep 10-fold CV",
                                `20rep_5fold` = "tuning: 20-rep 5-fold CV",
                                `boot632` = "tuning: .632 BS",
                                `optboot` = "tuning: regular BS") |>
           factor(levels = c("tuning: 20-rep 5-fold CV",
                             "tuning: 10-rep 10-fold CV",
                             "tuning: regular BS",
                             "tuning: .632 BS"),
                  ordered = TRUE)) |>
  rename(tuning = tuning_method) 

# APPARENT PERFORMANCE IN NULL MODELS ----

# Set apparent estimation of null models to NA (non-meaningful in practice)
val_res <- val_res |>
  mutate(roc_app = ifelse(nonull_coefs != 0, roc_app, NA),
         calslope_glm_app = ifelse(nonull_coefs != 0, calslope_glm_app, NA),
         calslope_logistf_app = ifelse(nonull_coefs != 0, calslope_logistf_app, NA))

# REGULAR BS AND .632 BS ESTIMATES ----

w <- 0.632
noinf_roc <- 0.5
noinf_cal <- 0

val_res <- val_res |>
  mutate(roc_optboot = roc_app - (roc_app_boot - roc_orig_boot),
         roc_boot632 = (1-w)*roc_app + w*roc_oob_boot,
         calslope_optboot = calslope_logistf_app - (calslope_logistf_app_boot - calslope_logistf_orig_boot),
         calslope_boot632 = (1-w)*calslope_logistf_app + w*calslope_logistf_oob_boot)

# R AND W COMPUTATION FOR .632+ BS ----

val_res <- val_res |>
  mutate(roc_r_boot632plus = (roc_oob_boot - roc_app)/(noinf_roc - roc_app),
         roc_w_boot632plus = w/(1 - (1-w)*roc_r_boot632plus),
         calslope_r_boot632plus = (calslope_logistf_oob_boot - calslope_logistf_app)/(noinf_cal - calslope_logistf_app),
         calslope_w_boot632plus = w/(1 - (1-w)*calslope_r_boot632plus))

val_res$roc_r_boot632plus |>
  summary()

val_res$calslope_r_boot632plus |>
  summary()

# 1. AUC ----

# Relative overfitting (r) values 

# Check values for relative overfitting (r from .632+ BS)
val_res$roc_r_boot632plus |> summary()
# Values exceeding 1

# Check values for w from .632+ BS
val_res$roc_w_boot632plus |> summary()
# Values exceeding 1

val_res |>
  filter(is.na(roc_w_boot632plus)) |>
  select(nonull_coefs) |>
  pull() |>
  summary()
# NA values correspond to null models (i.e., models in which no genes are selected)

# OOB weight (w) values
val_res$roc_w_boot632plus |>
  summary()
# w values exceeding 1

# 2. Calibration slope ----

# Relative overfitting (r) values 
# Check values for relative overfitting (r from .632+ BS)
val_res$calslope_r_boot632plus |> summary()
# Negative finite values
# Values exceeding 1

val_res |>
  filter(calslope_r_boot632plus < 0) |>
  select(calslope_r_boot632plus, calslope_r_boot632plus,
         calslope_logistf_oob_boot,
         calslope_logistf_app, 
         calslope_logistf_test) |>
  View()
# Negative finite values arise because the numerator in the formula for r (OOB - app) 
# has a positive sign (OOB > app), while the denominator (no-inf - app) 
# has a negative sign (no-inf = 0, app > 0)

val_res |>
  filter(is.na(calslope_r_boot632plus)) |>
  select(nonull_coefs) |>
  pull() |>
  summary()
# NA values correspond to null models (i.e., models in which no genes are selected). 
# In this case, estimation of the calibration slope is not feasible.

# OOB weight (w) values
val_res$calslope_w_boot632plus |>
  summary()
# w values exceeding 1
# w values lower than 0.632

# .632+ ESTIMATES ----

# Truncation of w values 
# w values greater than 1 are truncated to 1
# w values lower than 0.632 are truncated to 0.632
# this correspond to truncate r (relative overfitting) values greater than 1 to one, 
# and r values lower than 0 to 0.
val_res <- val_res |>
  mutate(roc_w_boot632plus = case_when(roc_w_boot632plus > 1 ~ 1,
                                       roc_w_boot632plus < w ~ w,
                                       .default = roc_w_boot632plus),
         calslope_w_boot632plus = case_when(calslope_w_boot632plus > 1 ~ 1,
                                            calslope_w_boot632plus < w ~ w,
                                            .default = calslope_w_boot632plus))

val_res <- val_res |>
  mutate(roc_boot632plus = (1 - roc_w_boot632plus)*roc_app + roc_w_boot632plus*roc_oob_boot,
         calslope_boot632plus = (1 - calslope_w_boot632plus)*calslope_logistf_app + calslope_w_boot632plus*calslope_logistf_oob_boot)

# DIFFERENCES ESTIMATE - TRUE PERFORMANCE ----

# 1. AUC ----

# Differences from true values: ROC AUC
val_res_auc_diff <- val_res |>
  mutate(roc_app_diff = ifelse(nonull_coefs != 0, roc_app - roc_test, NA),
         roc_optboot_diff = ifelse(nonull_coefs != 0, roc_optboot - roc_test, NA),
         roc_boot632_diff = ifelse(nonull_coefs != 0, roc_boot632 - roc_test, NA),
         roc_boot632plus_diff = ifelse(nonull_coefs != 0, roc_boot632plus - roc_test, NA),
         roc_bootoob_diff = ifelse(nonull_coefs != 0, roc_oob_boot - roc_test, NA),
         roc_20rep5foldCV_diff = ifelse(nonull_coefs != 0, roc_20rep5foldCV - roc_test, NA),
         roc_10rep10foldCV_diff = ifelse(nonull_coefs != 0, roc_10rep10foldCV - roc_test, NA)) |>
  select(sim,
         tuning,
         scenario,
         outcome_frac,
         roc_app_diff,
         roc_optboot_diff:roc_10rep10foldCV_diff) |>
  pivot_longer(cols = roc_app_diff:roc_10rep10foldCV_diff,
               names_to = "technique",
               values_to = "diff") |>
  mutate(technique = str_remove_all(technique, "roc_|_diff"),
         technique = recode(technique,
                            app = "apparent",
                            `10rep10foldCV` = "10-rep 10-fold CV",
                            `20rep5foldCV` = "20-rep 5-fold CV",
                            optboot = "regular BS",
                            boot632 = ".632 BS",
                            boot632plus = ".632+ BS",
                            bootoob = "OOB BS") |>
           factor(levels = c("apparent",
                             "20-rep 5-fold CV",
                             "10-rep 10-fold CV",
                             "regular BS",
                             ".632 BS",
                             ".632+ BS",
                             "OOB BS"),
                  ordered = TRUE))

# 2. Calibration slope ----

# Differences from true values: calibration slope
val_res_cal_diff <- val_res |>
  mutate(calslope_app_diff = calslope_logistf_app - calslope_logistf_test,
         calslope_optboot_diff = calslope_optboot - calslope_logistf_test,
         calslope_boot632_diff = calslope_boot632 - calslope_logistf_test,
         calslope_boot632plus_diff = calslope_boot632plus - calslope_logistf_test,
         calslope_bootoob_diff = calslope_logistf_oob_boot - calslope_logistf_test,
         calslope_20rep5foldCV_diff = calslope_logistf_20rep5foldCV - calslope_logistf_test,
         calslope_10rep10foldCV_diff = calslope_logistf_10rep10foldCV - calslope_logistf_test) |>
  select(sim,
         tuning,
         scenario,
         outcome_frac,
         calslope_app_diff,
         calslope_app_diff:calslope_10rep10foldCV_diff) |>
  pivot_longer(cols = calslope_app_diff:calslope_10rep10foldCV_diff,
               names_to = "technique",
               values_to = "diff") |>
  mutate(technique = str_remove_all(technique, "calslope_|_diff"),
         technique = recode(technique,
                            app = "apparent",
                            `10rep10foldCV` = "10-rep 10-fold CV",
                            `20rep5foldCV` = "20-rep 5-fold CV",
                            optboot = "regular BS",
                            boot632 = ".632 BS",
                            boot632plus = ".632+ BS",
                            bootoob = "OOB BS") |>
           factor(levels = c("apparent",
                             "20-rep 5-fold CV",
                             "10-rep 10-fold CV",
                             "regular BS",
                             ".632 BS",
                             ".632+ BS",
                             "OOB BS"),
                  ordered = TRUE))

# SAVE RESULTS ----

rm(list = setdiff(ls(), c("coef_res", "val_res", "val_res_auc_diff", "val_res_cal_diff")))

save.image(here::here("results", "intermediate", "GSE275126_binded_results.RData"))
