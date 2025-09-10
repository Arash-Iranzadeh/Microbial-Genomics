#!/usr/bin/env bash
#SBATCH --job-name="QC_Cleaning_Detection"
#SBATCH --cpus-per-task=32
#SBATCH --mem=128GB
#SBATCH --output=./logs/QC_cleaning_out.log
#SBATCH --error=./logs/QC_cleaning_err.log
#SBATCH --time=24:00:00

# If you want interactive jobs:
# srun --cpus-per-task=8 --mem=32GB  --pty bash

set -euo pipefail

module load fastqc fastp multiqc trimmomatic kraken2 
OUTPUT_DIR="/data/users/${USER}/data_analysis"
THREADS=$(nproc)
# Input locations
TB_RAW="/data/Dataset_Mt_Vc/tb/raw_data"
VC_RAW="/data/Dataset_Mt_Vc/vc/raw_data"
# Trimmomatic adapters
ADAPT_COMBO="/data/timmomatic_adapter_Combo.fa"
# making output folders
mkdir -p ${OUTPUT_DIR}/qc_raw/tb ${OUTPUT_DIR}/qc_raw/vc
mkdir -p ${OUTPUT_DIR}/trimmed_trimmomatic/tb ${OUTPUT_DIR}/trimmed_trimmomatic/vc
mkdir -p ${OUTPUT_DIR}/trimmed_fastp/tb ${OUTPUT_DIR}/trimmed_fastp/vc
mkdir -p ${OUTPUT_DIR}/qc_trim_trimmomatic/tb ${OUTPUT_DIR}/qc_trim_trimmomatic/vc
mkdir -p ${OUTPUT_DIR}/qc_trim_fastp/tb ${OUTPUT_DIR}/qc_trim_fastp/vc
mkdir -p ${OUTPUT_DIR}/kraken2_trimmomatic/tb ${OUTPUT_DIR}/kraken2_trimmomatic/vc

ls ${TB_RAW} | cut -f1 -d '_' | sort | uniq > ${OUTPUT_DIR}/tb_IDs
ls ${VC_RAW} | cut -f1 -d '_' | sort | uniq > ${OUTPUT_DIR}/vc_IDs

