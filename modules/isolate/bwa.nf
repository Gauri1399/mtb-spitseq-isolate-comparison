process BWA_MEM {

    tag "$sample_id"

    // Use 4 CPUs for BWA and samtools
    cpus 4

    // Store BWA-MEM results in a separate directory
    publishDir "${params.outdir}/isolate/bwa-mem", mode: 'copy'

    input:
    // Input sample ID and paired-end trimmed reads
    tuple val(sample_id), path(read1), path(read2)

    // Input H37Rv reference and BWA index files
    path reference_files

    output:
    // Output sorted BAM and BAM index
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai")

    script:
    """
    # Align trimmed reads to the H37Rv reference
    bwa mem \
        -t ${task.cpus} \
        -R '@RG\\tID:${sample_id}\\tLB:lib1\\tPL:ILLUMINA\\tPU:unit1\\tSM:${sample_id}' \
        H37Rv.fna \
        ${read1} \
        ${read2} \
        | samtools view -b - \
        | samtools sort \
            -@ ${task.cpus} \
            -o ${sample_id}.sorted.bam -

    # Create BAM index
    samtools index \
        -@ ${task.cpus} \
        ${sample_id}.sorted.bam
    """
}