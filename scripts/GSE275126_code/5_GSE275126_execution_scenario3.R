# DESCRIPTION:
# GSE275126 data
# Execution for scenario 3

# SCENARIO INDEX ----
library(here)

scenario_ind <- 3

# STUDY DATA ----
study_data <- "GSE275126"

# OUTCOME: POSITIVE CLASS ---
positive_class <- "yes"

# SCENARIOS:
# scenario  outcome permutation fraction   
# 1         0                                 excellent discrimination scenario (original scenario)
# 2         0.3                               moderate discrimination scenario (simulated scenario)
# 3         1                                 null discrimination scenario (simulated scenario)


# LOAD NEEDED FUNCTIONS ----
source(here::here("R", "required_functions.R"))

# LOAD GLOBAL PARAMETERS ----
source(here::here("R", "global_parameters.R"))

# LOAD OBJECT WITH DATA FOR ALL SCENARIOS ----
data_list <- readRDS(here::here("results", "intermediate", "GSE275126_data_sim_scenarios.rds"))

# SELECT DATA TO USE ----

x_matrix <- data_list$expr_mat

y_vector <- data_list$y_vector[[scenario_ind]]

# Remove object
rm(data_list)

# RUN SIMULATIONS -----

# To increase total size allowed whithin future
oopts <- options(future.globals.maxSize = 800 * 1024 ^ 2 )
on.exit(options(oopts))

# Execution
start_time <- Sys.time()

set.seed(seed)
results <- fitting_and_validation(x_matrix = x_matrix,
                                  y_vector = y_vector,
                                  positive_class = positive_class)
stop_time <- Sys.time()

# SAVE RESULTS ----
saveRDS(results,
        here::here("results", "intermediate", paste0(study_data, "_scenario", scenario_ind, "_results.rds")))

# EXECUTION TIME ----
start_time
stop_time
