#!/usr/bin/env bash
set -euo pipefail

# QC + Cleaning + Species ID (FastQC → Trimmomatic/fastp → FastQC/MultiQC → Kraken2)
# Designed for workshop VMs (≈16 cores, 64 GB RAM).
#
# USAGE:
#   1) Put/point to your raw data here (do NOT commit FASTQs to the repo).
#      By default we expect the external working folder layout:
#         ${DATA_ROOT}/workshop/tb/raw_data/*.fastq.gz
#         ${DATA_ROOT}/workshop/vc/raw_data/*.fastq.gz
#   2) Set DATA_ROOT and KRAKEN_DB before running, e.g.:
#         export DATA_ROOT=/scratch3/users/arash
#         export KRAKEN_DB=/path/to/kraken2_db
#   3) Run:
#         bash scripts/qc_species_id.sh
#
# OUTPUTS go under the repo "results/" folder.

# ---- Config ----
THREADS="${THREADS:-16}"
DATA_ROOT="${DATA_ROOT:-/scratch3/users/arash}"
TB_RAW="${DATA_ROOT}/workshop/tb/raw_data"
VC_RAW="${DATA_ROOT}/workshop/vc/raw_data"

# repo-relative outputs
BASE_RESULTS="results"
RAW_QC_DIR="${BASE_RESULTS}/fastqc_reports/raw"
TRIM_DIR="${BASE_RESULTS}/trimmed_reads"
TRIM_QC_DIR="${BASE_RESULTS}/fastqc_reports/trimmed"
REPORT_DIR="${BASE_RESULTS}/multiqc_reports"
KRAKEN_DIR="${BASE_RESULTS}/kraken2_reports"

mkdir -p "${RAW_QC_DIR}" "${TRIM_DIR}" "${TRIM_QC_DIR}" "${REPORT_DIR}" "${KRAKEN_DIR}"

# Adapter file for Trimmomatic (ensure it exists in current dir or give full path)
ADAPTERS="${ADAPTERS:-TruSeq3-PE.fa}"

# Kraken2 DB (must be set by user)
: "${KRAKEN_DB:?Set KRAKEN_DB to your Kraken2 database path}"

# ---- Step 1: FastQC on raw data ----
echo "[1/6] FastQC on raw reads..."
fastqc -t "${THREADS}" -o "${RAW_QC_DIR}" \
  "${TB_RAW}"/*_1.fastq.gz "${TB_RAW}"/*_2.fastq.gz \
  "${VC_RAW}"/*_1.fastq.gz "${VC_RAW}"/*_2.fastq.gz

# ---- Step 2: MultiQC summary (raw) ----
echo "[2/6] MultiQC (raw) ..."
multiqc "${RAW_QC_DIR}" -n multiqc_raw.html -o "${REPORT_DIR}"

# ---- Step 3: Trimming (Trimmomatic by default) ----
echo "[3/6] Trimming with Trimmomatic..."
shopt -s nullglob
for R1 in "${TB_RAW}"/*_1.fastq.gz "${VC_RAW}"/*_1.fastq.gz; do
  R2="${R1/_1.fastq.gz/_2.fastq.gz}"
  SAMPLE="$(basename "${R1%_1.fastq.gz}")"
  echo "   -> ${SAMPLE}"
  if command -v trimmomatic >/dev/null 2>&1; then
    trimmomatic PE -threads "${THREADS}" -phred33 \
      "${R1}" "${R2}" \
      "${TRIM_DIR}/${SAMPLE}_1P.fastq.gz" "${TRIM_DIR}/${SAMPLE}_1U.fastq.gz" \
      "${TRIM_DIR}/${SAMPLE}_2P.fastq.gz" "${TRIM_DIR}/${SAMPLE}_2U.fastq.gz" \
      ILLUMINACLIP:"${ADAPTERS}":2:30:10 SLIDINGWINDOW:4:20 MINLEN:50
  else
    : "${TRIMMO_JAR:?trimmomatic not found; set TRIMMO_JAR=/path/to/trimmomatic.jar}"
    java -jar "${TRIMMO_JAR}" PE -threads "${THREADS}" -phred33 \
      "${R1}" "${R2}" \
      "${TRIM_DIR}/${SAMPLE}_1P.fastq.gz" "${TRIM_DIR}/${SAMPLE}_1U.fastq.gz" \
      "${TRIM_DIR}/${SAMPLE}_2P.fastq.gz" "${TRIM_DIR}/${SAMPLE}_2U.fastq.gz" \
      ILLUMINACLIP:"${ADAPTERS}":2:30:10 SLIDINGWINDOW:4:20 MINLEN:50
  fi
done

# ---- (Alt) fastp trimming (disabled by default). Uncomment to use fastp instead. ----
: <<'FASTP'
echo "[3/6-alt] Trimming with fastp..."
for R1 in "${TB_RAW}"/*_1.fastq.gz "${VC_RAW}"/*_1.fastq.gz; do
  R2="${R1/_1.fastq.gz/_2.fastq.gz}"
  SAMPLE="$(basename "${R1%_1.fastq.gz}")"
  fastp -w "${THREADS}" -i "${R1}" -I "${R2}" \
        -o "${TRIM_DIR}/${SAMPLE}_1P.fastq.gz" -O "${TRIM_DIR}/${SAMPLE}_2P.fastq.gz" \
        -l 50 -h "${TRIM_DIR}/${SAMPLE}_fastp.html" -j "${TRIM_DIR}/${SAMPLE}_fastp.json"
done
FASTP

# ---- Step 4: FastQC on trimmed reads ----
echo "[4/6] FastQC on trimmed reads..."
fastqc -t "${THREADS}" -o "${TRIM_QC_DIR}" "${TRIM_DIR}"/*_1P.fastq.gz "${TRIM_DIR}"/*_2P.fastq.gz

# ---- Step 5: MultiQC summary (trimmed) ----
echo "[5/6] MultiQC (trimmed) ..."
multiqc "${TRIM_QC_DIR}" -n multiqc_trimmed.html -o "${REPORT_DIR}"

# ---- Step 6: Kraken2 species ID ----
echo "[6/6] Kraken2 classification..."
for R1P in "${TRIM_DIR}"/*_1P.fastq.gz; do
  R2P="${R1P/_1P.fastq.gz/_2P.fastq.gz}"
  SAMPLE="$(basename "${R1P%_1P.fastq.gz}")"
  echo "   -> ${SAMPLE}"
  kraken2 --db "${KRAKEN_DB}" --threads "${THREADS}" \
          --paired "${R1P}" "${R2P}" \
          --report "${KRAKEN_DIR}/${SAMPLE}.report" \
          --output "${KRAKEN_DIR}/${SAMPLE}.kraken"
done

echo
echo "Done. Open reports in results/:"
echo " - Raw FastQC:      ${RAW_QC_DIR}"
echo " - Trimmed FastQC:  ${TRIM_QC_DIR}"
echo " - MultiQC:         ${REPORT_DIR}/multiqc_raw.html and multiqc_trimmed.html"
echo " - Kraken2 reports: ${KRAKEN_DIR}/*.report"
