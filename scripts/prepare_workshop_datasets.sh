#!/usr/bin/env bash
# prepare_workshop_datasets.sh
# Purpose: Fetch small, class-friendly datasets for TB and Vibrio cholerae from ENA
# Author: Arash + ChatGPT helper
# Last updated: 2025-08-21

set -euo pipefail

# ============================ Config (env-overridable) =========================
BASE="${BASE:-$(pwd)/dataset}"

# Species/taxa
TB_TAX="${TB_TAX:-1773}"          # Mycobacterium tuberculosis
VC_TAX="${VC_TAX:-666}"           # Vibrio cholerae

# Selection sizes (defaults: 20 TB + 20 VC split 10/10)
TOTAL_TB="${TOTAL_TB:-20}"        # total TB runs selected
MAX_PER_GROUP="${MAX_PER_GROUP:-10}"  # VC: N per group (clinical + environmental)

# Download control
DOWNLOAD_FASTQS="${DOWNLOAD_FASTQS:-false}"   # "true" to fetch FASTQs
MAX_DOWNLOAD_MB="${MAX_DOWNLOAD_MB:-800}"     # per-run cap for downloads (both mates combined)
MAX_DOWNLOAD_BYTES=$(( MAX_DOWNLOAD_MB * 1024 * 1024 ))

# Fields we fetch from ENA (ORDER MATTERS for downstream AWK)
COMMON_FIELDS="run_accession,sample_accession,country,isolation_source,collection_date,serotype,fastq_ftp,submitted_ftp,base_count"

# Output directories
TB_DIR="${BASE}/tb/short_reads"
VC_DIR="${BASE}/vc/short_reads"
mkdir -p "${TB_DIR}" "${VC_DIR}"

# ============================ Helpers ==========================================
log(){ printf "[%s] %s\n" "$(date +'%H:%M:%S')" "$*"; }
die(){ echo "ERROR: $*" >&2; exit 1; }

# Clean up weird dirs created by earlier buggy runs
cleanup_weird_dirs(){ rm -rf "$1"/Supported\ types\ are* 2>/dev/null || true; }
cleanup_weird_dirs "${VC_DIR}"

# ENA search wrapper
ena_search(){
  # Args: query outfile [fields]
  local query="$1"; local outfile="$2"; local fields="${3:-$COMMON_FIELDS}"
  curl -sG 'https://www.ebi.ac.uk/ena/portal/api/search' \
    --data-urlencode "result=read_run" \
    --data-urlencode "format=tsv" \
    --data-urlencode "limit=5000" \
    --data-urlencode "fields=${fields}" \
    --data-urlencode "query=${query}" \
    > "${outfile}"
}

# Validate TSV header
is_valid_tsv(){
  local f="$1"
  local h; h="$(head -n1 "$f" 2>/dev/null || true)"
  [[ "$h" == run_accession$'\t'* ]]
}

validate_ena_tsv_or_die(){
  local f="$1"
  if ! is_valid_tsv "$f"; then
    echo "---- ENA response (first 15 lines) ----" >&2
    head -n15 "$f" >&2 || true
    echo "---------------------------------------" >&2
    die "Not a valid TSV: $f"
  fi
}

rowcount_no_header(){
  local f="$1"; local n
  n=$(($(wc -l < "$f") - 1)); (( n < 0 )) && n=0
  echo "$n"
}

select_preferring_unique_countries(){
  # Args: infile N outfile
  local in="$1"; local n="$2"; local out="$3"
  local header; header="$(head -n1 "$in")"
  local uniq fill
  uniq="$(mktemp)"; fill="$(mktemp)"
  awk -F'\t' 'NR>1 && $3!="" && !seen[$3]++' "$in" > "$uniq"
  { echo "$header"; head -n "$n" "$uniq"; } > "$out"
  local count=$(( $(wc -l < "$out") - 1 ))
  if (( count < n )); then
    awk 'NR==1{next}1' "$in" | shuf > "$fill"
    head -n $((n-count)) "$fill" >> "$out"
  fi
  rm -f "$uniq" "$fill"
}

append_class_and_header(){
  # Args: infile label outfile
  local in="$1" lab="$2" out="$3"
  awk -F'\t' -v OFS='\t' -v L="$lab" '
    NR==1{ if($NF!="source_class"){print $0,"source_class";next} }
    NR>1{print $0,L}
  ' "$in" > "$out"
}

write_metadata(){
  # Args: runs.tsv (includes source_class)  out.tsv
  local in="$1" out="$2"
  awk -F'\t' -v OFS='\t' '
    NR==1{ for(i=1;i<=NF;i++) idx[$i]=i
           print "run_accession","sample_accession","country","collection_date","serotype","source_class"; next }
    { print $(idx["run_accession"]),$(idx["sample_accession"]),$(idx["country"]),$(idx["collection_date"]),$(idx["serotype"]),$(idx["source_class"]) }
  ' "$in" > "$out"
}

