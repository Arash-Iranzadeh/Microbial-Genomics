#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Pathogen Genomics Workshop Dataset Orchestrator (DE-DUP SAFE)
# - TB (20): balanced DS/MDR/preXDR/XDR from CRyPTIC reuse table
# - V. cholerae (20): 10 clinical + 10 environmental, global
# - Optional downsampling to ~30× coverage (seqtk)
# Base directory: ./bacterial_genomics (under current working directory)
# Usage:
#   bash prepare_workshop_datasets.sh
#   bash prepare_workshop_datasets.sh --downsample
# ==============================================================================

BASE="${PWD}/bacterial_genomics"   # <— use current directory
TB_DIR="${BASE}/tb/short_reads"
VC_DIR="${BASE}/vc/short_reads"
THREADS_ENA=4
DS_SEED=100
TB_GENOME_SIZE=4400000
VC_GENOME_SIZE=4000000
CRyPTIC_URL="https://ftp.ebi.ac.uk/pub/databases/cryptic/release_june2022/reuse/CRyPTIC_reuse_table_20231208.csv"

mkdir -p "${TB_DIR}" "${VC_DIR}"

need_bin() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' not found."; exit 1; }; }

ensure_tools() {
  for b in curl awk xargs python3 gzip wget; do need_bin "$b"; done
  command -v dos2unix >/dev/null 2>&1 || true
}

ensure_enabrowser() {
  if ! command -v enaDataGet >/dev/null 2>&1; then
    echo "[*] Installing enaBrowserTools locally..."
    ( cd "${BASE}" && git clone https://github.com/enasequence/enaBrowserTools.git >/dev/null 2>&1 || true )
    export PATH="${BASE}/enaBrowserTools/python3:${PATH}"
  fi
}

# Helper: check if a RUN already has paired FASTQs anywhere under the dataset dir
have_run_pairs() {
  local run="$1"
  local d="$2"
  local f1 f2
  f1=$(find "${d}" -type f -regex ".*/${run}.*_1\.fastq\.gz" | head -n1 || true)
  f2=$(find "${d}" -type f -regex ".*/${run}.*_2\.fastq\.gz" | head -n1 || true)
  [[ -n "${f1}" && -n "${f2}" ]]
}

# Helper: download one RUN safely (enaDataGet first, wget fallback into per-RUN dir)
download_run_safe() {
  local run="$1"
  local tsv="$2"
  local dstdir="$3"
  mkdir -p "${dstdir}/${run}"
  # Try enaDataGet (if present)
  if command -v enaDataGet >/dev/null 2>&1; then
    enaDataGet -f fastq "${run}" >/dev/null 2>&1 || true
  fi
  # If we still don't have both mates, wget just this run's URLs into its folder
  if ! have_run_pairs "${run}" "${dstdir}"; then
    # extract fastq_ftp or submitted_ftp for this run
    awk -F'\t' -v r="${run}" 'NR>1 && $1==r{
      urls=$6; if(urls=="") urls=$7;
      n=split(urls,a,";");
      for(i=1;i<=n;i++) if(a[i]!="") print "https://"a[i]
    }' "${tsv}" | while read -r url; do
      ( cd "${dstdir}/${run}" && wget -q --show-progress -nc "${url}" )
    done
  fi
}

