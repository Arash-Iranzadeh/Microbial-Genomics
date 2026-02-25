🌳 Phylogenetic Reconstruction (Read this fore step 5)

This project utilizes a high-resolution Maximum Likelihood (ML) approach to reconstruct the phylogeny of the isolates. To ensure the evolutionary signal is not distorted by recombination, we perform recombination filtering before tree building.
🧬 Workflow Summary

    Variant Calling: SNPs and Indels are identified using snippy.

    Recombination Masking: Gubbins is used to identify and mask regions of high recombination density.

    SNP Extraction: snp-sites is used to extract polymorphic sites from the recombination-filtered alignment.

    ML Phylogeny: IQ-TREE 2 is used for the final tree reconstruction.

💻 Execution Command
Bash

# IQ-TREE 2 command for recombination-filtered SNP alignment
iqtree2 -s clean.core.aln \
        -m MFP+ASC \
        -B 1000 \
        -alrt 1000 \
        -T AUTO \
        --ntmax 32 \
        --prefix TB_pangenome_iqtree

⚙️ Parameters Explained

    -s clean.core.aln: The input alignment file containing only variable sites (SNPs) after recombination masking by Gubbins.

    -m MFP+ASC:

        MFP (ModelFinder Plus): Automatically determines the best-fit substitution model.

        ASC (Ascertainment Bias Correction): Corrects for the absence of constant sites in the SNP-only alignment. This is required for accurate branch length estimation when using core.aln.

    -B 1000: Performs 1,000 UltraFast Bootstrap replicates (values ≥ 95 indicates strong support).

    -alrt 1000: SH-like approximate likelihood ratio test (values ≥ 80 indicates strong support).

    -T AUTO --ntmax 32: Optimizes multi-threading performance up to a maximum of 32 CPU cores.

🔬 Alignment Selection: core.aln vs. core.full.aln

In this pipeline, we prioritize the use of core.aln (SNP-only) for phylogenetic inference:
Feature	core.aln	core.full.aln
Data Type	Polymorphic sites only	Whole-genome (including invariant sites)
Speed	Optimized: Fast processing for 1000+ taxa	Slow: High computational overhead
Model	Requires +ASC correction	Uses standard models
Recommendation	Best for large-scale pangenomes	Best for detailed recombination detection

Decision: We utilize core.aln because it provides the necessary phylogenetic signal while significantly reducing the computational time and memory footprint required for 1,774 isolates. By using the +ASC flag, we ensure that the branch lengths remain mathematically accurate despite the removal of constant sites.
Final Notes

    The final tree file is saved as TB_pangenome_iqtree.treefile.

    Bootstrap and SH-aLRT values are mapped to the branches for statistical validation.
