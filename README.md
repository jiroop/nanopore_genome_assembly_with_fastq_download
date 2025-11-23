# Nanopore Genome Assembly Pipeline

A comprehensive Nextflow pipeline for assembling and annotating genomes from Oxford Nanopore long-read sequencing data downloaded from NCBI SRA.

## Features

- **Automated Data Download**: Automatically downloads Nanopore reads from NCBI SRA
- **Assembly**: High-quality genome assembly using Flye de novo assembler
- **Polishing**: 2-pass error correction with Racon to improve accuracy
- **Quality Control**:
  - NanoPlot: Read quality and statistics visualization
  - QUAST: Assembly quality metrics and statistics
  - BUSCO: Genome completeness assessment
  - Bandage: Assembly graph visualization
  - Coverage analysis: Per-base coverage depth and mapping statistics
- **Annotation**:
  - Gene prediction with MAKER + Augustus
  - Protein homology annotation with Diamond/SwissProt
  - Integration of RNA-seq and protein evidence
- **Results**: Organized final output directory with assembly, annotations, QC reports, and evidence files

## Requirements

- **Nextflow** >= 25.04.7
- **Conda** or **Mamba** (for dependency management)
- **Sufficient disk space** (≥200 GB recommended for intermediate files and downloads)
- **Memory**: 16 GB+ recommended
- **Internet connection** (to download reads from NCBI SRA)

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/jiroop/nanopore_genome_assembly_with_fastq_download.git
cd nanopore_genome_assembly_with_fastq_download
```

### 2. Install Nextflow (if not already installed)
```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
./nextflow version
```

Or install via conda:
```bash
conda install -c bioconda nextflow
```

### 3. Install Conda/Mamba

Nextflow will automatically create conda environments for each process. No manual installation needed!

## Quick Start

### 1. Edit Pipeline Parameters

Open `pipeline.nf` and edit these parameters at the top:
```nextflow
params.sra_accession = 'SRR21031641'  // Change to your SRA accession
params.outdir = 'results'
params.genome_size = '12m'            // Change to your approximate genome size
params.subsample = 100000             // Change to desired number of reads (0 = use all)
```

**Parameter descriptions**:
- `sra_accession`: NCBI SRA accession number (e.g., SRR21031641)
- `genome_size`: Approximate genome size (e.g., 8m for 8 megabases, 12m for yeast, 100m for larger genomes)
- `subsample`: Number of reads to subsample for faster assembly (0 = use all reads)
- `outdir`: Output directory for results

### 2. Run the Pipeline
```bash
nextflow run pipeline.nf -profile mac
```

Replace `mac` with your appropriate profile:
- `mac`: macOS (local execution)
- `local`: Linux/other systems (local execution)
- `cluster`: HPC cluster (requires additional configuration)

The pipeline will:
1. Download reads from NCBI SRA automatically
2. (Optional) Subsample reads if specified
3. Run quality control on reads
4. Assemble the genome
5. Polish the assembly
6. Annotate genes
7. Organize all results in `results/final_results/`

### 3. View Results

Results will be in `results/final_results/`:
```
final_results/
├── assembly/
│   └── polished_assembly.fasta          # Your final genome assembly
├── annotations/
│   ├── genes.gff3                       # Annotated genes (GFF3 format)
│   ├── proteins.fasta                   # Predicted protein sequences
│   └── transcripts.fasta                # Predicted transcript sequences
├── qc/
│   ├── busco/                           # BUSCO completeness assessment
│   ├── quast/                           # Assembly quality metrics
│   └── nanoplot/                        # Read quality reports
├── coverage/                             # BAM file and coverage statistics
└── annotation_evidence/                 # Diamond annotation results
```

## Example Parameter Configurations

### Small Test Assembly (Fast)

Edit `pipeline.nf`:
```nextflow
params.sra_accession = 'SRR21031641'
params.genome_size = '12m'
params.subsample = 10000
```

### Full Assembly (Comprehensive)
```nextflow
params.sra_accession = 'SRR21031641'
params.genome_size = '12m'
params.subsample = 0  // Use all reads
```

### Large Genome
```nextflow
params.sra_accession = 'SRR12345678'
params.genome_size = '100m'
params.subsample = 100000
```

## Finding Your SRA Accession

1. Go to [NCBI SRA](https://www.ncbi.nlm.nih.gov/sra)
2. Search for your organism or project
3. Find your run accession (starts with SRR, ERR, or DRR)
4. Copy that accession into `params.sra_accession` in `pipeline.nf`

Example: `SRR21031641` is a baker's yeast (Saccharomyces cerevisiae) Nanopore assembly

## Pipeline Workflow
```
DOWNLOAD_READS (from NCBI SRA)
    ↓
[Optional] SUBSAMPLE_READS
    ↓
QC_NANOPLOT (read quality assessment)
    ↓
