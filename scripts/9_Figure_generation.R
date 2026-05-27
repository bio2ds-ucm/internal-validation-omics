# DESCRIPTION:
# Code for figure generation
#
# NOTE: this script generates figures for ONE dataset at a time. To generate
# all figures of the paper, run it TWICE: once with dataset = "MMDx-Kidney dataset"
# (uncommenting the appropriate line below) and once with dataset = "SCAN-B dataset".

# LIBRARIES ----
library(here)
library(dplyr)
library(tidyr)
library(tidyverse)
library(ggplot2)
library(ggdist)
library(ggplotify)
library(cowplot)
library(scales)
library(openxlsx)

# LOAD RESULTS ----

# Assign one or another to generate the corresponding figures

# dataset <- "MMDx-Kidney dataset"
dataset <- "SCAN-B dataset"

if(dataset == "MMDx-Kidney dataset"){
  
  umap_res <- readRDS(here::here("results", "intermediate", "GSE275126_UMAP.rds"))
  limma_res <-  readRDS(here::here("results", "intermediate", "GSE275126_DGE_analysis.rds"))
  load(here::here("results", "intermediate", "GSE275126_binded_results.RData"))
  
} else {
  
  umap_res <- readRDS(here::here("results", "intermediate", "GSE202203_UMAP.rds"))
  limma_res <-  readRDS(here::here("results", "intermediate", "GSE202203_DGE_analysis.rds"))
  load(here::here("results", "intermediate", "GSE202203_binded_results.RData"))
  
}

# REAL DATA-BASED SIMULATED SCENARIOS ----

# 1. UMAP ----

if(dataset == "MMDx-Kidney dataset"){
  group_lab <- c("yes" = "rejection", "no" = "no rejection")
  umap_cols <- c("rejection" = "darkmagenta", "no rejection" = "darkgoldenrod2")
  
} else{
  group_lab <- c("yes" = "luminal A", "no" = "non-luminal A")
  umap_cols <- c("luminal A" = "darkmagenta", "non-luminal A" = "darkgoldenrod2")
}

umap_long <- umap_res |>
  pivot_longer(cols = outcome_scenario_1:outcome_scenario_3,
               names_to = "scenario",
               values_to = "outcome") |>
  mutate(scenario = recode(scenario,
                           outcome_scenario_1 = "excellent discrimination scenario",
                           outcome_scenario_2 = "moderate discrimination scenario",
                           outcome_scenario_3 = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario",
                             "moderate discrimination scenario",
                             "null discrimination scenario"),
                  ordered = TRUE),
         outcome = recode(outcome,
                          yes = group_lab[1],
                          no = group_lab[2]) |>
           factor(levels = unname(group_lab),
                  ordered = TRUE))

umap <- ggplot(umap_long |>
                 rename(phenotype = outcome),
               aes(x = umap_1,
                   y = umap_2,
                   color = phenotype,
                   shape = phenotype)) +
  labs(x = "UMAP 1", y = "UMAP 2") +
  geom_point(size = 0.05) +
  scale_color_manual(name = "outcome",  
                     values = umap_cols) +
  scale_shape_manual(name = "outcome",  
                     values = c(16, 17, 18)) +  
  facet_wrap(~ scenario,
             nrow = 1) +
  theme_classic() +
  theme(legend.position = "bottom",
        axis.ticks = element_line(size = 0.1),
        text = element_text(size = 4.25),
        axis.line = element_line(size = 0.1),
        strip.background = element_rect(
          size = 0.25               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-5, 0, -5, 0),
        legend.key.height = unit(2, "pt")) +
  guides(fill = guide_colorbar(barwidth = 9,
                               barheight = 0.3)) +
  ggtitle(dataset)

# 2. VOLCANO PLOT ----

if(dataset == "MMDx-Kidney dataset"){
  group_text <- "rejection biopsies"
  
} else{
  group_text <- "luminal A tumors"
}

levels <- c(paste("up-regulated in", group_text), paste("down-regulated in", group_text), "non-significant")

limma_res <- limma_res |>
  mutate(discrimination_scenario = recode(scenario,
                                          `scenario 1` = "excellent discrimination scenario",
                                          `scenario 2` = "moderate discrimination scenario",
                                          `scenario 3` = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario",
                             "moderate discrimination scenario",
                             "null discrimination scenario"),
                  ordered = TRUE)) |>
  mutate(significance = case_when(adj.P.Val < 0.05 & logFC > 0 ~ levels[1],
                                  adj.P.Val < 0.05 & logFC < 0 ~ levels[2],
                                  .default = levels[3]) |>
           factor(levels = levels,
                  ordered = TRUE))

volcano_cols <- c("tomato", 
                  "blue", 
                  "gray26")
names(volcano_cols) <- levels

volcano <- ggplot(limma_res,
                  aes(x = logFC,
                      y = -log10(adj.P.Val),
                      color = significance)) +
  geom_point(size = 0.01,
             alpha = 0.5) +
  geom_vline(xintercept = 0, linewidth = 0.1) +
  scale_color_manual(values = volcano_cols) +
  facet_wrap(~ discrimination_scenario) +
  theme_classic() +
  theme(legend.position = "bottom",
        axis.ticks = element_line(size = 0.1),
        text = element_text(size = 4.25),
        axis.line = element_line(size = 0.1),
        strip.background = element_rect(
          size = 0.25               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-5, 0, -5, 0),
        legend.key.height = unit(2, "pt")) +
  guides(color = guide_legend(nrow = 3)) +
  labs(x = expression("log"[2]*"(FC)"), 
       y = expression("-log"[10]*"(adj. p-value)"))  +
  ggtitle(dataset)

