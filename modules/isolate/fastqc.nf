process FASTQC_RAW {

    tag "$sample_id"

    input:
    tuple val(sample_id), path(reads)

    output:
    path "*.html"
    path "*.zip"

    script:
    """
    fastqc \
        -o . \
        ${reads[0]} \
        ${reads[1]}
    """
}
