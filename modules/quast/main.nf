#!/usr/bin/env nextflow


// Process to run QUAST for assembly quality assessment
// QUAST generates comprehensive statistics about the assembly
// Output includes HTML report, text reports, and various metrics

process QC_QUAST {
    publishDir "${params.outdir}/quast", mode: 'copy'

    input:
    path assembly

    output:
    path "*", emit: outputs
    path "report.html", emit: report

    script:
    """
    echo "Running QUAST on assembly..."

    quast.py ${assembly} \
        --output-dir . \
        --threads ${task.cpus} \
        --min-contig 500

    echo "QUAST complete. Check results/quast/report.html for detailed statistics."
    """
}