````markdown
# MTB SPIT-SEQ vs. Conventional Isolate WGS

## Overview

This project develops a reproducible Nextflow pipeline for analyzing *Mycobacterium tuberculosis* (MTB) whole-genome sequencing data from cultured isolates and evaluating genomic variation relevant to drug resistance.

The broader goal is to compare **conventional whole-genome sequencing (WGS) of cultured MTB isolates** with **SPIT-SEQ, a culture-free sequencing approach performed directly from sputum**, to determine whether direct-from-sputum sequencing can provide comparable information about resistance-associated mutations.

The current pipeline focuses on the conventional isolate WGS workflow and establishes the genomic and drug-resistance profiles that will serve as the reference for comparison with SPIT-SEQ data.

---

## Project Question

**Can direct-from-sputum SPIT-SEQ identify drug-resistance-associated mutations comparable to those detected through conventional WGS of cultured MTB isolates?**

The comparison will evaluate:

- Shared resistance-associated mutations
- Isolate-specific and sample-specific variants
- Fixed and mixed variants
- Mutations associated with first-, second-, and third-line drugs
- Concordance between SPIT-SEQ and conventional isolate WGS

---

## Workflow

The isolate WGS pipeline follows this workflow:

```text
Raw FASTQ files
      │
      ▼
   FastQC
      │
      ▼
 Trimmomatic
      │
      ▼
   FastQC
      │
      ▼
Alignment to H37Rv
      │
      ▼
Read Group Assignment
      │
      ▼
Mark PCR Duplicates
      │
      ├───────────────┐
      ▼               ▼
Marked BAM       Remove Duplicates
      │               │
      ▼               ▼
Variant Calling  Variant Calling
      │               │
      ▼               ▼
Variant QC       Variant QC
      │               │
      └───────┬───────┘
              ▼
     SNP / Variant Analysis
              │
              ▼
        TB-Profiler
              │
              ▼
     Drug-Resistance Profile
````

---

## Pipeline Steps

### 1. Raw Read Quality Control

**FastQC** is used to evaluate the quality of the raw sequencing reads before processing.

Quality metrics are inspected to identify potential sequencing or read-quality issues before downstream analysis.

### 2. Adapter and Quality Trimming

**Trimmomatic** is used to remove sequencing adapters and low-quality bases from the raw reads.

A second FastQC step is performed after trimming to assess the quality of the processed reads.

### 3. Reference Genome

Reads are aligned against the *M. tuberculosis* H37Rv reference genome.

The pipeline can download and index the reference genome when required.

### 4. Read Alignment

Trimmed paired-end reads are aligned to H37Rv using **BWA-MEM**.

The resulting alignments are sorted and indexed to produce BAM files for downstream analysis.

### 5. PCR Duplicate Processing

PCR duplicates are identified using **GATK MarkDuplicates**.

Two analysis branches are maintained:

* **Marked branch:** duplicates remain in the BAM but are flagged.
* **Deduplicated branch:** duplicate reads are removed before variant calling.

Maintaining both branches allows downstream variant results and QC metrics to be compared.

### 6. Variant Calling

Variants are identified using **GATK HaplotypeCaller** with a haploid configuration appropriate for MTB.

Variants are subsequently filtered based on quality and sequencing depth.

Current filtering criteria include:

* `QUAL >= 20`
* `DP >= 10`

### 7. Variant QC

Variant-level and sample-level QC metrics are collected, including:

* Number of variants/SNPs
* Allele frequency
* Sequencing depth

These metrics are used to assess the quality and consistency of variant calls across isolates.

### 8. Drug-Resistance Profiling

**TB-Profiler** is used to identify mutations associated with MTB drug resistance.

The VCF provides the overall set of variants detected relative to the H37Rv reference genome, while TB-Profiler interprets variants using a curated MTB drug-resistance knowledge base.

Therefore:

> The total number of SNPs detected in the VCF is not equivalent to the number of drug-resistance-associated mutations reported by TB-Profiler.

### 9. Visualization

R scripts in `Plots/` are used to summarize genomic variation and resistance-associated mutations across isolates.

Current figures include:

| Script                       | Description                         |
| ---------------------------- | ----------------------------------- |
| `Fig1_SNPs_per_Isolate.R`    | SNP counts across isolates          |
| `Fig2_Mutation_Categories.R` | Mutation categories                 |
| `Fig3_Drug_Resistance.R`     | Resistance-associated mutations     |
| `Fig4_Resistance_Profile.R`  | Resistance profiles across isolates |

---

## Repository Structure

```text
mtb-spitseq-isolate-comparison/
│
├── main.nf
├── nextflow.config
├── environment.yml
│
├── config/
│   ├── hpc.config
│   └── paths.config
│
├── modules/
│   ├── isolate/
│   │   ├── bwa.nf
│   │   ├── combined_variant_qc.nf
│   │   ├── dedup_reads.nf
│   │   ├── download_ref.nf
│   │   ├── fastqc.nf
│   │   ├── mark_duplicates_reads.nf
│   │   ├── tbprofiler.nf
│   │   ├── tbprofiler_collate.nf
│   │   ├── trimming.nf
│   │   ├── variant_calling.nf
│   │   └── variant_qc.nf
│   │
│   └── icmr/
│
├── data/
│   └── Input sequencing data
│
└── Plots/
    ├── Fig1_SNPs_per_Isolate.R
    ├── Fig2_Mutation_Categories.R
    ├── Fig3_Drug_Resistance.R
    └── Fig4_Resistance_Profile.R
