process TBPROFILER_COLLATE {

    publishDir "${params.outdir}/isolate/tbprofiler", mode: 'copy'

    input:
    path results

    output:
    path "tbprofiler*"

    script:
    """
    mkdir -p collate_results

    cp ${results} collate_results/

    # Create sample list sorted by isolate number
    for f in collate_results/*.results.json; do
        basename "\$f" .results.json
    done | sort -t_ -k2,2n > samples.txt

    tb-profiler collate \
        --dir collate_results \
        --samples samples.txt \
        --format csv \
        --prefix tbprofiler

    tb-profiler collate \
        --dir collate_results \
        --samples samples.txt \
        --format txt \
        --prefix tbprofiler
    """
}