FLYE_ASSEMBLY (de novo assembly)
    ↓
QC_BANDAGE (visualize assembly graph)
    ↓
POLISH_RACON (2-pass error correction)
    ↓
QC_COVERAGE (map reads back to assembly)
    ↓
QC_QUAST (assembly quality metrics)
    ↓
QC_BUSCO (completeness assessment)
    ↓
ANNOTATE_MAKER (gene prediction with evidence)
    ↓
CREATE_DIAMOND_DB (build protein search database)
    ↓
ANNOTATE_DIAMOND (annotate proteins)
    ↓
SEQUENCE_ANNOTATION_PYTHON (format final annotations)
    ↓
COLLECT_FINAL_RESULTS (organize outputs)
```

## Running Multiple Assemblies

For each new SRA accession you want to assemble:

1. Edit `pipeline.nf` and change `params.sra_accession` to your new SRA accession
2. Run the pipeline:
```bash
   nextflow run pipeline.nf -profile mac -resume
```

To avoid re-downloading shared resources (reference data, Diamond DB), use the `-resume` flag.

**Note**: Each run overwrites the previous results in `results/`. Save important results before starting a new assembly.

## Resuming a Failed Assembly

If your pipeline fails or is interrupted, resume from where it left off:
```bash
nextflow run pipeline.nf -profile mac -resume
```

## Using Results in IGV

1. Open **IGV** (Integrative Genomics Viewer)
2. Load genome: `results/final_results/assembly/polished_assembly.fasta`
3. Load annotations: `results/final_results/annotations/genes.gff3`
4. Load coverage: `results/final_results/coverage/overlaps.sorted.bam`

## Customization

### Modifying Assembly Parameters

Edit `pipeline.nf` to change parameters:
```nextflow
params {
    sra_accession = 'SRR21031641'
    genome_size = '12m'
    subsample = 100000
    outdir = 'results'
}
```

### Adding/Modifying Processes

Processes are located in `modules/` subdirectories. Each process has its own `main.nf` file. Modify these to customize pipeline behavior.

### Using Different Reference Data

By default, the pipeline uses:
- S288C (baker's yeast) reference transcripts and proteins
- SwissProt database for protein annotation

To use different references, modify the `DOWNLOAD_S288C_*` processes in the pipeline.

## Troubleshooting

### Invalid SRA Accession

Make sure your SRA accession is correct and matches the format (e.g., SRR21031641, ERR123456, DRR789012). Check [NCBI SRA](https://www.ncbi.nlm.nih.gov/sra) for valid accessions.

### Downloads are Slow

Large Nanopore datasets (10GB+) may take several hours to download from SRA. Use `-resume` to continue if the download is interrupted.

### Out of Memory Errors

Reduce the number of subsampled reads by editing `pipeline.nf`:
```nextflow
params.subsample = 10000
```

### Resume Failed Pipeline

Use the `-resume` flag to continue from where it stopped:
```bash
nextflow run pipeline.nf -profile mac -resume
```

### Clear Cache and Restart
```bash
rm -rf work/
nextflow run pipeline.nf -profile mac
```

## Output Files Guide

| File | Description |
|------|-------------|
| `polished_assembly.fasta` | Your final genome assembly |
| `genes.gff3` | Annotated genes (GFF3 format) |
| `proteins.fasta` | Predicted protein sequences with annotations |
| `transcripts.fasta` | Predicted transcript sequences |
| `busco_summary.txt` | BUSCO completeness assessment |
| `report.html` | QUAST assembly quality report |
| `overlaps.sorted.bam` | Read alignments (for IGV) |
| `diamond_results.tsv` | Protein homology annotations |

## Performance Notes

- **Download time**: Depends on dataset size and internet speed (10-50 hours for large datasets)
- **Subsampling to 50,000 reads**: ~2-4 hours on a 4-core machine
- **Full assembly (100,000+ reads)**: 8+ hours depending on genome size and complexity
- **Shared resources** (reference data, Diamond DB) are cached after first run and reused across assemblies

## Requirements for Quality Annotations

For best results with MAKER annotations:
- High-quality draft assembly (high N50, low error rate)
- Sufficient read depth (≥20x recommended)
- Reference species with annotated genomes (for homology evidence)

## Citation

If you use this pipeline, please cite the tools it depends on:

- **Flye**: Kolmogorov et al. (2019) Nat Biotechnol
- **Racon**: Vaser et al. (2017) Genome Biology
- **MAKER**: Campbell et al. (2014) Genome Biology
- **Diamond**: Buchfink et al. (2021) Nat Methods
- **BUSCO**: Simão et al. (2015) Bioinformatics
- **QUAST**: Gurevich et al. (2013) Bioinformatics
- **NanoPlot**: De Coster et al. (2023) Bioinformatics

EOF