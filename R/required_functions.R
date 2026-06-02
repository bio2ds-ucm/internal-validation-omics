# DESCRIPTION:
# Required functions for execution of the simulation study

# LIBRARIES ----
library(dplyr)
library(tibble) 
library(caret)
library(glmnet)
library(pROC)
library(logistf)
library(furrr)
library(future)

select <- dplyr::select

# LAMBDA GRID (for LASSO) ----

# lasso_grid_search:
# Sets grid of lambda values (length 100) according to
# Friedman, J., Hastie, T. and Tibshirani, R. (2010) ‘Regularization Paths for Generalized Linear Models via Coordinate Descent’

lasso_grid_search <- function(x_matrix, 
                              y_vector, 
                              positive_class,
                              grid_length){
  
  # Change to numeric
  y_vector <- (y_vector == positive_class) |> 
    as.integer()
  
  # Compute lambda max and min
  lambda_max <- max(abs(t(y_vector) %*% x_matrix)) / length(y_vector)
  lambda_min <- 0.001 * lambda_max
  
  # ratio
  ratio <- lambda_min / lambda_max
  
  lambda_grid <- numeric(length = grid_length)
  
  # logarithmic scale (equidistant in log scale)
  for (i in 1:grid_length){
    lambda_grid[i] <- lambda_max * (ratio ^ ((i - 1) / (grid_length - 1)))
  }
  
  # Grid for alpha (= 1, LASSO) and lambda
  grid <- expand.grid(alpha = 1, 
                      lambda = lambda_grid)
  
  grid
}

# MODEL FITTING ----

# model_fitting:

# Fits LASSO logistic model
# - the tuning of the lambda penalty parameter is done based on maximizing the
# estimated AUC
# - the AUC is estimated using the specified resampling-based strategy: 
# "repeatedcv", "optimism_boot", "boot632" (i.e., the methods under evaluation 
# implemented in the `caret` library)

model_fitting <- function(x_matrix,
                          y_vector,
                          tuning_method,
                          number,
                          repeats = NULL,
                          grid){
                        
                          

  alpha <- numeric(length = 1)
  lambda <- numeric(length = 1)
  
  if(tuning_method == "repeatedcv"){
    
    # Train control
    train_control <- trainControl(method = tuning_method, 
                                  number = number,
                                  repeats = repeats,
                                  classProbs = TRUE,
                                  summaryFunction = twoClassSummary)
    
    # Hyperparameter tuning
    tuning <- train(x = x_matrix,
                    y = y_vector,
                    method = "glmnet",
                    trControl = train_control,
                    tuneGrid = grid,
                    metric = "ROC")
    
    alpha <- tuning$bestTune$alpha
    lambda <- tuning$bestTune$lambda
    
  }
  
  else{
    # Train control
    train_control <- trainControl(method = tuning_method,
                                  number = number,
                                  classProbs = TRUE,
                                  summaryFunction = twoClassSummary)
    
    # Hyperparameter tuning
    tuning <- train(x = x_matrix,
                    y = y_vector,
                    method = "glmnet",
                    trControl = train_control,
                    tuneGrid = grid,
                    metric = "ROC")
    
    alpha <- tuning$bestTune$alpha
    lambda <- tuning$bestTune$lambda
    
  }
  
  # Fit 
  fit <- glmnet(x = x_matrix, 
                y = y_vector, 
                alpha = alpha, 
                lambda = lambda, 
                family = "binomial")
  
  # Number of non-zero coefficients
  coefs <- coef(fit, s = lambda)
  nonull_coefs <- sum(coefs[-1, ] != 0) 
  
  # Results
  list(fit = fit,
       coefs = coefs,
       alpha = alpha,
       lambda = lambda,
       nonull_coefs = nonull_coefs)
}
  
# PERFORMANCE METRICS ----

# performance:

# Computes performance metrics (AUC, calibration slope) for a given
# model on a specific dataset

# - calibration slope is computed both using standard logistic regression and 
# Firth's penalized logistic regression in order to check for convergence issues

