# Reading MultiQC’s FastQC Sections (Detailed Guide)

MultiQC **collects all your FastQC outputs** (per-sample HTML/TXT) and merges them into a single, cross-sample dashboard. Think of it as **“FastQC at scale”**: you get every FastQC module, but now it’s easy to (a) compare samples side-by-side, (b) spot outliers, and (c) decide batch-wide actions (e.g., trimming, resequencing).

> **Key idea:** The **Pass / Warn / Fail** badges shown in MultiQC are **FastQC’s own flags** aggregated by MultiQC. MultiQC adds the multi-sample plots/tables and quick filtering, but it doesn’t change FastQC’s logic.

---

## 1) General Statistics (FastQC summary, per sample)
- MultiQC builds a table with essential FastQC stats (e.g., total sequences, %GC, mean quality, duplication, adapter content) for **all** samples.
- **How to use:**
  - Sort columns to **find outliers** fast (e.g., one sample with low total reads or unusually high adapter content).
  - Look for **consistency** across replicates/batches; large deviations often indicate library prep or sequencing issues.

---

## 2) FastQC: Sequence Counts
- **What it is:** Total reads seen by FastQC per file. MultiQC displays them together so you can check **sequencing depth balance**.
- **Why it matters:** Depth affects downstream sensitivity and comparability.
- **Common observations:**
  - **Very low counts:** failed or underloaded library; may be unusable for variant calling or differential analysis.
  - **Very high counts** relative to others: can skew batch comparisons unless analyses are normalized or downsampled.
- **Action:** For strongly unbalanced depth, consider downsampling or resequencing the underpowered samples.

---

## 3) FastQC: Per Base Sequence Quality
- **What it is:** Boxplots of **Phred** quality score **by base position** across all reads.
- **Typical pattern:** Highest at read start; gradual decline toward the 3′ end (more pronounced in long reads).
- **Why it matters:** Low-quality tails increase mismatches, reduce mapping quality, and inflate false positives.
- **Red flags:** Large stretches dipping into low quality at read ends or throughout reads.
- **Action:** Apply quality trimming (e.g., `fastp`, `Trim Galore`, `Trimmomatic`) and remove adapter-contaminated tails before alignment/variant calling.

---

## 4) FastQC: Per Sequence Quality Scores
- **What it is:** Histogram of **mean read quality** per read.
- **Good:** Distinct peak at high Q (e.g., Q30+).
- **Concerning:** Left-shifted or very broad distributions → many poor reads.
- **Action:** Filter low-quality reads; if widespread, investigate run quality (cluster density, flow cell issues).

---

## 5) FastQC: Per Base Sequence Content
- **What it is:** Base composition (%A/%T/%C/%G) by position.
- **Expected:** Roughly flat and overlapping after the initial ~10 bp (minor start bias is normal for many libraries).
- **Red flags:** Sustained imbalance (e.g., A/T rich) → primer bias, contamination, or residual adapters.
- **Action:** Verify library strategy, confirm adapters are trimmed, check for contamination.

---

## 6) FastQC: Per Sequence GC Content
- **What it is:** Distribution of **%GC per read**.
- **Expected:** Approximately normal (bell-shaped) around the organism’s genome GC.
- **Red flags:**
  - Shifted peak: off-target species/contamination.
  - Multi-modal distribution: mixed content (e.g., host+microbe) or biased capture.
- **Action:** Confirm sample identity and pipeline inputs; consider decontamination filters for metagenomic contexts.

---

## 7) FastQC: Per Base N Content
- **What it is:** Proportion of **“N” (uncalled bases)** by position.
- **Expected:** Near zero at all positions.
- **Red flags:** Rising N rates at read ends or across reads → chemistry/cycle failures.
- **Action:** Trim affected tails; excessive Ns suggest a poor run or damaged libraries.

---

## 8) FastQC: Sequence Length Distribution
- **What it is:** Read length histogram.
- **Expected:** Single sharp peak at the intended read length (e.g., 150 bp).
- **Red flags:** Broad/variable lengths (beyond intentional trimming) → incomplete reads or aggressive trimming from low quality/adapters.
- **Action:** Confirm consistent read length in the run configuration; if trimming created heavy variability, ensure downstream tools tolerate variable lengths.

---

## 9) FastQC: Sequence Duplication Levels
- **What it is:** Fraction of reads appearing **more than once** (identical sequences), binned by duplication count.
- **Interpretation:**
  - **Low duplication:** Good library complexity.
  - **High duplication** can arise from:
    - **Low input / over-amplification** (PCR duplicates dominate).
    - **Over-sequencing** a small library (you “ran out” of unique molecules).
    - **Biological reality** (e.g., highly expressed transcripts in RNA-seq, targeted panels).
- **Action:**
  - For WGS/WES: high duplication → consider resequencing or revisiting library prep; mark duplicates post-alignment.
  - For RNA-seq: moderate duplication can be normal; assess with mapping-level metrics and expression distributions.

---

## 10) FastQC: Overrepresented Sequences
- **What it is:** Specific sequences occurring more often than expected.
- **Common causes:** Adapters/primers, rRNA, PhiX, or other technical/biological contaminants.
- **Action:** If adapters/primers → re-trim; if biological (rRNA) → consider depletion; if spike-in → confirm expected proportions.

---

## 11) FastQC: Adapter Content
- **What it is:** Estimated fraction of adapter sequence across read positions.
- **Expected:** Close to zero after proper trimming.
- **Red flags:** Rising adapter signal toward the 3′ end; elevated adapter in many samples indicates systematic under-trimming or short inserts.
- **Action:** Re-run adapter trimming with correct adapter set and minimum-length settings; verify with a second FastQC/MultiQC pass.

---

## 12) (If present) Per Tile Sequence Quality / K-mer Content
- **Per Tile Quality:** Identifies **spatial** issues on the flow cell (bad tiles). Stripes/bands of low quality suggest hardware/localized run problems.
- **K-mer Content:** Enrichment of short motifs. Strong k-mer spikes often indicate adapters/primers or sequence bias.
- **Action:** For tile issues, coordinate with the sequencing facility; for k-mers, confirm and trim adapters/primers, reassess library design.

---

## Practical Workflow With MultiQC + FastQC
1. **Run FastQC for all FASTQs** → **Run MultiQC** on the folder.  
2. In MultiQC:
   - Start at **General Statistics** → sort columns to find **outliers**.
   - Check **Sequence Counts** → ensure reasonable, comparable depth.
   - Inspect **Per Base Quality** and **Adapter Content** → decide **trimming**.
   - Review **Duplication** → infer **library complexity** and decide on **duplicate marking**.
   - Validate **GC Content** and **Base Composition** → rule out contamination.
3. **Fix issues** (trim/filter/mark duplicates) → **Re-run FastQC + MultiQC** to confirm improvements.

> **Rule of thumb:** Any systematic issue visible across multiple samples typically points to **library prep**, **run settings**, or **trimming parameters**; isolated outliers are **sample-specific** problems.
