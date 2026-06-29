# HiFi Variant Calling Lab (Nextflow + Singularity)
**Workflow:** minimap2 (map-hifi) → samtools sort/index → Clair3 → VCF

## Learning objectives
By the end of this lab, you will be able to:
1. Run a reproducible genomics workflow using Nextflow and Singularity.
2. Align PacBio HiFi reads to a reference genome using minimap2.
3. Create a coordinate-sorted BAM and BAM index using samtools.
4. Call small variants (SNVs/indels) using Clair3.
5. Validate outputs and troubleshoot common problems.

---

## 1) Prerequisites
You need access to:
- **Nextflow** (DSL2)
- **Singularity** or **Apptainer**
- **Java** (required by Nextflow)

> On clusters, use the provided modules (e.g., `module load nextflow singularity`) if available.

---

## 2) Project structure
This lab folder contains:
```
hifi_variant_lab/
├─ main.nf
├─ nextflow.config
├─ LAB_MANUAL.md
├─ README.md
├─ data/
│  ├─ reference.fasta         # you provide this
│  └─ sample.fastq.gz         # you provide this
└─ containers/                # optional: instructor-provided .sif files
```

---

## 3) Inputs (single sample)
You will run one sample per pipeline execution.

### Reference genome
A FASTA file, e.g.:
- `data/reference.fasta`

### Reads (HiFi)
One FASTQ/FASTQ.GZ file, e.g.:
- `data/sample.fastq.gz`

### Clair3 model
Clair3 requires a **HiFi** model directory, e.g.:
- `/shared/clair3_models/hifi`

Ask your instructor for the correct path.

---

## 4) Run the pipeline
From inside the lab directory:

```bash
nextflow run main.nf -profile singularity   --reference data/reference.fasta   --reads data/sample.fastq.gz   --model_path /shared/clair3_models/hifi   --sample sample1   --outdir results   --threads 8
```

### Parameters
Required:
- `--reference` : reference FASTA
- `--reads` : HiFi FASTQ/FASTQ.GZ
- `--model_path` : Clair3 model directory

Optional:
- `--sample` : label used for output files (default: derived from FASTQ name)
- `--outdir` : results folder (default: `results`)
- `--threads` : CPU threads (default: 8)

---

## 5) Expected outputs
After a successful run:

```
results/
├─ sample1.sam                 
├─ sample1.sorted.bam
├─ sample1.sorted.bam.bai
├─ sample1.vcf.gz
└─ sample1.vcf.gz.tbi
```



