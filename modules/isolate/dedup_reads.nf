process DEDUPLICATE {

    tag "$sample_id"

    cpus 2

    publishDir "${params.outdir}/isolate/trimmed_dedup_reads", mode: 'copy'

    input:
    tuple val(sample_id), path(sorted_bam), path(sorted_bai)

    output:
    tuple val(sample_id),
          path("${sample_id}_dedup.bam"),
          path("${sample_id}_dedup.bam.bai")

    script:
    """
    gatk MarkDuplicates \
        -I ${sorted_bam} \
        -O ${sample_id}_dedup.bam \
        -M ${sample_id}_dedup_metrics.txt \
        --REMOVE_DUPLICATES true \
        --VALIDATION_STRINGENCY SILENT

    samtools index \
        -@ ${task.cpus} \
        ${sample_id}_dedup.bam
    """
}