#!/usr/bin/env bash

OUTPUT_DIR="/data/users/${USER}/data_analysis"

cp -r /data/users/user28/data_analysis/trimmed_trimmomatic/tb ${OUTPUT_DIR}
cp /data/users/user28/data_analysis/TB_H37Rv.fasta ${OUTPUT_DIR}
cp /data/users/user28/data_analysis/Mtb_NC_000962.3_mask.bed ${OUTPUT_DIR}
cp /data/users/user28/data_analysis/tb_problematic ${OUTPUT_DIR}
# TB REF: https://www.ncbi.nlm.nih.gov/nuccore/NC_000962.3?report=fasta
REF="${OUTPUT_DIR}/TB_H37Rv.fasta"
THREADS=$(nproc)

module load anaconda3/2024.10
conda activate snippy
#https://github.com/tseemann/snippy
mkdir -p ${OUTPUT_DIR}/core_snp_phylogeny
cd ${OUTPUT_DIR}/core_snp_phylogeny

for id in $(ls $OUTPUT_DIR/trimmed_trimmomatic/tb/ | cut -f 1 -d '_' | sort | uniq); do 
forward=$(ls "$OUTPUT_DIR/trimmed_trimmomatic/tb/${id}_1.fastq.gz") 
reverse=$(ls "$OUTPUT_DIR/trimmed_trimmomatic/tb/${id}_2.fastq.gz") 
echo -e "${id}\t${forward}\t${reverse}"; done \
 | grep -v -f $OUTPUT_DIR/tb_problematic > tb_core_snp_input_tab

snippy-multi tb_core_snp_input_tab --ref ${REF} \
--cpus ${THREADS}  > tb_core_snp_running.sh

# bedfile to mask repetitive genes cause false positives, or masking phage regions
# download from here: 
# https://github.com/tseemann/snippy/blob/master/etc/Mtb_NC_000962.3_mask.bed
# open tb_core_snp_running.sh and after "snp-core" in the last line:
# add this "--mask ${OUTPUT_DIR}/Mtb_NC_000962.3_mask.bed"

bash tb_core_snp_running.sh

#check the number of variants
module load bcftools
bcftools stats core.vcf | grep ^SN
wc -l core.tab

# on your desktop: 
pip install alv
alv core.aln
# or use it: https://alignmentviewer.org/

#remove all the "weird" characters and replace them with N, useful for tree-building or recombination-removal tool
time snippy-clean_full_aln core.full.aln > clean.full.aln

conda activate gubbins
run_gubbins.py -p gubbins -c ${THREADS} clean.full.aln

conda activate snippy
snp-sites -c gubbins.filtered_polymorphic_sites.fasta > clean.core.aln
fasttree -gtr -nt clean.core.aln > clean.core.tree





