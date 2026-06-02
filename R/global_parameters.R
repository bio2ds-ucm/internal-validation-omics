# DESCRIPTION:
# Global parameters for simulation study

# GLOBAL PARAMETERS ----

# Seed (for replicability)
seed <- 18500581

# Number of simulations
nsim <- 100

# Sample size for train data
nsubjects_train <- 100

# Length for lambda grid in hyperparameter tuning (LASSO)
grid_length <- 100

# Number of folds for repeated k-fold CV
k <- c(5, 10)

# Number of repeats for repeated k-fold CV
rep <- c(20, 10)

# Number of bootstrap samples for bootstrap methods (regular BS, .632 BS, and .632+ BS)
nboot <- 100

# Number of cores (for parallelization)
ncores <- 50


