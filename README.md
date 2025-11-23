# Nanopore Genome Assembly Pipeline

A comprehensive Nextflow pipeline for assembling and annotating genomes from Oxford Nanopore long-read sequencing data.

## Features

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
- **Sufficient disk space** (≥100 GB recommended for intermediate files)
- **Memory**: 16 GB+ recommended

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/my-custom-nanopore-pipeline.git
cd my-custom-nanopore-pipeline
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

Nextflow will automatically create conda environments for each process using specifications in the pipeline. No manual installation needed!

## Quick Start

### 1. Set Up Your Assembly

Create a directory for your assembly with reads and configuration:
```bash
mkdir -p assemblies/my_assembly/data
```

### 2. Add Your Reads

Place your FASTQ file(s) in the data directory:
```bash
cp /path/to/reads.fastq.gz assemblies/my_assembly/data/
```

### 3. Create a Configuration File

Create `assemblies/my_assembly/config.csv`:
```csv
parameter,value
reads_path,./data/reads.fastq.gz
subsample,50000
genome_size,12m
```

**Parameters**:
- `reads_path`: Path to your FASTQ file (relative to assembly directory)
- `subsample`: Number of reads to subsample for faster assembly (0 = use all reads)
- `genome_size`: Approximate genome size (e.g., 8m for 8 megabases, 1g for 1 gigabase)

### 4. Run the Pipeline
```bash
nextflow run pipeline.nf --assembly_dir ./assemblies/my_assembly -profile mac
```

Replace `mac` with your appropriate profile:
- `mac`: macOS (local execution)
- `local`: Linux/other systems (local execution)
- `cluster`: HPC cluster (requires additional configuration)

### 5. View Results

Results will be in `assemblies/my_assembly/results/final_results/`:
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
├── coverage/                             # BAM file and coverage statistics (for IGV)
└── annotation_evidence/                 # Diamond annotation results
```

## Detailed Configuration

### Example Configurations

#### Small test assembly (fast)
```csv
parameter,value
reads_path,./data/reads.fastq.gz
subsample,10000
genome_size,12m
```

#### Full assembly (slow but comprehensive)
```csv
parameter,value
reads_path,./data/reads.fastq.gz
subsample,0
genome_size,12m
```

#### Large genome
```csv
parameter,value
reads_path,./data/reads.fastq.gz
subsample,100000
genome_size,100m
```

## Pipeline Workflow
```
DOWNLOAD_READS / Load local reads
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

You can run multiple assemblies in sequence:
```bash
for assembly in assembly_1 assembly_2 assembly_3; do
    echo "Running $assembly..."
    nextflow run pipeline.nf --assembly_dir ./assemblies/$assembly -profile mac -resume
done
```

Or use the resume flag to continue from where you left off:
```bash
nextflow run pipeline.nf --assembly_dir ./assemblies/my_assembly -profile mac -resume
```

## Using Results in IGV

1. Open **IGV** (Integrative Genomics Viewer)
2. Load genome: `assemblies/my_assembly/results/final_results/assembly/polished_assembly.fasta`
3. Load annotations: `assemblies/my_assembly/results/final_results/annotations/genes.gff3`
4. Load coverage: `assemblies/my_assembly/results/final_results/coverage/overlaps.sorted.bam`

## Customization

### Modifying Assembly Parameters

Edit `nextflow.config` to change default parameters:
```nextflow
params {
    genome_size = '12m'
    subsample = 100000
    outdir = 'shared_resources'
}
```

### Adding/Modifying Processes

Processes are located in `modules/` subdirectories. Each process has its own `main.nf` file. Modify these to customize the pipeline behavior.

### Using Different Reference Data

By default, the pipeline uses:
- S288C (baker's yeast) reference transcripts and proteins
- SwissProt database for protein annotation

To use different references, modify the `DOWNLOAD_S288C_*` processes in the pipeline.

## Troubleshooting

### Pipeline fails with "command not found"

Ensure you're using the correct Nextflow profile:
```bash
nextflow run pipeline.nf --assembly_dir ./assemblies/my_assembly -profile mac
```

### Out of memory errors

Reduce the number of subsampled reads or use fewer threads:
```bash
nextflow run pipeline.nf --assembly_dir ./assemblies/my_assembly -profile mac --subsample 10000
```

### Resume failed pipeline

Use the `-resume` flag to continue from where it stopped:
```bash
nextflow run pipeline.nf --assembly_dir ./assemblies/my_assembly -profile mac -resume
```

### Clear cache and restart
```bash
rm -rf work/
nextflow run pipeline.nf --assembly_dir ./assemblies/my_assembly -profile mac
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

- **Subsampling to 50,000 reads**: ~2-4 hours on a 4-core machine
- **Full assembly (100,000+ reads)**: 8+ hours depending on genome size and complexity
- **Shared resources** (reference data, Diamond DB) are cached after first run and reused across assemblies

## Requirements for Annotations

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

## License

[Add your license here, e.g., MIT, GPL, etc.]

## Support

For issues, questions, or contributions, please open an issue on GitHub.

## Authors

Created for reliable, reproducible nanopore genome assembly and annotation.

EOF