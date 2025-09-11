#!/usr/bin/env bash
INPUT_DIR="/data/users/${USER}/data_analysis"
OUTPUT_DIR="/data/users/${USER}/data_analysis"
# TB REF: https://www.ncbi.nlm.nih.gov/nuccore/NC_000962.3?report=fasta
REF="${INPUT_DIR}/TB_H37Rv.fasta"
THREADS=$(nproc)

module load anaconda3/2024.10
conda activate snippy
#https://github.com/tseemann/snippy
mkdir -p ${OUTPUT_DIR}/core_snp_phylogeny
cd ${OUTPUT_DIR}/core_snp_phylogeny
snippy-multi ${INPUT_DIR}/tb_core_snp_input_tab --ref ${REF} \
--cpus ${THREADS}  > tb_core_snp_running.sh

# bedfile to mask repetitivegenes cause false positives, or masking phage regions
#download from here: 
#https://github.com/tseemann/snippy/blob/master/etc/Mtb_NC_000962.3_mask.bed
# open tb_core_snp_running.sh and after "snp-core" in the last line:
# add this "--mask ${INPUT_DIR}/Mtb_NC_000962.3_mask.bed"

bash tb_core_snp_running.sh

#remove all the "weird" characters and replace them with N, useful for tree-building or recombination-removal tool

snippy-clean_full_aln core.full.aln > clean.full.aln

conda activate gubbins
run_gubbins.py -p gubbins -c ${THREADS} clean.full.aln

conda activate snippy
snp-sites -c gubbins.filtered_polymorphic_sites.fasta > clean.core.aln
fasttree -gtr -nt clean.core.aln > clean.core.tree





