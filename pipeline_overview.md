# Pipeline Overview

This document explains what this pipeline does, how it works, and the purpose of each file in the repository.

## What This Pipeline Does

This is a Nextflow pipeline for calling genetic variants (SNPs and INDELs) from PacBio HiFi long-read sequencing data. It takes a reference genome and HiFi reads as input, and produces a VCF file containing the called variants.

## Workflow Steps

The pipeline runs four sequential steps:

1. **INDEX_REF_MINIMAP2** — Builds a minimap2 index (`.mmi`) from the reference FASTA for fast alignment.
2. **ALIGN_MINIMAP2** — Aligns the HiFi FASTQ reads to the reference using the `map-hifi` preset, producing a SAM file.
3. **SORT_INDEX_SAMTOOLS** — Sorts the SAM file by coordinate and converts it to an indexed, sorted BAM file.
4. **CALL_VARIANTS_CLAIR3** — Runs Clair3 (using the HiFi-specific deep learning model) on the BAM file to call variants, producing a compressed and indexed VCF file.

```
reference.fasta + sample.fastq
        |
        v
INDEX_REF_MINIMAP2  -->  reference.mmi
        |
        v
ALIGN_MINIMAP2      -->  sample.sam
        |
        v
SORT_INDEX_SAMTOOLS -->  sample.sorted.bam (+ .bai)
        |
        v
CALL_VARIANTS_CLAIR3 --> sample.vcf.gz (+ .tbi)
```

## Repository Structure

| File | Purpose |
|---|---|
| `main.nf` | Core pipeline logic — defines the workflow and all four processes. |
| `nextflow.config` | Configuration: default parameters, per-process CPU/memory/time limits, and execution profiles (`singularity`, `apptainer`). |
| `run_pipeline.sh` | Convenience shell script that wraps the full `nextflow run` command so it doesn't need to be retyped manually. |
| `README.md` | General project description and usage instructions. |
| `LAB_MANUAL.md` | Step-by-step usage guide, written for lab/teaching context. |
| `.gitignore` | Excludes large/generated files (data, models, results, work directory, container caches) from version control. |
| `PIPELINE_OVERVIEW.md` | This file — explains the pipeline's purpose, steps, and file structure. |

## What Is NOT in This Repository (and why)

The following are intentionally excluded via `.gitignore` because they are either too large for Git or are regenerated automatically each run:

- **`data/`** — Reference FASTA and FASTQ read files (can be GBs in size). Users should supply their own input data.
- **`models/`** — Clair3's pre-trained HiFi model files. Downloaded separately (see setup instructions below).
- **`results/`** — Pipeline output (BAM, VCF files). Generated fresh each run.
- **`work/`** — Nextflow's internal working directory, created automatically during execution.
- **`.apptainer_cache/` / `.singularity_cache/`** — Downloaded container images, often 500 MB–2 GB each.

## Containers Used

This pipeline pulls containers directly from public registries at runtime — no local `.sif` files are required or stored in this repo:

- `quay.io/biocontainers/minimap2:2.28--he4a0461_0`
- `quay.io/biocontainers/samtools:1.20--h50ea8bc_0`
- `hkubal/clair3:latest`

Apptainer (or Singularity) automatically downloads and caches these images the first time the pipeline runs.

## Setup Before Running

1. **Install Nextflow** and **Apptainer**.
2. **Download the Clair3 HiFi model** (choose the variant matching your sequencer — Sequel II or Revio):
   ```bash
   mkdir -p models/hifi_sequel2
   wget -r -np -nH --cut-dirs=3 -R "index.html*" -P ./models/hifi_sequel2 \
       https://www.bio8.cs.hku.hk/clair3/clair3_models_pytorch/hifi_sequel2/
   ```
3. **Index your reference FASTA**:
   ```bash
   samtools faidx data/reference.fasta
   ```

## Running the Pipeline

```bash
nextflow run main.nf \
    -profile apptainer \
    --reference data/reference.fasta \
    --reads data/sample.fastq \
    --model_path /absolute/path/to/models/hifi_sequel2 \
    --sample sample1 \
    --outdir results \
    --threads 4 \
    -resume
```

Note: `--model_path` must be an **absolute path** — Clair3 will fail with "Model path not found" if given a relative one.

## Issues Encountered During Development (and Fixes)

| Issue | Fix |
|---|---|
| DSL2 syntax errors (statements outside `workflow {}`) | Moved `if` checks and `Channel` declarations inside the `workflow` block. |
| Requested more CPUs than available | Set `--threads` to match actual available CPUs. |
| Host drive full, causing crashes during image pulls | Moved Apptainer cache directory to a drive with more free space. |
| Reference not indexed | Ran `samtools faidx` on the reference before variant calling. |
| Relative `--model_path` not recognized inside container | Used an absolute path instead. |
| Clair3's internal `parallel` tool failed (missing temp dir) | Created a `tmp_parallel` directory and set `TMPDIR` inside the process script. |
| Memory request exceeded available RAM | Lowered the `CALL_VARIANTS_CLAIR3` memory limit in `nextflow.config` to fit available system memory. |

## Output

After a successful run, `results/` will contain:

- `<sample>.sorted.bam` — Aligned reads, sorted and indexed.
- `<sample>.sorted.bam.bai` — BAM index.
- `<sample>.vcf.gz` — Called variants (SNPs and INDELs).
- `<sample>.vcf.gz.tbi` — VCF index.
