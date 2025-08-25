# Microbial Genomics Workshop Materials

This repository contains teaching materials for the **Microbial Genomics and Metagenomics for Clinical and Public Health Applications** workshop (UCT, Sept 2025).

## Structure
- `data/` – metadata and download scripts (TB and VC datasets)
- `scripts/` – pipelines for each session
- `results/` – representative outputs (FastQC, MultiQC, Kraken2)
- `docs/` – slides, tutorials, and images

### Clone repository:
- git clone https://github.com/Arash-Iranzadeh/Microbial-Genomics.git

### Download data:
 - cd Microbial-Genomics/
 - cd path/to/Microbial-Genomics/data/tb/metadata/; ./tb_download.sh
 - cd path/to/Microbial-Genomics/data/vc/metadata/; ./vc_download.sh
   After downloading samples, the directory will include raw data in fastq format.

### Quality control (QC) and data cleaning:
