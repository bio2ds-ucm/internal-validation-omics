# `data/` — Datasets

This study uses two **publicly available** transcriptomic cohorts from the Gene Expression Omnibus (GEO). Both can be downloaded directly from GEO without restricted access. They are NOT redistributed in this repository (the `data/raw/` folder is gitignored).

## Folder structure

```
data/
├── README.md      # this file
├── raw/           # raw downloads from GEO (gitignored)
│   ├── GSE275126_microarray/   # CEL files for MMDx-Kidney
│   └── GSE202203_rnaseq/       # raw counts TSV for SCAN-B
└── processed/     # preprocessed data (gitignored)
```

The `raw/` and `processed/` subfolders are excluded from Git. After download, place files there locally.

---

## Dataset 1 — MMDx-Kidney (GSE275126)

Affymetrix PrimeView microarray gene expression from kidney transplant biopsies, with rejection phenotypes determined by the MMDx algorithm.

- **GEO accession**: [GSE275126](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE275126)
- **Technology**: microarray (Affymetrix PrimeView, ENTREZG re-annotation)
- **Sample size**: ~5,000 biopsies
- **Outcome**: binary rejection (yes/no), derived from `rej7aaclust` classification (NR = no, anything else = yes)

### How to obtain

1. Visit [https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE275126](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE275126).
2. Download the supplementary CEL files (raw microarray intensities). They will arrive as a `.tar` archive.
3. Extract all `.CEL` files into:

   ```
   data/raw/GSE275126_microarray/
   ```

4. Metadata (phenotypes) is downloaded automatically by the script `scripts/GSE275126_code/1_GSE275126_data_processing.R` via the `GEOquery` package.

### Preprocessing

Implemented in `scripts/GSE275126_code/1_GSE275126_data_processing.R`:

- RMA normalization with custom CDF (`primeviewhsentrezgcdf`) to obtain gene-level expression.
- Binary outcome construction.
- Final dataset saved to `results/intermediate/GSE275126_microarray_data.rds`.

---

## Dataset 2 — SCAN-B (GSE202203)

RNA-sequencing data from invasive primary breast cancer tumors of the SCAN-B (Sweden Cancerome Analysis Network — Breast) project, with PAM50 molecular subtypes.

- **GEO accession**: [GSE202203](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202203)
- **Technology**: RNA-seq
- **Sample size**: 2,854 tumors (after excluding unclassified PAM50)
- **Outcome**: binary Luminal A subtype (yes/no), derived from PAM50 classification

### How to obtain

1. Visit [https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202203](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE202203).
2. Download the supplementary file `GSE202203_RawCounts_gene_3207.tsv` (gene-level raw counts).
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
- Final dataset saved to `results/intermediate/GSE202203_rnaseq_data.rds`.

---

## Citation

If you use these datasets, please cite the original GEO depositions and any associated publications listed on the GEO pages. Required citation information is available on the corresponding GEO accession pages above.
