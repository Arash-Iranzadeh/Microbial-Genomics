#!/usr/bin/env bash
set -euo pipefail

# -------- Config (env-overridable) --------
BASE="${BASE:-$(pwd)/dataset}"
VC_TAX="${VC_TAX:-666}"                # Vibrio cholerae
MAX_PER_GROUP="${MAX_PER_GROUP:-10}"   # N clinical + N environmental
DOWNLOAD_FASTQS="${DOWNLOAD_FASTQS:-false}"
FORCE_IPV4="${FORCE_IPV4:-true}"       # add -4 to curl to avoid IPv6 DNS issues

COMMON_FIELDS="run_accession,sample_accession,country,isolation_source,collection_date,serotype,fastq_ftp,submitted_ftp,base_count,sample_attribute"
VC_DIR="${BASE}/vc"
mkdir -p "${VC_DIR}"

log(){ printf "[%s] %s\n" "$(date +'%H:%M:%S')" "$*"; }
die(){ echo "ERROR: $*" >&2; exit 1; }

# Curl opts
CURL_GET_OPTS=( -fsSL --retry 4 --retry-delay 2 --connect-timeout 20 )
if [[ "$FORCE_IPV4" == "true" ]]; then CURL_GET_OPTS=( -4 "${CURL_GET_OPTS[@]}" ); fi

ena_search(){
  local query="$1" outfile="$2" fields="${3:-$COMMON_FIELDS}"
  curl -sG 'https://www.ebi.ac.uk/ena/portal/api/search' \
    --data-urlencode "result=read_run" \
    --data-urlencode "format=tsv" \
    --data-urlencode "limit=5000" \
    --data-urlencode "fields=${fields}" \
    --data-urlencode "query=${query}" \
    > "${outfile}"
}

is_valid_tsv(){ local h; h="$(head -n1 "$1" 2>/dev/null || true)"; [[ "$h" == run_accession$'\t'* ]]; }
validate_or_die(){ is_valid_tsv "$1" || { head -n20 "$1" >&2 || true; die "Not a valid TSV: $1"; }; }

select_unique_country_then_fill(){
  local in="$1" n="$2" out="$3"
  local header; header="$(head -n1 "$in")"
  local uniq fill; uniq="$(mktemp)"; fill="$(mktemp)"
  awk -F'\t' 'NR>1 && $3!="" && !seen[$3]++' "$in" > "$uniq"
  { echo "$header"; head -n "$n" "$uniq"; } > "$out"
  local have=$(( $(wc -l < "$out") - 1 ))
  if (( have < n )); then
    awk 'NR==1{next}1' "$in" | shuf > "$fill"
    head -n $((n-have)) "$fill" >> "$out"
  fi
  rm -f "$uniq" "$fill"
}

append_class_and_header(){
  local in="$1" label="$2" out="$3"
  awk -F'\t' -v OFS='\t' -v L="$label" '
    NR==1{ if($NF!="source_class"){print $0,"source_class";next} }
    NR>1{print $0,L}
  ' "$in" > "$out"
}

write_metadata(){
  local in="$1" out="$2"
  awk -F'\t' -v OFS='\t' '
    NR==1{ for(i=1;i<=NF;i++) h[$i]=i
           print "run_accession","sample_accession","country","collection_date","serotype","source_class"; next }
    { print $(h["run_accession"]),$(h["sample_accession"]),$(h["country"]),$(h["collection_date"]),$(h["serotype"]),$(h["source_class"]) }
  ' "$in" > "$out"
}

