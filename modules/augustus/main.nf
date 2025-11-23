#!/usr/bin/env nextflow


// Process to run Augustus for gene prediction on the assembled genome
// Augustus predicts genes and outputs GFF3 and protein sequences
// --species denotes the organism used for modeling ORF structures, but is not a template for annotation

process ANNOTATE_AUGUSTUS {
    publishDir "${params.outdir}/augustus", mode: 'copy'
    
    input:
    path assembly
    
    output:
    path "genes.gff3", emit: gff
    path "proteins.faa", emit: proteins
    
    script:
    """
    echo "Running Augustus gene prediction..."
    
    augustus --species=saccharomyces \
             --gff3=on \
             --protein=on \
             --UTR=off \
             --genemodel=complete \
             ${assembly} > genes.gff3
    
    # Extract protein sequences from GFF3
    getAnnoFasta.pl genes.gff3
    mv genes3.aa proteins.faa
    
    echo "Gene prediction complete."
    """
}