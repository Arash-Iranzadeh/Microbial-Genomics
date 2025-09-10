#!/usr/bin/env bash
# copy the gff files resulted from annotation into the INPUT_DIR/gff_vc
INPUT_DIR="/data/users/user28/data_analysis"
OUTPUT_DIR="/data/users/${USER}/data_analysis"
mkdir -p ${OUTPUT_DIR}/pangenome_vc ${OUTPUT_DIR}/pangenome_vc/QC

# running panaroo for annotation qc and pangenome construction
# we need this file in INPUT_DIR, wget https://gembox.cbcb.umd.edu/mash/refseq.genomes.k21s1000.msh
module load panaroo/1.5.0
# quality checks on the input annotation files
panaroo-qc -t $(nproc) --graph_type all -i ${INPUT_DIR}/gff_vc/*.gff \
 --ref_db ${INPUT_DIR}/refseq.genomes.k21s1000.msh -o ${OUTPUT_DIR}/pangenome_vc/QC
rm ${OUTPUT_DIR}/pangenome_vc/QC/tmp*
# running panaroo and creating a pangenome
panaroo -i ${INPUT_DIR}/gff_vc/*.gff -o ${OUTPUT_DIR}/pangenome_vc \
--clean-mode strict -a core -a pan --core_threshold 1 --quiet -t $(nproc)
# to understand outputs: https://gthlab.au/panaroo/#/gettingstarted/output
cat $OUTPUT_DIR/pangenome_vc/summary_statistics.txt

# filtering gene presence/absence file
cd ${OUTPUT_DIR}/pangenome_vc
panaroo-filter-pa -i gene_presence_absence.csv \
 -o . --type pseudo,length
# checking gene neighborhood 
panaroo-gene-neighbourhood --gene trkI \
 --graph final_graph.gml --expand_no 10 --out trkI_neighbourhood.txt
cd ${OUTPUT_DIR}

# phylogenetics 
module load  anaconda3/2024.10
conda activate gubbins
mkdir -p ${OUTPUT_DIR}/phylogeny

cp ${OUTPUT_DIR}/pangenome_vc/core_gene_alignment_filtered.aln ${OUTPUT_DIR}/phylogeny/
cd ${OUTPUT_DIR}/phylogeny
# constructing recombination free phylogenetic tree
run_gubbins.py core_gene_alignment_filtered.aln \
 -p gubbins -c $(nproc) -t veryfasttree
# to undestand the output file: https://github.com/nickjcroucher/gubbins/blob/master/docs/gubbins_manual.md

# tree visualization, download  gubbins.final_tree.tre and visualize it on itol\





 

 
# On personal computer
conda create -n panaroo python=3.9
conda activate panaroo
conda install -n panaroo -c bioconda -c conda-forge panaroo
# on cluster
module spider conda ==>  anaconda3/2024.10
module load anaconda3/2024.10
conda activate 
conda create -n panaroo -c bioconda -c conda-forge panaroo
