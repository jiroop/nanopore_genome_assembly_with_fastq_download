#!/usr/bin/env nextflow


// Assess assembly completeness using BUSCO
// BUSCO will use Augustus for gene prediction on the core set of BUSCO genes
// BUSCO will call different alleles as duplicates if they are heterozygous
// BUSCO should not call yeast paraglos as duplicates

process QC_BUSCO {

    publishDir "${params.outdir}/busco", mode: 'copy'

    input:
    path assembly 

    output:
    path "short_summary.txt", emit: summary
    path "full_table.tsv", emit: full_table
    path "missing_busco_list.tsv", emit: missing_list


    script:
    """
    busco \
        -i ${assembly} \
        -l saccharomycetes_odb10 \
        -m genome \
        -o output \
        --cpu ${task.cpus} \
        -f 

    cp ./output/run_saccharomycetes_odb10/short_summary.txt ./short_summary.txt
    cp ./output/run_saccharomycetes_odb10/full_table.tsv ./full_table.tsv
    cp ./output/run_saccharomycetes_odb10/missing_busco_list.tsv ./missing_busco_list.tsv
    """
}