# 3. TRUE AUC (OVERALL) ----

val_res <- val_res |>
  mutate(discrimination_scenario = recode(scenario, 
                                          `scenario 1` = "excellent discrimination scenario",
                                          `scenario 2` = "moderate discrimination scenario",
                                          `scenario 3` = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario",
                             "moderate discrimination scenario",
                             "null discrimination scenario"),
                  ordered = TRUE))

scenario_cols <- c("excellent discrimination scenario" = "#3CB371",
                   "moderate discrimination scenario" = "#E1AD01",
                   "null discrimination scenario" = "#CD5C5C")

auc_stats <- val_res |>
  group_by(discrimination_scenario) |>
  summarise(
    min    = min(roc_test, na.rm = TRUE),
    q1     = quantile(roc_test, 0.25, na.rm = TRUE),
    median = median(roc_test, na.rm = TRUE),
    mean   = mean(roc_test, na.rm = TRUE),
    q3     = quantile(roc_test, 0.75, na.rm = TRUE),
    max    = max(roc_test, na.rm = TRUE)) |>
  mutate(across(where(is.numeric), ~ round(.x, digits = 2)))

auc_test_overall <- ggplot(val_res,
                           aes(x = 1, 
                               y = roc_test,
                               color = discrimination_scenario,
                               fill = discrimination_scenario)) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               mapping = aes(x = 1,
                             y = roc_test),
               alpha = 0.35) +
  geom_point(data = val_res,
             inherit.aes = FALSE,
             aes(x = 1 - 0.15,
                 y = roc_test,
                 color = discrimination_scenario),
             size = 0.01,
             alpha = 0.5,
             position = position_jitter(width = 0.05,
                                        height = 0)) +
  geom_boxplot(outlier.shape = NA,
               color = "black",
               alpha = 0.1,
               fatten = 1.5,
               size = 0.1) +
  geom_label(
    data = auc_stats,
    aes(x = 1.6, 
        y = median, label = median),
    inherit.aes = FALSE,
    size = 1.5,
    label.size = 0.1
  ) +
  scale_fill_manual(values = scenario_cols) +
  scale_color_manual(values = scenario_cols) +
  scale_y_continuous(limits = c(0.45, 1),
                     breaks = seq(0.5, 1, 0.1)) +
  facet_wrap(~ discrimination_scenario) +
  theme_classic() +
  theme(legend.position = "none",
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.ticks = element_line(size = 0.1),
        text = element_text(size = 4.25),
        axis.line = element_line(size = 0.1),
        strip.background = element_rect(
          size = 0.25               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, 0, 0),
        legend.spacing = unit(0, "pt")) +
  guides(fill = guide_legend(nrow = 3)) +
  labs(x = "",
       y = "true AUC") +
  ggtitle(dataset)

# 4. COMPOSED FIGURE: SIMULATION dataset ----

fig_data <- plot_grid(auc_test_overall,
                      volcano,
                      umap,
                      nrow = 1,
                      labels = c("A", "B", "C"),
                      label_size = 8) |>   
  as.ggplot() +
  theme(plot.background = element_rect(fill = "white", colour = NA))

if (dataset == "MMDx-Kidney dataset"){
  ggsave(here::here("results", "figures", "Figure_S1.tiff"),
         plot = fig_data,
         units = "cm",
         width = 24,
         height = 8,
         dpi = 300)
} else {
  ggsave(here::here("results", "figures", "Figure_S2.tiff"),
         plot = fig_data,
         units = "cm",
         width = 24,
         height = 8,
         dpi = 300)
}

# GENE SELECTION ----

# 1. COMPUTE % OF WEAKLY INFORMATIVE GENES ----

pval_cutoff <- 0.20

scenarios <- limma_res$scenario |> unique()

val_res <- val_res |>
  mutate(weak_genes = 0)

for(sce in scenarios){
  
  weak_genes <- limma_res |>
    filter(scenario == sce & adj.P.Val >= pval_cutoff) |> 
    select(gene) |>
    pull()
  
  coef_subset <- coef_res[coef_res$scenario == sce, !names(coef_res) %in% c("(Intercept)", "sim", "tuning", "scenario", "outcome_frac")]
  
  val_res[val_res$scenario == sce, "weak_genes"] <- rowSums(coef_subset[, weak_genes, drop = FALSE] != 0)
}

non_signif_prop <- limma_res |>
  filter(scenario != "scenario 3") |>
  group_by(scenario) |>
  summarise(
    n_total = n(),
    n_nonsig = sum(adj.P.Val > 0.05),
    proportion_significant = n_nonsig / n_total
  )

non_signif_prop

weak_genes_prop <- limma_res |>
  filter(scenario != "scenario 3") |>
  group_by(scenario) |>
  summarise(
    n_total = n(),
    n_weak = sum(adj.P.Val >= pval_cutoff),
    proportion_significant = n_weak / n_total
  )

