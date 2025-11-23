#!/usr/bin/env nextflow

// Process to download Nanopore reads from SRA and convert to fasttq.gz
// Note that fasterq-dump downloads as fastq, not fastq.gz, so we gzip after download
// fasterq-dump is part of the SRA Toolkit
// split-files is used to separate paired-end reads, if applicable

process DOWNLOAD_READS {
    storeDir "${projectDir}/data/fastq"
        
    output:
    path "*.fastq.gz", emit: reads 

    script:
    """
    echo "Downloading and converting ${params.sra_accession}..."

    fasterq-dump ${params.sra_accession} \
        --threads ${task.cpus} \
        --progress \
        --split-files
    gzip *.fastq 
    """
}