```

---

## Software

The pipeline uses:

| Tool            | Purpose                               |
| --------------- | ------------------------------------- |
| **Nextflow**    | Workflow orchestration                |
| **FastQC**      | Sequencing read QC                    |
| **Trimmomatic** | Adapter and quality trimming          |
| **BWA-MEM**     | Read alignment                        |
| **Samtools**    | BAM processing and QC                 |
| **GATK**        | Duplicate marking and variant calling |
| **BCFtools**    | Variant processing                    |
| **SnpEff**      | Variant annotation                    |
| **TB-Profiler** | MTB drug-resistance profiling         |
| **R**           | Visualization and downstream analysis |

The computational environment is documented in `environment.yml`.

---

## Running the Pipeline

### Requirements

Install:

* Nextflow
* Java
* Conda or Mamba

### Clone the repository

```bash
git clone https://github.com/Gauri1399/mtb-spitseq-isolate-comparison.git
cd mtb-spitseq-isolate-comparison
```

### Create the environment

```bash
conda env create -f environment.yml
conda activate mtb-pipeline
```

### Run the pipeline using the default configuration

```bash
nextflow run main.nf
```

### Run on HPC

```bash
nextflow run main.nf -c config/hpc.config
```

Paths and environment-specific settings are maintained separately in the `config/` directory.

---

## Input Data

The pipeline expects paired-end sequencing reads for MTB isolates.

Example:

```text
data/
└── isolate/
    ├── Isolate_1_R1.fastq.gz
    ├── Isolate_1_R2.fastq.gz
    ├── Isolate_2_R1.fastq.gz
    └── Isolate_2_R2.fastq.gz
```

Input file locations are configured through the project configuration files.

---

## Outputs

The pipeline generates intermediate and final outputs for:

* Read quality control
* Trimmed reads
* Aligned BAM files
* Duplicate-marked and deduplicated BAM files
* Variant calls
* Variant QC metrics
* TB-Profiler resistance profiles
* Combined analysis tables

Generated sequencing files should be kept outside version control when they contain large or sensitive research datasets.

---

## Variant Interpretation

Variant calls are reported relative to the H37Rv reference genome.

A detected SNP indicates that the sequenced isolate differs from the reference at that genomic position. **Not every SNP is associated with drug resistance.**

For resistance analysis, variants are interpreted using TB-Profiler and its curated resistance annotations.

### Fixed vs. Mixed Variants

The pipeline also considers allele frequency when evaluating variants.

* **Fixed variants:** the alternate allele is supported by approximately all reads at the position.
* **Mixed variants:** both reference and alternate alleles are detected at appreciable frequencies, which may indicate a mixed bacterial population or heteroresistance.

Mixed variants are particularly relevant when comparing SPIT-SEQ with conventional isolate WGS because differences in variant detection may affect resistance-profile concordance.

---

## Planned SPIT-SEQ Comparison

The next stage of the project will process SPIT-SEQ data using a comparable variant-analysis workflow.

The comparison will evaluate:

```text
Conventional Isolate WGS
          │
          ├── Resistance-associated mutations
          │
          ├── Fixed variants
          │
          └── Mixed variants
                    │
                    ▼
             Compare with
                    │
                    ▼
              SPIT-SEQ
```

The analysis will classify variants as:

* Shared between methods
* Detected only by isolate WGS
* Detected only by SPIT-SEQ
* Fixed or mixed
* Resistance-associated or non-resistance-associated

The overall objective is to determine whether **culture-free SPIT-SEQ can reliably capture resistance-associated mutations identified by conventional WGS of cultured MTB isolates.**

---

## Reproducibility

The workflow is implemented in **Nextflow DSL2** to provide a modular and reproducible analysis framework.

The repository separates:

* Workflow orchestration
* Individual analysis modules
* Configuration
* Computational environments
* Visualization scripts

This structure allows the pipeline to be run across local and HPC environments with environment-specific configuration files.

---

## Data and Privacy

Raw sequencing data, BAM files, VCF files, reference genome files, and other large or potentially sensitive research data are not intended to be committed to this public repository.

Only pipeline code, configuration, documentation, and appropriate non-sensitive example outputs should be version controlled.

---

## Project Status

**Current stage:** Conventional MTB isolate WGS pipeline and resistance profiling

### Completed

* [x] Raw read QC
* [x] Adapter/quality trimming
* [x] H37Rv alignment
* [x] Read group assignment
* [x] Duplicate marking/removal
* [x] Variant calling
* [x] Variant QC
* [x] TB-Profiler resistance profiling
* [x] SNP visualization
* [x] Resistance-associated mutation visualization

### Next Steps

* [ ] Process SPIT-SEQ samples
* [ ] Compare SPIT-SEQ and isolate WGS variants
* [ ] Evaluate fixed and mixed variants
* [ ] Compare resistance-associated mutations
* [ ] Identify shared, missed, and unique variants
* [ ] Quantify concordance between sequencing approaches

---

## Author

**Gauri Agrawal**

MS Bioinformatics, Johns Hopkins University

[GitHub](https://github.com/Gauri1399)

```
