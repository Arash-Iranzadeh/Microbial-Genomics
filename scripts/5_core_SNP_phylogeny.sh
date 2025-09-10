#!/usr/bin/env bash
INPUT_DIR="/data/users/user28/data_analysis"
OUTPUT_DIR="/data/users/${USER}/data_analysis"
REF="/data/TB_H37Rv.fasta"
THREADS=$(nproc)

module load anaconda3/2024.10
conda activate snippy
#https://github.com/tseemann/snippy
mkdir -p ${OUTPUT_DIR}/core_snp_phylogeny
cd ${OUTPUT_DIR}/core_snp_phylogeny
snippy-multi ${INPUT_DIR}/tb_core_snp_input_tab --ref ${REF} \
--cpus ${THREADS}  > tb_core_snp_running.sh
bash tb_core_snp_running.sh


#remove all the "weird" characters and replace them with N, useful for tree-building or recombination-removal tool

% snippy-clean_full_aln core.full.aln > clean.full.aln
% run_gubbins.py -p gubbins clean.full.aln
% snp-sites -c gubbins.filtered_polymorphic_sites.fasta > clean.core.aln
% FastTree -gtr -nt clean.core.aln > clean.core.tree





# bedfile to mask repetitivegenes cause false positives, or masking phage regions
wget https://github.com/tseemann/snippy/blob/master/etc/Mtb_NC_000962.3_mask.bed
