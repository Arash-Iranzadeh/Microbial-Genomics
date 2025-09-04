set -euo pipefail

srun --cpus-per-task=16 --mem=64GB --time 3:00:00 --pty bash

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

#TB assembly
for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  spades.py -1 ${TB_CLEAN}/${SAMPLE}_1.fastq.gz -2 ${TB_CLEAN}/${SAMPLE}_2.fastq.gz \
  --careful -t ${THREADS} --cov-cutoff "auto" -o ${OUTPUT_DIR}/assembly/tb/${SAMPLE}
done

module load anaconda3/2024.10
conda activate prokka

for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  prokka --outdir ${OUTPUT_DIR}/annotation/tb/${SAMPLE} \
         --prefix ${SAMPLE} \
         --cpus ${THREADS} --genus Mycobacterium --species tuberculosis \
         --kingdom Bacteria ${OUTPUT_DIR}/assembly/tb/${SAMPLE}/contigs.fasta
done

conda deactivate
