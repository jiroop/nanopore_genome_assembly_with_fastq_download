#!/usr/bin/env nextflow

// Process to run Flye assembler for Nanopore reads
// Flye is a de novo assembler for long reads
// Output includes assembled contigs, assembly info, and assembly graph
// Output is saved in the results/assembly directory

process FLYE_ASSEMBLY {

    publishDir "${params.outdir}/assembly/${reads.simpleName}", mode: 'copy'
               

    input:
    path reads

    output:
    path "assembly.fasta", emit: assembly
    path "assembly_info.txt", emit: assembly_info
    path "assembly_graph.gfa", emit: assembly_graph
    path "flye.log", emit: flye_log


    script:
    """
    echo "Running Flye assembly on ${reads}..."

    flye --nano-raw ${reads} \
        --genome-size ${params.genome_size} \
        --out-dir . \
        --threads ${task.cpus} \
        --iterations 2 
        

    echo "Assembly complete. Check results/assembly for output files."
    """
}