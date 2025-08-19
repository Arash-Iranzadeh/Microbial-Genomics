# Microbial Genomics (workshop utilities)

Private repo for preparing training datasets for the “Microbial Genomics and Metagenomics for Clinical and Public Health Applications” workshop (UCT, 1–12 Sep 2025).

## Contents
- `scripts/prepare_workshop_datasets.sh` — orchestrator to fetch:
  - 20 *M. tuberculosis* (DS/MDR/pre-XDR/XDR, balanced) from CRyPTIC/ENA
  - 20 *Vibrio cholerae* (10 clinical + 10 environmental) from ENA
  - optional downsampling to ~30×

## Usage (for collaborators)
```bash
git clone git@github.com:Arash-Iranzadeh/microbial_genomics.git
cd microbial_genomics/scripts
./prepare_workshop_datasets.sh
./prepare_workshop_datasets.sh --downsample