weak_genes_prop

# 2. # GENES SELECTED ----

gene_num_plot <- ggplot(val_res,
                        aes(x = as.numeric(discrimination_scenario),
                            y = nonull_coefs,
                            fill = discrimination_scenario)) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               alpha = 0.7) +
  geom_point(aes(x = as.numeric(discrimination_scenario) - 0.15,
                 y = nonull_coefs,
                 color = discrimination_scenario),
             size = 0.05,
             alpha = 0.7,
             position = position_jitter(width = 0.05,
                                        height = 0)) +
  geom_boxplot(outlier.shape = NA,
               alpha = 0,
               fatten = 1.5,
               size = 0.1,
               color = "black",
               size = 0.05) +
  scale_fill_manual(values = scenario_cols) +
  scale_color_manual(values = scenario_cols) +
  scale_y_continuous(limits = c(0, 90),
                     breaks = seq(0, 90, by = 10)) +
  labs(x = "",
       y = "genes in the model (#)",
       fill = "scenario") +
  facet_grid( ~ tuning) +
  theme_classic() +
  theme(legend.position = "bottom",
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.ticks = element_line(size = 0.1),
        text = element_text(size = 4.25),
        axis.line = element_line(size = 0.1),
        strip.background = element_rect(
          size = 0.25               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, -5, 0),
        legend.key.height = unit(6.5, "pt")) +
  guides(fill = guide_legend(nrow = 3)) +
  guides(fill = guide_legend(nrow = 2),
         color = "none") +
  ggtitle(dataset)

val_res |>
  filter(scenario == "scenario 3") |>
  group_by(tuning) |>
  summarise(
    min    = min(nonull_coefs, na.rm = TRUE),
    q1     = quantile(nonull_coefs, 0.25, na.rm = TRUE),
    median = median(nonull_coefs, na.rm = TRUE),
    mean   = mean(nonull_coefs, na.rm = TRUE),
    q3     = quantile(nonull_coefs, 0.75, na.rm = TRUE),
    max    = max(nonull_coefs, na.rm = TRUE),
    n_total = n(),
    n_null = sum(nonull_coefs == 0),
    prop_null = n_null / n_total)

# 3. PROPORTION OF WEAKLY INFORMATIVE GENES ----

val_res <- val_res |>
  mutate(weak_gene_prop = weak_genes/nonull_coefs)

weak_gene_prop <- ggplot(val_res |>
                           filter(discrimination_scenario != "null discrimination scenario"),
                         aes(x = as.numeric(discrimination_scenario),
                             y = weak_gene_prop,
                             fill = discrimination_scenario)) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               alpha = 0.7) +
  geom_point(aes(x = as.numeric(discrimination_scenario) - 0.15,
                 y = weak_gene_prop,
                 color = discrimination_scenario),
             size = 0.05,
             alpha = 0.7,
             position = position_jitter(width = 0.05,
                                        height = 0)) +
  geom_boxplot(outlier.shape = NA,
               alpha = 0,
               fatten = 1.5,
               color = "black",
               size = 0.1) +
  scale_y_continuous(limits = c(0, 0.30),
                     breaks = seq(0, 0.30, by = 0.05),
                     labels = label_percent()) +
  scale_fill_manual(values = scenario_cols) +
  scale_color_manual(values = scenario_cols) +
  labs(x = "",
       y = "weakly informative genes in the model (%)",
       fill = "scenario") +
  facet_wrap(~ tuning, nrow = 1) +
  theme_classic() +
  theme(legend.position = "bottom",
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.ticks = element_line(size = 0.1),
        text = element_text(size = 4.25),
        axis.line = element_line(size = 0.1),
        strip.background = element_rect(
          size = 0.25               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, -5, 0),
        legend.key.height = unit(6.5, "pt")) +
  guides(fill = guide_legend(nrow = 3)) +
  guides(fill = guide_legend(nrow = 2),
         color = "none") +
  ggtitle(dataset)

weak_gene_tuning <- val_res |>
  filter(scenario != "scenario 3") |>
  group_by(scenario, tuning) |>
  summarise(
    min    = min(weak_gene_prop, na.rm = TRUE),
    q1     = quantile(weak_gene_prop, 0.25, na.rm = TRUE),
    median = median(weak_gene_prop, na.rm = TRUE),
    mean   = mean(weak_gene_prop, na.rm = TRUE),
    q3     = quantile(weak_gene_prop, 0.75, na.rm = TRUE),
    max    = max(weak_gene_prop, na.rm = TRUE))

weak_gene_tuning

# 4. COMPOSED FIGURE: GENE SELECTION ----

fig_genes <- plot_grid(gene_num_plot,
                       weak_gene_prop,
                       nrow = 1,
                       labels = c("A", "B"),
                       label_size = 8) |>   
  as.ggplot() +
  theme(plot.background = element_rect(fill = "white", colour = NA))

if (dataset == "MMDx-Kidney dataset"){
  ggsave(here::here("results", "figures", "Figure_3.tiff"),
         plot = fig_genes,
         units = "cm",
         width = 16,
         height = 8,
         dpi = 300)
} else {
  ggsave(here::here("results", "figures", "Figure_S3.tiff"),
         plot = fig_genes,
         units = "cm",
         width = 16,
         height = 8,
         dpi = 300)
}

