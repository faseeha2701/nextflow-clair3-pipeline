set -euo pipefail

nextflow run main.nf -profile apptainer \
    --reference data/reference.fasta \
    --reads data/sample.fastq \
    --model_path /root/nextflow_hg/nextflow/models/hifi_sequel2 \
    --sample sample1 \
    --outdir results \
    --threads 4
