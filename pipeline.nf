#!/usr/bin/env nextflow

// Pipeline parameters

params.sra_accession = 'SRR21031641' 
params.outdir = 'results'
params.genome_size = '12m' // Appoximate genome size, e.g., 12m for 12 megabases
params.subsample = 100000 // Set to 0 to skip subsampling


// Module INCLUDE statements

include { DOWNLOAD_READS } from './modules/fasterq/main.nf'
include { SUBSAMPLE_READS } from './modules/seqtk/main.nf'
include { QC_NANOPLOT } from './modules/nanoplot/main.nf'   
include { FLYE_ASSEMBLY } from './modules/flye/main.nf'
include { QC_QUAST } from './modules/quast/main.nf'
include { QC_BANDAGE } from './modules/bandage/main.nf'
include { ANNOTATE_AUGUSTUS } from './modules/augustus/main.nf'
include { QC_BUSCO } from './modules/busco/main.nf'
include { DOWNLOAD_S288C_CDNA } from './modules/download/main.nf'
include { DOWNLOAD_S288C_PROTEINS } from './modules/download/main.nf'
include { CREATE_DIAMOND_DB } from './modules/diamond/main.nf'
include { ANNOTATE_DIAMOND } from './modules/diamond/main.nf'
include { PROCESS_ANNOTATION_OUTPUT } from './modules/python/main.nf'
include { ANNOTATE_MAKER } from './modules/maker/main.nf'
include { MERGE_MAKER_OUTPUT } from './modules/maker/main.nf'
include { SEQUENCE_ANNOTATION_PYTHON } from './modules/custom_annotation/main.nf'
include { POLISH_RACON } from './modules/racon/main.nf'
include { QC_COVERAGE } from './modules/minimap2/main.nf'
include { COLLECT_FINAL_RESULTS } from './modules/final_collection/main.nf'

// Primary workflow definition

workflow {

DOWNLOAD_READS()

if (params.subsample > 0) {
        SUBSAMPLE_READS(DOWNLOAD_READS.out.reads)
        reads_ch = SUBSAMPLE_READS.out.reads
} else {
        reads_ch = DOWNLOAD_READS.out.reads
    }
    
    
QC_NANOPLOT(reads_ch)

FLYE_ASSEMBLY(reads_ch)

QC_BANDAGE(FLYE_ASSEMBLY.out.assembly_graph)

POLISH_RACON(FLYE_ASSEMBLY.out.assembly, reads_ch)

QC_COVERAGE(POLISH_RACON.out.polished_assembly, reads_ch)

QC_QUAST(POLISH_RACON.out.polished_assembly)

QC_BUSCO(POLISH_RACON.out.polished_assembly)

DOWNLOAD_S288C_CDNA()

DOWNLOAD_S288C_PROTEINS()

ANNOTATE_MAKER(POLISH_RACON.out.polished_assembly, DOWNLOAD_S288C_CDNA.out.S288C_cDNA, DOWNLOAD_S288C_PROTEINS.out.S288C_proteins)

MERGE_MAKER_OUTPUT(ANNOTATE_MAKER.out.maker_output_dir)

CREATE_DIAMOND_DB(DOWNLOAD_S288C_PROTEINS.out.S288C_proteins)

ANNOTATE_DIAMOND(MERGE_MAKER_OUTPUT.out.proteins, CREATE_DIAMOND_DB.out.swissprot_and_s288c_prot_db)

SEQUENCE_ANNOTATION_PYTHON(MERGE_MAKER_OUTPUT.out.proteins, MERGE_MAKER_OUTPUT.out.transcripts, ANNOTATE_DIAMOND.out.results, file("${projectDir}/bin/format_final_CDS_and_transcript_seqs.py"))

COLLECT_FINAL_RESULTS(
    POLISH_RACON.out.polished_assembly,
    MERGE_MAKER_OUTPUT.out.gff,
    MERGE_MAKER_OUTPUT.out.proteins,
    MERGE_MAKER_OUTPUT.out.transcripts,
    QC_BUSCO.out.summary,
    QC_BUSCO.out.full_table,
    QC_QUAST.out.outputs,
    QC_NANOPLOT.out[0],
    QC_COVERAGE.out.sorted_bam,
    QC_COVERAGE.out.per_base_coverage,
    QC_COVERAGE.out.report,
    ANNOTATE_DIAMOND.out.results,
    ANNOTATE_DIAMOND.out.annotated,
    SEQUENCE_ANNOTATION_PYTHON.out.final_proteins,
    SEQUENCE_ANNOTATION_PYTHON.out.final_transcripts,
    QC_BANDAGE.out.png,
    QC_BANDAGE.out.svg
)

}