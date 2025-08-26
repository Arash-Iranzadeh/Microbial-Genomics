# Microbial Genomics and Metagenomics for Clinical and Public Health Applications
## University of Cape Town · 1 – 12 September 2025

This repository contains teaching materials for the **Microbial Genomics and Metagenomics for Clinical and Public Health Applications** workshop (UCT, Sept 2025)

## Structure
- `data/` – metadata and download scripts (TB and VC datasets).
- `scripts/` – pipelines for each session.
- `results/` – representative outputs.
- `docs/` – teaching materials.

### Clone repository:
- git clone https://github.com/Arash-Iranzadeh/Microbial-Genomics.git

### Download data:
 - `cd Microbial-Genomics/`
 - `cd path/to/Microbial-Genomics/data/tb/metadata/`; `./tb_download.sh`
 - `cd path/to/Microbial-Genomics/data/vc/metadata/`; `./vc_download.sh`
 - The raw data in FASTQ format will be downloaded and saved under Microbial-Genomics/data/tb or vc/raw_data/ 

## Schedule – Sessions by Arash Iranzadeh

| Date       | Topic                                                                | Duration | Tools / Notes                              |
|------------|----------------------------------------------------------------------|----------|--------------------------------------------|
| **Sep 1**  | Introduction to command line interface (Git Bash)                    | 90 min   | Unix basics                                |
| **Sep 2**  | Quality checking & species identification                            | 60 min   | FastQC, MultiQC, fastp, Kraken2            |
|            | De novo & reference-based assembly, annotation (co-teaching)         | 60 min   | SPAdes, BBMap, Prokka, QUAST               |
|            | Exploring pangenomes and genomic diversity                           | 90 min   | Panaroo                                    |
| **Sep 3**  | Inferring evolutionary relationships from core SNPs                  | 60 min   | Snippy                                     |
|            | Building recombination-free phylogenies                              | 90 min   | Snippy-core, Gubbins, IQ-TREE              |
|            | Phylogenetic tree visualisation                                      | 60 min   | R, iTOL                                    |
| **Sep 4**  | Multi-locus sequence typing and serotyping                           | 60 min   | MLST tools, serotyping workflows           |

ry Layout

