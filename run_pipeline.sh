#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper for students (edit paths as needed)
nextflow run main.nf -profile singularity   --reference data/reference.fasta   --reads data/sample.fastq.gz   --model_path /shared/clair3_models/hifi   --sample sample1   --outdir results   --threads 8
