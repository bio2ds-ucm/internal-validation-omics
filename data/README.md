# `data/` — Data sources and access

This study uses **two publicly described transcriptomic cohorts**. Both require formal access requests and are NOT redistributed in this repository.

## Folder structure

```
data/
├── README.md          # this file
├── raw/               # raw downloads (gitignored)
└── processed/         # preprocessed datasets (gitignored)
```

The `raw/` and `processed/` subfolders are excluded from Git via `.gitignore`. Place data there locally after obtaining access.

---

## Dataset 1 — MMDx-Kidney

Genome-wide microarray gene expression from kidney transplant biopsies.

- **Source studies**: MMDx-Kidney studies (ClinicalTrials.gov: NCT01299168, NCT04239703).
- **Sample size**: 5,086 biopsies.
- **Genes**: 18,593.
- **Outcome used**: Binary kidney transplant rejection (2,244 / 44.12%) vs non-rejection.
- **Reference for the dataset**: *[Add citation here]*
- **Access**: *[Add procedure here — e.g., contact corresponding author of MMDx studies, GEO accession, dbGaP request, etc.]*

### How to obtain

> **TODO**: document the exact access procedure once confirmed. Include:
> 1. URL or accession.
> 2. Application form, if needed.
> 3. Approximate processing time.
> 4. Citation requirements.

### Where to place after download

```
data/raw/mmdx-kidney/
```

The preprocessing pipeline in `scripts/01-data-preparation.R` will transform raw files into `data/processed/mmdx-kidney.rds`.

---

## Dataset 2 — SCAN-B

Whole-transcriptome RNA-sequencing from invasive primary breast cancer.

- **Source study**: SCAN-B study (ClinicalTrials.gov: NCT02306096).
- **Sample size**: 2,854 tumors.
- **Genes**: 19,644.
- **Outcome used**: Binary Luminal A (1,398 / 48.98%) vs non-Luminal A (PAM50 subtypes).
- **Reference for the dataset**: *[Add citation here]*
- **Access**: *[Add procedure here — typically via GEO or via SCAN-B consortium request]*

### How to obtain

> **TODO**: document the exact access procedure once confirmed.

### Where to place after download

```
data/raw/scan-b/
```

The preprocessing pipeline in `scripts/01-data-preparation.R` will transform raw files into `data/processed/scan-b.rds`.

---

## Preprocessing

Both datasets are preprocessed following established pipelines including normalization and log-transformation. The exact procedure is implemented in `scripts/01-data-preparation.R` and documented therein.

## Citation

If you use these datasets, please **cite the original consortia and publications** in addition to our paper. Required citations are listed in the original references above.
