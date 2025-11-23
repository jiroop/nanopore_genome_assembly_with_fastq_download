#!/usr/bin/env nextflow

// Process to visualize assembly graph with Bandage
// Bandage creates PNG image of the assembly graph
// Helps identify repeats, misassemblies, and circular contigs

process QC_BANDAGE {
    publishDir "${params.outdir}/bandage", mode: 'copy'
    errorStrategy 'ignore'  // this crashes when the app is installed?

    input:
    path graph

    output:
    path "assembly_graph.png", emit: png
    path "assembly_graph.svg", emit: svg

    script:
    """
    echo "Creating assembly graph visualization with Bandage..."

    BandageNG image ${graph} assembly_graph.png \
        --height 2000 \
        --width 2000 

    BandageNG image ${graph} assembly_graph.svg \
        --height 2000 \
        --width 2000 

    echo "Bandage visualization complete. Check results/bandage for graph images."
    """
}