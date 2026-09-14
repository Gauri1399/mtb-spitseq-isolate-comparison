process DOWNLOAD_REFERENCE {

    // Store the reference and BWA index files
    publishDir "${projectDir}/reference", mode: 'copy'

    output:
    path "H37Rv.*"

    script:
    """
    # Download H37Rv reference genome
    wget -O H37Rv.fna.gz "${params.mtb_reference_url}"

    # Decompress reference genome
    gunzip H37Rv.fna.gz

    # Create BWA index files
    bwa index H37Rv.fna
   
    # Create index files for GATK
    samtools faidx H37Rv.fna

    gatk CreateSequenceDictionary -R H37Rv.fna
    """
}