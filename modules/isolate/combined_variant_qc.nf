process COMBINE_VARIANT_QC {

    tag "$branch"

    publishDir path:"${params.outdir}/isolate/variants/isolate_vcfqc_results/${branch}", mode: 'copy'

    input:
    val branch
    path freq_files
    path depth_files

    output:
    path "all_samples_frequency.xlsx"
    path "all_samples_depth.xlsx"

    script:
    """
    echo "Frequency files:"
    ls *_freq.frq

    echo "Depth files:"
    ls *_depth.idepth

    python3 - <<'PY'

    import pandas as pd
    import glob
    import os

    # Combine frequency files
    freq_files = sorted(glob.glob("*_freq.frq"))

    freq_tables = []

    for f in freq_files:

        sample = os.path.basename(f).replace("_freq.frq", "")

        print("Processing frequency:", f, "->", sample)

        df = pd.read_csv(
            f,
            sep="\\t",
            dtype=str
        )

        df = df.drop(columns=["Sample"], errors="ignore")
        df.insert(0, "Sample", sample)

        freq_tables.append(df)

    frequency_combined = pd.concat(
        freq_tables,
        ignore_index=True,
        sort=False
    )

    frequency_combined.to_excel(
        "all_samples_frequency.xlsx",
        index=False
    )


    # Combine depth files
    depth_files = sorted(glob.glob("*_depth.idepth"))

    depth_tables = []

    for f in depth_files:

        sample = os.path.basename(f).replace("_depth.idepth", "")

        print("Processing depth:", f, "->", sample)

        df = pd.read_csv(
            f,
            sep="\\t"
        )

        df = df.drop(
            columns=["Sample", "INDV"],
            errors="ignore"
        )

        df.insert(0, "Sample", sample)

        depth_tables.append(df)

    depth_combined = pd.concat(
        depth_tables,
        ignore_index=True
    )

    depth_combined.to_excel(
        "all_samples_depth.xlsx",
        index=False
    )

    print("Frequency samples:")
    print(frequency_combined["Sample"].unique())

    print("Depth samples:")
    print(depth_combined["Sample"].unique())

    PY
    """
}