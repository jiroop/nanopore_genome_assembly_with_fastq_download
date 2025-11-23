process PROCESS_ANNOTATION_OUTPUT {
    publishDir "${params.outdir}/proteins_annotated", mode: 'copy'
    
    input: 
    path proteins
    path genes_gff3

    output:
    path "gene_contig_mapping.txt", emit: annotated_proteins

    script:
    """
    grep 'AUGUSTUS\\ttranscript' ${genes_gff3} | awk '{print \$1, \$9}' | sed 's/\\([^ ]*\\) .*ID=\\([^;]*\\).*/\\2 \\1/' > gene_contig_mapping.txt
    """

}