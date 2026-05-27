# DESCRIPTION:
# GSE275126 data
# Microarray data processing
# Obtaining final data, containing expression data and outcome of interest

# LIBRARIES ----
library(here)
library(dplyr)
library(tibble)
library(stringr)
library(affy)
library(primeviewhsentrezgcdf)
library(GEOquery)

# PROCESS EXPRESSION DATA ----

# 1. RMA ----

# Path for CEL files
cel_path <- here::here("data", "raw", "GSE275126_microarray/")

# Obtain CEL file names
cel_names <- list.files(path = cel_path, 
                        full.names = FALSE)

# cdfname = "primeviewhsentrezgcdf" to obtain expression values at the gene level
eset <- justRMA(filenames = cel_names,
                background = TRUE,
                bgversion = 2,
                normalize = TRUE,
                destructive = TRUE,
                cdfname = "primeviewhsentrezgcdf")

# 2. Extract and save expression matrix ----

expr_mat <- exprs(eset)

saveRDS(expr_mat,
        here::here("results", "intermediate", "GSE275126_norm_matrix.rds"))

# LOAD METADATA FROM GEO ----

# GEO data
geo_data <- getGEO("GSE275126", GSEMatrix = TRUE)

# Metadata
geo_metadata <- pData(phenoData(geo_data[[1]]))

geo_metadata |>
  dim()

# CHECK SAMPLE ID CORRESPONDENCE ----

# Head: metadata
geo_metadata |>
  rownames() |>
  head()

# Head: expression set
expr_mat |>
  colnames() |>
  head()

# Tail
geo_metadata |>
  rownames() |>
  tail()

expr_mat |>
  colnames() |>
  tail()

# Remove substring after first "_" in eset colnames
sample_id_split <- strsplit(colnames(expr_mat), "_")
sample_id <- sapply(sample_id_split, FUN = function(x) x[[1]])

# Explore head and tail
sample_id |> head()
sample_id |> tail()

# Check consistency and order with sample IDs in metadata
all(sample_id == rownames(geo_metadata))

# Assign new sample IDs to expression matrix
colnames(expr_mat) <- sample_id

# Check after assigning
all(colnames(expr_mat) == rownames(geo_metadata))

# OUTCOME ----

geo_metadata$`rej7aaclust (nr, minor, tcmr1, tcmr2, eabmr, fabmr, labmr):ch1` |>
  table(useNA = "always")

# Binary outcome: rejection vs. no rejection
geo_metadata <- geo_metadata |>
  mutate(rejection = case_when(`rej7aaclust (nr, minor, tcmr1, tcmr2, eabmr, fabmr, labmr):ch1` != "NR" ~ "yes",
                               .default = "no") |>
           factor())

# Check 
geo_metadata$rejection |>
  table(useNA = "always")

# FINAL DATAFRAME ----

# 1. Metadata: subset of columns ----

geo_metadata <- geo_metadata |>
  rownames_to_column(var = "sample_id") |>
  select(sample_id, rejection)

geo_metadata |>
  str()

# 2. Expression data ----

expr_data <- expr_mat |>
  t() |>
  as.data.frame() |>
  rownames_to_column(var = "sample_id")

# 3. Final data set ----

data <- geo_metadata |>
  inner_join(expr_data) 

# Check dimensions after joining
geo_metadata |>
  dim()

expr_data |>
  dim()

data |>
  dim()

saveRDS(data,
        here::here("results", "intermediate", "GSE275126_microarray_data.rds"))