# PERFORMANCE ON TEST DATA ----

# 1. AUC ----

auc_tuning_stats <- val_res |>
  filter(nonull_coefs != 0) |>
  filter(scenario != "scenario 3") |>
  group_by(discrimination_scenario, tuning) |>
  summarise(
    min    = min(roc_test, na.rm = TRUE),
    q1     = quantile(roc_test, 0.25, na.rm = TRUE),
    median = median(roc_test, na.rm = TRUE),
    mean   = mean(roc_test, na.rm = TRUE),
    q3     = quantile(roc_test, 0.75, na.rm = TRUE),
    max    = max(roc_test, na.rm = TRUE)) |>
  mutate(across(where(is.numeric), ~ round(.x, digits = 2)))

auc_test_tuning <- ggplot(val_res |>
                            filter(scenario != "scenario 3"),
                          aes(x = 1,
                              y = roc_test,
                              fill = discrimination_scenario)) +
  geom_hline(
    data = subset(val_res, scenario == "scenario 1"),
    aes(yintercept = 0.9),
    linetype = "dotted",
    color = "gray26",
    lwd = 0.25
  ) +
  geom_hline(
    data = subset(val_res, scenario == "scenario 2"),
    aes(yintercept = 0.75),
    linetype = "dotted",
    color = "gray26",
    linewidth = 0.25
  ) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               alpha = 0.7) +
  geom_point(aes(x = 1 - 0.15,
                 y = roc_test,
                 color = discrimination_scenario),
             size = 0.05,
             alpha = 0.7,
             position = position_jitter(width = 0.05)) +
  geom_boxplot(outlier.shape = NA,
               alpha = 0,
               fatten = 1.5,
               color = "black",
               width = 0.5,
               size = 0.1) +
  geom_blank(aes(y = case_when(
    scenario == "scenario 1" ~ 0.75,  
    scenario == "scenario 2" ~ 0.6))) +
  geom_blank(aes(y = case_when(
    scenario == "scenario 1" ~ 1,
    scenario == "scenario 2" ~ 0.85
  ))) +
  scale_fill_manual(values = scenario_cols) +
  scale_color_manual(values = scenario_cols) +
  labs(x = "",
       y = "true AUC",
       fill = "scenario") +
  theme_classic() +
  geom_label(
    data = auc_tuning_stats,
    aes(x = 1.5, y = median, label = median),
    inherit.aes = FALSE,
    size = 1.5,
    label.size = 0.1
  ) +
  facet_grid(discrimination_scenario ~ tuning, scales = "free") +
  theme(legend.position = "none",
        axis.ticks = element_line(size = 0.1),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        text = element_text(size = 4.25),
        axis.line = element_line(size = 0.1),
        strip.background = element_rect(
          size = 0.25               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, -5, 0),
        legend.key.height = unit(6.5, "pt")) +
  guides(fill = guide_legend(nrow = 1),
         color = "none") +
  ggtitle(dataset)

auc_test_tuning

# 2. Calibration slope ----

calslope_tuning_stats <- val_res |>
  filter(nonull_coefs != 0) |>
  filter(scenario != "scenario 3") |>
  group_by(discrimination_scenario, tuning) |>
  summarise(
    min    = min(calslope_logistf_test, na.rm = TRUE),
    q1     = quantile(calslope_logistf_test, 0.25, na.rm = TRUE),
    median = median(calslope_logistf_test, na.rm = TRUE),
    mean   = mean(calslope_logistf_test, na.rm = TRUE),
    q3     = quantile(calslope_logistf_test, 0.75, na.rm = TRUE),
    max    = max(calslope_logistf_test, na.rm = TRUE)) |>
  mutate(across(where(is.numeric), ~ round(.x, digits = 2)))

calslope_test_tuning_zoom <- ggplot(val_res |>
                                      filter(scenario != "scenario 3"),
                                    aes(x = 1,
                                        y = calslope_logistf_test,
                                        fill = discrimination_scenario)) +
  geom_hline(
    aes(yintercept = 1),
    linetype = "dotted",
    color = "gray26",
    lwd = 0.25
  ) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               alpha = 0.7) +
  geom_point(aes(x = 1 - 0.15,
                 y = calslope_logistf_test,
                 color = discrimination_scenario),
             size = 0.05,
             alpha = 0.7,
             position = position_jitter(width = 0.05)) +
  geom_boxplot(outlier.shape = NA,
               alpha = 0,
               fatten = 1.5,
               color = "black",
               width = 0.5,
               size = 0.1) +
  scale_y_continuous(limits = c(0, 10),
                     breaks = seq(0, 10, by = 2)) +
  scale_fill_manual(values = scenario_cols) +
  scale_color_manual(values = scenario_cols) +
  labs(x = "",
       y = "true calibration slope",
       fill = "scenario") +
  theme_classic() +
  geom_label(
    data = calslope_tuning_stats,
    aes(x = 1.5, y = median, label = median),
    inherit.aes = FALSE,
    size = 1.5,
    label.size = 0.1
  ) +
  facet_grid(discrimination_scenario ~ tuning, scales = "free") +
  theme(legend.position = "none",
        axis.ticks = element_line(size = 0.1),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        text = element_text(size = 4.25),
        axis.line = element_line(size = 0.1),
        strip.background = element_rect(
          size = 0.25               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, -5, 0),
        legend.key.height = unit(6.5, "pt")) +
  guides(fill = guide_legend(nrow = 1),
         color = "none") +
  ggtitle(dataset)

