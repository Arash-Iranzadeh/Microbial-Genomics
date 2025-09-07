#!/bin/bash
#SBATCH --job-name="assembly_annotation"
#SBATCH --cpus-per-task=32
#SBATCH --mem=128GB
#SBATCH --output=./logs/assembly_annotation_out.log
#SBATCH --error=./logs/assembly_annotation_err.log
#SBATCH --time=24:00:00
set -euo pipefail

module purge
module load multiqc spades/4.2.0 quast/5.3.0 bwa bedtools
OUTPUT_DIR="/data/users/${USER}/data_analysis"
THREADS=$(nproc)
# Input locations
TB_CLEAN="/data/users/user28/data_analysis/trimmed_trimmomatic/tb"
VC_CLEAN="/data/users/user28/data_analysis/trimmed_trimmomatic/vc"

# making output folders
mkdir -p ${OUTPUT_DIR}/assembly/tb ${OUTPUT_DIR}/assembly/vc
mkdir -p ${OUTPUT_DIR}/assembly_evaluation/tb ${OUTPUT_DIR}/assembly_evaluation/vc
mkdir -p ${OUTPUT_DIR}/annotation/tb ${OUTPUT_DIR}/annotation/vc 

ls $TB_CLEAN | cut -f1 -d '_' | sort | uniq > $OUTPUT_DIR/tb_IDs
ls $VC_CLEAN | cut -f1 -d '_' | sort | uniq > $OUTPUT_DIR/vc_IDs

echo "1) Genome assembly / TB ..."
for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  spades.py -1 ${TB_CLEAN}/${SAMPLE}_1.fastq.gz -2 ${TB_CLEAN}/${SAMPLE}_2.fastq.gz \
  --isolate -t ${THREADS} --cov-cutoff "auto" -o ${OUTPUT_DIR}/assembly/tb/${SAMPLE}
done

echo "2) Assembly evaluation / TB ..."
# Note: Quast failed to run on 128GB of RAW, it was run on 240GB 
for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  quast.py -o $OUTPUT_DIR/assembly_evaluation/tb/${SAMPLE} -t $THREADS --plots-format png \
  --silent $OUTPUT_DIR/assembly/tb/${SAMPLE}/contigs.fasta
done
 multiqc --dirs ${OUTPUT_DIR}/assembly_evaluation/tb --force 
 -n tb_multiqc_assembly.html -o ${OUTPUT_DIR}/assembly_evaluation/tb
 
module purge
module load anaconda3/2024.10
conda activate prokka
echo "3) Genome annotation / TB ..."
for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  prokka --outdir ${OUTPUT_DIR}/annotation/tb/${SAMPLE} \
         --prefix ${SAMPLE} \
         --cpus ${THREADS} --genus Mycobacterium --species tuberculosis \
         --kingdom Bacteria ${OUTPUT_DIR}/assembly/tb/${SAMPLE}/contigs.fasta
done
conda deactivate

module purge
module load multiqc spades/4.2.0 quast/5.3.0 bwa bedtools
# VC
echo "1) Genome assembly / VC ..."
for SAMPLE in $(cat $OUTPUT_DIR/vc_IDs); do
  spades.py -1 ${VC_CLEAN}/${SAMPLE}_1.fastq.gz -2 ${VC_CLEAN}/${SAMPLE}_2.fastq.gz \
  --isolate -t ${THREADS} --cov-cutoff "auto" -o ${OUTPUT_DIR}/assembly/vc/${SAMPLE}
done

echo "2) Assembly evaluation / VC ..."
for SAMPLE in $(cat $OUTPUT_DIR/vc_IDs); do
  quast.py -o $OUTPUT_DIR/assembly_evaluation/vc/${SAMPLE} -t $THREADS --plots-format png \
  --silent $OUTPUT_DIR/assembly/vc/${SAMPLE}/contigs.fasta
done
 multiqc --dirs ${OUTPUT_DIR}/assembly_evaluation/vc --force -n
 vc_multiqc_assembly.html -o ${OUTPUT_DIR}/assembly_evaluation/vc
 
module purge
module load anaconda3/2024.10
conda activate prokka
echo "3) Genome annotation / VC ..."
for SAMPLE in $(cat $OUTPUT_DIR/vc_IDs); do
  prokka --outdir ${OUTPUT_DIR}/annotation/vc/${SAMPLE} \
         --prefix ${SAMPLE} \
         --cpus ${THREADS} --genus Mycobacterium --species tuberculosis \
         --kingdom Bacteria ${OUTPUT_DIR}/assembly/vc/${SAMPLE}/contigs.fasta
done
conda deactivate
