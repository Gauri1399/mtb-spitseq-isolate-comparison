process TBPROFILER {

    tag "$sample_id"

    publishDir "${params.outdir}/isolate/tbprofiler", mode: 'copy'

    input:
    tuple val(sample_id), path(r1), path(r2)

    output:
    path "results/${sample_id}*"

    script:
    """
    tb-profiler profile -1 ${r1} -2 ${r2} --prefix ${sample_id} --threads 16 --no_delly
    """
}