# ---------------------- TB: Select 20 samples from CRyPTIC ---------------------
tb_select_from_cryptic() {
  cd "${TB_DIR}"
  echo "[TB] Downloading CRyPTIC reuse table..."
  curl -L -o CRyPTIC_reuse.csv "${CRyPTIC_URL}"

  echo "[TB] Selecting 5 DS, 5 MDR, 5 preXDR, 5 XDR..."
  python3 - <<'PY'
import csv, random, sys
random.seed(7)
def g(row,drug): return (row.get(f"{drug}_BINARY_PHENOTYPE","") or "").strip().upper()
drugs = ['AMI','BDQ','CFZ','DLM','EMB','ETH','INH','KAN','LEV','LZD','MXF','RIF','RFB']
DS, MDR, PRX, XDR = [], [], [], []
with open('CRyPTIC_reuse.csv', newline='') as f:
    r = csv.DictReader(f)
    for row in r:
        ena = (row.get('ENA_SAMPLE') or '').strip()
        if not ena: continue
        vals = [g(row,d) for d in drugs if row.get(f"{d}_BINARY_PHENOTYPE") is not None]
        INH, RIF = g(row,'INH'), g(row,'RIF')
        LEV, MXF = g(row,'LEV'), g(row,'MXF')
        BDQ, LZD = g(row,'BDQ'), g(row,'LZD')
        if vals and all(v=='S' for v in vals if v): DS.append(ena); continue
        if (INH=='R' and RIF=='R') and (LEV=='R' or MXF=='R') and (BDQ=='R' or LZD=='R'): XDR.append(ena); continue
        if (INH=='R' and RIF=='R') and (LEV=='R' or MXF=='R') and not (BDQ=='R' or LZD=='R'): PRX.append(ena); continue
        if (INH=='R' and RIF=='R') and not (LEV=='R' or MXF=='R'): MDR.append(ena); continue
def pick(L,k): random.shuffle(L); return list(dict.fromkeys(L))[:k]
sel_DS  = pick(DS,5); sel_MDR = pick(MDR,5); sel_PRX = pick(PRX,5); sel_XDR = pick(XDR,5)
sel = sel_DS + sel_MDR + sel_PRX + sel_XDR
open('tb_ena_samples.txt','w').write("\n".join(sel)+"\n")
with open('tb_phen_map.tsv','w',newline='') as out:
    w=csv.writer(out,delimiter='\t'); w.writerow(['sample_accession','phenotype'])
    for s in sel:
        p = 'DS' if s in sel_DS else 'MDR' if s in sel_MDR else 'preXDR' if s in sel_PRX else 'XDR'
        w.writerow([s,p])
print(f"Selected: DS={len(sel_DS)} MDR={len(sel_MDR)} preXDR={len(sel_PRX)} XDR={len(sel_XDR)} total={len(sel)}", file=sys.stderr)
PY

  echo "[TB] Selection summary:"
  wc -l tb_ena_samples.txt | awk '{print "  samples:",$1}'
  echo "  breakdown:"
  cut -f2 tb_phen_map.tsv | tail -n +2 | sort | uniq -c | sed 's/^/    /'
}

# ---------------------- TB: Build run table & download (de-dup safe) ----------
tb_fetch_runs_and_reads() {
  cd "${TB_DIR}"
  [ -f tb_ena_samples.txt ] || { echo "[TB] ERROR: tb_ena_samples.txt missing."; exit 1; }
  command -v dos2unix >/dev/null 2>&1 && dos2unix tb_ena_samples.txt || true

  OUT_TSV="tb_runs.tsv"
  echo -e "run_accession\tsample_accession\tcountry\tcollection_date\tlibrary_layout\tfastq_ftp\tsubmitted_ftp\tbase_count" > "${OUT_TSV}"

  echo "[TB] Resolving runs from ENA (GET; sample_accession OR secondary_sample_accession)..."
  while read -r S; do
    [ -z "${S}" ] && continue
    curl -sG 'https://www.ebi.ac.uk/ena/portal/api/search' \
      --data-urlencode "result=read_run" \
      --data-urlencode "format=tsv" \
      --data-urlencode "fields=run_accession,sample_accession,country,collection_date,library_layout,fastq_ftp,submitted_ftp,base_count" \
      --data-urlencode "query=(sample_accession=\"${S}\" OR secondary_sample_accession=\"${S}\")" \
    | awk 'NR==1{next}1' >> "${OUT_TSV}"
  done < tb_ena_samples.txt

  echo "[TB] Rows in tb_runs.tsv (incl header): $(wc -l < "${OUT_TSV}")"
  [ "$(wc -l < "${OUT_TSV}")" -gt 1 ] || { echo "[TB] ERROR: No runs found."; exit 1; }

  ensure_enabrowser
  echo "[TB] Downloading FASTQs per-run (no duplicates)..."
  # Loop runs and download each safely
  awk -F'\t' 'NR>1{print $1}' "${OUT_TSV}" | sort -u | while read -r RUN; do
    if have_run_pairs "${RUN}" "${TB_DIR}"; then
      echo "[TB] ${RUN} already present — skipping."
    else
      download_run_safe "${RUN}" "${OUT_TSV}" "${TB_DIR}"
    fi
  done

  echo "[TB] Writing tb_metadata.tsv (join with phenotype labels)..."
  python3 - <<'PY'
import csv
phen={r['sample_accession']:r['phenotype'] for r in csv.DictReader(open('tb_phen_map.tsv'),delimiter='\t')}
rows=list(csv.DictReader(open('tb_runs.tsv'),delimiter='\t'))
fields=list(rows[0].keys())+['phenotype']
w=csv.DictWriter(open('tb_metadata.tsv','w',newline=''),delimiter='\t',fieldnames=fields)
w.writeheader()
for r in rows:
    r['phenotype']=phen.get(r['sample_accession'],'')
    w.writerow(r)
PY
}

