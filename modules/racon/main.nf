#!/usr/bin/env nextflow

// Process to polish assembly using Racon
// Racon corrects consensus errors by mapping reads back to the draft assembly
// and using majority voting to fix substitutions and indels
// Runs 2 passes for progressively better error correction

process POLISH_RACON {
    publishDir "${params.outdir}/racon", mode: 'copy'
    
    input:
    path assembly
    path reads
    
    output:
    path "polished_assembly.fasta", emit: polished_assembly
    path "racon_pass1.fasta", emit: pass1_assembly
    path "racon.log", emit: log
    
    script:
    """
    echo "Starting Racon polishing on ${assembly}..." | tee racon.log
    
    # Pass 1: First polishing round
    echo "Running Racon pass 1..." >> racon.log
    # -a specifies SAM output, snd -x map-ont specifices presets for working with Oxford Nanopore reads
    # overlaps_passX.sam is the alignment file 
    minimap2 -ax map-ont -t ${task.cpus} ${assembly} ${reads} > overlaps_pass1.sam
    
    racon -t ${task.cpus} ${reads} overlaps_pass1.sam ${assembly} > racon_pass1.fasta
    
    # Pass 2: Second polishing round for improved accuracy
    echo "Running Racon pass 2..." >> racon.log
    minimap2 -ax map-ont -t ${task.cpus} racon_pass1.fasta ${reads} > overlaps_pass2.sam
    racon -t ${task.cpus} ${reads} overlaps_pass2.sam racon_pass1.fasta > polished_assembly.fasta
    
    # Cleanup
    rm overlaps_pass1.sam overlaps_pass2.sam
    
    echo "Racon polishing complete." >> racon.log
    
    # Quick stats
    echo "Draft assembly sequences: \$(grep -c '^>' ${assembly})" >> racon.log
    echo "Polished assembly sequences: \$(grep -c '^>' polished_assembly.fasta)" >> racon.log
    """
}