calslope_test_tuning_zoom

fig_test_performance <- plot_grid(auc_test_tuning,
                                  calslope_test_tuning_zoom,
                                  nrow = 1,
                                  labels = c("A", "B"),
                                  label_size = 8) |>   
  as.ggplot() +
  theme(plot.background = element_rect(fill = "white", colour = NA))

if (dataset == "MMDx-Kidney dataset"){
  ggsave(here::here("results", "figures", "Figure_4.tiff"),
         plot = fig_test_performance,
         units = "cm",
         width = 16,
         height = 8,
         dpi = 300)
} else {
  ggsave(here::here("results", "figures", "Figure_S4.tiff"),
         plot = fig_test_performance,
         units = "cm",
         width = 16,
         height = 8,
         dpi = 300)
}

# PERFORMANCE ESTIMATION ----

est_cols <- c(apparent = "gray26",
              "20-rep 5-fold CV" = "#ff9896", 
              "10-rep 10-fold CV"= "#fcae91", 
              "regular BS"= "#253494", 
              ".632 BS" = "#225ea8", 
              ".632+ BS" = "#67a9cf", 
              "OOB BS" = "#c6dbef")

# 1. AUC ----

# 1.1. Apparent performance ----

# reshape data
val_res_long <- val_res |>
  filter(nonull_coefs != 0) |>
  pivot_longer(
    cols = c(roc_app, roc_test),
    names_to = "auc_type",
    values_to = "auc"
  ) |>
  mutate(
    auc_type = recode(
      auc_type,
      roc_app  = "Apparent",
      roc_test = "True value"
    )
  )

# summary stats
auc_stats <- val_res_long |>
  group_by(discrimination_scenario, tuning, auc_type) |>
  summarise(
    median = median(auc, na.rm = TRUE),
    .groups = "drop"
  )

auc_app_test <- ggplot(
  val_res_long,
  aes(
    x = auc_type,
    y = auc,
    fill = discrimination_scenario
  )
) +
  stat_halfeye(
    .width = 0,
    point_interval = NULL,
    alpha = 0.7
  ) +
  geom_point(
    aes(color = discrimination_scenario),
    size = 0.05,
    alpha = 0.7,
    position = position_jitter(width = 0.05, height = 0)
  ) +
  geom_boxplot(
    outlier.shape = NA,
    alpha = 0,
    color = "black",
    width = 0.5,
    fatten = 1.5,
    size = 0.1
  ) +
  geom_label(
    data = auc_stats,
    aes(
      x = auc_type,
      y = median,
      label = round(median, 2)
    ),
    inherit.aes = FALSE,
    size = 1.5,
    label.size = 0.1,
    hjust = 0,                 
    nudge_x = 0.28             
  ) +
  scale_fill_manual(values = scenario_cols) +
  scale_color_manual(values = scenario_cols) +
  
  scale_y_continuous(limits = c(0.45, 1.05),
                     breaks = seq(0.5, 1, 0.1)) +
  
  labs(
    x = "",
    y = "AUC",
    fill = "scenario"
  ) +
  facet_grid(discrimination_scenario ~ tuning) +
  theme_classic() +
  theme(
    legend.position = "none",
    axis.ticks = element_line(size = 0.1),
    text = element_text(size = 4.25),
    axis.line = element_line(size = 0.1),
    strip.background = element_rect(size = 0.25),
    legend.margin     = margin(0, 0, 0, 0),
    legend.box.margin = margin(-15, 0, -5, 0),
    legend.key.height = unit(6.5, "pt")
  ) +
  guides(
    fill = guide_legend(nrow = 2),
    color = "none"
  ) +
  ggtitle(dataset)

if (dataset == "MMDx-Kidney dataset"){
  ggsave(here::here("results", "figures", "Figure_S5.tiff"),
         plot = auc_app_test,
         units = "cm",
         width = 8,
         height = 8,
         dpi = 300)
} else {
  ggsave(here::here("results", "figures", "Figure_S6.tiff"),
         plot = auc_app_test,
         units = "cm",
         width = 8,
         height = 8,
         dpi = 300)
}

# 1.2. Differences estimate-true value ----

# Prepare data
val_res_auc_diff <- val_res_auc_diff |>
  mutate(scenario = recode(scenario,
                           `scenario 1` = "excellent discrimination scenario",
                           `scenario 2` = "moderate discrimination scenario",
                           `scenario 3` = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario",
                             "moderate discrimination scenario",
                             "null discrimination scenario"),
                  ordered = TRUE))

