#! /usr/bin/env nextflow

// Process to assess coverage of reads mapped back to assembly using Minimap2 and Samtools
process QC_COVERAGE {
    publishDir "${params.outdir}/minimap2", mode: 'copy'
    
    input:
    path assembly
    path reads
    
    output:
    path "coverage_report.txt", emit: report
    path "coverage_per_base.txt", emit: per_base_coverage
    path "overlaps.sorted.bam", emit: sorted_bam
    
    script:
    """
    minimap2 -ax map-ont -t ${task.cpus} ${assembly} ${reads} | \
        samtools view -b - | \
        samtools sort - > overlaps.sorted.bam
    
    samtools index overlaps.sorted.bam
    samtools coverage overlaps.sorted.bam > coverage_report.txt
    samtools depth overlaps.sorted.bam > coverage_per_base.txt
    """
}