process TRIMMOMATIC {

    tag "$sample_id"

    // Publish trimmed paired-end reads
    publishDir "${params.outdir}/isolate/trimmed/", mode: 'copy'

    input:
    tuple val(sample_id), path(read1), path(read2)

    // Adapter sequence file
    path adapters

    output:
    tuple val(sample_id),
          path("${sample_id}_R_1_trimmed.fastq.gz"),
          path("${sample_id}_R_2_trimmed.fastq.gz")

    script:
    """
    trimmomatic PE -threads ${task.cpus} -phred33 \
        ${read1} \
        ${read2} \
        ${sample_id}_R_1_trimmed.fastq.gz \
        /dev/null \
        ${sample_id}_R_2_trimmed.fastq.gz \
        /dev/null \
        ILLUMINACLIP:${adapters}:2:30:10 \
        LEADING:20 \
        TRAILING:20 \
        SLIDINGWINDOW:4:20 \
        MINLEN:36
    """
}