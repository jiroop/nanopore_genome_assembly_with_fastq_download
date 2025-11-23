#!/usr/bin/env nextflow

// Process to run NanoPlot for quality control of Nanopore reads
// NanoPlot generates various plots and statistics for long-read data
// Output is saved in the results/nanoplot directory

process QC_NANOPLOT {
    publishDir "${params.outdir}/nanoplot", mode: 'copy'

    input:
    path reads

    output:
    path "${reads.simpleName}/*"
    path "${reads.simpleName}/NanoStats.txt", emit: stats

    script:

    """
    echo "Running NanoPlot on ${reads}..."

    NanoPlot --fastq ${reads} \
        --outdir ${reads.simpleName} \
        --threads ${task.cpus} \
        --N50 \
        --plots dot \
        --legacy hex

    echo "QC complete. Check results/nanoplot for output files."
    """ 
}