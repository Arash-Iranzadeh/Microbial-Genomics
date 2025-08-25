# Microbial Genomics Workshop Materials

This repository contains teaching materials for the **Microbial Genomics and Metagenomics for Clinical and Public Health Applications** workshop (UCT, Sept 2025).

## Structure
- `data/` – metadata and download scripts (TB and VC datasets)
- `scripts/` – pipelines for each session
- `results/` – representative outputs (FastQC, MultiQC, Kraken2, ...)
- `docs/` – slides, tutorials, and images

### Clone repository:
- git clone https://github.com/Arash-Iranzadeh/Microbial-Genomics.git

### Download data:
 - `cd Microbial-Genomics/`
 - `cd path/to/Microbial-Genomics/data/tb/metadata/`; `./tb_download.sh`
 - `cd path/to/Microbial-Genomics/data/vc/metadata/`; `./vc_download.sh`
 - The raw data in FASTQ format will be downloaded and saved under Microbial-Genomics/data/<tb or vc>/raw_data/ .
   
### Quality control (QC) and data cleaning:
 - On slurm cluster request the computing resources: `srun --cpus-per-task=32 --mem=240GB  --pty bash`
 - `mkdir -p results/fastqc/raw/tb`
 - `mkdir -p results/fastqc/raw/vc`
 - `module load fastqc`
 - `fastqc -t 32 -o ./results/fastqc/raw/tb/ ./data/tb/raw_data/*_1.fastq.gz ./data/tb/raw_data/*_2.fastq.gz`
 - `fastqc -t 32 -o ./results/fastqc/raw/vc/ ./data/vc/raw_data/*_1.fastq.gz ./data/vc/raw_data/*_2.fastq.gz`