performance <- function(fit,
                        newx,
                        newy){

  # Linear predictor
  lp <- predict(fit, newx = newx, type = "link")[, 1]

  # i. ROC AUC
  roc <- auc(response = newy, predictor = lp, direction = "<")
  
  # ii. CALIBRATION SLOPE
  # Estimation via glm
  calslope <- coef(glm(newy ~ lp, family = "binomial",
                       control = list(maxit = 100)))[2]

  calslope_warning <- function(){

    # To catch warnings:
    # 1: glm.fit: algorithm did not converge
    # 2: glm.fit: fitted probabilities numerically 0 or 1 occurred
    # In case of warning, NA is returned
    tryCatch(

    # Code to be evaluated
    expr = {
      coef(glm(newy ~ lp, family = "binomial",
               control = list(maxit = 100)))[2]
    },

    # Return NA if a warning is catched
    warning = function(w){
      return(NA)
    })
  }
  
  # Warning via glm
  calslope_warn <- calslope_warning()
  
  # Estimation via logistf
  calslope_logistf_error <- function(){

    # To prevent stopping due to any errors
    tryCatch(

      # Code to be evaluated
      expr = {
        coef(logistf(newy ~ lp, family = "binomial",
                     control = logistf.control(maxit = 100)))[2]
      },

      # Return NA if an error is catched
      error = function(e){
        return(NA)
      })
  }
  
  calslope_logistf <- calslope_logistf_error()
                          
  # Results
  results <- c("roc" = roc,
               "calslope_glm" = unname(calslope),
               "calslope_glm_warning" = unname(calslope_warn),
               "calslope_logistf" = unname(calslope_logistf))

  results
}


# REPEATED K-FOLD CV ----

# repeated_cv:

# Performs repeated K-fold cross-validation for post-development performance estimation
# (AUC and calibration slope)

# - the full modelling pipeline, including penalty hyperparameter tuning, 
# is repeated within each resampling iteration 

repeated_cv <- function(x_matrix,
                        y_vector,
                        positive_class,
                        nfolds,
                        nrep,
                        tuning_method,
                        tuning_number,
                        tuning_repeats){
  
  # 1. Iterate over repetition number ----
  repcv_results <- lapply(1:nrep, FUN = function(rep){
    
    # 2. Partition in folds ----
    folds_seq <- rep(1:nfolds, length.out = y_vector |> length())
    folds <- sample(folds_seq, replace = FALSE)
    
    # 3. Iterate over test fold ----
    fold_results <- lapply(1:nfolds, FUN = function(test_fold){
      
      # Check that there are subjects from both groups in train folds
      check_cond_1 <- (y_vector[folds != test_fold] |> unique() |> length()) > 1
     
      # Check that there are subjects from both groups in test fold
      check_cond_2 <- (y_vector[folds == test_fold] |> unique() |> length()) > 1
      
      if(check_cond_1 & check_cond_2){
        
        # 4. Model fitting using train folds ----
        
        # Tuning grid
        tuning_grid <- lasso_grid_search(x_matrix = x_matrix[folds != test_fold, ],
                                         y_vector = y_vector[folds != test_fold],
                                         grid_length = grid_length,
                                         positive_class = positive_class)
        
        # Model fitting
        fit <- model_fitting(x_matrix = x_matrix[folds != test_fold, ],
                             y_vector = y_vector[folds != test_fold],
                             tuning_method = tuning_method,
                             number = tuning_number,
                             repeats = tuning_repeats,
                             grid = tuning_grid)
        
        # 5. Model performance on test fold ----
        
        testfold_perf <- performance(fit = fit$fit,
                                     newx = x_matrix[folds == test_fold, ],
                                     newy = y_vector[folds == test_fold])
        
        # Results
        results <- testfold_perf |> 
          list() |>
          unlist() |>
          t() |>
          as_tibble()
        
        results
      }
      
    }) |>
      bind_rows()
  }) |>
    bind_rows()
  
  # Mean values
  mean_results <- repcv_results |>
    apply(MARGIN = 2, FUN = mean, na.rm = TRUE)
  
  mean_results
}

# BOOTSTRAP ----

# bootstrap:

# Performs bootstrapping for post-development performance estimation (AUC and 
# calibration slope), computing for each bootstrap sample: 

# (i) apparent performance, 
# (ii) performance on the original dataset
# (iii) out-of-bag (OOB) performance,
# and then averaging results 
# (required to obtain the final estimates from regular BS, .632 BS, and .632+ BS)

# - the full modelling pipeline, including penalty hyperparameter tuning, 
# is repeated within each resampling iteration 

bootstrap <- function(x_matrix,
                      y_vector,
                      positive_class = "positive",
                      nboot,
                      tuning_method,
                      tuning_number,
                      tuning_repeats){
  
  # 1. Iterate over bootstrap sample number ----
  boot_results <- lapply(1:nboot, FUN = function(boot_ind){
    
    # 2. Draw subjects in bootstrap sample ----
    
    subjects_in_boot <- sample(1:nrow(x_matrix),
                               size = nrow(x_matrix),
                               replace = TRUE)

    # 3. Model fitting using bootstrap sample ----
    
    # Check that there are subjects from both subgroups in the bootstrap sample
    check_cond_1 <- (y_vector[subjects_in_boot] |> unique() |> length()) > 1
    
    # Check that there are from both subgroups in the out-of-bag sample
    check_cond_2 <- (y_vector[-subjects_in_boot] |> unique() |> length()) > 1
    
    if(check_cond_1 & check_cond_2){
      
      # Tuning grid
      tuning_grid <- lasso_grid_search(x_matrix = x_matrix[subjects_in_boot, ],
                                       y_vector = y_vector[subjects_in_boot],
                                       grid_length = grid_length,
                                       positive_class = positive_class)
      
      # Model fitting
      fit <- model_fitting(x_matrix = x_matrix[subjects_in_boot, ],
                           y_vector = y_vector[subjects_in_boot],
                           tuning_method = tuning_method,
                           number = tuning_number,
                           repeats = tuning_repeats,
                           grid = tuning_grid)
      
      # 4. Performance on bootstrap sample ----
      app_perf <- performance(fit = fit$fit,
                              newx = x_matrix[subjects_in_boot, ],
                              newy = y_vector[subjects_in_boot])
      
      # 5. Performance on original sample ----
      orig_perf <- performance(fit = fit$fit,
                               newx = x_matrix,
                               newy = y_vector)
      
      # 6.Performance on out-of-bag sample ----
      oob_perf <- performance(fit = fit$fit,
                              newx = x_matrix[-subjects_in_boot, ],
                              newy = y_vector[-subjects_in_boot])
      
      
      # Results
      names(app_perf) <- paste0(names(app_perf), "_app")
      names(orig_perf) <- paste0(names(orig_perf), "_orig")
      names(oob_perf) <- paste0(names(oob_perf), "_oob")
      
      results <- list(app_perf, orig_perf, oob_perf) |>
        unlist() |>
        t() |>
        as_tibble()
      
      results
    }
  }) |>
    bind_rows()
  
  # Mean values
  mean_results <- boot_results |>
    apply(MARGIN = 2, FUN = mean, na.rm = TRUE)
  mean_results
}


# MODEL FITTING AND INTERNAL VALIDATION ----

# fitting_and_validation

# - Randomly samples 100 different training datasets from the corresponding full dataset;
# the remaining observations form the large, independent evaluation set

# - On each training dataset, fits several LASSO logistic models, each using a 
# different resampling-based strategy (repeated K-fold CV, regular BS, .632 BS) 
# for AUC estimation during penalty hyperparameter tuning

# - For each of these models, computes post-development performance:
#  (i) true performance (i.e., on independent evaluation data)
#  (ii) estimates from repeated K-fold CV and bootstrap methods (apparent performance, 
# performance on the original training dataset, and OOB performance; required to 
# obtain the final estimates from regular BS, .632 BS, and .632+ BS)

