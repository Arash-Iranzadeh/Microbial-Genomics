#!/usr/bin/env bash
# On personal computer
conda create -n panaroo python=3.9
conda activate panaroo
conda install -n panaroo -c bioconda -c conda-forge panaroo
# on cluster
module spider conda ==>  anaconda3/2024.10
module load anaconda3/2024.10
conda activate 
conda create -n panaroo -c bioconda -c conda-forge panaroo

# copy the gff files resulted from annotation into the INPUT_DIR
INPUT_DIR="/data/users/${USER}/data_analysis/vc_pangenome/gff"
OUTPUT_DIR="/data/users/${USER}/data_analysis/vc_pangenome"
mkdir -p ${INPUT_DIR}  ${OUTPUT_DIR}/QC

module load panaroo/1.5.0

# performing some rudimentary quality checks on the input data prior to running Panaroo using mash datbase
wget https://gembox.cbcb.umd.edu/mash/refseq.genomes.k21s1000.msh
panaroo-qc -t $(nproc) --graph_type all -i ${INPUT_DIR}/*.gff \
 --ref_db refseq.genomes.k21s1000.msh -o ${OUTPUT_DIR}/QC
# running panaroo and creating a pangenome

panaroo -i ${INPUT_DIR}/*.gff -o ${OUTPUT_DIR} --clean-mode st
rict -a core -a pan --core_threshold 1 --quiet -t $(nproc)

# to understand outputs: https://gthlab.au/panaroo/#/gettingstarted/output

# post-processing
cd $OUTPUT_DIR
# filtering gene presence/absence file
panaroo-filter-pa -i ./gene_presence_absence.csv -o . --type pseudo,length
# phylogenetic tree construction
iqtree2 -s core_gene_alignment.aln -pre core_tree -nt 8 -fast -m GTR




 

 