# TB
echo "1) FastQC + MultiQC on raw data / TB ..."
fastqc -t ${THREADS} -o ${OUTPUT_DIR}/qc_raw/tb ${TB_RAW}/*_1.fastq.gz ${TB_RAW}/*_2.fastq.gz
multiqc ${OUTPUT_DIR}/qc_raw/tb --force -n tb_multiqc_raw.html -o ${OUTPUT_DIR}/qc_raw/tb

echo "2) Cleaning with Trimmomatic / TB ..." 
# TB (MINLEN 50)
for SAMPLE in $(cat ${OUTPUT_DIR}/tb_IDs); do
  echo "[TB|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    ${TB_RAW}/${SAMPLE}_1.fastq.gz ${TB_RAW}/${SAMPLE}_2.fastq.gz  \
    "${OUTPUT_DIR}/trimmed_trimmomatic/tb/${SAMPLE}_1.fastq.gz" "${OUTPUT_DIR}/trimmed_trimmomatic/tb/${SAMPLE}_1U.fastq.gz" \
    "${OUTPUT_DIR}/trimmed_trimmomatic/tb/${SAMPLE}_2.fastq.gz" "${OUTPUT_DIR}/trimmed_trimmomatic/tb/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT_COMBO}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:50
done

echo "3) QC after cleaning by Trimmomatic / TB ..."
fastqc -t ${THREADS} -o ${OUTPUT_DIR}/qc_trim_trimmomatic/tb ${OUTPUT_DIR}/trimmed_trimmomatic/tb/*_1.fastq.gz ${OUTPUT_DIR}/trimmed_trimmomatic/tb/*_2.fastq.gz
multiqc ${OUTPUT_DIR}/qc_trim_trimmomatic/tb --force -n tb_multiqc_trimmed_trimmomatic.html -o ${OUTPUT_DIR}/qc_trim_trimmomatic/tb

echo "4) Cleaning with Fastp / TB ..."
# TB (length_required 50) + polyG/polyX trimming
for SAMPLE in $(cat ${OUTPUT_DIR}/tb_IDs); do
  echo "[TB|fastp] ${SAMPLE}"
  fastp -w ${THREADS} \
    -i ${TB_RAW}/${SAMPLE}_1.fastq.gz  -I ${TB_RAW}/${SAMPLE}_2.fastq.gz \
    -o "${OUTPUT_DIR}/trimmed_fastp/tb/${SAMPLE}_1.fastq.gz" \
    -O "${OUTPUT_DIR}/trimmed_fastp/tb/${SAMPLE}_2.fastq.gz" \
    --detect_adapter_for_pe --trim_poly_g --trim_poly_x \
    --qualified_quality_phred 30 --length_required 50 \
    -h "${OUTPUT_DIR}/trimmed_fastp/tb/${SAMPLE}_fastp.html" 
done

echo "5) QC after cleaning with fastp / TB ..."
fastqc -t ${THREADS} -o ${OUTPUT_DIR}/qc_trim_fastp/tb ${OUTPUT_DIR}/trimmed_fastp/tb/*_1.fastq.gz ${OUTPUT_DIR}/trimmed_fastp/tb/*_2.fastq.gz
multiqc ${OUTPUT_DIR}/qc_trim_fastp/tb --force -n tb_multiqc_trimmed_fastp.html -o ${OUTPUT_DIR}/qc_trim_fastp/tb

# VC
echo "1) FastQC + MultiQC on raw reads / VC ..."
fastqc -t ${THREADS} -o ${OUTPUT_DIR}/qc_raw/vc ${VC_RAW}/*_1.fastq.gz ${VC_RAW}/*_2.fastq.gz
multiqc ${OUTPUT_DIR}/qc_raw/vc --force -n vc_multiqc_raw.html -o ${OUTPUT_DIR}/qc_raw/vc

echo "2) Cleaning with trimmomatic / VC ..."
# VC (MINLEN 50)
for SAMPLE in $(cat ${OUTPUT_DIR}/vc_IDs); do
  echo "[VC|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    ${VC_RAW}/${SAMPLE}_1.fastq.gz ${VC_RAW}/${SAMPLE}_2.fastq.gz  \
    "${OUTPUT_DIR}/trimmed_trimmomatic/vc/${SAMPLE}_1.fastq.gz" "${OUTPUT_DIR}/trimmed_trimmomatic/vc/${SAMPLE}_1U.fastq.gz" \
    "${OUTPUT_DIR}/trimmed_trimmomatic/vc/${SAMPLE}_2.fastq.gz" "${OUTPUT_DIR}/trimmed_trimmomatic/vc/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT_COMBO}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:50
done

echo "3) QC after cleaning with Trimmomatic / VC ..."
fastqc -t ${THREADS} -o ${OUTPUT_DIR}/qc_trim_trimmomatic/vc ${OUTPUT_DIR}/trimmed_trimmomatic/vc/*_1.fastq.gz ${OUTPUT_DIR}/trimmed_trimmomatic/vc/*_2.fastq.gz
multiqc ${OUTPUT_DIR}/qc_trim_trimmomatic/vc --force -n vc_multiqc_trimmed_trimmomatic.html -o ${OUTPUT_DIR}/qc_trim_trimmomatic/vc

echo "4) Cleaning with Fastp / VC ..."
# VC (length_required 50) + polyG/polyX trimming
for SAMPLE in $(cat ${OUTPUT_DIR}/vc_IDs); do
  echo "[VC|fastp] ${SAMPLE}"
  fastp -w ${THREADS} \
    -i ${VC_RAW}/${SAMPLE}_1.fastq.gz  -I ${VC_RAW}/${SAMPLE}_2.fastq.gz \
    -o "${OUTPUT_DIR}/trimmed_fastp/vc/${SAMPLE}_1.fastq.gz" \
    -O "${OUTPUT_DIR}/trimmed_fastp/vc/${SAMPLE}_2.fastq.gz" \
    --detect_adapter_for_pe --trim_poly_g --trim_poly_x \
    --qualified_quality_phred 30 --length_required 50 \
    -h "${OUTPUT_DIR}/trimmed_fastp/vc/${SAMPLE}_fastp.html" 
done

echo "5) QC after cleaning with Fastp / VC ..."
fastqc -t ${THREADS} -o ${OUTPUT_DIR}/qc_trim_fastp/vc ${OUTPUT_DIR}/trimmed_fastp/vc/*_1.fastq.gz ${OUTPUT_DIR}/trimmed_fastp/vc/*_2.fastq.gz
multiqc ${OUTPUT_DIR}/qc_trim_fastp/vc --force -n vc_multiqc_trimmed_fastp.html -o ${OUTPUT_DIR}/qc_trim_fastp/vc

# you can remove unpaired reads to save space:
rm ${OUTPUT_DIR}/trimmed_trimmomatic/*/*U*

