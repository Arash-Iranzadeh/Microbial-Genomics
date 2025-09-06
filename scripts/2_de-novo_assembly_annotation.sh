#!/bin/bash
#SBATCH --job-name="assembly_annotation"
#SBATCH --cpus-per-task=32
#SBATCH --mem=128GB
#SBATCH --output=./logs/assembly_annotation_out.log
#SBATCH --error=./logs/assembly_annotation_err.log
#SBATCH --time=24:00:00
set -euo pipefail

module purge
module load spades/4.2.0
OUTPUT_DIR="/data/users/${USER}/data_analysis"
THREADS=$(nproc)
# Input locations
TB_CLEAN="/data/users/user28/data_analysis/trimmed_trimmomatic/tb"
VC_CLEAN="/data/users/user28/data_analysis/trimmed_trimmomatic/vc"

# making output folders
mkdir -p ${OUTPUT_DIR}/assembly/tb ${OUTPUT_DIR}/assembly/vc
mkdir -p ${OUTPUT_DIR}/annotation/tb ${OUTPUT_DIR}/annotation/vc

ls $TB_CLEAN | cut -f1 -d '_' | sort | uniq > $OUTPUT_DIR/tb_IDs
ls $VC_CLEAN | cut -f1 -d '_' | sort | uniq > $OUTPUT_DIR/vc_IDs

echo "1) Genome assembly / TB ..."
for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  spades.py -1 ${TB_CLEAN}/${SAMPLE}_1.fastq.gz -2 ${TB_CLEAN}/${SAMPLE}_2.fastq.gz \
  --careful -t ${THREADS} --cov-cutoff "auto" -o ${OUTPUT_DIR}/assembly/tb/${SAMPLE}
done

module load anaconda3/2024.10
conda activate prokka
echo "2) Genome annotation / TB ..."
for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  prokka --outdir ${OUTPUT_DIR}/annotation/tb/${SAMPLE} \
         --prefix ${SAMPLE} \
         --cpus ${THREADS} --genus Mycobacterium --species tuberculosis \
         --kingdom Bacteria ${OUTPUT_DIR}/assembly/tb/${SAMPLE}/contigs.fasta
done

conda deactivate

module purge
module load spades/4.2.0
# VC
echo "1) Genome assembly / VC ..."
for SAMPLE in $(cat $OUTPUT_DIR/vc_IDs); do
  spades.py -1 ${VC_CLEAN}/${SAMPLE}_1.fastq.gz -2 ${VC_CLEAN}/${SAMPLE}_2.fastq.gz \
  --careful -t ${THREADS} --cov-cutoff "auto" -o ${OUTPUT_DIR}/assembly/vc/${SAMPLE}
done

module load anaconda3/2024.10
conda activate prokka
echo "2) Genome annotation / VC ..."
for SAMPLE in $(cat $OUTPUT_DIR/vc_IDs); do
  prokka --outdir ${OUTPUT_DIR}/annotation/vc/${SAMPLE} \
         --prefix ${SAMPLE} \
         --cpus ${THREADS} --genus Mycobacterium --species tuberculosis \
         --kingdom Bacteria ${OUTPUT_DIR}/assembly/vc/${SAMPLE}/contigs.fasta
done

conda deactivate

