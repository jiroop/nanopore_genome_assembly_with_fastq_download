#!/usr/bin/env nextflow

// Download S288C reference cDNA sequences from SGD

process DOWNLOAD_S288C_CDNA {

    storeDir "${params.outdir}/reference"

    output:
    path "s288c_cDNA.fasta", emit: S288C_cDNA

    script:
    """
    wget -O s288c_cDNA.fasta.gz \
        https://downloads.yeastgenome.org/sequence/S288C_reference/orf_dna/orf_coding_all.fasta.gz
    
    gunzip s288c_cDNA.fasta.gz
    
    # Quick stats
    echo "S288C cDNA sequences downloaded:"
    grep -c "^>" s288c_cDNA.fasta
    """
}

process DOWNLOAD_S288C_PROTEINS {

    storeDir "${params.outdir}/reference"

    output:
    path "s288c_proteins.fasta", emit: S288C_proteins

    script:
    """
    wget -O s288c_proteins.fasta.gz \
        https://downloads.yeastgenome.org/sequence/S288C_reference/orf_protein/orf_trans_all.fasta.gz
    
    gunzip s288c_proteins.fasta.gz
    
    # Quick stats
    echo "S288C protein sequences downloaded:"
    grep -c "^>" s288c_proteins.fasta
    """
}