# ---------------------- VC: Select, build run table & download (de-dup safe) ---
vc_select_fetch_and_download() {
  cd "${VC_DIR}"
  FIELDS="run_accession,sample_accession,country,isolation_source,collection_date,serotype,fastq_ftp,submitted_ftp,base_count"

  echo "[VC] Querying ENA for clinical-like runs..."
  CLIN_QUERY='result=read_run&format=tsv&limit=5000&query=tax_eq(666)%20AND%20instrument_platform%3DILLUMINA%20AND%20library_strategy%3DWGS%20AND%20library_layout%3DPAIRED%20AND%20(isolation_source%20LIKE%20%22stool%25%22%20OR%20isolation_source%20LIKE%20%22human%25%22%20OR%20isolation_source%20LIKE%20%22patient%25%22)'
  curl -sG 'https://www.ebi.ac.uk/ena/portal/api/search' --data-urlencode "${CLIN_QUERY}" --data-urlencode "fields=${FIELDS}" > vcholerae_clinical.tsv

  echo "[VC] Querying ENA for environmental-like runs..."
  ENV_QUERY='result=read_run&format=tsv&limit=5000&query=tax_eq(666)%20AND%20instrument_platform%3DILLUMINA%20AND%20library_strategy%3DWGS%20AND%20library_layout%3DPAIRED%20AND%20(environmental_sample%3Dtrue%20OR%20isolation_source%20LIKE%20%22water%25%22%20OR%20isolation_source%20LIKE%20%22seawater%25%22%20OR%20isolation_source%20LIKE%20%22river%25%22%20OR%20isolation_source%20LIKE%20%22estuary%25%22)'
  curl -sG 'https://www.ebi.ac.uk/ena/portal/api/search' --data-urlencode "${ENV_QUERY}"  --data-urlencode "fields=${FIELDS}" > vcholerae_environment.tsv

  echo "[VC] Selecting 10 per group, preferring unique countries..."
  {
    head -n1 vcholerae_clinical.tsv
    awk -F'\t' 'NR>1 && $3!="" && !seen[$3]++' vcholerae_clinical.tsv | head -n 10
  } > vc_clinical_10.tsv
  CLN=$(($(wc -l < vc_clinical_10.tsv)-1))
  if [ "${CLN}" -lt 10 ]; then
    awk 'NR==1{next}1' vcholerae_clinical.tsv | shuf | head -n $((10-CLN)) >> vc_clinical_10.tsv
  fi

  {
    head -n1 vcholerae_environment.tsv
    awk -F'\t' 'NR>1 && $3!="" && !seen[$3]++' vcholerae_environment.tsv | head -n 10
  } > vc_environment_10.tsv
  ENVN=$(($(wc -l < vc_environment_10.tsv)-1))
  if [ "${ENVN}" -lt 10 ]; then
    awk 'NR==1{next}1' vcholerae_environment.tsv | shuf | head -n $((10-ENVN)) >> vc_environment_10.tsv
  fi

  echo "[VC] Merging selections & annotating source_class..."
  {
    head -n1 vc_clinical_10.tsv | awk '{print $0"\tsource_class"}'
    awk 'NR>1{print $0"\tclinical"}' vc_clinical_10.tsv
    awk 'NR>1{print $0"\tenvironmental"}' vc_environment_10.tsv
  } > vc_runs.tsv

  echo "[VC] Downloading FASTQs per-run (no duplicates)..."
  ensure_enabrowser
  awk -F'\t' 'NR>1{print $1}' vc_runs.tsv | sort -u | while read -r RUN; do
    if have_run_pairs "${RUN}" "${VC_DIR}"; then
      echo "[VC] ${RUN} already present — skipping."
    else
      download_run_safe "${RUN}" "vc_runs.tsv" "${VC_DIR}"
    fi
  done

  echo "[VC] Writing vc_metadata.tsv..."
  awk -F'\t' 'NR==1{print "run_accession\tsample_accession\tcountry\tcollection_date\tserotype\tsource_class"; next}{print $1"\t"$2"\t"$3"\t"$5"\t"$6"\t"$9}' vc_runs.tsv > vc_metadata.tsv
}

