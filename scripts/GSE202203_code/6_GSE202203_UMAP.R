# LIBRARIES ----
library(here)
library(dplyr)
library(Seurat)
library(uwot)

# LOAD RESULTS ----
data_list <- readRDS(here::here("results", "intermediate", "GSE202203_data_sim_scenarios.rds"))


expr_mat_t <- data_list$expr_mat |>
  t()

# SEURAT OBJECT ----

# Create seurat object
seurat_obj <- CreateSeuratObject(counts = expr_mat_t)

# Counts are already normalized and log- transformed
LayerData(seurat_obj, layer = "data") <- LayerData(seurat_obj, layer = "counts")

# TOP VARIABLE GENES AND PCA ----

# Top 2000 variable genes
nfeatures <- 2000
seurat_obj <- FindVariableFeatures(seurat_obj, 
                                   selection.method = "vst", 
                                   nfeatures = nfeatures)

vargenes <- VariableFeatures(seurat_obj)

# scale data
seurat_obj <- ScaleData(seurat_obj)

# PCA

# Number of PCs to retain
npc <- 50
seurat_obj <- RunPCA(seurat_obj, 
                     features = vargenes,
                     npcs = npc)

# UMAP ----
seed <- 1850
set.seed(seed)
seurat_obj  <- RunUMAP(seurat_obj, dims = 1:npc,
                       n.neighbors = 100,
                       min.dist = 0.5)

# UMAP coordinates
umap_coords <- Embeddings(seurat_obj, reduction = "umap")

umap_coords <- umap_coords |>
  as.data.frame() |>
  rownames_to_column(var = "sample") |>
  mutate(outcome_scenario_1 = data_list$y_vector$y_vector_orig,
         outcome_scenario_2 = data_list$y_vector$y_vector_perm30,
         outcome_scenario_3 = data_list$y_vector$y_vector_perm100)

saveRDS(umap_coords,
        here::here("results", "intermediate", "GSE202203_UMAP.rds"))