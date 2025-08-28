#instalation
brew install brewsci/bio/mlst

# Confirm the scheme name
# *mlst ships with classic PubMLST schemes and knows P. aeruginosa as the scheme paeruginosa. You can see available schemes with:

mlst --list
# or, for details:
mlst --longlist

# Run MLST in CSV mode, forcing the P. aeruginosa scheme for consistency.
# Accepts FASTA/GenBank/EMBL files (even .gz/.bz2/.zip).
mlst --scheme paeruginosa --threads 8  GCF_000273445.1_Stre_pneu_Tigr4_V1_genomic.fna > Tigr4.ST.tsv