auc_true_table <- tibble(dataset = rep(dataset, nrow(val_res)),
                         metric = rep("AUC", nrow(val_res))) |>
  bind_cols(val_res) |>
  mutate(dataset = dataset,
         matric = "AUC",
         scenario = recode(scenario,
                           `scenario 1` = "excellent discrimination scenario",
                           `scenario 2` = "moderate discrimination scenario",
                           `scenario 3` = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario",
                             "moderate discrimination scenario",
                             "null discrimination scenario"),
                  ordered = TRUE)) |>
  select(dataset, metric, scenario, tuning, roc_test) |>
  mutate(technique = "true value") |>
  rename(diff = roc_test)


# Supplementary data
auc_diff_table <- tibble(dataset = rep(dataset, nrow(val_res_auc_diff)),
                         metric = rep("AUC", nrow(val_res_auc_diff))) |>
  bind_cols(val_res_auc_diff) |>
  filter(technique != "OOB BS") |> 
  select(dataset, metric, scenario, tuning, diff, technique)

auc_table <- auc_true_table |>
  bind_rows(auc_diff_table) |>
  mutate(performance_metric = "AUC",
         technique = factor(technique,
                            levels = c("true value",
                                       "apparent",
                                       "20-rep 5-fold CV",
                                       "10-rep 10-fold CV",
                                       "regular BS",
                                       ".632 BS",
                                       ".632+ BS"),
                            ordered = TRUE)) |>
  group_by(dataset, metric, scenario, tuning, technique) |>
  summarise(mean = mean(diff, na.rm = TRUE) |> round(digits = 4),
            sd = sd(diff, na.rm = TRUE) |> round(digits = 4),
            median = median(diff, na.rm = TRUE) |> round(digits = 4),
            q1 = quantile(diff, probs = 0.25, na.rm = TRUE) |> round(digits = 4),
            q3 = quantile(diff, probs = 0.75, na.rm = TRUE) |> round(digits = 4),
            iqr = (quantile(diff, probs = 0.75, na.rm = TRUE) - quantile(diff, probs = 0.25, na.rm = TRUE)) |> round(digits = 4),
            p10 = quantile(diff, probs = 0.10, na.rm = TRUE) |> round(digits = 4),
            p90 = quantile(diff, probs = 0.90, na.rm = TRUE) |> round(digits = 4),
            min = min(diff, na.rm = TRUE) |> round(digits = 4),
            max = max(diff, na.rm = TRUE) |> round(digits = 4),
            n = sum(!is.na(diff))) 

write.xlsx(auc_table,
           file = here::here("results", "tables", paste0("Supp_File_F1_auc", dataset, ".xlsx")))


# Figure
auc_est <- ggplot(val_res_auc_diff |>
                    filter(technique != "apparent" & technique != "OOB BS"),
                  aes(x = as.numeric(technique),
                      y = diff,
                      fill = technique)) +
  geom_hline(yintercept = 0,
             lwd = 0.25) +
  geom_hline(yintercept = c(-0.05, -0.025, 0.025, 0.05),
             linetype = "dotted",
             color = "gray26",
             lwd = 0.25) +
  geom_point(aes(x = as.numeric(technique) - 0.15,
                 y = diff,
                 color = technique),
             size = 0.05,
             alpha = 0.7,
             position = position_jitter(width = 0.05)) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               mapping = aes(x = as.numeric(technique),
                             y = diff),
               alpha = 0.7) +
  geom_boxplot(outlier.shape = NA,
               lwd = 0.25,
               alpha = 0,
               fatten = 1.5,
               size = 0.1,
               color = "black") +
  scale_y_continuous(limits = c(-0.275, 0.475), 
                     breaks = seq(-0.2, 0.4, 0.1),
                     labels = label_number(accuracy = 0.01)) +
  scale_fill_manual(values = est_cols) +
  scale_color_manual(values = est_cols) +
  labs(x = "",
       y = "AUC: estimate - true value",
       fill = "validation strategy") +
  theme_classic() +
  facet_grid(scenario ~ tuning) +
  theme(legend.position = "bottom",
        axis.ticks = element_line(size = 0.1),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.line = element_line(size = 0.25),
        strip.background = element_rect(
          size = 0.5               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, -5, 0)) +
  guides(fill = guide_legend(nrow = 2),
         color = "none") +
  ggtitle(dataset)


if (dataset == "MMDx-Kidney dataset"){
  ggsave(here::here("results", "figures", "Figure_5.tiff"),
         plot = auc_est,
         units = "cm",
         width = 21,
         height = 21,
         dpi = 300)
} else {
  ggsave(here::here("results", "figures", "Figure_S7.tiff"),
         plot = auc_est,
         units = "cm",
         width = 21,
         height = 21,
         dpi = 300)
}

