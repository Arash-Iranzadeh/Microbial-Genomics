#!/usr/bin/env bash
set -euo pipefail

# ===========================================
# QC + Cleaning + Detection (simple & clear)
# - FastQC + MultiQC (raw)
# - Trimmomatic (trim) -> separate outputs
# - fastp (trim)       -> separate outputs
# - FastQC + MultiQC (trimmed by each tool)
# - Build Kraken2 DBs (bacteria + standard)
# - Kraken2 on fastp-cleaned reads
# - Build KmerFinder DBs (bacteria + all)
# - (Example) KmerFinder on fastp-cleaned reads
# ===========================================

THREADS=32

# Input locations
TB_RAW="data/tb/raw_data"
VC_RAW="data/vc/raw_data"

# Trimmomatic adapters:
# We combine Nextera + TruSeq3 (you saw both in MultiQC).
ADAPT_COMBO="$HOME/adapters/Combo_Nextera_TruSeq3_PE.fa"
mkdir -p "$(dirname "$ADAPT_COMBO")"
if [ ! -s "$ADAPT_COMBO" ]; then
  cat /software/bio/trimmomatic/0.39/adapters/NexteraPE-PE.fa \
      /software/bio/trimmomatic/0.39/adapters/TruSeq3-PE.fa \
      > "$ADAPT_COMBO"
fi

# Output folders
mkdir -p results/qc_raw/tb results/qc_raw/vc
mkdir -p results/trimmed_trimmomatic/tb results/trimmed_trimmomatic/vc
mkdir -p results/trimmed_fastp/tb results/trimmed_fastp/vc
mkdir -p results/qc_trim_trimmomatic/tb results/qc_trim_trimmomatic/vc
mkdir -p results/qc_trim_fastp/tb results/qc_trim_fastp/vc
mkdir -p results/kraken2_fastp/tb results/kraken2_fastp/vc
mkdir -p results/kmerfinder/tb results/kmerfinder/vc

