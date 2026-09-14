process FASTQC {

    tag "$sample_id"

    publishDir { output_dir }, mode: 'copy'

    input:
    tuple val(sample_id), path(read1), path(read2)
    val output_dir

    output:
    path "*.html"
    path "*.zip"

    script:
    """
    fastqc \
        -o . \
        ${read1} \
        ${read2}
    """
}