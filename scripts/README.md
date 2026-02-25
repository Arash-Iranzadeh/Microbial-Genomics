🌳 Phylogenetic Reconstruction (Read this before running 5_core_SNP_phylogeny.sh)

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

core.aln: polymorphic sites only, fast processing for 1000+ taxa, requires +ASC correction, best for large-scale pangenomes
core.full.aln: whole-genome (including invariant sites), slow with high computational overhead, requires standard models, best for detailed recombination detection
