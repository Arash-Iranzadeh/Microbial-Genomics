# https://github.com/sanger-pathogens/ariba
# On PC: pip3 install ariba
# On cluster:
# wget https://github.com/sanger-pathogens/ariba/releases/download/v2.14.7/ariba_v2.14.7.img
# singularity build output_file.sif /ariba_v2.14.7.img
# ARIBA is a tool that identifies antibiotic resistance genes by running local assemblies. It can also be used for MLST calling.


#https://github.com/sanger-pathogens/ariba/wiki
#Get reference data. It's from CARD here, also support several others (see getref for a full list).
ariba getref card out.card
# Prepare reference data for ARIBA
ariba prepareref --force --threads 16 -f out.card.fa -m out.card.tsv out.card.prepareref
#Run local assemblies and call variants
ariba run --force --threads 16 out.card.prepareref ../data/*_1P.fastq.gz ../data/*_2P.fastq.gz ERR1485273_ariba
# Summarise data from several runs (in this case 3)
ariba summary vc.summary ERR1485273_ariba/report.tsv ERR1485279_ariba/report.tsv
# See summary
cat vc.summary.csv

# https://github.com/sanger-pathogens/ariba/wiki/MLST-calling-with-ARIBA
#ARIBA can be used for MLST using the typing schemes from PubMLST. A list of available species can be obtained by running
ariba pubmlstspecies
# Download the data (in this example, Staphylococcus aureus) using pubmlstget
ariba pubmlstget "Vibrio cholerae" mlst_vibrio_cholerae
#Then run MLST using ARIBA with:
ariba run get_mlst/ref_db reads_1.fq reads_2.fq ariba_out







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
