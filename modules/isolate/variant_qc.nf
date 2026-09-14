process VARIANT_QC {

    tag "$sample_id"

    input:
    tuple val(sample_id), path(vcf), path(vcf_tbi)

    output:
    tuple val(sample_id), path("${sample_id}_freq.frq"), path("${sample_id}_depth.idepth")

    script:
    """
    vcftools \
        --gzvcf ${vcf} \
        --freq \
        --out ${sample_id}_freq

    vcftools \
        --gzvcf ${vcf} \
        --depth \
        --out ${sample_id}_depth

    awk -v sample="${sample_id}" \
        'BEGIN {FS="\\t"; OFS="\\t"}
        NR==1 {print "Sample", \$0; next}
        {print sample, \$0}' \
        ${sample_id}_freq.frq > ${sample_id}_freq.tmp

    mv ${sample_id}_freq.tmp ${sample_id}_freq.frq

    awk -v sample="${sample_id}" \
        'BEGIN {FS="\\t"; OFS="\\t"}
        NR==1 {print "Sample", \$0; next}
        {print sample, \$0}' \
        ${sample_id}_depth.idepth > ${sample_id}_depth.tmp

    mv ${sample_id}_depth.tmp ${sample_id}_depth.idepth
    """
}