# ---------------------- Optional downsampling (~30×) ---------------------------
downsample_30x() {
  local ddir="$1"; local meta="$2"; local gsize="$3"
  echo "[DS] Downsampling in: ${ddir} (genome size=${gsize})"
  cd "${ddir}"
  need_bin seqtk
  awk -F'\t' -v GS="${gsize}" 'NR>1 && $8 ~ /^[0-9]+$/ {frac=(30*GS)/$8; if(frac>1) frac=1; if(frac<=0) frac=0.01; print $1"\t"frac}' "${meta}" > fractions.tsv
  echo "[DS] Fractions for $(wc -l < fractions.tsv) runs."
  while IFS=$'\t' read -r RUN FRAC; do
    f1=$(find . -type f -regex ".*/${RUN}.*_1\.fastq\.gz" | head -n1 || true)
    f2=$(find . -type f -regex ".*/${RUN}.*_2\.fastq\.gz" | head -n1 || true)
    if [ -z "${f1}" ] || [ -z "${f2}" ]; then echo "[DS] Skipping ${RUN} (pairs not found)."; continue; fi
    echo "[DS] ${RUN} -> fraction=${FRAC}"
    seqtk sample -s"${DS_SEED}" "${f1}" "${FRAC}" | gzip > "$(dirname "${f1}")/${RUN}.ds_1.fastq.gz"
    seqtk sample -s"${DS_SEED}" "${f2}" "${FRAC}" | gzip > "$(dirname "${f2}")/${RUN}.ds_2.fastq.gz"
  done < fractions.tsv
  echo "[DS] Done in ${ddir}"
}

# ================================== MAIN ======================================
ensure_tools

echo "[*] Base dir: ${BASE}"
echo "[*] Preparing TB dataset..."
tb_select_from_cryptic
tb_fetch_runs_and_reads

echo "[*] Preparing V. cholerae dataset..."
vc_select_fetch_and_download

if [[ "${1:-}" == "--downsample" ]]; then
  echo "[*] Downsampling to ~30×..."
  downsample_30x "${TB_DIR}" "${TB_DIR}/tb_runs.tsv" "${TB_GENOME_SIZE}"
  downsample_30x "${VC_DIR}" "${VC_DIR}/vc_runs.tsv" "${VC_GENOME_SIZE}"
fi

echo
echo "=== Summary ==="
echo "TB:"
echo "  - FASTQs under: ${TB_DIR}/<RUN>/*fastq.gz"
echo "  - Run table:    ${TB_DIR}/tb_runs.tsv"
echo "  - Metadata:     ${TB_DIR}/tb_metadata.tsv"
echo "VC:"
echo "  - FASTQs under: ${VC_DIR}/<RUN>/*fastq.gz"
echo "  - Run table:    ${VC_DIR}/vc_runs.tsv"
echo "  - Metadata:     ${VC_DIR}/vc_metadata.tsv"
echo "All set ✅"
