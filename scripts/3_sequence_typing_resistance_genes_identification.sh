#!/usr/bin/env bash
set -euo pipefail
srun --cpus-per-task=8 --mem=32GB --time 3:00:00 --pty bash
module load anaconda3/2024.10

# Vibrio cholera typing with ariba
# https://github.com/sanger-pathogens/ariba
conda activate /software/common/anaconda3/2024.10/envs/ariba

DATA_DIR="/data/Dataset_Mt_Vc/vc/raw_data"
OUTPUT_DIR="/data/users/user28/data_analysis/sequence_typing/vc"
THREADS=$(nproc)
mkdir -p ${OUTPUT_DIR}

# Typing schemes from PubMLST.
# https://github.com/sanger-pathogens/ariba/wiki/MLST-calling-with-ARIBA
# A list of available species can be obtained by running
ariba pubmlstspecies
echo "Download the data using pubmlstget"
ariba pubmlstget "Vibrio cholerae" ${OUTPUT_DIR}/mlst_vibrio_cholerae
#Then run MLST using ARIBA with:
for SAMPLE in $(ls $DATA_DIR  | cut -f1 -d '_' | sort | uniq); do
    ariba run  --force --threads ${THREADS} ${OUTPUT_DIR}/mlst_vibrio_cholerae/ref_db \
    ${DATA_DIR}/${SAMPLE}_1.fastq.gz ${DATA_DIR}/${SAMPLE}_2.fastq.gz ${OUTPUT_DIR}/${SAMPLE}_typing
done

# Identification of antibiotic resistance genes
# https://github.com/sanger-pathogens/ariba/wiki
#Get reference data. It's from CARD here, also support several others (see getref for a full list).
ariba getref card ${OUTPUT_DIR}/out.card
# Prepare reference data for Ariba
ariba prepareref --force --threads 16 -f ${OUTPUT_DIR}/out.card.fa \
 -m ${OUTPUT_DIR}/out.card.tsv ${OUTPUT_DIR}/out.card.prepareref
#Run local assemblies and call variants
reports=()
for SAMPLE in $(ls $DATA_DIR  | cut -f1 -d '_' | sort | uniq); do
    ariba run --force --threads ${THREADS} ${OUTPUT_DIR}/out.card.prepareref \ 
     ${DATA_DIR}/${SAMPLE}_1.fastq.gz ${DATA_DIR}/${SAMPLE}_2.fastq.gz "${OUTPUT_DIR}/${SAMPLE}_amr"
    reports+=("${OUTPUT_DIR}/${SAMPLE}/report.tsv")
done
# Summarise data from several runs (in this case 3)
ariba summary "${OUT_PREFIX}.summary" "${reports[@]}"
cat "${OUT_PREFIX}.summary.csv"

# View the results by dragging and dropping the files *.phandango.tre and *.phandango.csv into the Phandago:
# https://jameshadfield.github.io/phandango/#/


# Mycobacterium tuberculosis typing with TBProfiler
# https://github.com/jodyphelan/TBProfiler

tb-profiler profile -1 ${sample_name}_1.fastq.gz -2 ${sample_name}_2.fastq.gz -p $sample_name -t 16 \
  --spoligotype --txt --call_whole_genome --dir outputDir
# The results from numerous runs can be collated into one table using the following command:
tb-profiler collate -d outputDir/results/
cut -f1-5,9,13 tbprofiler.txt


#instalation
# *mlst ships with classic PubMLST schemes and knows P. aeruginosa as the scheme paeruginosa. You can see available schemes with:

mlst --list
# or, for details:
mlst --longlist

# Run MLST in CSV mode, forcing the P. aeruginosa scheme for consistency.
# Accepts FASTA/GenBank/EMBL files (even .gz/.bz2/.zip).
mlst --scheme spneumoniae --threads 8  GCF_000273445.1_Stre_pneu_Tigr4_V1_genomic.fna > Tigr4.ST.tsv

# => result must indicate TIGR4 ST type is ST205
