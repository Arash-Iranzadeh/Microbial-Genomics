#!/usr/bin/env bash

# Simple QC + Cleaning + Species ID
# Tools: FastQC, MultiQC, Trimmomatic, fastp, Kraken2
# Data:
#   data/tb/raw_data/*_1.fastq.gz and *_2.fastq.gz
#   data/vc/raw_data/*_1.fastq.gz and *_2.fastq.gz
# Results go under results/

THREADS=32
ADAPT="/software/bio/trimmomatic/0.39/adapters/TruSeq3-PE.fa"   # Trimmomatic adapters

# Set KRAKEN_DB if you already have one; otherwise we will fetch MiniKraken2 (~8 GB)
KRAKEN_DB="${KRAKEN_DB:-}"

# Make folders
mkdir -p results/qc_raw/tb results/qc_raw/vc
mkdir -p results/trimmed_trimmomatic/tb results/trimmed_trimmomatic/vc
mkdir -p results/trimmed_fastp/tb results/trimmed_fastp/vc
mkdir -p results/qc_trim_trimmomatic/tb results/qc_trim_trimmomatic/vc
mkdir -p results/qc_trim_fastp/tb results/qc_trim_fastp/vc
mkdir -p results/kraken2_fastp/tb results/kraken2_fastp/vc

echo "=== 1) FastQC on RAW reads + MultiQC ==="
# TB
fastqc -t ${THREADS} -o results/qc_raw/tb data/tb/raw_data/*_1.fastq.gz data/tb/raw_data/*_2.fastq.gz
multiqc results/qc_raw/tb -n tb_multiqc_raw.html -o results/qc_raw/tb
# VC
fastqc -t ${THREADS} -o results/qc_raw/vc data/vc/raw_data/*_1.fastq.gz data/vc/raw_data/*_2.fastq.gz
multiqc results/qc_raw/vc -n vc_multiqc_raw.html -o results/qc_raw/vc

echo "=== 2) Trimming with TRIMMOMATIC (saved under results/trimmed_trimmomatic) ==="
# TB (MINLEN 50)
for R1 in data/tb/raw_data/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[TB|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    "$R1" "$R2" \
    "results/trimmed_trimmomatic/tb/${SAMPLE}_1P.fastq.gz" "results/trimmed_trimmomatic/tb/${SAMPLE}_1U.fastq.gz" \
    "results/trimmed_trimmomatic/tb/${SAMPLE}_2P.fastq.gz" "results/trimmed_trimmomatic/tb/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:50
done

# VC (MINLEN 36)
for R1 in data/vc/raw_data/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[VC|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    "$R1" "$R2" \
    "results/trimmed_trimmomatic/vc/${SAMPLE}_1P.fastq.gz" "results/trimmed_trimmomatic/vc/${SAMPLE}_1U.fastq.gz" \
    "results/trimmed_trimmomatic/vc/${SAMPLE}_2P.fastq.gz" "results/trimmed_trimmomatic/vc/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:36
done

echo "=== 3) Trimming with FASTP (saved under results/trimmed_fastp) ==="
# TB (length_required 50)
for R1 in data/tb/raw_data/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[TB|fastp] $SAMPLE"
  fastp -w ${THREADS} \
    -i "$R1" -I "$R2" \
    -o "results/trimmed_fastp/tb/${SAMPLE}_1P.fastq.gz" \
    -O "results/trimmed_fastp/tb/${SAMPLE}_2P.fastq.gz" \
    --detect_adapter_for_pe --qualified_quality_phred 20 --length_required 50 \
    -h "results/trimmed_fastp/tb/${SAMPLE}_fastp.html" \
    -j "results/trimmed_fastp/tb/${SAMPLE}_fastp.json"
done

# VC (length_required 36)
for R1 in data/vc/raw_data/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[VC|fastp] $SAMPLE"
  fastp -w ${THREADS} \
    -i "$R1" -I "$R2" \
    -o "results/trimmed_fastp/vc/${SAMPLE}_1P.fastq.gz" \
    -O "results/trimmed_fastp/vc/${SAMPLE}_2P.fastq.gz" \
    --detect_adapter_for_pe --qualified_quality_phred 20 --length_required 36 \
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

echo "=== 5) Kraken2 database check / setup (MiniKraken2 if needed) ==="
if [ -z "$KRAKEN_DB" ] || [ ! -f "$KRAKEN_DB/hash.k2d" ]; then
  echo "No valid KRAKEN_DB set. Downloading MiniKraken2 (8 GB) to \$HOME/kraken2_db ..."
  DBROOT="$HOME/kraken2_db"
  URL="https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904.tgz"
  mkdir -p "$DBROOT"
  cd "$DBROOT"
  if [ ! -f "$(basename "$URL")" ]; then
    wget "$URL"
  fi
  tar -xzf "$(basename "$URL")"
  KRAKEN_DB="$DBROOT/minikraken2_v2_8GB_201904"
  cd - >/dev/null
fi

echo "Using Kraken2 DB: $KRAKEN_DB"
if [ ! -f "$KRAKEN_DB/hash.k2d" ]; then
  echo "Kraken2 DB not found or incomplete at: $KRAKEN_DB"
  echo "Skipping Kraken step."
  exit 0
fi

echo "=== 6) Kraken2 on FASTP-cleaned reads only ==="
# TB
for R1P in results/trimmed_fastp/tb/*_1P.fastq.gz; do
  [ -e "$R1P" ] || continue
  R2P=${R1P/_1P.fastq.gz/_2P.fastq.gz}
  SAMPLE=$(basename "$R1P" | sed 's/_1P\.fastq\.gz//')
  echo "[TB|Kraken2] $SAMPLE"
  kraken2 --db "$KRAKEN_DB" --threads ${THREADS} \
    --paired "$R1P" "$R2P" \
    --report "results/kraken2_fastp/tb/${SAMPLE}.report" \
    --output "results/kraken2_fastp/tb/${SAMPLE}.kraken"
done

# VC
for R1P in results/trimmed_fastp/vc/*_1P.fastq.gz; do
  [ -e "$R1P" ] || continue
  R2P=${R1P/_1P.fastq.gz/_2P.fastq.gz}
  SAMPLE=$(basename "$R1P" | sed 's/_1P\.fastq\.gz//')
  echo "[VC|Kraken2] $SAMPLE"
  kraken2 --db "$KRAKEN_DB" --threads ${THREADS} \
    --paired "$R1P" "$R2P" \
    --report "results/kraken2_fastp/vc/${SAMPLE}.report" \
    --output "results/kraken2_fastp/vc/${SAMPLE}.kraken"
done

echo
echo "=== Done. Open these reports: ==="
echo "  RAW MultiQC:           results/qc_raw/tb/tb_multiqc_raw.html, results/qc_raw/vc/vc_multiqc_raw.html"
echo "  TRIM (Trimmomatic):    results/qc_trim_trimmomatic/*/*.html"
echo "  TRIM (fastp):          results/qc_trim_fastp/*/*.html"
echo "  Kraken2 (fastp only):  results/kraken2_fastp/*/*.report"

