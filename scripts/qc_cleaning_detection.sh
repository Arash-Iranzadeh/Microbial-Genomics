#!/usr/bin/env bash
set -euo pipefail
# ===========================================
# QC + Cleaning + Detection 
# - FastQC + MultiQC (raw)
# - Trimmomatic (trim) -> separate outputs
# - fastp (trim)       -> separate outputs
# - FastQC + MultiQC (on cleaned reads by each of trimmomatic and fastp)
# - Build Kraken2 DBs 
# - Kraken2 on cleaned reads
# ===========================================

module load fastqc multiqc trimmomatic fastp kraken2 
THREADS=$(nproc)
# Input locations
TB_RAW="/data/Dataset_Mt_Vc/tb/raw_data"
VC_RAW="/data/Dataset_Mt_Vc/vc/raw_data"
# Trimmomatic adapters
ADAPT_COMBO="/data/timmomatic_adapter_Combo.fa"
# saving sample IDs
ls ${TB_RAW} | cut -f1 -d '_'  | sort | uniq > data_analysis/tb_IDs
ls ${VC_RAW} | cut -f1 -d '_'  | sort | uniq > data_analysis/vc_IDs

# Output folders
mkdir -p data_analysis/qc_raw/tb data_analysis/qc_raw/vc
mkdir -p data_analysis/trimmed_trimmomatic/tb data_analysis/trimmed_trimmomatic/vc
mkdir -p data_analysis/trimmed_fastp/tb data_analysis/trimmed_fastp/vc
mkdir -p data_analysis/qc_trim_trimmomatic/tb data_analysis/qc_trim_trimmomatic/vc
mkdir -p data_analysis/qc_trim_fastp/tb data_analysis/qc_trim_fastp/vc
mkdir -p data_analysis/kraken2_trimmomatic/tb data_analysis/kraken2_trimmomatic/vc

# Quality check
# For long read data use longqc:
https://github.com/yfukasawa/LongQC
# 1) FastQC on RAW reads + MultiQC ==="

# TB
fastqc -t ${THREADS} -o data_analysis/qc_raw/tb ${TB_RAW}/*_1.fastq.gz ${TB_RAW}/*_2.fastq.gz
multiqc data_analysis/qc_raw/tb -n tb_multiqc_raw.html -o data_analysis/qc_raw/tb
#
VC
fastqc -t ${THREADS} -o data_analysis/qc_raw/vc ${VC_RAW}/*_1.fastq.gz ${VC_RAW}/*_2.fastq.gz
multiqc data_analysis/qc_raw/vc -n vc_multiqc_raw.html -o data_analysis/qc_raw/vc



# Data cleaning
# for long read data use:
# Guppy: Oxford Nanopore's basecaller which also performs adapter trimming.
# Pychopper: A tool to trim and orient Nanopore cDNA reads.
# Filtlong: A tool that filters long reads by length and quality, allowing you to select the best reads for downstream analysis.
# MinIONQC and NanoPack: A set of tools for quality control and filtering of Nanopore data.
# SMRT Link: PacBio's official software for primary analysis (demultiplexing, adapter removal, Consensus Sequences (generation).


# 2) Cleaning with TRIMMOMATIC 
# TB (MINLEN 50)
for SAMPLE in $(cat data_analysis/tb_IDs); do
  echo "[TB|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    ${TB_RAW}/${SAMPLE}_1.fastq.gz ${TB_RAW}/${SAMPLE}_2.fastq.gz  \
    "data_analysis/trimmed_trimmomatic/tb/${SAMPLE}_1.fastq.gz" "data_analysis/trimmed_trimmomatic/tb/${SAMPLE}_1U.fastq.gz" \
    "data_analysis/trimmed_trimmomatic/tb/${SAMPLE}_2.fastq.gz" "data_analysis/trimmed_trimmomatic/tb/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT_COMBO}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:50
done

# VC (MINLEN 50)
for SAMPLE in $(cat data_analysis/vc_IDs); do
  trimmomatic PE -threads ${THREADS} -phred33 \
    ${VC_RAW}/${SAMPLE}_1.fastq.gz ${VC_RAW}/${SAMPLE}_2.fastq.gz  \
    "data_analysis/trimmed_trimmomatic/vc/${SAMPLE}_1.fastq.gz" "data_analysis/trimmed_trimmomatic/vc/${SAMPLE}_1U.fastq.gz" \
    "data_analysis/trimmed_trimmomatic/vc/${SAMPLE}_2.fastq.gz" "data_analysis/trimmed_trimmomatic/vc/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT_COMBO}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:50
done

# you can remove unpaired reads to save space:
rm ./data_analysis/trimmed_trimmomatic/*/*U*

