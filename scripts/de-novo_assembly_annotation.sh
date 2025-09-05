set -euo pipefail

srun --cpus-per-task=16 --mem=64GB --time 3:00:00 --pty bash

module purge
module load spades/4.2.0 bedtools
OUTPUT_DIR="/data/users/${USER}/data_analysis"
THREADS=$(nproc)

# TB
# Input locations
TB_CLEAN="/data/users/${USER}/data_analysis/trimmed_trimmomatic/tb"
# Output location
mkdir -p ${OUTPUT_DIR}/assembly/tb ${OUTPUT_DIR}/annotation/tb
ls $TB_CLEAN | cut -f1 -d '_' | sort | uniq > $OUTPUT_DIR/tb_IDs

#TB assembly
for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  spades.py -1 ${TB_CLEAN}/${SAMPLE}_1.fastq.gz -2 ${TB_CLEAN}/${SAMPLE}_2.fastq.gz \
  --careful -t ${THREADS} --cov-cutoff "auto" -o ${OUTPUT_DIR}/assembly/tb/${SAMPLE}
done

#TB annotation
module load anaconda3/2024.10
conda activate prokka
for SAMPLE in $(cat $OUTPUT_DIR/tb_IDs); do
  prokka --outdir ${OUTPUT_DIR}/annotation/tb/${SAMPLE} \
         --prefix ${SAMPLE} \
         --cpus ${THREADS} --genus Mycobacterium --species tuberculosis \
         --kingdom Bacteria ${OUTPUT_DIR}/assembly/tb/${SAMPLE}/contigs.fasta
done
conda deactivate

# Peek at what’s annotated, count CDS, rRNA, tRNA per sample (from GFF)
# # check the results and axplain it
BASE=/data/users/${USER}/data_analysis/annotation/tb
SAMPLES="ERR10225374 ERR10225402"   # start with two; you can also do: SAMPLES=$(basename -a $BASE/ERR*)
for S in $SAMPLES; do
  GFF=$BASE/$S/${S}.gff
  cds=$(grep -P "\tCDS\t" "$GFF" | wc -l)
  trna=$(grep -P "\ttRNA\t" "$GFF" | wc -l)
  rrna=$(grep -P "\trRNA\t" "$GFF" | wc -l)
  echo -e "${S}\tCDS:${cds}\ttRNA:${trna}\trRNA:${rrna}"
done

# Count the total number of features in a GFF file
grep -v "^#" your.gff | cut -f 3 | sort | uniq -c

# Calculating feature length statistics
grep -v "^#" your.gff | awk '$3 == "exon"' | awk '{print $5-$4}' | awk '{sum+=$1} END {print sum/NR}'

# Summarizing feature lengths by type
grep -v "^#" your.gff | awk '{print $1"\t"$4"\t"$5"\t"$3}' | bedtools sort -i - | bedtools groupBy -i - -c 4 -o count







# VC 
VC_CLEAN="/data/users/${USER}/data_analysis/trimmed_trimmomatic/vc"
mkdir -p ${OUTPUT_DIR}/assembly/vc ${OUTPUT_DIR}/annotation/vc
ls $VC_CLEAN | cut -f1 -d '_' | sort | uniq > $OUTPUT_DIR/vc_IDs

#VC assembly
for SAMPLE in $(cat $OUTPUT_DIR/vc_IDs); do
  spades.py -1 ${VC_CLEAN}/${SAMPLE}_1.fastq.gz -2 ${VC_CLEAN}/${SAMPLE}_2.fastq.gz \
  --careful -t ${THREADS} --cov-cutoff "auto" -o ${OUTPUT_DIR}/assembly/vc/${SAMPLE}
done

#VC annotation
module load anaconda3/2024.10
conda activate prokka
for SAMPLE in $(cat $OUTPUT_DIR/vc_IDs); do
  prokka --outdir ${OUTPUT_DIR}/annotation/vc/${SAMPLE} \
         --prefix ${SAMPLE} \
         --cpus ${THREADS} --genus Mycobacterium --species tuberculosis \
         --kingdom Bacteria ${OUTPUT_DIR}/assembly/vc/${SAMPLE}/contigs.fasta
done
conda deactivate


