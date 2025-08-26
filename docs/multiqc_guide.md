# How to Read a MultiQC Report

MultiQC aggregates results from bioinformatics tools such as FastQC, alignment software, and variant callers into a single, easy-to-read report.  
This guide explains the main sections you will see.

---

## 1. General Statistics
A summary table with key metrics for each sample:
- **Total reads**
- **%GC content**
- **Mean quality score**
- **Duplication rate**

👉 Use this to quickly spot samples that deviate from the rest.

---

## 2. FastQC: Sequence Counts
Shows how many reads are present in each file.  
- **Consistent counts** = balanced sequencing.  
- **Low counts** = poor sequencing/library prep.  

---

## 3. FastQC: Per Base Sequence Quality
Boxplots of quality scores across each base in the read.  
- **Green (Q ≥ 30):** very good.  
- **Orange/Red (Q < 20):** low-quality regions; consider trimming.  

---

## 4. FastQC: Per Sequence Quality Scores
Histogram of average read quality.  
- A strong peak at high Q is good.  
- A left-shifted peak means too many poor reads.  

---

## 5. FastQC: Per Base Sequence Content
Base composition (A, T, C, G) at each position.  
- Should be relatively flat.  
- Strong bias may indicate contamination or adapters.  

---

## 6. FastQC: Per Sequence GC Content
Distribution of GC content across reads.  
- Should match the organism’s genome GC%.  
- Multiple peaks = contamination.  

---

## 7. FastQC: Per Base N Content
Frequency of undetermined bases ("N").  
- Should be close to zero.  

---

## 8. FastQC: Sequence Length Distribution
Distribution of read lengths.  
- Fixed for Illumina runs (e.g., 150 bp).  
- Variable = trimming or artifacts.  

---

## 9. FastQC: Sequence Duplication Levels
Shows how many reads are duplicated.  
- Low duplication = good diversity.  
- High duplication = possible PCR artifacts or low complexity.  

---

## 10. FastQC: Overrepresented Sequences
Lists sequences appearing more often than expected.  
- Usually adapters or rRNA.  
- Should be trimmed or removed.  

---

## 11. FastQC: Adapter Content
Proportion of reads containing adapter sequences.  
- Should be minimal.  
- If high, trim adapters before alignment.  

---

## 12. Other Modules
Depending on the pipeline, you may also see:
- **Alignment Stats** (mapping rate, paired reads)  
- **Insert Size Distribution** (paired-end libraries)  
- **Variant Calling Metrics** (SNP/indel counts, Ti/Tv ratio)  

---

## ✅ Summary
- Look for **consistency across samples**.  
- Watch for **low-quality bases** or **adapter contamination**.  
- Use trimming/cleaning tools (e.g., `Trimmomatic`, `fastp`) before downstream analysis if needed.  

