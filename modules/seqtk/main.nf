#!/usr/bin/env nextflow

// Process to subsample reads using seqtk for faster assembly
// Adjust the number of reads to subsample via params.subsample, or set to 0 to skip subsampling
// Subsampling is useful for testing the pipeline before running on the full dataset

process SUBSAMPLE_READS {

    input: 
    path reads

    output:
    path "subsampled_${reads.simpleName}.fastq.gz", emit: reads

    script:   

    """
    seqtk sample -s100 ${reads} ${params.subsample} | gzip > subsampled_${reads.simpleName}.fastq.gz
    """

}