nextflow.enable.dsl=2

workflow {

  if( !params.reference )  error "Missing --reference"
  if( !params.reads )      error "Missing --reads"
  if( !params.model_path ) error "Missing --model_path"

  def ch_ref   = Channel.fromPath(params.reference)
  def ch_reads = Channel.fromPath(params.reads)
  def sampleName = params.sample ?: file(params.reads).getBaseName().replaceAll(/(\.fastq|\.fq)$/,'')

  def ch_mmi = INDEX_REF_MINIMAP2(ch_ref)
  def ch_sam = ALIGN_MINIMAP2(ch_reads, ch_mmi, ch_ref, sampleName)
  def ch_bam = SORT_INDEX_SAMTOOLS(ch_sam, sampleName)
  CALL_VARIANTS_CLAIR3(ch_bam.bam, ch_bam.bai, ch_ref, sampleName)
}

process INDEX_REF_MINIMAP2 {
  container "docker://quay.io/biocontainers/minimap2:2.28--he4a0461_0"
  input: path ref_fa
  output: path "reference.mmi", emit: mmi
  script:
  """
  minimap2 -d reference.mmi ${ref_fa}
  """
}

process ALIGN_MINIMAP2 {
  container "docker://quay.io/biocontainers/minimap2:2.28--he4a0461_0"
  publishDir params.outdir, mode: 'copy'
  input:
    path reads
    path mmi
    path ref_fa
    val  sample
  output: path "${sample}.sam", emit: sam
  script:
  """
  minimap2 -t ${task.cpus} -a -x map-hifi ${mmi} ${reads} > ${sample}.sam
  """
}

process SORT_INDEX_SAMTOOLS {
  container "docker://quay.io/biocontainers/samtools:1.20--h50ea8bc_0"
  publishDir params.outdir, mode: 'copy'
  input:
    path sam
    val  sample
  output:
    path "${sample}.sorted.bam", emit: bam
    path "${sample}.sorted.bam.bai", emit: bai
  script:
  """
  samtools sort -@ ${task.cpus} -o ${sample}.sorted.bam ${sam}
  samtools index -@ ${task.cpus} ${sample}.sorted.bam
  """
}

process CALL_VARIANTS_CLAIR3 {
  container "docker://hkubal/clair3:latest"
  publishDir params.outdir, mode: 'copy'
  input:
    path bam
    path bai
    path ref_fa
    val  sample
  output:
    path "${sample}.vcf.gz"
    path "${sample}.vcf.gz.tbi"
  script:
  """
  mkdir -p clair3_out
  mkdir -p \$PWD/tmp_parallel
  export TMPDIR=\$PWD/tmp_parallel

  run_clair3.sh \
    --bam_fn ${bam} \
    --ref_fn ${ref_fa} \
    --threads ${task.cpus} \
    --platform hifi \
    --model_path ${params.model_path} \
    --output clair3_out

  cp clair3_out/merge_output.vcf.gz ${sample}.vcf.gz
  cp clair3_out/merge_output.vcf.gz.tbi ${sample}.vcf.gz.tbi
  """
}