# Quality check after cleaning by trimmomati
fastqc -t ${THREADS} -o data_analysis/qc_trim_trimmomatic/tb data_analysis/trimmed_trimmomatic/tb/*_1.fastq.gz data_analysis/trimmed_trimmomatic/tb/*_2.fastq.gz
fastqc -t ${THREADS} -o data_analysis/qc_trim_trimmomatic/vc data_analysis/trimmed_trimmomatic/vc/*_1.fastq.gz data_analysis/trimmed_trimmomatic/vc/*_2.fastq.gz

multiqc data_analysis/qc_trim_trimmomatic/tb -n tb_multiqc_trimmed_trimmomatic.html -o data_analysis/qc_trim_trimmomatic/tb
multiqc data_analysis/qc_trim_trimmomatic/vc -n vc_multiqc_trimmed_trimmomatic.html -o data_analysis/qc_trim_trimmomatic/vc





# Cleaning by fastp (optional)
# TB (length_required 50) + polyG/polyX trimming
for SAMPLE in $(cat data_analysis/tb_IDs); do
  echo "[TB|fastp] ${SAMPLE}"
  fastp -w ${THREADS} \
    -i ${TB_RAW}/${SAMPLE}_1.fastq.gz  -I ${TB_RAW}/${SAMPLE}_2.fastq.gz \
    -o "data_analysis/trimmed_fastp/tb/${SAMPLE}_1.fastq.gz" \
    -O "data_analysis/trimmed_fastp/tb/${SAMPLE}_2.fastq.gz" \
    --detect_adapter_for_pe --trim_poly_g --trim_poly_x \
    --qualified_quality_phred 30 --length_required 50 \
    -h "data_analysis/trimmed_fastp/tb/${SAMPLE}_fastp.html" 
done

# VC (length_required 50) + polyG/polyX trimming
for SAMPLE in $(cat data_analysis/vc_IDs); do
  echo "[VC|fastp] ${SAMPLE}"
  fastp -w ${THREADS} \
    -i ${VC_RAW}/${SAMPLE}_1.fastq.gz  -I ${VC_RAW}/${SAMPLE}_2.fastq.gz \
    -o "data_analysis/trimmed_fastp/vc/${SAMPLE}_1.fastq.gz" \
    -O "data_analysis/trimmed_fastp/vc/${SAMPLE}_2.fastq.gz" \
    --detect_adapter_for_pe --trim_poly_g --trim_poly_x \
    --qualified_quality_phred 30 --length_required 50 \
    -h "data_analysis/trimmed_fastp/vc/${SAMPLE}_fastp.html" 
done

# Quality check after cleaning by fastp
fastqc -t ${THREADS} -o data_analysis/qc_trim_fastp/tb data_analysis/trimmed_fastp/tb/*_1.fastq.gz data_analysis/trimmed_fastp/tb/*_2.fastq.gz
fastqc -t ${THREADS} -o data_analysis/qc_trim_fastp/vc data_analysis/trimmed_fastp/vc/*_1.fastq.gz data_analysis/trimmed_fastp/vc/*_2.fastq.gz

multiqc data_analysis/qc_trim_fastp/tb -n tb_multiqc_trimmed_fastp.html -o data_analysis/qc_trim_fastp/tb
multiqc data_analysis/qc_trim_fastp/vc -n vc_multiqc_trimmed_fastp.html -o data_analysis/qc_trim_fastp/vc




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
# 5) Kraken2 on FASTP-cleaned reads (if DB available) ==="
# TB
for SAMPLE in $(cat data_analysis/tb_IDs); do
 kraken2 --db "$KRAKEN_DB" --threads ${THREADS} \
    --quick --confidence 0.1 --memory-mapping --gzip-compressed --use-names \
    --paired ./data_analysis/trimmed_trimmomatic/tb/${SAMPLE}_1.fastq.gz ./data_analysis/trimmed_trimmomatic/tb/${SAMPLE}_2.fastq.gz \
    --report "data_analysis/kraken2_trimmomatic/tb/${SAMPLE}.report" \
    --output "data_analysis/kraken2_trimmomatic/tb/${SAMPLE}.kraken"
done

# VC
for SAMPLE in $(cat data_analysis/vc_IDs); do
 kraken2 --db "$KRAKEN_DB" --threads ${THREADS} \
  --quick --confidence 0.1 --memory-mapping --gzip-compressed --use-names \
  --paired /data_analysis/trimmed_trimmomatic/vc/${SAMPLE}_1.fastq.gz ./data_analysis/trimmed_trimmomatic/vc/${SAMPLE}_2.fastq.gz \
  --report "data_analysis/kraken2_trimmomatic/vc/${SAMPLE}.report" \
  --output "data_analysis/kraken2_trimmomatic/vc/${SAMPLE}.kraken"
  done

# to visualize the kraken data_analysis use Pavian that is an R/Shiny application. 
# Install R and RStudio. Install Pavian dependencies: Open R and run the following commands.
if (!require(remotes)) {
    install.packages("remotes")
}
remotes::install_github("fbreitwieser/pavian")

# Run Pavian: In R type

library(pavian)
pavian::runApp(port=5000)

This will start a web server and print the address in the console. Paste this address into your web browser to use the application. 
