# DESCRIPTION:
# GSE202203 data
# Generation of simulated scenarios of diminished discrimination capacity by
# permuting the outcome in a fraction of the observations

# LIBRARIES ----
library(here)
library(dplyr)

# LOAD DATA ----

data <- readRDS(here::here("data", "processed", "GSE202203_processed_data.rds"))

# EXTRACT X_MATRIX AND Y_VECTOR ----

# x_matrix
x_matrix <- data |>
  select(-sample_id, -lumA_subtype) |>
  as.matrix()

rownames(x_matrix) <- data$sample_id

# y_vector
y_vector <- data$lumA_subtype

names(y_vector) <- data$sample_id


# OUTCOME PERMUTATION -----

# Seed (for replicability)
seed <- 1850

# Fraction and number of observations to permute
perm_frac_outc <- c(0.30, 1)
n_obs <- y_vector |> length()
nobs_to_permute <- floor(perm_frac_outc * n_obs)

# Sample observations to permute
set.seed(seed)
obs_to_permute <- list(sample(1:n_obs, size = nobs_to_permute[1]),
                       sample(1:n_obs, size = nobs_to_permute[2]))

# Permute outcome in 30% of observations
set.seed(seed) 
y_vector_perm30 <- y_vector
y_vector_perm30[obs_to_permute[[1]]] <- sample(y_vector[obs_to_permute[[1]]], 
                                               size = nobs_to_permute[1])

# Permute outcome in 100% of observations
set.seed(seed)
y_vector_perm100 <- y_vector
y_vector_perm100[obs_to_permute[[2]]] <- sample(y_vector[obs_to_permute[[2]]],
                                                size = nobs_to_permute[2])

# SAVE OBJECT WITH DATA FOR ALL SCENARIOS ----

data_list <- list(expr_mat = x_matrix,
                  y_vector = list(y_vector_orig = y_vector,
                                  y_vector_perm30 = y_vector_perm30,
                                  y_vector_perm100 = y_vector_perm100))

saveRDS(data_list,
        here::here("results", "intermediate", "GSE202203_data_sim_scenarios.rds"))