# Only excellent discrimination scenario
auc_est_subset <- ggplot(val_res_auc_diff |>
                           filter(technique != "apparent" & technique != "OOB BS" & outcome_frac == 0),
                         aes(x = as.numeric(technique),
                             y = diff,
                             fill = technique)) +
  geom_hline(yintercept = 0,
             lwd = 0.25) +
  geom_hline(yintercept = c(-0.05, -0.025, 0.025, 0.05),
             linetype = "dotted",
             color = "gray26") +
  geom_point(aes(x = as.numeric(technique) - 0.15,
                 y = diff,
                 color = technique),
             size = 0.05,
             alpha = 0.7,
             position = position_jitter(width = 0.05)) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               mapping = aes(x = as.numeric(technique),
                             y = diff),
               alpha = 0.7) +
  geom_boxplot(outlier.shape = NA,
               lwd = 0.25,
               alpha = 0,
               fatten = 1.5,
               size = 0.1,
               color = "black") +
  scale_y_continuous(limits = c(-0.16, 0.12), 
                     breaks = seq(-0.16, 0.12, 0.01)) +
  scale_fill_manual(values = est_cols) +
  scale_color_manual(values = est_cols) +
  labs(x = "",
       y = "AUC: estimate - true value",
       fill = "validation strategy") +
  theme_classic() +
  facet_grid(scenario ~ tuning) +
  theme(legend.position = "bottom",
        axis.ticks = element_line(size = 0.1),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.line = element_line(size = 0.25),
        strip.background = element_rect(
          size = 0.5               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, -5, 0)
  ) +
  guides(fill = guide_legend(nrow = 2),
         color = "none") +
  ggtitle(dataset)


if (dataset == "MMDx-Kidney dataset"){
  ggsave(here::here("results", "figures", "Figure_S8.tiff"),
         plot = auc_est_subset,
         units = "cm",
         width = 21,
         height = 12,
         dpi = 300)
} else {
  ggsave(here::here("results", "figures", "Figure_S9.tiff"),
         plot = auc_est_subset,
         units = "cm",
         width = 21,
         height = 12,
         dpi = 300)
}

# 2. Calibration slope ----

# 2.1. Differences estimate-true value ----

# Prepare data
val_res_cal_diff <- val_res_cal_diff |>
  mutate(scenario = recode(scenario,
                           `scenario 1` = "excellent discrimination scenario",
                           `scenario 2` = "moderate discrimination scenario",
                           `scenario 3` = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario",
                             "moderate discrimination scenario",
                             "null discrimination scenario"),
                  ordered = TRUE))

# Supplementary data
cal_true_table <- tibble(dataset = rep(dataset, nrow(val_res)),
                         metric = rep("calibration slope", nrow(val_res))) |>
  bind_cols(val_res) |>
  mutate(scenario = recode(scenario,
                           `scenario 1` = "excellent discrimination scenario",
                           `scenario 2` = "moderate discrimination scenario",
                           `scenario 3` = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario",
                             "moderate discrimination scenario",
                             "null discrimination scenario"),
                  ordered = TRUE)) |>
  select(dataset, metric, scenario, tuning, calslope_logistf_test) |>
  mutate(technique = "true value") |>
  rename(diff = calslope_logistf_test)

cal_diff_table <- tibble(dataset = rep(dataset, nrow(val_res_cal_diff)),
                         metric = rep("calibration slope", nrow(val_res_cal_diff))) |>
  bind_cols(val_res_cal_diff) |>
  filter(technique != "OOB BS") |> 
  select(dataset, metric, scenario, tuning, diff, technique)

cal_table <- cal_true_table |>
  bind_rows(cal_diff_table) |>
  mutate(performance_metric = "calibration slope",
         technique = factor(technique,
                            levels = c("true value",
                                       "apparent",
                                       "20-rep 5-fold CV",
                                       "10-rep 10-fold CV",
                                       "regular BS",
                                       ".632 BS",
                                       ".632+ BS"),
                            ordered = TRUE)) |>
  group_by(dataset, metric, scenario, tuning, technique) |>
  summarise(mean = mean(diff, na.rm = TRUE) |> round(digits = 4),
            sd = sd(diff, na.rm = TRUE) |> round(digits = 4),
            median = median(diff, na.rm = TRUE) |> round(digits = 4),
            q1 = quantile(diff, probs = 0.25, na.rm = TRUE) |> round(digits = 4),
            q3 = quantile(diff, probs = 0.75, na.rm = TRUE) |> round(digits = 4),
            iqr = (quantile(diff, probs = 0.75, na.rm = TRUE) - quantile(diff, probs = 0.25, na.rm = TRUE)) |> round(digits = 4),
            p10 = quantile(diff, probs = 0.10, na.rm = TRUE) |> round(digits = 4),
            p90 = quantile(diff, probs = 0.90, na.rm = TRUE) |> round(digits = 4),
            min = min(diff, na.rm = TRUE) |> round(digits = 4),
            max = max(diff, na.rm = TRUE) |> round(digits = 4),
            n = sum(!is.na(diff))) 

write.xlsx(cal_table,
           file = here::here("results", "tables", paste0("Supp_File_F3_calibration_slope_", dataset, ".xlsx")))

