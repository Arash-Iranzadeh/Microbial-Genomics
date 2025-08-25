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

After downloading samples, the directory structure will include raw data as follows:

Microbial-Genomics
├── LICENSE
├── README.md
├── data
│   ├── tb
│   │   ├── metadata
│   │   │   ├── IDs
│   │   │   ├── tb_all.xlsx
│   │   │   ├── tb_download.sh
│   │   │   ├── tb_download_link
│   │   │   └── tb_metadata.tsv
│   │   └── raw_data
│   │       ├── ERR036221_1.fastq.gz
│   │       ├── ERR036221_2.fastq.gz
│   │       ├── ERR036223_1.fastq.gz
│   │       ├── ERR036223_2.fastq.gz
│   │       ├── ERR036226_1.fastq.gz
│   │       ├── ERR036226_2.fastq.gz
│   │       ├── ERR036227_1.fastq.gz
│   │       ├── ERR036227_2.fastq.gz
│   │       ├── ERR036232_1.fastq.gz
│   │       ├── ERR036232_2.fastq.gz
│   │       ├── ERR036234_1.fastq.gz
│   │       ├── ERR036234_2.fastq.gz
│   │       ├── ERR036249_1.fastq.gz
│   │       ├── ERR036249_2.fastq.gz
│   │       ├── ERR10112845_1.fastq.gz
│   │       ├── ERR10112845_2.fastq.gz
│   │       ├── ERR10112846_1.fastq.gz
│   │       ├── ERR10112846_2.fastq.gz
│   │       ├── ERR10112851_1.fastq.gz
│   │       ├── ERR10112851_2.fastq.gz
│   │       ├── ERR10112852_1.fastq.gz
│   │       ├── ERR10112852_2.fastq.gz
│   │       ├── ERR10112854_1.fastq.gz
│   │       ├── ERR10112854_2.fastq.gz
│   │       ├── ERR10112855_1.fastq.gz
│   │       ├── ERR10112855_2.fastq.gz
│   │       ├── ERR10112903_1.fastq.gz
│   │       ├── ERR10112903_2.fastq.gz
│   │       ├── ERR10225374_1.fastq.gz
│   │       ├── ERR10225374_2.fastq.gz
│   │       ├── ERR10225387_1.fastq.gz
│   │       ├── ERR10225387_2.fastq.gz
│   │       ├── ERR10225388_1.fastq.gz
│   │       ├── ERR10225388_2.fastq.gz
│   │       ├── ERR10225402_1.fastq.gz
│   │       ├── ERR10225402_2.fastq.gz
│   │       ├── ERR10225409_1.fastq.gz
│   │       ├── ERR10225409_2.fastq.gz
│   │       ├── ERR10225413_1.fastq.gz
│   │       ├── ERR10225413_2.fastq.gz
│   │       └── README.md
│   └── vc
│       ├── SRR25120478_2.fastq.gz
│       ├── metadata
│       │   ├── IDs
│       │   ├── vc_all.xlsx
│       │   ├── vc_download.sh
│       │   ├── vc_download_link
│       │   └── vc_metadata.tsv
│       └── raw_data
│           ├── ERR1485273_1.fastq.gz
│           ├── ERR1485273_2.fastq.gz
│           ├── ERR1485279_1.fastq.gz
│           ├── ERR1485279_2.fastq.gz
│           ├── ERR1485281_1.fastq.gz
│           ├── ERR1485281_2.fastq.gz
│           ├── ERR1485283_1.fastq.gz
│           ├── ERR1485283_2.fastq.gz
│           ├── ERR1485285_1.fastq.gz
│           ├── ERR1485285_2.fastq.gz
│           ├── ERR1485287_1.fastq.gz
│           ├── ERR1485287_2.fastq.gz
│           ├── ERR1485334_1.fastq.gz
│           ├── ERR1485334_2.fastq.gz
│           ├── README.md
│           ├── SRR25120478_1.fastq.gz
│           ├── SRR25120478_2.fastq.gz
│           ├── SRR25120500_1.fastq.gz
│           ├── SRR25120500_2.fastq.gz
│           ├── SRR25120511_1.fastq.gz
│           ├── SRR25120511_2.fastq.gz
│           ├── SRR25120533_1.fastq.gz
│           ├── SRR25120533_2.fastq.gz
│           ├── SRR25120555_1.fastq.gz
│           ├── SRR25120555_2.fastq.gz
│           ├── SRR25120563_1.fastq.gz
│           ├── SRR25120563_2.fastq.gz
│           ├── SRR25120565_1.fastq.gz
│           ├── SRR25120565_2.fastq.gz
│           ├── SRR32625472_1.fastq.gz
│           ├── SRR32625472_2.fastq.gz
│           ├── SRR32625473_1.fastq.gz
│           ├── SRR32625473_2.fastq.gz
│           ├── SRR32625480_1.fastq.gz
│           ├── SRR32625480_2.fastq.gz
│           ├── SRR32625491_1.fastq.gz
│           ├── SRR32625491_2.fastq.gz
│           ├── SRR32625492_1.fastq.gz
│           ├── SRR32625492_2.fastq.gz
│           ├── SRR32625525_1.fastq.gz
│           ├── SRR32625525_2.fastq.gz
│           └── temp
├── docs
│   ├── LICENSE-CC-BY-4.0.txt
│   ├── images
│   │   └── TB_cholera_image.png
│   └── tutorials
│       └── qc_cleaning_speciesID.md
├── results
│   ├── fastqc_reports
│   ├── kraken2_reports
│   └── multiqc_reports
└── scripts
    ├── prepare_tb.sh
    ├── prepare_vc.sh
    ├── prepare_workshop_datasets.sh
    └── qc_species_identification.sh







