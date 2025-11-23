
process SEQUENCE_ANNOTATION_PYTHON {

    publishDir "${params.outdir}/custom_annotation", mode: 'copy'

    input:
    path proteins
    path transcripts
    path diamond_results
    path script
     
    output:
    path "final_annotated_proteins.fasta", emit: final_proteins
    path "final_annotated_transcripts.fasta", emit: final_transcripts

    script:
    """
    python3 ${script}
    """

}