# Progressive query runner: tries queries in order until >=1 row returns
ena_try_sequence(){
  # Args: outfile fields query1 [query2 ...]
  local outfile="$1"; shift
  local fields="$1"; shift
  local q
  for q in "$@"; do
    log "  -> trying: $q"
    ena_search "$q" "$outfile" "$fields"
    if is_valid_tsv "$outfile" && [[ "$(rowcount_no_header "$outfile")" -ge 1 ]]; then
      log "  ✓ got $(rowcount_no_header "$outfile") rows"
      return 0
    fi
  done
  validate_ena_tsv_or_die "$outfile"
}

# Size-capped FASTQ downloader (per-run cap across both mates)
download_fastqs(){
  # Args: runs.tsv outdir
  local runs="$1" dir="$2"; mkdir -p "$dir/fastq"
  local kept=0 skipped=0 kept_bytes=0 skipped_bytes=0

  # Use process substitution (not a pipe) so counters persist
  while IFS= read -r ftp_list; do
      # Split multi-file field by ';'
      IFS=';' read -r -a files <<< "$ftp_list"

      local total_bytes=0
      local -a urls_to_get=()

      for f in "${files[@]}"; do
        # Prefer HTTPS so we can HEAD for Content-Length
        local u="https://${f#ftp://}"
        # HEAD to get size
        local cl
        cl=$(curl -sI "$u" | awk -F': ' 'tolower($1)=="content-length"{print $2}' | tr -d '\r')
        if [[ -n "$cl" && "$cl" =~ ^[0-9]+$ ]]; then
          total_bytes=$(( total_bytes + cl ))
          urls_to_get+=("$u")
        else
          # Unknown size → treat as too large (skip conservatively)
          total_bytes=$(( MAX_DOWNLOAD_BYTES + 1 ))
          urls_to_get+=("$u")
        fi
      done

      if (( total_bytes <= MAX_DOWNLOAD_BYTES )); then
        local mb; mb=$(awk -v b="$total_bytes" 'BEGIN{printf "%.1f", b/1048576}')
        for u in "${urls_to_get[@]}"; do
          log "Downloading $(basename "$u")  [${mb} MB/run]"
          curl -sSfL "$u" -o "$dir/fastq/$(basename "$u")"
        done
        kept=$(( kept + 1 ))
        kept_bytes=$(( kept_bytes + total_bytes ))
      else
        local mb; mb=$(awk -v b="$total_bytes" 'BEGIN{printf "%.1f", b/1048576}')
        log "Skipping run (~${mb} MB) exceeds MAX_DOWNLOAD_MB=${MAX_DOWNLOAD_MB}"
        skipped=$(( skipped + 1 ))
        skipped_bytes=$(( skipped_bytes + total_bytes ))
      fi
    done < <(
      # Emit one line per run with whichever FTP field is populated (prefer fastq_ftp)
      awk -F'\t' '
        NR==1{
          for(i=1;i<=NF;i++) h[$i]=i
          next
        }
        {
          fq   = (h["fastq_ftp"]     ? $(h["fastq_ftp"])     : "")
          subm = (h["submitted_ftp"] ? $(h["submitted_ftp"]) : "")
          if (fq == "" && subm != "") fq = subm
          if (fq != "") print fq
        }
      ' "$runs"
    )

  log "[DL] Kept runs: ${kept}  (~$(awk -v b="$kept_bytes" 'BEGIN{printf "%.1f", b/1048576}') MB total)"
  log "[DL] Skipped runs: ${skipped}  (~$(awk -v b="$skipped_bytes" 'BEGIN{printf "%.1f", b/1048576}') MB total; or size unknown)"
}

# ============================ TB dataset ======================================
tb_prepare(){
  log "[TB] Preparing TB"
  local q='tax_eq('"${TB_TAX}"') AND instrument_platform="ILLUMINA" AND library_strategy="WGS" AND library_layout="PAIRED"'
  local all="$TB_DIR/tb_all.tsv" pick="$TB_DIR/tb_selected.tsv" runs="$TB_DIR/tb_runs.tsv" meta="$TB_DIR/tb_metadata.tsv"

  log "[TB] Querying ENA ..."
  ena_search "$q" "$all"; validate_ena_tsv_or_die "$all"

  log "[TB] Selecting ${TOTAL_TB} runs ..."
  select_preferring_unique_countries "$all" "$TOTAL_TB" "$pick"
  append_class_and_header "$pick" "clinical_or_unknown" "$runs"
  write_metadata "$runs" "$meta"

  if [[ "$DOWNLOAD_FASTQS" == "true" ]]; then
    log "[TB] Downloading FASTQs (<= ${MAX_DOWNLOAD_MB} MB/run) ..."
    download_fastqs "$runs" "$TB_DIR"
  fi

  log "[TB] Done. Files written:"
  printf "%s\n" "$all" "$pick" "$runs" "$meta"
}