echo "=== 1) FastQC on RAW reads + MultiQC ==="
# TB
fastqc -t ${THREADS} -o results/qc_raw/tb ${TB_RAW}/*_1.fastq.gz ${TB_RAW}/*_2.fastq.gz
multiqc results/qc_raw/tb -n tb_multiqc_raw.html -o results/qc_raw/tb
# VC
fastqc -t ${THREADS} -o results/qc_raw/vc ${VC_RAW}/*_1.fastq.gz ${VC_RAW}/*_2.fastq.gz
multiqc results/qc_raw/vc -n vc_multiqc_raw.html -o results/qc_raw/vc

echo "=== 2) Trimming with TRIMMOMATIC (saved in results/trimmed_trimmomatic) ==="
# TB (MINLEN 50)
for R1 in ${TB_RAW}/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[TB|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    "$R1" "$R2" \
    "results/trimmed_trimmomatic/tb/${SAMPLE}_1P.fastq.gz" "results/trimmed_trimmomatic/tb/${SAMPLE}_1U.fastq.gz" \
    "results/trimmed_trimmomatic/tb/${SAMPLE}_2P.fastq.gz" "results/trimmed_trimmomatic/tb/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT_COMBO}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:50
done

# VC (MINLEN 36)
for R1 in ${VC_RAW}/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[VC|Trimmomatic] $SAMPLE"
  trimmomatic PE -threads ${THREADS} -phred33 \
    "$R1" "$R2" \
    "results/trimmed_trimmomatic/vc/${SAMPLE}_1P.fastq.gz" "results/trimmed_trimmomatic/vc/${SAMPLE}_1U.fastq.gz" \
    "results/trimmed_trimmomatic/vc/${SAMPLE}_2P.fastq.gz" "results/trimmed_trimmomatic/vc/${SAMPLE}_2U.fastq.gz" \
    ILLUMINACLIP:"${ADAPT_COMBO}":2:30:10 SLIDINGWINDOW:4:20 LEADING:3 TRAILING:3 MINLEN:36
done

echo "=== 3) Trimming with FASTP (saved in results/trimmed_fastp) ==="
# TB (length_required 50) + polyG/polyX trimming
for R1 in ${TB_RAW}/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[TB|fastp] $SAMPLE"
  fastp -w ${THREADS} \
    -i "$R1" -I "$R2" \
    -o "results/trimmed_fastp/tb/${SAMPLE}_1P.fastq.gz" \
    -O "results/trimmed_fastp/tb/${SAMPLE}_2P.fastq.gz" \
    --detect_adapter_for_pe --trim_poly_g --trim_poly_x \
    --qualified_quality_phred 20 --length_required 50 \
    -h "results/trimmed_fastp/tb/${SAMPLE}_fastp.html" \
    -j "results/trimmed_fastp/tb/${SAMPLE}_fastp.json"
done

# VC (length_required 36) + polyG/polyX trimming
for R1 in ${VC_RAW}/*_1.fastq.gz; do
  [ -e "$R1" ] || continue
  R2=${R1/_1.fastq.gz/_2.fastq.gz}
  SAMPLE=$(basename "$R1" | sed 's/_1\.fastq\.gz//')
  echo "[VC|fastp] $SAMPLE"
  fastp -w ${THREADS} \
    -i "$R1" -I "$R2" \
    -o "results/trimmed_fastp/vc/${SAMPLE}_1P.fastq.gz" \
    -O "results/trimmed_fastp/vc/${SAMPLE}_2P.fastq.gz" \
    --detect_adapter_for_pe --trim_poly_g --trim_poly_x \
    --qualified_quality_phred 20 --length_required 36 \
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

# ===========================================
# DB BUILDING + DETECTION
# ===========================================

echo "=== 5) Build Kraken2 databases (optional but included here) ==="
# A) Bacteria-only DB
if [ ! -f ./kraken2_db_bacteria/hash.k2d ]; then
  echo "[Kraken2] Preparing bacteria-only DB at ./kraken2_db_bacteria (this may take time)"
  kraken2-build --download-taxonomy --db ./kraken2_db_bacteria
  kraken2-build --download-library bacteria --threads ${THREADS} --db ./kraken2_db_bacteria
  kraken2-build --build --threads ${THREADS} --db ./kraken2_db_bacteria
fi

# B) Standard DB (prepackaged helper; also takes time/disk)
if [ ! -f ./kraken2_db_standard/hash.k2d ]; then
  echo "[Kraken2] Preparing STANDARD DB at ./kraken2_db_standard (large; may take hours)"
  kraken2-build --standard --threads ${THREADS} --db ./kraken2_db_standard
fi

# Choose which DB to use (prefer standard if built)
if [ -f ./kraken2_db_standard/hash.k2d ]; then
  KRAKEN_DB="./kraken2_db_standard"
elif [ -f ./kraken2_db_bacteria/hash.k2d ]; then
  KRAKEN_DB="./kraken2_db_bacteria"
else
  KRAKEN_DB=""
fi

if [ -n "$KRAKEN_DB" ]; then
  echo "Using Kraken2 DB: $KRAKEN_DB"
else
  echo "No Kraken2 DB available; skipping Kraken classification."
fi

echo "=== 6) Kraken2 on FASTP-cleaned reads (if DB available) ==="
if [ -n "$KRAKEN_DB" ]; then
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
fi

echo "=== 7) Build KmerFinder databases (bacteria + all) ==="
# Your commands, with light timing around them
echo "Making KmerFinder bacterial database ..."
t1=$SECONDS
mkdir -p /scratch3/users/arash/Kmer_bacterial_database
KmerFinder_DB="/scratch3/users/arash/Kmer_bacterial_database"
cd /users/arash/tools/kmerfinder_db/
bash INSTALL.sh "$KmerFinder_DB" bacteria latest
t2=$SECONDS
echo "Elapsed time for KmerFinder bacteria database: $((t2 - t1)) seconds!"

echo "Making KmerFinder ALL database ..."
t1=$SECONDS
mkdir -p /scratch3/users/arash/Kmer_all_database
KmerFinder_DB_ALL="/scratch3/users/arash/Kmer_all_database"
cd /users/arash/tools/kmerfinder_db/
bash INSTALL.sh "$KmerFinder_DB_ALL" all
t2=$SECONDS
echo "Elapsed time for KmerFinder all database: $((t2 - t1)) seconds!"
cd - >/dev/null

echo "=== 8) (Example) Run KmerFinder on FASTP-cleaned reads ==="
# NOTE:
#  - The exact CLI may vary (kmerfinder.py vs wrapper). Adjust as needed.
#  - Many installations accept: kmerfinder.py -i "R1,R2" -db <DB> -o <OUTDIR>
#  - We show bacteria DB for speed; switch to $KmerFinder_DB_ALL if you want everything.

for R1P in results/trimmed_fastp/tb/*_1P.fastq.gz; do
  [ -e "$R1P" ] || continue
  R2P=${R1P/_1P.fastq.gz/_2P.fastq.gz}
  SAMPLE=$(basename "$R1P" | sed 's/_1P\.fastq\.gz//')
  OUTDIR="results/kmerfinder/tb/${SAMPLE}"
  mkdir -p "$OUTDIR"
  echo "[TB|KmerFinder] $SAMPLE  ->  $OUTDIR"
  # Replace 'kmerfinder.py' with the actual executable on your system if different
  # Common pattern (adjust flags if your version differs):
  kmerfinder.py -i "${R1P},${R2P}" -db "/scratch3/users/arash/Kmer_bacterial_database" -o "$OUTDIR" || true
done

for R1P in results/trimmed_fastp/vc/*_1P.fastq.gz; do
  [ -e "$R1P" ] || continue
  R2P=${R1P/_1P.fastq.gz/_2P.fastq.gz}
  SAMPLE=$(basename "$R1P" | sed 's/_1P\.fastq\.gz//')
  OUTDIR="results/kmerfinder/vc/${SAMPLE}"
  mkdir -p "$OUTDIR"
  echo "[VC|KmerFinder] $SAMPLE  ->  $OUTDIR"
  kmerfinder.py -i "${R1P},${R2P}" -db "/scratch3/users/arash/Kmer_bacterial_database" -o "$OUTDIR" || true
done

echo
echo "=== DONE ==="
echo "Open:"
echo "  RAW MultiQC:                         results/qc_raw/tb/tb_multiqc_raw.html, results/qc_raw/vc/vc_multiqc_raw.html"
echo "  TRIM (Trimmomatic) MultiQC:          results/qc_trim_trimmomatic/*/*.html"
echo "  TRIM (fastp) MultiQC:                results/qc_trim_fastp/*/*.html"
echo "  Kraken2 (fastp) reports:             results/kraken2_fastp/*/*.report"
echo "  KmerFinder outputs:                  results/kmerfinder/*/* (per-sample folders)"
