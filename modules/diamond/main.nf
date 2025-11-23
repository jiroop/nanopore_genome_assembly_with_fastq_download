#!/usr/bin/env nextflow

process CREATE_DIAMOND_DB {
    storeDir "${params.outdir}/diamond_annotation"
    
    input:
    path s288c_proteins
    
    output:
    path "sp_and_s288c_prot.dmnd", emit: swissprot_and_s288c_prot_db
    
    script:
    """
    echo "Downloading SwissProt database..."
    
    # Download SwissProt (smaller, curated)
    wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz
    
    gunzip uniprot_sprot.fasta.gz
    
    echo "Combining SwissProt with S288C proteins..."

    cat uniprot_sprot.fasta ${s288c_proteins} > combined_swissprot_s288c.fasta

    echo "Building Diamond database..."
    diamond makedb \
        --in combined_swissprot_s288c.fasta \
        --db sp_and_s288c_prot \
        --threads ${task.cpus}

    echo "Combined DIAMOND database built: combined_swissprot_s288c.fasta"
    rm uniprot_sprot.fasta combined_swissprot_s288c.fasta  # Clean up
    """
}

process ANNOTATE_DIAMOND {
    publishDir "${params.outdir}/diamond_annotation", mode: 'copy'

    input:
    path proteins
    path database
    
    output:
    path "diamond_results.tsv", emit: results
    path "annotated_proteins.tsv", emit: annotated
    
    script:
    """
    # copy file so it is not a symlink - sed may have issues with symlinks
    
    sed 's/ protein AED:[0-9]\\.[0-9]\\{1,2\\} /_/' ${proteins} > proteins_AED_concat.fasta  # Clean up headers for Diamond compatibility
    

    echo "Running Diamond BLASTP..."
    
    diamond blastp \
        --query proteins_AED_concat.fasta \
        --db ${database} \
        --outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovhsp scovhsp stitle \
        --out diamond_results.tsv \
        --max-target-seqs 1 \
        --evalue 1e-0 \
        --threads ${task.cpus} \
        --fast
    
    # Create more readable annotation file
    awk 'BEGIN {OFS="\\t"; print "Gene_ID", "Best_Hit", "Identity%", "Match_Length", "Query_cov%", "Subject_cov%", "E-value"} \
         {print \$1, \$2, \$3, \$4, \$13, \$14, \$11}' \
         diamond_results.tsv > annotated_proteins.tsv
    
    echo "Annotated \$(wc -l < diamond_results.tsv) proteins"
    """
}