# ===========================================
# DB BUILDING + DETECTION
# ===========================================
# If kraken database is not available, make it:
# Preparing standard Kraken DB (this takes time)
# kraken2-build --standard --threads ${THREADS} --db /path/to/kraken2_db_standard

# Preparing bacteria-only DB
# kraken2-build --download-taxonomy --db ./kraken2_db_bacteria
# kraken2-build --download-library bacteria --threads ${THREADS} --db ./kraken2_db_bacteria
# kraken2-build --build --threads ${THREADS} --db ./kraken2_db_bacteria

KRAKEN_DB="/data/kraken2_db_standard"
# Kraken2 on trimmomatic-cleaned reads (if DB available) ==="
# TB
echo "1) Running Kraken / TB ..."
for SAMPLE in $(cat ${OUTPUT_DIR}/tb_IDs); do
 kraken2 --db "$KRAKEN_DB" --threads ${THREADS} \
    --quick --confidence 0.1 --memory-mapping --gzip-compressed --use-names \
    --paired ${OUTPUT_DIR}/trimmed_trimmomatic/tb/${SAMPLE}_1.fastq.gz ${OUTPUT_DIR}/trimmed_trimmomatic/tb/${SAMPLE}_2.fastq.gz \
    --report "${OUTPUT_DIR}/kraken2_trimmomatic/tb/${SAMPLE}.report" \
    --output "${OUTPUT_DIR}/kraken2_trimmomatic/tb/${SAMPLE}.kraken"
done

# VC
echo "2) Running Kraken / VC ..."
for SAMPLE in $(cat ${OUTPUT_DIR}/vc_IDs); do
 kraken2 --db "$KRAKEN_DB" --threads ${THREADS} \
  --quick --confidence 0.1 --memory-mapping --gzip-compressed --use-names \
  --paired ${OUTPUT_DIR}/trimmed_trimmomatic/vc/${SAMPLE}_1.fastq.gz ${OUTPUT_DIR}/trimmed_trimmomatic/vc/${SAMPLE}_2.fastq.gz \
  --report "${OUTPUT_DIR}/kraken2_trimmomatic/vc/${SAMPLE}.report" \
  --output "${OUTPUT_DIR}/kraken2_trimmomatic/vc/${SAMPLE}.kraken"
  done

# To summarize kraken resukts use summarize_kraken.sh
# to visualize the kraken data_analysis use Pavian that is an R/Shiny application. 
# Install R and RStudio. Install Pavian dependencies: Open R and run the following commands.
#if (!require(remotes)) {
#    install.packages("remotes")
#}
#remotes::install_github("fbreitwieser/pavian")

# Run Pavian: In R type

#library(pavian)
#pavian::runApp(port=5000)

#This will start a web server and print the address in the console. Paste this address into your web browser to use the application. 
