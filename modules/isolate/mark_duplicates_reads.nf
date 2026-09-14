process MARK_DUPLICATES {

    tag "$sample_id"

    cpus 2

    publishDir "${params.outdir}/isolate/trimmed_marked_reads", mode: 'copy'

    input:
    tuple val(sample_id), path(sorted_bam), path(sorted_bai)

    output:
    tuple val(sample_id),
          path("${sample_id}_marked.bam"),
          path("${sample_id}_marked.bam.bai")

    script:
    """
    gatk MarkDuplicates \
        -I ${sorted_bam} \
        -O ${sample_id}_marked.bam \
        -M ${sample_id}_marked_metrics.txt \
        --REMOVE_DUPLICATES false \
        --VALIDATION_STRINGENCY SILENT

    samtools index \
        -@ ${task.cpus} \
        ${sample_id}_marked.bam
    """
}