fitting_and_validation <- function(x_matrix,
                                   y_vector,
                                   positive_class){
                               
  future::plan(multisession, workers = ncores)
  
  validation_results <- future_map(1:nsim, function(sim){
    
    # Split in train and test ----
    train_ind <- sample(1:nrow(x_matrix), size = nsubjects_train)
    
    # Check that there are subjects from both subgroups in train sample
    check_cond <- (y_vector[train_ind] |> unique() |> length()) > 1
    
    if(check_cond){
      
      # Grid for hyperparameter tuning ----
      tuning_grid <- lasso_grid_search(x_matrix = x_matrix[train_ind, ],
                                       y_vector = y_vector[train_ind],
                                       positive_class = positive_class,
                                       grid_length = grid_length)
      
      # Model fitting using 20-time repeated 5-fold CV -----
      
      # 1. Model fitting ----
      fit <- model_fitting(x_matrix = x_matrix[train_ind, ],
                           y_vector = y_vector[train_ind],
                           tuning_method = "repeatedcv",
                           number = k[1],
                           repeats = rep[1],
                           grid = tuning_grid)
      
      fit_20rep_5fold_coefs <- fit$coefs |> t()
      
      # 2. Apparent performance ----
      fit_app_perf <- performance(fit = fit$fit,
                                  newx = x_matrix[train_ind, ],
                                  newy = y_vector[train_ind])
      
      
      # 3. Test performance ----
      fit_test_perf <- performance(fit = fit$fit,
                                   newx = x_matrix[-train_ind, ],
                                   newy = y_vector[-train_ind])
      
      
      # 4. Validation via 20-time repeated 5-fold CV ----
      val_repcv_k5 <- repeated_cv(x_matrix = x_matrix[train_ind, ],
                                  y_vector = y_vector[train_ind],
                                  positive_class = positive_class,
                                  nfolds = k[1],
                                  nrep = rep[1],
                                  tuning_method = "repeatedcv",
                                  tuning_number = k[1],
                                  tuning_repeats = k[1])
      
      # 5. Validation via 10-time repeated 10-fold CV ----
      val_repcv_k10 <- repeated_cv(x_matrix = x_matrix[train_ind, ],
                                   y_vector = y_vector[train_ind],
                                   positive_class = positive_class,
                                   nfolds = k[2],
                                   nrep = rep[2],
                                   tuning_method = "repeatedcv",
                                   tuning_number = k[1],
                                   tuning_repeats = k[1])
      
      # 6. Validation via bootstrap ----
      val_boot <- bootstrap(x_matrix = x_matrix[train_ind, ],
                            y_vector = y_vector[train_ind],
                            positive_class = positive_class,
                            nboot = nboot,
                            tuning_method = "repeatedcv",
                            tuning_number = k[1],
                            tuning_repeats = k[1])
      
      # 7. Results ----
      fit <- fit[-c(1, 2)] |> 
        unlist()
      names(fit_app_perf) <- paste0(names(fit_app_perf), "_app")
      names(fit_test_perf) <- paste0(names(fit_test_perf), "_test")
      names(val_repcv_k5) <- paste0(names(val_repcv_k5), "_20rep5foldCV")
      names(val_repcv_k10) <- paste0(names(val_repcv_k10), "_10rep10foldCV")
      names(val_boot) <- paste0(names(val_boot), "_boot")
      
      fit_repcv_k5_results <- list(fit,
                                   fit_app_perf,
                                   fit_test_perf,
                                   val_repcv_k5,
                                   val_repcv_k10,
                                   val_boot) |>
        unlist() |>
        t() |>
        as_tibble() |>
        mutate(sim = sim,
               tuning_method = "20rep_5fold")
      
      # Remove objects after saving results
      rm(fit,
         fit_app_perf,
         fit_test_perf,
         val_repcv_k5,
         val_repcv_k10,
         val_boot)
      
      # Model fitting using 10-time repeated 10-fold CV -----
      
      # 1. Model fitting ----
      fit <- model_fitting(x_matrix = x_matrix[train_ind, ],
                           y_vector = y_vector[train_ind],
                           tuning_method = "repeatedcv",
                           number = k[2],
                           repeats = rep[2],
                           grid = tuning_grid)
      
      fit_10rep_10fold_coefs <- fit$coefs |> t()
      
      # 2. Apparent performance ----
      fit_app_perf <- performance(fit = fit$fit,
                                  newx = x_matrix[train_ind, ],
                                  newy = y_vector[train_ind])
      
      
      # 3. Test performance ----
      fit_test_perf <- performance(fit = fit$fit,
                                   newx = x_matrix[-train_ind, ],
                                   newy = y_vector[-train_ind])
      
      
      # 4. Validation via 20-time repeated 5-fold CV ----
      val_repcv_k5 <- repeated_cv(x_matrix = x_matrix[train_ind, ],
                                  y_vector = y_vector[train_ind],
                                  positive_class = positive_class,
                                  nfolds = k[1],
                                  nrep = rep[1],
                                  tuning_method = "repeatedcv",
                                  tuning_number = k[2],
                                  tuning_repeats = k[2])
      
      # 5. Validation via 10-time repeated 10-fold CV ----
      val_repcv_k10 <- repeated_cv(x_matrix = x_matrix[train_ind, ],
                                   y_vector = y_vector[train_ind],
                                   positive_class = positive_class,
                                   nfolds = k[2],
                                   nrep = rep[2],
                                   tuning_method = "repeatedcv",
                                   tuning_number = k[2],
                                   tuning_repeats = k[2])
      
      # 6. Validation via bootstrap ----
      val_boot <- bootstrap(x_matrix = x_matrix[train_ind, ],
                            y_vector = y_vector[train_ind],
                            positive_class = positive_class,
                            nboot = nboot,
                            tuning_method = "repeatedcv",
                            tuning_number = k[2],
                            tuning_repeats = k[2])
      
      # 7. Results ----
      fit <- fit[-c(1, 2)] |> 
        unlist()
      names(fit_app_perf) <- paste0(names(fit_app_perf), "_app")
      names(fit_test_perf) <- paste0(names(fit_test_perf), "_test")
      names(val_repcv_k5) <- paste0(names(val_repcv_k5), "_20rep5foldCV")
      names(val_repcv_k10) <- paste0(names(val_repcv_k10), "_10rep10foldCV")
      names(val_boot) <- paste0(names(val_boot), "_boot")
      
      fit_repcv_k10_results <- list(fit,
                                    fit_app_perf,
                                    fit_test_perf,
                                    val_repcv_k5,
                                    val_repcv_k10,
                                    val_boot) |>
        unlist() |>
        t() |>
        as_tibble() |>
        mutate(sim = sim,
               tuning_method = "10rep_10fold")
      
      # Remove objects after saving results
      rm(fit,
         fit_app_perf,
         fit_test_perf,
         val_repcv_k5,
         val_repcv_k10,
         val_boot)
      
      # Model fitting using optimism bootstrap -----
      
      # 1. Model fitting ----
      fit <- model_fitting(x_matrix = x_matrix[train_ind, ],
                           y_vector = y_vector[train_ind],
                           tuning_method = "optimism_boot",
                           number = nboot,
                           repeats = NULL,
                           grid = tuning_grid)
      
      fit_optboot_coefs <- fit$coefs |> t()
      
      # 2. Apparent performance ----
      fit_app_perf <- performance(fit = fit$fit,
                                  newx = x_matrix[train_ind, ],
                                  newy = y_vector[train_ind])
      
      # 3. Test performance ----
      fit_test_perf <- performance(fit = fit$fit,
                                   newx = x_matrix[-train_ind, ],
                                   newy = y_vector[-train_ind])
      
      # 4. Validation via 20-time repeated 5-fold CV ----
      val_repcv_k5 <- repeated_cv(x_matrix = x_matrix[train_ind, ],
                                  y_vector = y_vector[train_ind],
                                  positive_class = positive_class,
                                  nfolds = k[1],
                                  nrep = rep[1],
                                  tuning_method = "optimism_boot",
                                  tuning_number = nboot,
                                  tuning_repeats = NULL)
      
      # 5. Validation via 10-time repeated 10-fold CV ----
      val_repcv_k10 <- repeated_cv(x_matrix = x_matrix[train_ind, ],
                                   y_vector = y_vector[train_ind],
                                   positive_class = positive_class,
                                   nfolds = k[2],
                                   nrep = rep[2],
                                   tuning_method = "optimism_boot",
                                   tuning_number = nboot,
                                   tuning_repeats = NULL)
      
      # 6. Validation via bootstrap ----
      val_boot <- bootstrap(x_matrix = x_matrix[train_ind, ],
                            y_vector = y_vector[train_ind],
                            positive_class = positive_class,
                            nboot = nboot,
                            tuning_method = "optimism_boot",
                            tuning_number = nboot,
                            tuning_repeats = NULL)
      
      # # 7. Results ----
      fit <- fit[-c(1, 2)] |> 
        unlist()
      names(fit_app_perf) <- paste0(names(fit_app_perf), "_app")
      names(fit_test_perf) <- paste0(names(fit_test_perf), "_test")
      names(val_repcv_k5) <- paste0(names(val_repcv_k5), "_20rep5foldCV")
      names(val_repcv_k10) <- paste0(names(val_repcv_k10), "_10rep10foldCV")
      names(val_boot) <- paste0(names(val_boot), "_boot")
      
      fit_optboot_results <- list(fit,
                                  fit_app_perf,
                                  fit_test_perf,
                                  val_repcv_k5,
                                  val_repcv_k10,
                                  val_boot) |>
        
        unlist() |>
        t() |>
        as_tibble() |>
        mutate(sim = sim,
               tuning_method = "optboot")
      
      # Remove objects after saving results
      rm(fit,
         fit_app_perf,
         fit_test_perf,
         val_repcv_k5,
         val_repcv_k10,
         val_boot)
      
      # Model fitting using .632 bootstrap -----
      
      # 1. Model fitting ----
      fit <- model_fitting(x_matrix = x_matrix[train_ind, ],
                           y_vector = y_vector[train_ind],
                           tuning_method = "boot632",
                           number = nboot,
                           repeats = NULL,
                           grid = tuning_grid)
      
      fit_boot632_coefs <- fit$coefs |> t()
      
      # 2. Apparent performance ----
      fit_app_perf <- performance(fit = fit$fit,
                                  newx = x_matrix[train_ind, ],
                                  newy = y_vector[train_ind])
      
      # 3. Test performance ----
      fit_test_perf <- performance(fit = fit$fit,
                                   newx = x_matrix[-train_ind, ],
                                   newy = y_vector[-train_ind])
      
      # 4. Validation via 20-time repeated 5-fold CV ----
      val_repcv_k5 <- repeated_cv(x_matrix = x_matrix[train_ind, ],
                                  y_vector = y_vector[train_ind],
                                  positive_class = positive_class,
                                  nfolds = k[1],
                                  nrep = rep[1],
                                  tuning_method = "boot632",
                                  tuning_number = nboot,
                                  tuning_repeats = NULL)
      
      # 5. Validation via 10-time repeated 10-fold CV ----
      val_repcv_k10 <- repeated_cv(x_matrix = x_matrix[train_ind, ],
                                   y_vector = y_vector[train_ind],
                                   positive_class = positive_class,
                                   nfolds = k[2],
                                   nrep = rep[2],
                                   tuning_method = "boot632",
                                   tuning_number = nboot,
                                   tuning_repeats = NULL)
      
      # 6. Validation via bootstrap ----
      val_boot <- bootstrap(x_matrix = x_matrix[train_ind, ],
                            y_vector = y_vector[train_ind],
                            positive_class = positive_class,
                            nboot = nboot,
                            tuning_method = "boot632",
                            tuning_number = nboot,
                            tuning_repeats = NULL)
      
      # # 7. Results ----
      fit <- fit[-c(1, 2)] |> 
        unlist()
      names(fit_app_perf) <- paste0(names(fit_app_perf), "_app")
      names(fit_test_perf) <- paste0(names(fit_test_perf), "_test")
      names(val_repcv_k5) <- paste0(names(val_repcv_k5), "_20rep5foldCV")
      names(val_repcv_k10) <- paste0(names(val_repcv_k10), "_10rep10foldCV")
      names(val_boot) <- paste0(names(val_boot), "_boot")
      
      fit_boot632_results <- list(fit,
                                  fit_app_perf,
                                  fit_test_perf,
                                  val_repcv_k5,
                                  val_repcv_k10,
                                  val_boot) |>
        
        unlist() |>
        t() |>
        as_tibble() |>
        mutate(sim = sim,
               tuning_method = "boot632")
      
      # Remove objects after saving results
      rm(fit,
         fit_app_perf,
         fit_test_perf,
         val_repcv_k5,
         val_repcv_k10,
         val_boot)
      
      # Bind results ----
      
      # Bind coefficient matrices
      coefs <- Reduce(Matrix::rbind2, list(fit_20rep_5fold_coefs,
                                           fit_10rep_10fold_coefs,
                                           fit_optboot_coefs,
                                           fit_boot632_coefs))
      
      # Columns to add: simulation and tuning method
        # For tuning method:
        # 1 = 20rep_5fold CV
        # 2 = 10rep_5fold CV
        # 3 = OPTBOOT
        # 4 = BOOT632
      sim_col <- Matrix(rep(sim, 4), sparse = TRUE,
                        dimnames = list(NULL, "sim"))
      
      tuning_col <- Matrix(1:4, sparse = TRUE,
                           dimnames = list(NULL, "tuning"))
      
      # Add defined columns
      coefs <- Reduce(Matrix::cbind2, list(coefs,
                                           sim_col,
                                           tuning_col))

      # Global results
      results <- list(fit_repcv_k5_results,
                      fit_repcv_k10_results,
                      fit_optboot_results,
                      fit_boot632_results) |>
        bind_rows()
      
      # List to return
      list(results = results,
           coefs = coefs)
    }
  }, .options = furrr_options(seed = TRUE))
  
  plan(sequential)
  
  validation_results
}
