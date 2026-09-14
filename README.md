# MTB SPIT-SEQ vs. Conventional Isolate WGS

## Overview

This project develops a reproducible **Nextflow pipeline** for analyzing *Mycobacterium tuberculosis* (MTB) whole-genome sequencing data from cultured isolates and evaluating genomic variation relevant to drug resistance.

The broader goal is to compare **conventional whole-genome sequencing (WGS) of cultured MTB isolates** with **SPIT-SEQ, a culture-free sequencing approach performed directly from sputum**, to determine whether direct-from-sputum sequencing can provide comparable information about resistance-associated mutations.

The current pipeline focuses on the conventional isolate WGS workflow and establishes the genomic and drug-resistance profiles that will serve as the reference for comparison with SPIT-SEQ data.

The comparison will evaluate:

* Shared resistance-associated mutations
* Isolate-specific variants
* Fixed and mixed variants
* Mutations associated with first-, second-, and third-line drugs
* Concordance between SPIT-SEQ and conventional isolate WGS

---

## Pipeline Workflow

```text
Raw FASTQ
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
BWA-MEM Alignment
    │
    ▼
Read Groups
    │
    ▼
Mark PCR Duplicates
    │
    ├──────────────────────┐
    ▼                      ▼
Marked BAM          Remove Duplicates
    │                      │
    ▼                      ▼
Variant Calling     Deduplicated BAM
    │                      │
    ▼                      ▼
Variant QC          Variant Calling
                           │
    |                      ▼
                       Variant QC
    │                      │
    └──────────┬───────────┘
               ▼
       SNP / Variant Analysis
               │
               ▼
          TB-Profiler
               │
               ▼
     Drug-Resistance Profile
               │
               ▼
     Future: Compare with SPIT-SEQ
```

---

## Pipeline Steps

### 1. Raw Read Quality Control

**FastQC** is used to assess the quality of raw sequencing reads before downstream processing.

This step helps identify sequencing quality issues before trimming and alignment.

### 2. Adapter and Quality Trimming

**Trimmomatic** removes sequencing adapters and low-quality bases from the raw reads.

A second **FastQC** analysis is performed after trimming to confirm improvement or retention of read quality.

### 3. Reference Genome

Reads are aligned against the ***M. tuberculosis* H37Rv reference genome**.

The pipeline includes a module for downloading and indexing the reference genome when required.

### 4. Read Alignment

Trimmed paired-end reads are aligned to H37Rv using **BWA-MEM**.

The resulting alignments are sorted and indexed to produce BAM files for downstream analysis.

### 5. PCR Duplicate Processing

**GATK MarkDuplicates** identifies PCR duplicate reads.

The workflow maintains two branches:

| Branch           | Description                                        |
| ---------------- | -------------------------------------------------- |
| **Marked**       | Duplicate reads remain in the BAM but are flagged  |
| **Deduplicated** | Duplicate reads are removed before variant calling |

This allows variant calls and QC metrics from the two approaches to be compared.

### 6. Variant Calling

Variants are identified using **GATK HaplotypeCaller** with a haploid configuration appropriate for MTB.

Variants are filtered based on sequencing quality and depth.

Current filtering criteria:

```text
QUAL ≥ 20
DP   ≥ 10
```

### 7. Variant Quality Control

Variant and sample-level QC metrics include:

* SNP/variant counts
* Allele frequency
* Sequencing depth

These metrics are used to assess variant quality and consistency across isolates.

### 8. Drug-Resistance Profiling

**TB-Profiler** is used to identify mutations associated with MTB drug resistance.

The VCF contains variants detected relative to the H37Rv reference genome, while TB-Profiler interprets variants using a curated MTB drug-resistance knowledge base.

Therefore, the **total number of SNPs in the VCF is not equivalent to the number of drug-resistance-associated mutations** reported by TB-Profiler.

### 9. Visualization

R scripts in the `Plots/` directory generate visualizations of genomic variation and resistance-associated mutations.

