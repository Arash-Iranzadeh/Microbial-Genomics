#!/usr/bin/env bash
# https://github.com/sanger-pathogens/ariba
# On PC: pip3 install ariba
# On cluster:
# wget https://github.com/sanger-pathogens/ariba/releases/download/v2.14.7/ariba_v2.14.7.img
# singularity build output_file.sif /ariba_v2.14.7.img
# If sif file is used: ARIBA=singularity exec /path/to/ariba_v2.14.7.sif ariba
# Aroba is a tool for MLST typing and antibiotic resistance genes identification.

#Vibrio cholera
module load singularity
DATA_DIR="/scratch3/users/arash/Microbial-Genomics/results/trimmed_trimmomatic/vc"
OUTPUT_DIR="/scratch3/users/arash/Microbial-Genomics/results/typing_amr"

ariba_cmd() {
    singularity exec /cbio/users/arash/containers/ariba_v2.14.7.sif ariba "$@"
}
THREADS=$(nproc)
mkdir -p ${OUTPUT_DIR}

# Typing schemes from PubMLST.
# https://github.com/sanger-pathogens/ariba/wiki/MLST-calling-with-ARIBA
# A list of available species can be obtained by running
#ariba_cmd pubmlstspecies
echo "Download the data using pubmlstget"
ariba_cmd pubmlstget "Vibrio cholerae" ${OUTPUT_DIR}/mlst_vibrio_cholerae
#Then run MLST using ARIBA with:
for R1 in "${DATA_DIR}"/*_1P.fastq.gz; do
    SAMPLE=$(basename "${R1}" "_1P.fastq.gz")
    R2="${DATA_DIR}/${SAMPLE}_2P.fastq.gz"
    echo "Working on ${SAMPLE} typing ..."
    ariba_cmd run  --threads ${THREADS} ${OUTPUT_DIR}/mlst_vibrio_cholerae/ref_db $R1 $R2 ${OUTPUT_DIR}/${SAMPLE}_typing
    echo "${SAMPLE} analysis is done!"
done

# Identification of antibiotic resistance genes
# https://github.com/sanger-pathogens/ariba/wiki
#Get reference data. It's from CARD here, also support several others (see getref for a full list).
ariba_cmd getref card ${OUTPUT_DIR}/out.card
# Prepare reference data for Ariba
ariba_cmd prepareref --force --threads 16 -f ${OUTPUT_DIR}/out.card.fa -m ${OUTPUT_DIR}/out.card.tsv ${OUTPUT_DIR}/out.card.prepareref
#Run local assemblies and call variants
reports=()
for R1 in "${DATA_DIR}"/*_1P.fastq.gz; do
    SAMPLE=$(basename "${R1}" "_1P.fastq.gz")
    R2="${DATA_DIR}/${SAMPLE}_2P.fastq.gz"
    echo "Working on resistance gene identification in ${SAMPLE} ..."
    ariba_cmd run --force --threads ${THREADS} ${OUTPUT_DIR}/out.card.prepareref "${R1}" "${R2}" "${OUTPUT_DIR}/${SAMPLE}_amr"
    reports+=("${OUTPUT_DIR}/${SAMPLE}/report.tsv")
    echo "${SAMPLE} analysis is done!"
done
# Summarise data from several runs (in this case 3)
ariba_cmd summary "${OUT_PREFIX}.summary" "${reports[@]}"
cat "${OUT_PREFIX}.summary.csv"


# View the results by dragging and dropping the files *.phandango.tre and *.phandango.csv into the Phandago:
# https://jameshadfield.github.io/phandango/#/
tb-profiler profile -1 ${sample_name}_1.fastq.gz -2 ${sample_name}_2.fastq.gz -p $sample_name -t 16 \
  --spoligotype --txt --call_whole_genome --dir outputDir
# The results from numerous runs can be collated into one table using the following command:
tb-profiler collate


 --prefix

--spoligotype
#Mycobacterium tuberculosis
# https://github.com/jodyphelan/TBProfiler

#instalation
brew install brewsci/bio/mlst

# Confirm the scheme name
# *mlst ships with classic PubMLST schemes and knows P. aeruginosa as the scheme paeruginosa. You can see available schemes with:

mlst --list
# or, for details:
mlst --longlist

# Run MLST in CSV mode, forcing the P. aeruginosa scheme for consistency.
# Accepts FASTA/GenBank/EMBL files (even .gz/.bz2/.zip).
mlst --scheme spneumoniae --threads 8  GCF_000273445.1_Stre_pneu_Tigr4_V1_genomic.fna > Tigr4.ST.tsv

# => result must indicate TIGR4 ST type is ST205
