# `data/` — Datasets

This study uses two **publicly available** transcriptomic cohorts from the Gene Expression Omnibus (GEO). Both can be downloaded directly from GEO without restricted access. They are NOT redistributed in this repository (the `data/raw/` folder is gitignored).

## Folder structure

```
data/
├── README.md      # this file
├── raw/           # raw downloads from GEO (gitignored)
│   ├── GSE275126_raw/   # CEL files for MMDx-Kidney
│   └── GSE202203_raw/   # raw count matrix for SCAN-B
└── processed/     # preprocessed data (gitignored)
```

The `raw/` and `processed/` subfolders are excluded from Git. After download, place files there locally.

---

## Dataset 1 — MMDx-Kidney (GSE275126)

Affymetrix PrimeView microarray gene expression from kidney transplant biopsies included in the MMDx-Kidney studies.

- **GEO accession**: [GSE275126](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE275126)
- **CEL files**: [GSE275126_RAW.tar](https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE275126&format=file)
- **Technology**: microarray (Affymetrix PrimeView)
- **Sample size**: 5,086 biopsies
- **Outcome**: binary rejection (yes/no), derived from `rej7aaclust` classification (NR = no, anything else = yes)

### How to obtain

1. Visit [https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE275126](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE275126).
2. Download the supplementary `.tar` archive containing the CEL files `GSE275126_RAW.tar` (raw microarray intensities)
3. Extract all `.CEL` files into:

   ```
   data/raw/GSE275126_raw/
   ```

4. Metadata (phenotypes) is downloaded automatically by the script `scripts/GSE275126_code/1_GSE275126_data_processing.R` via the `GEOquery` package.

### Preprocessing

Implemented in `scripts/GSE275126_code/1_GSE275126_data_processing.R`:

- RMA normalization with custom CDF (`primeviewhsentrezgcdf`) to obtain gene-level expression.
- Binary outcome construction.
- Final dataset saved to `data/processed/GSE275126_processed_data.rds`.

---

## Dataset 2 — SCAN-B (GSE202203)

RNA-sequencing data from invasive primary breast cancer tumors included in the SCAN-B study, with PAM50 molecular subtype classification.

- **GEO accession**: [GSE202203](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202203)
- **Raw count matrix**: [GSE202203_RawCounts_gene_3207.tsv.gz](https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE202203&format=file&file=GSE202203%5FRawCounts%5Fgene%5F3207%2Etsv%2Egz)
- **Technology**: RNA-seq
- **Sample size**: 2,854 tumors (after excluding unclassified PAM50 tumors)
- **Outcome**: binary Luminal A subtype (yes/no), derived from `pam50 subtype:ch1` (LumA = yes, anything else = no)

### How to obtain

1. Visit [https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202203](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202203).
2. Download the supplementary file `GSE202203_RawCounts_gene_3207.tsv` (gene-level raw count matrix).
3. Place it in:

   ```
   data/raw/GSE202203_rnaseq/GSE202203_RawCounts_gene_3207.tsv
   ```

4. Metadata is downloaded automatically by `scripts/GSE202203_code/1_GSE202203_data_processing.R` via `GEOquery`.

### Preprocessing

Implemented in `scripts/GSE202203_code/1_GSE202203_data_processing.R`:

- Filter out tumors with `Unclassified` PAM50 subtype.
- Upper-quantile normalization with `EDASeq`.
- Variance Stabilizing Transformation (VST) with `DESeq2`.
- Final dataset saved to `data/processed/GSE202203_processed_data.rds`.

---

## Citation

If you use these datasets, please cite the original GEO depositions and any associated publications listed on the GEO pages. Required citation information is available on the corresponding GEO accession pages above.
