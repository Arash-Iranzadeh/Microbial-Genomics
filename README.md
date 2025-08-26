# Microbial Genomics Workshop Materials

This repository contains teaching materials for the **Microbial Genomics and Metagenomics for Clinical and Public Health Applications** workshop (UCT, Sept 2025).

## Structure
- `data/` – metadata and download scripts (TB and VC datasets)
- `scripts/` – pipelines for each session
- `results/` – representative outputs (FastQC, MultiQC, Kraken2, ...)
- `docs/` – teaching materials

### Clone repository:
- git clone https://github.com/Arash-Iranzadeh/Microbial-Genomics.git

### Download data:
 - `cd Microbial-Genomics/`
 - `cd path/to/Microbial-Genomics/data/tb/metadata/`; `./tb_download.sh`
 - `cd path/to/Microbial-Genomics/data/vc/metadata/`; `./vc_download.sh`
 - The raw data in FASTQ format will be downloaded and saved under Microbial-Genomics/data/tb or vc/raw_data/ .
   
### Quality control (QC) and data cleaning:
#### Running Fastqc and Multiqc on raw data:
 - `mkdir -p results/qc_raw/tb`
 - `mkdir -p results/qc_raw/vc`
 - `fastqc -t 32 -o ./results/qc_raw/tb/ ./data/tb/raw_data/*_1.fastq.gz ./data/tb/raw_data/*_2.fastq.gz`
 - `fastqc -t 32 -o ./results/qc_raw/vc/ ./data/vc/raw_data/*_1.fastq.gz ./data/vc/raw_data/*_2.fastq.gz`
 - `multiqc ./results/qc_raw/tb -n tb_multiqc_raw.html -o ./results/qc_raw/tb`
 - `multiqc ./results/qc_raw/vc -n vc_multiqc_raw.html -o ./results/qc_raw/vc`