# Figure
cal_est_diff <- ggplot(val_res_cal_diff |>
                         filter(technique != "apparent" & technique != "OOB BS"),
                       aes(x = as.numeric(technique),
                           y = diff,
                           fill = technique)) +
  geom_hline(yintercept = 0,
             lwd = 0.25) +
  geom_hline(yintercept = c(-1, -0.5, 0.5, 1),
             linetype = "dotted",
             color = "gray26",
             lwd = 0.25) +
  geom_point(aes(x = as.numeric(technique) - 0.15,
                 y = diff,
                 color = technique),
             size = 0.025,
             alpha = 0.7,
             position = position_jitter(width = 0.05)) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               mapping = aes(x = as.numeric(technique),
                             y = diff),
               alpha = 0.7) +
  geom_boxplot(outlier.shape = NA,
               lwd = 0.25,
               alpha = 0,
               fatten = 1.5,
               size = 0.025,
               color = "black") +
  scale_y_continuous(limits = c(-10, 15),
                     breaks = seq(-10, 14, 2)) +
  scale_fill_manual(values = est_cols) +
  scale_color_manual(values = est_cols) +
  labs(x = "",
       y = "calibration slope: estimate - true value",
       fill = "validation strategy") +
  theme_classic() +
  facet_grid(scenario ~ tuning) +
  theme(legend.position = "bottom",
        axis.ticks = element_line(size = 0.1),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.line = element_line(size = 0.25),
        strip.background = element_rect(
          size = 0.5               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, -5, 0)
  ) +
  guides(fill = guide_legend(nrow = 2),
         color = "none") +
  ggtitle(dataset)


if (dataset == "MMDx-Kidney dataset"){
  ggsave(here::here("results", "figures", "Figure_6.tiff"),
         plot = cal_est_diff,
         units = "cm",
         width = 21,
         height = 21,
         dpi = 300)
} else {
  ggsave(here::here("results", "figures", "Figure_S10.tiff"),
         plot = cal_est_diff,
         units = "cm",
         width = 21,
         height = 21,
         dpi = 300)
}

# 2.2. True value and estimates ----

val_res_cal_long <- val_res |>
  select(sim,
         tuning,
         scenario,
         outcome_frac,
         calslope_logistf_test,
         calslope_logistf_20rep5foldCV,
         calslope_logistf_10rep10foldCV,
         calslope_optboot,
         calslope_boot632,
         calslope_boot632plus,
         calslope_logistf_oob_boot) |>
  pivot_longer(cols = calslope_logistf_test:calslope_logistf_oob_boot,
               names_to = "technique",
               values_to = "estimate") |>
  mutate(technique = recode(technique,
                            calslope_logistf_test = "true value",
                            `calslope_logistf_10rep10foldCV` = "10-rep 10-fold CV",
                            `calslope_logistf_20rep5foldCV` = "20-rep 5-fold CV",
                            calslope_optboot = "regular BS",
                            calslope_boot632 = ".632 BS",
                            calslope_boot632plus = ".632+ BS",
                            calslope_logistf_oob_boot = "OOB BS") |>
           factor(levels = c("true value",
                             "20-rep 5-fold CV",
                             "10-rep 10-fold CV",
                             "regular BS",
                             ".632 BS",
                             ".632+ BS",
                             "OOB BS"),
                  ordered = TRUE))

val_res_cal_long <- val_res_cal_long |>
  mutate(scenario = recode(scenario,
                           `scenario 1` = "excellent discrimination scenario",
                           `scenario 2` = "moderate discrimination scenario",
                           `scenario 3` = "null discrimination scenario") |>
           factor(levels = c("excellent discrimination scenario",
                             "moderate discrimination scenario",
                             "null discrimination scenario"),
                  ordered = TRUE))

est_cols_test <- c("true value" = "gray26", est_cols)

cal_est <- ggplot(val_res_cal_long |>
                    filter(technique != "apparent" & technique != "OOB BS"),
                  aes(x = as.numeric(technique),
                      y = estimate,
                      fill = technique)) +
  geom_hline(yintercept = 1,
             linetype = "dotted", 
             color = "gray26",
             lwd = 0.25) +
  geom_point(aes(x = as.numeric(technique) - 0.15,
                 y = estimate,
                 color = technique),
             size = 0.025,
             alpha = 0.7,
             position = position_jitter(width = 0.05)) +
  stat_halfeye(.width = 0,
               point_interval = NULL,
               mapping = aes(x = as.numeric(technique),
                             y = estimate),
               alpha = 0.7) +
  geom_boxplot(outlier.shape = NA,
               lwd = 0.25,
               alpha = 0,
               fatten = 1.5,
               size = 0.025,
               color = "black") +
  scale_y_continuous(limits = c(-6, 10),
                     breaks =  seq(-6, 10, by = 2)) +
  scale_fill_manual(values = est_cols_test) +
  scale_color_manual(values = est_cols_test) +
  labs(x = "",
       y = "calibration slope estimate",
       fill = "validation strategy") +
  theme_classic() +
  facet_grid(scenario ~ tuning) +
  theme(legend.position = "bottom",
        axis.ticks = element_line(size = 0.1),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.line = element_line(size = 0.25),
        strip.background = element_rect(
          size = 0.5               
        ),
        legend.margin     = margin(0, 0, 0, 0),
        legend.box.margin = margin(-15, 0, -5, 0)
  ) +
  guides(fill = guide_legend(nrow = 2),
         color = "none") +
  ggtitle(dataset)


if (dataset == "MMDx-Kidney dataset"){
  ggsave(here::here("results", "figures", "Figure_S11.tiff"),
         plot = cal_est,
         units = "cm",
         width = 21,
         height = 21,
         dpi = 300)
} else {
  ggsave(here::here("results", "figures", "Figure_S12.tiff"),
         plot = cal_est,
         units = "cm",
         width = 21,
         height = 21,
         dpi = 300)
}