# ============================ VC dataset (clinical/env) ========================
vc_prepare(){
  log "[VC] Preparing Vibrio cholerae"

  local fields="$COMMON_FIELDS"
  local clin_all="$VC_DIR/vcholerae_clinical.tsv"
  local env_all="$VC_DIR/vcholerae_environment.tsv"

  # Clinical-like (reliable filters; no %)
  local q_clin_1='tax_eq('"${VC_TAX}"') AND instrument_platform="ILLUMINA" AND library_strategy="WGS" AND library_layout="PAIRED" AND (host_tax_id=9606 OR host="Homo sapiens")'
  local q_clin_2='tax_eq('"${VC_TAX}"') AND instrument_platform="ILLUMINA" AND library_strategy="WGS" AND (host_tax_id=9606 OR host="Homo sapiens")'
  local q_clin_3='tax_eq('"${VC_TAX}"') AND library_strategy="WGS" AND (host_tax_id=9606 OR host="Homo sapiens")'
  local q_clin_4='tax_eq('"${VC_TAX}"') AND library_strategy="WGS" AND (host="human" OR host="patient" OR isolation_source="stool" OR isolation_source="faeces" OR isolation_source="feces")'

  log "[VC] Querying ENA (clinical-like) ..."
  ena_try_sequence "$clin_all" "$fields" "$q_clin_1" "$q_clin_2" "$q_clin_3" "$q_clin_4"

  # Environmental-like (flag first; no wildcards)
  local q_env_1='tax_eq('"${VC_TAX}"') AND instrument_platform="ILLUMINA" AND library_strategy="WGS" AND library_layout="PAIRED" AND environmental_sample=true'
  local q_env_2='tax_eq('"${VC_TAX}"') AND instrument_platform="ILLUMINA" AND library_strategy="WGS" AND environmental_sample=true'
  local q_env_3='tax_eq('"${VC_TAX}"') AND library_strategy="WGS" AND environmental_sample=true'
  local q_env_4='tax_eq('"${VC_TAX}"') AND library_strategy="WGS" AND (isolation_source="water" OR isolation_source="seawater" OR isolation_source="river" OR isolation_source="estuary" OR isolation_source="marine" OR isolation_source="lake" OR isolation_source="wastewater" OR isolation_source="sewage")'

  log "[VC] Querying ENA (environmental-like) ..."
  ena_try_sequence "$env_all" "$fields" "$q_env_1" "$q_env_2" "$q_env_3" "$q_env_4"

  # Select per-group
  local clin_top="$VC_DIR/vc_clinical_${MAX_PER_GROUP}.tsv"
  local env_top="$VC_DIR/vc_environment_${MAX_PER_GROUP}.tsv"
  log "[VC] Selecting ${MAX_PER_GROUP} per group ..."
  select_preferring_unique_countries "$clin_all" "$MAX_PER_GROUP" "$clin_top"
  select_preferring_unique_countries "$env_all" "$MAX_PER_GROUP" "$env_top"

  # Combine & metadata
  local tmpc="$VC_DIR/.tmpc.tsv" tmpe="$VC_DIR/.tmpe.tsv"
  append_class_and_header "$clin_top" "clinical" "$tmpc"
  append_class_and_header "$env_top"  "environmental" "$tmpe"
  { head -n1 "$tmpc"; awk 'NR>1' "$tmpc"; awk 'NR>1' "$tmpe"; } > "$VC_DIR/vc_runs.tsv"
  write_metadata "$VC_DIR/vc_runs.tsv" "$VC_DIR/vc_metadata.tsv"
  rm -f "$tmpc" "$tmpe"

  if [[ "$DOWNLOAD_FASTQS" == "true" ]]; then
    log "[VC] Downloading FASTQs (<= ${MAX_DOWNLOAD_MB} MB/run) ..."
    download_fastqs "$VC_DIR/vc_runs.tsv" "$VC_DIR"
  fi

  log "[VC] Done. Files written:"
  printf "%s\n" "$clin_all" "$env_all" "$clin_top" "$env_top" "$VC_DIR/vc_runs.tsv" "$VC_DIR/vc_metadata.tsv"
}

# ============================ Run all =========================================
main(){
  log "Base directory: $BASE"
  tb_prepare
  vc_prepare
  log "All done."
}
main "$@"
