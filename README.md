# HiFi single-sample variant calling (Nextflow + Singularity)

**Inputs**
- Reference: FASTA (`--reference`)
- Reads: HiFi FASTQ/FASTQ.GZ (`--reads`)
- Clair3 HiFi model directory (`--model_path`)

**Outputs**
- Sorted BAM + BAI
- VCF.GZ + TBI

## Quick start

```bash
nextflow run main.nf -profile singularity \
  --use_local_sifs true \
  --sif_minimap2 containers/minimap2.sif \
  --sif_samtools containers/samtools.sif \
  --sif_clair3   containers/clair3.sif \
  --reference data/reference.fasta \
  --reads data/sample.fastq.gz \
  --model_path /shared/clair3_models/hifi \
  --sample sample1
```
