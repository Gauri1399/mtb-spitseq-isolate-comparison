process VARIANT_CALLING {

    tag "$sample_id"

    publishDir { output_dir }, mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path reference
    val output_dir

    output:
    tuple val(sample_id), path("${sample_id}_filtered.vcf.gz"), path("${sample_id}_filtered.vcf.gz.tbi")

    script:
    """
    gatk HaplotypeCaller \
        -R H37Rv.fna \
        -I ${bam} \
        -O ${sample_id}_raw.vcf.gz \
        --sample-ploidy 1

    gatk VariantFiltration \
        -V ${sample_id}_raw.vcf.gz \
        -O ${sample_id}_filtered.vcf.gz \
        --filter-name "LowQual" \
        --filter-expression "QUAL < 20.0 || DP < 10"

    gatk IndexFeatureFile \
        -I ${sample_id}_filtered.vcf.gz
    """
}