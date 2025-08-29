# Microbial Genomics
## University of Cape Town 1 – 12 September 2025

This repository contains teaching materials for the **Microbial Genomics** workshop.

## Structure
- `data/` – metadata and download scripts (TB and VC datasets).
- `scripts/` – pipelines for each session.
- `results/` – representative outputs.
- `docs/` – teaching materials.

**Note:** Raw FASTQ files and large results are not stored in this repository. Place your sequencing data into data/tb/raw_data/ or data/vc/raw_data/, or store it locally and update the paths in scripts accordingly.

### Clone repository:
- git clone https://github.com/Arash-Iranzadeh/Microbial-Genomics.git

### Download data:
 - `cd Microbial-Genomics/`
 - `cd path/to/Microbial-Genomics/data/tb/metadata/`; `./tb_download.sh`
 - `cd path/to/Microbial-Genomics/data/vc/metadata/`; `./vc_download.sh`
 - The raw data in FASTQ format will be downloaded and saved under Microbial-Genomics/data/tb or vc/raw_data/
