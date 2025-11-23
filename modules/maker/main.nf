process ANNOTATE_MAKER {
    publishDir "${params.outdir}/maker", mode: 'copy'

    input:
    path assembly
    path est_evidence
    path protein_evidence

    output:
    path "maker_output.maker.output", emit: maker_output_dir

    script:
    """
    maker -CTL
    
    # specifiy genome and evidence files
    sed -i 's/^genome=.*/genome=${assembly}/' maker_opts.ctl
    sed -i 's/^est=.*/est=${est_evidence}/' maker_opts.ctl
    sed -i 's/^protein=.*/protein=${protein_evidence}/' maker_opts.ctl

    # setting species to saccharomyces for Augustus gene prediction. 
    sed -i 's/^augustus_species=.*/augustus_species=saccharomyces/' maker_opts.ctl
    
    # setting model_org to blank to skip using a pre-trained model for repeat masking
    sed -i 's/^model_org=.*/model_org=/' maker_opts.ctl
    
    # enabling expression evidence-based gene prediction
    sed -i 's/^est2genome=.*/est2genome=1/' maker_opts.ctl
     
    # enabling protein evidence-based gene prediction
    sed -i 's/^protein2genome=.*/protein2genome=1/' maker_opts.ctl

    sed -i 's/^cpus=.*/cpus=${task.cpus}/' maker_opts.ctl
    
    # -q for quiet mode
    maker -base maker_output -q
    
    # By default, maker creates seperate output for for each contifg/scaffold
    # We will merge them in the next process 

    """
}


process MERGE_MAKER_OUTPUT {
    publishDir "${params.outdir}/maker", mode: 'copy'
    
    input:
    path maker_output_dir
    
    output:
    path "*.all.gff", emit: gff
    path "*.all.maker.proteins.fasta", emit: proteins
    path "*.all.maker.transcripts.fasta", emit: transcripts
    
    script:
    """
    gff3_merge -d ${maker_output_dir}/maker_output_master_datastore_index.log
    fasta_merge -d ${maker_output_dir}/maker_output_master_datastore_index.log
    """
}