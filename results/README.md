# Results are saved here!
## The result of quality control on TB and VC:
### TB dataset (Mycobacterium tuberculosis)
- Per-base quality: High overall, but tails of reads (after ~120 bp) show quality drop.
- Adapter content: Strong Illumina adapter signal present in many samples.
- Per-sequence GC content: Consistent with Mtb (high GC, ~65%), so no contamination issues.
- Overrepresented sequences: Adapters dominate here.
### VC dataset (Vibrio cholerae)
- Per-base quality: Mostly good, slight decline after ~140 bp.
- Adapter content: Much weaker than TB dataset, but still present in some runs.
- GC content: Matches V. cholerae (low GC, ~47%), clean distribution.
- Overrepresented sequences: Some adapter traces + ribosomal RNA fragments.