| Script                       | Description                         |
| ----------------------------- | ------------------------------------ |
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
│
└── Plots/
    ├── Fig1_SNPs_per_Isolate.R
    ├── Fig2_Mutation_Categories.R
    ├── Fig3_Drug_Resistance.R
    └── Fig4_Resistance_Profile.R
```

---

## Software

| Tool            | Purpose                               |
| --------------- | -------------------------------------- |
| **Nextflow**    | Workflow orchestration                |
| **FastQC**      | Read quality control                  |
| **Trimmomatic** | Adapter and quality trimming          |
| **BWA-MEM**     | Read alignment                        |
| **Samtools**    | BAM processing and QC                 |
| **GATK**        | Duplicate marking and variant calling |
| **BCFtools**    | Variant processing                    |
| **SnpEff**      | Variant annotation                    |
| **TB-Profiler** | MTB drug-resistance profiling         |
| **R**           | Data analysis and visualization       |

---

## Running the Pipeline

### Requirements

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

### Run locally

```bash
nextflow run main.nf
```

### Run on HPC

```bash
nextflow run main.nf -c config/hpc.config
```

---

## Input Data

The pipeline expects paired-end FASTQ files for MTB isolates.

Example:

```text
data/
└── isolate/
    ├── Isolate_1_R1.fastq.gz
    ├── Isolate_1_R2.fastq.gz
    ├── Isolate_2_R1.fastq.gz
    └── Isolate_2_R2.fastq.gz
```

Input paths are specified through the configuration files in `config/`.

---

## Outputs

The pipeline generates:

* Raw read QC reports
* Trimmed FASTQ files
* Aligned BAM files
* Duplicate-marked BAM files
* Deduplicated BAM files
* Variant calls
* Variant QC metrics
* TB-Profiler resistance profiles
* Combined analysis tables
* Visualization-ready data

---

## Variant Interpretation

Variant calls represent differences between each isolate and the H37Rv reference genome.

A detected SNP **does not necessarily indicate drug resistance**.

Resistance-associated mutations are identified through downstream annotation and TB-Profiler.

### Fixed vs. Mixed Variants

Allele frequency is considered when evaluating variants.

* **Fixed variants:** the alternate allele is supported by approximately all reads at the position.
* **Mixed variants:** both reference and alternate alleles are detected at appreciable frequencies.

Mixed variants may indicate a mixed bacterial population or heteroresistance and are particularly important when comparing sequencing approaches.

---

## SPIT-SEQ Comparison

The next stage of the project will process SPIT-SEQ data using a comparable variant-analysis workflow.

The comparison will evaluate:

| Category                       | Comparison                         |
| ------------------------------- | ------------------------------------ |
| Shared variants                | Detected by both approaches        |
| Isolate WGS-only               | Detected by conventional WGS       |
| SPIT-SEQ-only                  | Detected by SPIT-SEQ               |
| Fixed variants                 | Predominantly one allele           |
| Mixed variants                 | Both alleles detected              |
| Resistance-associated variants | Variants linked to drug resistance |

The overall objective is to determine whether **culture-free SPIT-SEQ can reliably capture resistance-associated mutations identified by conventional WGS of cultured MTB isolates.**

---

## Reproducibility

The workflow is implemented using **Nextflow DSL2** to provide a modular and reproducible analysis framework.

The repository separates:

* Workflow orchestration
* Analysis modules
* Configuration
* Computational environments
* Visualization scripts

Environment-specific settings are maintained separately for local and HPC execution.

---

## Data and Privacy

Raw sequencing data, BAM files, VCF files, reference genome files, and other large or potentially sensitive research data should **not** be committed to the public repository.

The repository is intended to contain:

* Pipeline code
* Configuration files
* Documentation
* Visualization scripts
* Appropriate non-sensitive example outputs

---

## Project Status

### Completed

* [x] Raw read QC
* [x] Adapter and quality trimming
* [x] Post-trimming QC
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
