nextflow.enable.dsl=2

workflow {
    reads = Channel.fromFilePairs(
        "${params.isolate_input}/*_R_{1,2}.fastq.gz",
        flat: true
    )
    reads.view()
}
