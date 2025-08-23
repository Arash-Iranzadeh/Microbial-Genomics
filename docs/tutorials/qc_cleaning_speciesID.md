# QC, Cleaning & Species Identification (Workshop)

This tutorial walks through:
1) FastQC on raw reads
2) Trimming with Trimmomatic (or fastp)
3) FastQC + MultiQC after trimming
4) Kraken2 species identification

## Quickstart
```bash
export DATA_ROOT=/scratch3/users/arash       # where your workshop/tb|vc/raw_data live
export KRAKEN_DB=/path/to/kraken2_db         # set to your DB
bash scripts/qc_species_id.sh
