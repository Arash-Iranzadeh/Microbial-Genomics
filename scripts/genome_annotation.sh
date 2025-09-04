#!/usr/bin/bash

# Run the command below before starting the analysis
srun --cpus-per-task=8 --mem=32GB  --pty bash
module load prokka

# List of prokka databases 
prokka  --listdb
 
OUTPUT_DIR="/data/users/user28/data_analysis"
# Defining variable
mkdir -p ${OUTPUT_DIR}/results/prokka_vc results/prokka_tb

for SAMPLE in 
prokka --outdir "prokka/${SAMPLE}" --prefix "$SAMPLE" \
      --genus Mycobacterium --species tuberculosis --kingdom Bacteria "$f"
