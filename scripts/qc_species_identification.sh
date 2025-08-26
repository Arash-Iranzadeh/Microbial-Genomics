#!/usr/bin/env bash

# -----------------------------------------------------------
# QC + Cleaning + Species ID (simple version for beginners)
# Tools: FastQC, MultiQC, Trimmomatic (or fastp), Kraken2
# Data folders:
#   data/tb/raw_data/*.fastq.gz
#   data/vc/raw_data/*.fastq.gz
# Results will be written under results/
# -----------------------------------------------------------

# Threads and Kraken2 DB (EDIT this path!)
THREADS=32
KRAKEN_DB="/path/to/kraken2_db"   # <--- set this before running

# Trimmomatic adapters on your SLURM cluster:
ADAPT="/software/bio/trimmomatic/0.39/adapters/TruSeq3-PE.fa"

# 0) Make output folders
mkdir -p results/qc_raw/tb results/qc_raw/vc
mkdir -p results/trimmed/tb results/trimmed/vc
mkdir -p results/qc_trim/tb results/qc_trim/vc
mkdir -p results/kraken2/tb results/kraken2/vc

echo "=== 1) FASTQC on RAW reads ==="
# TB
fastqc -t ${THREADS} -o ./results/qc_raw/tb/ ./data/tb/raw_data/*_1.fastq.gz ./data/tb/raw_data/*_2.fastq.gz
multiqc ./results/qc_raw/tb -n tb_multiqc_raw.html -o ./results/qc_raw/tb
# VC
fastqc -t ${THREADS} -o ./results/qc_raw/vc/ ./data/vc/raw_data/*_1.fastq.gz ./data/vc/raw_data/*_2.fastq.gz
multiqc ./results/qc_raw/vc -n vc_multiqc_raw.html -o ./results/qc_raw/vc

echo "=== 2) TRIMMING with Trimmomatic (adapters + quality) ==="
# ----- TB -----
for R1 in ./data/tb/raw_data/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=$(echo "$R1" | sed 's/_1\.fastq\.gz/_2.fastq.gz/')
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[TB] Trimming $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    "$R1" "$R2" \
    "./results/trimmed/tb/${SAMPLE}_1P.fastq.gz" "./results/trimmed/tb/${SAMPLE}_1U.fastq.gz" \
    "./results/trimmed/tb/${SAMPLE}_2P.fastq.gz" "./results/trimmed/tb/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT}":2:30:10 \
    LEADING:3 TRAILING:3 \
    SLIDINGWINDOW:4:20 \
    MINLEN:50
done

# ----- VC -----
for R1 in ./data/vc/raw_data/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=$(echo "$R1" | sed 's/_1\.fastq\.gz/_2.fastq.gz/')
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[VC] Trimming $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    "$R1" "$R2" \
    "./results/trimmed/vc/${SAMPLE}_1P.fastq.gz" "./results/trimmed/vc/${SAMPLE}_1U.fastq.gz" \
    "./results/trimmed/vc/${SAMPLE}_2P.fastq.gz" "./results/trimmed/vc/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT}":2:30:10 \
    LEADING:3 TRAILING:3 \
    SLIDINGWINDOW:4:20 \
    MINLEN:36
done

# (Alternative: fastp — uncomment to use instead of Trimmomatic)
# for R1 in ./data/tb/raw_data/*_1.fastq.gz; do
#   [ -e "$R1" ] || continue
#   R2=$(echo "$R1" | sed 's/_1\.fastq\.gz/_2.fastq.gz/')
#   SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
#   echo "[TB-fastp] $SAMPLE"
#   fastp -w ${THREADS} -i "$R1" -I "$R2" \
#     -o "./results/trimmed/tb/${SAMPLE}_1P.fastq.gz" \
#     -O "./results/trimmed/tb/${SAMPLE}_2P.fastq.gz" \
#     --detect_adapter_for_pe --length_required 50 \
#     -h "./results/trimmed/tb/${SAMPLE}_fastp.html" \
#     -j "./results/trimmed/tb/${SAMPLE}_fastp.json"
# done
# (Repeat similarly for VC with length_required 36 if you prefer)

echo "=== 3) FASTQC on TRIMMED reads + MultiQC ==="
# TB
fastqc -t ${THREADS} -o ./results/qc_trim/tb/ ./results/trimmed/tb/*_1P.fastq.gz ./results/trimmed/tb/*_2P.fastq.gz
multiqc ./results/qc_trim/tb -n tb_multiqc_trimmed.html -o ./results/qc_trim/tb
# VC
fastqc -t ${THREADS} -o ./results/qc_trim/vc/ ./results/trimmed/vc/*_1P.fastq.gz ./results/trimmed/vc/*_2P.fastq.gz
multiqc ./results/qc_trim/vc -n vc_multiqc_trimmed.html -o ./results/qc_trim/vc

echo "=== 4) SPECIES IDENTIFICATION with Kraken2 ==="
# TB
for R1P in ./results/trimmed/tb/*_1P.fastq.gz; do
  [ -e "$R1P" ] || continue
  R2P=$(echo "$R1P" | sed 's/_1P\.fastq\.gz/_2P.fastq.gz/')
  SAMPLE=$(basename "$R1P" | sed 's/_1P\.fastq\.gz//')
  echo "[TB] Kraken2 $SAMPLE"
  kraken2 --db "${KRAKEN_DB}" --threads ${THREADS} \
    --paired "$R1P" "$R2P" \
    --report "./results/kraken2/tb/${SAMPLE}.report" \
    --output "./results/kraken2/tb/${SAMPLE}.kraken"
done
# VC
for R1P in ./results/trimmed/vc/*_1P.fastq.gz; do
  [ -e "$R1P" ] || continue
  R2P=$(echo "$R1P" | sed 's/_1P\.fastq\.gz/_2P.fastq.gz/')
  SAMPLE=$(basename "$R1P" | sed 's/_1P\.fastq\.gz//')
  echo "[VC] Kraken2 $SAMPLE"
  kraken2 --db "${KRAKEN_DB}" --threads ${THREADS} \
    --paired "$R1P" "$R2P" \
    --report "./results/kraken2/vc/${SAMPLE}.report" \
    --output "./results/kraken2/vc/${SAMPLE}.kraken"
done

echo "=== All done. Open these reports: ==="
echo "  - Raw QC:      results/qc_raw/tb/tb_multiqc_raw.html, results/qc_raw/vc/vc_multiqc_raw.html"
echo "  - Trimmed QC:  results/qc_trim/tb/tb_multiqc_trimmed.html, results/qc_trim/vc/vc_multiqc_trimmed.html"
echo "  - Kraken2:     results/kraken2/tb/*.report, results/kraken2/vc/*.report"
