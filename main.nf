nextflow.enable.dsl=2

// Perform FastQC for raw files
include { FASTQC as FASTQC_RAW } from './modules/isolate/fastqc.nf'
include { FASTQC as FASTQC_TRIMMED } from './modules/isolate/fastqc.nf'

// Perform adapter and quality trimming
include { TRIMMOMATIC } from './modules/isolate/trimming.nf'

// Install reference file
include { DOWNLOAD_REFERENCE } from './modules/isolate/download_ref.nf'

// Perform BWA alignment, bam sorting and indexing
include { BWA_MEM } from './modules/isolate/bwa.nf'

// Mark the reads using GATK
include { MARK_DUPLICATES } from './modules/isolate/mark_duplicates_reads.nf'

// Remove duplicate reads using GATK
include { DEDUPLICATE } from './modules/isolate/dedup_reads.nf'

// Variant calling and filtering
include { VARIANT_CALLING as VC_MARKED } from './modules/isolate/variant_calling.nf'
include { VARIANT_CALLING as VC_DEDUP } from './modules/isolate/variant_calling.nf'

// Variant QC 
include { VARIANT_QC as QC_MARKED } from './modules/isolate/variant_qc.nf'
include { VARIANT_QC as QC_DEDUP } from './modules/isolate/variant_qc.nf'

// Combine the variant QC
include { COMBINE_VARIANT_QC as COMBINE_MARKED } from './modules/isolate/combined_variant_qc.nf'
include { COMBINE_VARIANT_QC as COMBINE_DEDUP } from './modules/isolate/combined_variant_qc.nf'

// Run TBprofiler
include { TBPROFILER } from './modules/isolate/tbprofiler.nf'

// Generate summary of tbprofiler results
include { TBPROFILER_COLLATE } from './modules/isolate/tbprofiler_collate.nf'

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

    // Run FastQC on raw FASTQ files
    FASTQC_RAW(reads,"${params.outdir}/isolate/fastqc/raw")

    // Load the adapter sequence file
    adapters = Channel.value(params.adapters_url)

    // Trim adapters and low-quality bases
    trimmed_reads = TRIMMOMATIC(reads, adapters)

    // Run FastQC on trimmed reads
    //FASTQC_TRIMMED(trimmed_reads, "${params.outdir}/isolate/fastqc/trimmed")

    // Download the H37Rv reference genome
    DOWNLOAD_REFERENCE()

    // Align trimmed reads and create sorted, indexed BAM files
    BWA_MEM(trimmed_reads, DOWNLOAD_REFERENCE.out)

    // Mark duplicates
    MARK_DUPLICATES(BWA_MEM.out)

    // Remove duplicates
    DEDUPLICATE(BWA_MEM.out)

    // Call variants using BAM files with duplicates marked 
    VC_MARKED(
        MARK_DUPLICATES.out,
        DOWNLOAD_REFERENCE.out,
        "${params.outdir}/isolate/variants/marked"
    )

    // Call variants using deduplicated BAM files 
    VC_DEDUP(
        DEDUPLICATE.out,
        DOWNLOAD_REFERENCE.out,
        "${params.outdir}/isolate/variants/dedup"
    )
    
    // Calculate variant quality metrics for the marked-duplicate results
    QC_MARKED(VC_MARKED.out)
    
    // Calculate variant quality metrics for the deduplicated results
    QC_DEDUP(VC_DEDUP.out)

    // Extract allele frequencies and sequencing depth from marked-variant QC
    marked_freq = QC_MARKED.out.map { sample_id, freq, depth -> freq }
    marked_depth = QC_MARKED.out.map { sample_id, freq, depth -> depth }

    // Extract allele frequencies and sequencing depth from deduplicated QC
    dedup_freq = QC_DEDUP.out.map { sample_id, freq, depth -> freq }
    dedup_depth = QC_DEDUP.out.map { sample_id, freq, depth -> depth }

    // Combine QC metrics across isolates for comparison of variants
    COMBINE_MARKED('marked', marked_freq.collect(), marked_depth.collect())
    COMBINE_DEDUP('dedup', dedup_freq.collect(), dedup_depth.collect())

    // Profile drug-resistance-associated mutations using TB-Profiler
    tbprofiler_results = TBPROFILER(trimmed_reads)

    // Combine TB-Profiler results across all isolates for downstream comparison
    TBPROFILER_COLLATE(tbprofiler_results.collect())

}
