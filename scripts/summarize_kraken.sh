#Output format: TopSpecies<TAB>SampleID (species is “in front of” the ID as you requested).
#Uses column 4 (S) to keep only species-level rows, column 1 for the percent in clad and trims the indentation on the species name.


for f in tb/*.report vc/*.report; do
  awk -F'\t' -v sample="$(basename "$f" .report)" '
    $4=="S" {
      name=$6; gsub(/^ +/, "", name);      # trim leading spaces from the taxon name
      if ($1>max) { max=$1; top=name }     # pick species with highest % in clade (col 1)
    }
    END { if (top=="") top="NA"; print top "\t" sample }
  ' "$f"
done | column -t

