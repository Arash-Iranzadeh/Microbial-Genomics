#!/usr/bin/env bash
set -euo pipefail
# ===========================================
# QC + Cleaning + Detection (simple & clear)
# - FastQC + MultiQC (raw)
# - Trimmomatic (trim) -> separate outputs
# - fastp (trim)       -> separate outputs
# - FastQC + MultiQC (trimmed by each tool)
# - Build Kraken2 DBs (bacteria + standard)
# - Kraken2 on cleaned reads
# ===========================================

module load fastqc multiqc trimmomatic kraken2
FASTP="/cbio/training/courses/2025/micmet-genomics/fastp"
THREADS=$(nproc)
# Input locations
TB_RAW="/cbio/training/courses/2025/micmet-genomics/Dataset_Mt_Vc/tb/raw_data"
VC_RAW="/cbio/training/courses/2025/micmet-genomics/Dataset_Mt_Vc/vc/raw_data"

# Trimmomatic adapters:
# We combine all adapters
ADAPT_COMBO="/cbio/training/courses/2025/micmet-genomics/timmomatic_adapter_Combo.fa"
mkdir -p "$(dirname "$ADAPT_COMBO")"
if [ ! -s "$ADAPT_COMBO" ]; then
  cat /software/bio/trimmomatic/0.39/adapters/* > "$ADAPT_COMBO"
fi

# Output folders
mkdir -p results/qc_raw/tb results/qc_raw/vc
mkdir -p results/trimmed_trimmomatic/tb results/trimmed_trimmomatic/vc
mkdir -p results/trimmed_fastp/tb results/trimmed_fastp/vc
mkdir -p results/qc_trim_trimmomatic/tb results/qc_trim_trimmomatic/vc
mkdir -p results/qc_trim_fastp/tb results/qc_trim_fastp/vc
mkdir -p results/kraken2_trimmomatic/tb results/kraken2_trimmomatic/vc

# Quality check
# For long read data use longqc:
https://github.com/yfukasawa/LongQC
time1=$SECONDS
echo "=== 1) FastQC on RAW reads + MultiQC ==="
# TB
fastqc -t ${THREADS} -o results/qc_raw/tb ${TB_RAW}/*_1.fastq.gz ${TB_RAW}/*_2.fastq.gz
multiqc results/qc_raw/tb -n tb_multiqc_raw.html -o results/qc_raw/tb
# VC
fastqc -t ${THREADS} -o results/qc_raw/vc ${VC_RAW}/*_1.fastq.gz ${VC_RAW}/*_2.fastq.gz
multiqc results/qc_raw/vc -n vc_multiqc_raw.html -o results/qc_raw/vc

# Data cleaning
# for long read data use:
Guppy: Oxford Nanopore's basecaller which also performs adapter trimming.
Pychopper: A tool to trim and orient Nanopore cDNA reads.
Filtlong: A tool that filters long reads by length and quality, allowing you to select the best reads for downstream analysis.
MinIONQC and NanoPack: A set of tools for quality control and filtering of Nanopore data.
SMRT Link: PacBio's official software for primary analysis (demultiplexing, adapter removal, Consensus Sequences (generation).
echo "=== 2) Trimming with TRIMMOMATIC (saved in results/trimmed_trimmomatic) ==="
# TB (MINLEN 50)
for R1 in ${TB_RAW}/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" "_1.fastq.gz")
  echo "[TB|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    "$R1" "$R2" \
    "results/trimmed_trimmomatic/tb/${SAMPLE}_1P.fastq.gz" "results/trimmed_trimmomatic/tb/${SAMPLE}_1U.fastq.gz" \
    "results/trimmed_trimmomatic/tb/${SAMPLE}_2P.fastq.gz" "results/trimmed_trimmomatic/tb/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT_COMBO}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:50
done

# VC (MINLEN 50)
for R1 in ${VC_RAW}/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" "_1.fastq.gz")
  echo "[VC|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    "$R1" "$R2" \
    "results/trimmed_trimmomatic/vc/${SAMPLE}_1P.fastq.gz" "results/trimmed_trimmomatic/vc/${SAMPLE}_1U.fastq.gz" \
    "results/trimmed_trimmomatic/vc/${SAMPLE}_2P.fastq.gz" "results/trimmed_trimmomatic/vc/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT_COMBO}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:50
done
# To save soace, you can remove unpaired reads:
rm ./results/trimmed_trimmomatic/*/*U*

echo "=== 3) Trimming with FASTP (saved in results/trimmed_fastp) ==="
# TB (length_required 50) + polyG/polyX trimming
for R1 in ${TB_RAW}/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" "_1.fastq.gz")
  echo "[TB|fastp] $SAMPLE"
  ${FASTP} -w ${THREADS} \
    -i "$R1" -I "$R2" \
    -o "results/trimmed_fastp/tb/${SAMPLE}_1P.fastq.gz" \
    -O "results/trimmed_fastp/tb/${SAMPLE}_2P.fastq.gz" \
    --detect_adapter_for_pe --trim_poly_g --trim_poly_x \
    --qualified_quality_phred 30 --length_required 50 \
    -h "results/trimmed_fastp/tb/${SAMPLE}_fastp.html" \
    -j "results/trimmed_fastp/tb/${SAMPLE}_fastp.json"