# Parse sample_attribute for AMR hints and append 2 columns:
#   reported_amr (free text); reported_ast (true/false)
add_reported_amr_from_sample_attributes(){
  local runs="$1" out="$2"
  awk -F'\t' -v OFS='\t' '
    BEGIN{
      IGNORECASE=1
    }
    NR==1{
      for(i=1;i<=NF;i++) h[$i]=i
      # write header of compact metadata + two AMR columns
      print "run_accession","sample_accession","country","collection_date","serotype","source_class","reported_amr","reported_ast"
      next
    }
    {
      sa = (h["sample_attribute"]?$(h["sample_attribute"]):"")
      amr=""; has=0
      # keep lines that look like phenotype/AST
      if (sa ~ /(antibiotic|antimicrobial|resist|suscept|MIC|AST)/){
        amr = sa
        has = 1
      }
      print $(h["run_accession"]),$(h["sample_accession"]),$(h["country"]),
            $(h["collection_date"]),$(h["serotype"]),$(h["source_class"]),
            amr,(has?"true":"false")
    }
  ' "$runs" > "$out"
}


download_fastqs_simple(){
  local runs="$1" outdir="$2"; mkdir -p "$outdir/fastq"
  awk -F'\t' '
    NR==1{for(i=1;i<=NF;i++) h[$i]=i; next}
    { fq=(h["fastq_ftp"]?$(h["fastq_ftp"]):""); subm=(h["submitted_ftp"]?$(h["submitted_ftp"]):"");
      if(fq=="" && subm!="") fq=subm;
      if(fq!="") print fq; }
  ' "$runs" | while IFS= read -r list; do
    IFS=';' read -r -a files <<< "$list"
    for f in "${files[@]}"; do
      [[ "$f" != http*://* ]] && f="https://${f#ftp://}"
      log "Downloading $(basename "$f")"
      curl "${CURL_GET_OPTS[@]}" "$f" -o "$outdir/fastq/$(basename "$f")"
    done
  done
}

main(){
  log "[VC] Preparing Vibrio cholerae into ${VC_DIR}"

  local clin_all="${VC_DIR}/vcholerae_clinical.tsv"
  local env_all="${VC_DIR}/vcholerae_environment.tsv"

  # No % wildcards; rely on host + environmental flags
  local q_clin='tax_eq('"${VC_TAX}"') AND instrument_platform="ILLUMINA" AND library_strategy="WGS" AND library_layout="PAIRED" AND (host_tax_id=9606 OR host="Homo sapiens")'
  local q_env='tax_eq('"${VC_TAX}"') AND instrument_platform="ILLUMINA" AND library_strategy="WGS" AND library_layout="PAIRED" AND environmental_sample=true'

  log "[VC] Querying ENA (clinical-like) ..."
  ena_search "$q_clin" "$clin_all"; validate_or_die "$clin_all"

  log "[VC] Querying ENA (environmental-like) ..."
  ena_search "$q_env" "$env_all"; validate_or_die "$env_all"

  local clin_top="${VC_DIR}/vc_clinical_${MAX_PER_GROUP}.tsv"
  local env_top="${VC_DIR}/vc_environment_${MAX_PER_GROUP}.tsv"
  log "[VC] Selecting ${MAX_PER_GROUP} per group ..."
  select_unique_country_then_fill "$clin_all" "$MAX_PER_GROUP" "$clin_top"
  select_unique_country_then_fill "$env_all"  "$MAX_PER_GROUP" "$env_top"

  # Merge & annotate
  local tmpc="${VC_DIR}/.tmpc.tsv" tmpe="${VC_DIR}/.tmpe.tsv"
  append_class_and_header "$clin_top" "clinical" "$tmpc"
  append_class_and_header "$env_top"  "environmental" "$tmpe"
  { head -n1 "$tmpc"; awk 'NR>1' "$tmpc"; awk 'NR>1' "$tmpe"; } > "${VC_DIR}/vc_runs.tsv"
  write_metadata "${VC_DIR}/vc_runs.tsv" "${VC_DIR}/vc_metadata.tsv"
  add_reported_amr_from_sample_attributes "${VC_DIR}/vc_runs.tsv" "${VC_DIR}/vc_metadata_plus_amr.tsv"
  rm -f "$tmpc" "$tmpe"

  if [[ "$DOWNLOAD_FASTQS" == "true" ]]; then
    log "[VC] Downloading FASTQs (no size cap) ..."
    download_fastqs_simple "${VC_DIR}/vc_runs.tsv" "$VC_DIR"
  fi

  log "[VC] Done."
}
main "$@"
