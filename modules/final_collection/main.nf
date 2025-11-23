process COLLECT_FINAL_RESULTS {
    publishDir "${params.outdir}/final_results", mode: 'copy', overwrite: true

    input:
    path polished_assembly
    path maker_gff
    path maker_proteins
    path maker_transcripts
    path busco_summary
    path busco_full_table
    path quast_outputs
    path nanoplot_dir
    path bam
    path coverage_per_base
    path coverage_report
    path diamond_results
    path diamond_annotated
    path final_proteins
    path final_transcripts
    path bandage_png
    path bandage_svg


    output:
    path "final_results"

    script:
    """
    # Create directory structure
    mkdir -p final_results/{assembly,annotations,qc/{nanoplot,busco,quast,bandage},coverage,annotation_evidence}

    # Assembly files
    cp ${polished_assembly} final_results/assembly/polished_assembly.fasta
    samtools faidx final_results/assembly/polished_assembly.fasta

    # Annotation files
    cp ${maker_gff} final_results/annotations/genes.gff3
    cp ${final_proteins} final_results/annotations/proteins.fasta
    cp ${final_transcripts} final_results/annotations/transcripts.fasta

    # QC files
    cp ${busco_summary} final_results/qc/busco/busco_summary.txt
    cp ${busco_full_table} final_results/qc/busco/busco_full_table.tsv
    
    # Copy QUAST outputs
    find ${quast_outputs} -maxdepth 1 -type f \\( -name "*.html" -o -name "*.txt" -o -name "*.tsv" \\) -exec cp {} final_results/qc/quast/ \\;

    # NanoPlot results
    cp -r ${nanoplot_dir} final_results/qc/nanoplot

    # Coverage files (for IGV)
    cp ${bam} final_results/coverage/overlaps.sorted.bam
    samtools index final_results/coverage/overlaps.sorted.bam
    cp ${coverage_per_base} final_results/coverage/coverage_per_base.txt
    cp ${coverage_report} final_results/coverage/coverage_report.txt

    # Annotation evidence (Diamond results for reference)
    cp ${diamond_results} final_results/annotation_evidence/diamond_results.tsv
    cp ${diamond_annotated} final_results/annotation_evidence/diamond_annotated_proteins.tsv

    # Bandage outputs
    cp ${bandage_png} final_results/qc/bandage/assembly_graph.png
    cp ${bandage_svg} final_results/qc/bandage/assembly_graph.svg



    # Create manifest
cat > final_results/MANIFEST.txt << 'MANIFEST'
FINAL RESULTS MANIFEST
=====================

assembly/
  - polished_assembly.fasta: Final polished genome assembly (Racon 2-pass)
  - polished_assembly.fasta.fai: FASTA index file

annotations/
  - genes.gff3: Annotated genes (GFF3 format, from MAKER)
  - proteins.fasta: Predicted protein sequences (annotated with Diamond/SwissProt)
  - transcripts.fasta: Predicted transcript sequences

qc/
  busco/
    - busco_summary.txt: BUSCO completeness assessment summary
    - busco_full_table.tsv: Detailed BUSCO results for each gene
  quast/
    - report.html: Interactive QUAST assembly quality report
    - report.txt: Text version of QUAST report
    - Other QUAST metrics and statistics
  nanoplot/
    - NanoPlot-report.html: Read quality visualization
    - NanoStats.txt: Read statistics
  bandage/
    - assembly_graph.png: PNG image of assembly graph
    - assembly_graph.svg: SVG image of assembly graph

coverage/
  - overlaps.sorted.bam: Sorted BAM file of reads mapped to assembly (for IGV)
  - overlaps.sorted.bam.bai: BAM index file
  - coverage_per_base.txt: Per-base coverage depth
  - coverage_report.txt: Coverage summary statistics

annotation_evidence/
  - diamond_results.tsv: Raw Diamond BLASTP results (all hits)
  - diamond_annotated_proteins.tsv: Summary of best annotations per protein

USAGE NOTES
===========
- Open overlaps.sorted.bam in IGV along with genes.gff3 for genome browser visualization
- Check qc/busco/busco_summary.txt for genome completeness assessment
- View qc/nanoplot/NanoPlot-report.html for read quality metrics
- View qc/quast/report.html for assembly quality assessment
- Use annotations/proteins.fasta and annotations/transcripts.fasta for downstream functional analysis
MANIFEST
"""
}