done

# VC (length_required 50) + polyG/polyX trimming
for R1 in ${VC_RAW}/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" "_1.fastq.gz")
  echo "[VC|fastp] $SAMPLE"
  ${FASTP} -w ${THREADS} \
    -i "$R1" -I "$R2" \
    -o "results/trimmed_fastp/vc/${SAMPLE}_1P.fastq.gz" \
    -O "results/trimmed_fastp/vc/${SAMPLE}_2P.fastq.gz" \
    --detect_adapter_for_pe --trim_poly_g --trim_poly_x \
    --qualified_quality_phred 30 --length_required 50 \
    -h "results/trimmed_fastp/vc/${SAMPLE}_fastp.html" \
    -j "results/trimmed_fastp/vc/${SAMPLE}_fastp.json"
done

echo "=== 4) FastQC on TRIMMED reads + MultiQC (Trimmomatic vs fastp) ==="
# Trimmomatic QC
fastqc -t ${THREADS} -o results/qc_trim_trimmomatic/tb results/trimmed_trimmomatic/tb/*_1P.fastq.gz results/trimmed_trimmomatic/tb/*_2P.fastq.gz
fastqc -t ${THREADS} -o results/qc_trim_trimmomatic/vc results/trimmed_trimmomatic/vc/*_1P.fastq.gz results/trimmed_trimmomatic/vc/*_2P.fastq.gz
multiqc results/qc_trim_trimmomatic/tb -n tb_multiqc_trimmed_trimmomatic.html -o results/qc_trim_trimmomatic/tb
multiqc results/qc_trim_trimmomatic/vc -n vc_multiqc_trimmed_trimmomatic.html -o results/qc_trim_trimmomatic/vc

# fastp QC
fastqc -t ${THREADS} -o results/qc_trim_fastp/tb results/trimmed_fastp/tb/*_1P.fastq.gz results/trimmed_fastp/tb/*_2P.fastq.gz
fastqc -t ${THREADS} -o results/qc_trim_fastp/vc results/trimmed_fastp/vc/*_1P.fastq.gz results/trimmed_fastp/vc/*_2P.fastq.gz
multiqc results/qc_trim_fastp/tb -n tb_multiqc_trimmed_fastp.html -o results/qc_trim_fastp/tb
multiqc results/qc_trim_fastp/vc -n vc_multiqc_trimmed_fastp.html -o results/qc_trim_fastp/vc

time2=$SECONDS
echo "Elapsed time for QC and cleaning of all samples: $(((time2 - time1)/60)) minutes!"

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

KRAKEN_DB="/cbio/training/courses/2025/micmet-genomics/kraken2_db_standard"
time1=$SECONDS
echo "=== 5) Kraken2 on FASTP-cleaned reads (if DB available) ==="
# TB
for R1P in results/trimmed_trimmomatic/tb/*_1P.fastq.gz; do
  R2P=${R1P/_1P.fastq.gz/_2P.fastq.gz}
  SAMPLE=$(basename "$R1P" "_1_1P.fastq.gz")
  echo "[TB|Kraken2] $SAMPLE"
  kraken2 --db "$KRAKEN_DB" --threads ${THREADS} \
    --quick --confidence 0.1 --memory-mapping --gzip-compressed --use-names \
    --paired "$R1P" "$R2P" \
    --report "results/kraken2_trimmomatic/tb/${SAMPLE}.report" \
    --output "results/kraken2_trimmomatic/tb/${SAMPLE}.kraken"
done

# VC
for R1P in results/trimmed_trimmomatic/vc/*_1P.fastq.gz; do
 R2P=${R1P/_1P.fastq.gz/_2P.fastq.gz}
 SAMPLE=$(basename "$R1P" "_1_1P.fastq.gz")
 echo "[VC|Kraken2] $SAMPLE"
 kraken2 --db "$KRAKEN_DB" --threads ${THREADS} \
  --quick --confidence 0.1 --memory-mapping --gzip-compressed --use-names \
  --paired "$R1P" "$R2P" \
  --report "results/kraken2_trimmomatic/vc/${SAMPLE}.report" \
  --output "results/kraken2_trimmomatic/vc/${SAMPLE}.kraken"
  done

time2=$SECONDS
echo "Elapsed time for kraken2 running on all samples: $(((time2 - time1)/60)) minutes!"

echo
echo "=== DONE ==="
echo "Open:"
echo "  RAW MultiQC:                         results/qc_raw/tb/tb_multiqc_raw.html, results/qc_raw/vc/vc_multiqc_raw.html"
echo "  TRIM (Trimmomatic) MultiQC:          results/qc_trim_trimmomatic/*/*.html"
echo "  TRIM (fastp) MultiQC:                results/qc_trim_fastp/*/*.html"
echo "  Kraken2 (Trimmomatic) reports:             results/kraken2_trimmomatic/*/*.report"
