nextflow.enable.dsl=2

workflow {

    // Find and pair the isolate FASTQ files
    // Expected format:
    // Isolate_1_R_1.fastq.gz
    // Isolate_1_R_2.fastq.gz
    
    reads = Channel.fromFilePairs(
        "${params.isolate_input}/*_R_{1,2}.fastq.gz",
        flat: true
    )

    // Display the samples detected
    reads.view()
}
