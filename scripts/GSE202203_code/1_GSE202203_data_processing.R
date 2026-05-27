# DESCRIPTION:
# GSE202203 data
# RNAseq data processing
# Obtaining final data, containing expression data and outcome of interest

# LIBRARIES ----
library(here)
library(dplyr)
library(data.table)
library(GEOquery)
library(EDASeq)
library(edgeR)
library(DESeq2)
library(tibble)

# LOAD METADATA FROM GEO ----

# GEO data
geo_data <- getGEO("GSE202203", GSEMatrix = TRUE)

# Metadata
geo_metadata <- pData(phenoData(geo_data[[1]]))

geo_metadata |>
  dim()

# Set rownames
rownames(geo_metadata) <- geo_metadata$title

# OUTCOME ----

geo_metadata$`pam50 subtype:ch1` |>
  table(useNA = "always")
# No missing values, but unclassified tumors

# Filter out unclassified tumors
# Binary outcome: rejection vs. no rejection
geo_metadata <- geo_metadata |>
  filter(`pam50 subtype:ch1` != "Unclassified") |>
  mutate(lumA_subtype = case_when(`pam50 subtype:ch1` == "LumA" ~ "yes",
                                  .default = "no") |>
           factor())

# Check 
geo_metadata$lumA_subtype |>
  table(useNA = "always")

# LOAD EXPRESSION DATA ----

# GSE202203_RawCounts_gene_3207.tsv download from GEO

path <- here::here("data", "raw", "GSE202203_rnaseq/")

expr_mat <- fread(file = paste0(path, "GSE202203_RawCounts_gene_3207.tsv")) |>
  as.data.frame()

# Set rownames
rownames(expr_mat) <- expr_mat$X

expr_mat <- expr_mat |>
  select(-X)

# CHECK SAMPLE ID CORRESPONDENCE ----

# Head: metadata
geo_metadata |>
  rownames() |>
  head()

# Head: expression set
expr_mat |>
  colnames() |>
  head()

all(rownames(geo_metadata) %in% colnames(expr_mat))


# SUBSET EXPRESSSION DATA ----

expr_mat <- expr_mat |>
  select(rownames(geo_metadata)) |>
  as.matrix() |>
  round()

# NORMALIZATION + VST TRANSFORMATION ----

# ExpressionSet 
set <- newSeqExpressionSet(counts = expr_mat,
                           phenoData = geo_metadata)

# phenoData(set)@data to accesss phenoData in set

# Upper quantile normalization 
set <- betweenLaneNormalization(set, which = "upper")

# Size factor estimation
dds <- DESeqDataSetFromMatrix(counts(set), colData = pData(set), design = ~ 1)
dds <- estimateSizeFactors(dds)
dds <- estimateDispersionsGeneEst(dds)
cts <- counts(dds, normalized = TRUE)
disp <- pmax((rowVars(cts) - rowMeans(cts)), 0)/rowMeans(cts)^2
mcols(dds)$dispGeneEst <- disp
dds <- estimateDispersionsFit(dds, fitType = "mean")

# Transformation to the log space with a variance stabilizing transformation
vsd <- varianceStabilizingTransformation(dds, blind = FALSE)

# set@assayData$normalizedCounts to access normalized counts
# assay(vsd) to access normalized and log-transformed (vst-transformed) counts

norm_vst <- assay(vsd)

norm_vst |>
  dim()
# 19644  2854

saveRDS(norm_vst,
         here::here("results", "intermediate", "GSE202203_norm_matrix.rds"))

# FINAL DATAFRAME ----

# 1. Metadata: subset of columns ----

geo_metadata <- geo_metadata |>
  rownames_to_column(var = "sample_id") |>
  select(sample_id, lumA_subtype)

geo_metadata |>
  str()

# 2. Expression data ----

expr_data <- norm_vst |>
  t() |>
  as.data.frame() |>
  rownames_to_column(var = "sample_id")

# 3. Final data set ----

data <- geo_metadata |>
  inner_join(expr_data) 

# Check dimensions after joining
geo_metadata |>
  dim()
# [1] 2854    2

expr_data |>
  dim()
# [1]  2854 19645

data |>
  dim()
# [1]  2854 19645

saveRDS(data,
        here::here("results", "intermediate", "GSE202203_rnaseq_data.rds"))
