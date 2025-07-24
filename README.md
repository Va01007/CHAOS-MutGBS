# CHAOS-MutGBS
Controlled Heterozygosity & Aberration Operator for Simulated mutagenic Universal Template for Genotyping-by-Sequencing Simulation is a Nextflow-based pipeline for creating mutagenized Genotyping-by-Sequencing (GBS) data.

<!-- Нужно лучше отформатировать readme -->

Pipeline Overview
This Nextflow pipeline simulates genomic sequencing data with controlled structural variations. The workflow consists of four main processes:

1. Getstats: Extracts chromosome lengths from input genomes
2. Randomize: Introduces structural variations using a Python script
3. Simulate: Generates paired-end reads with the variations
4. OUT: Collects and renames final output files

Key features:
* Simulates structural variations at specified genomic locations
* Generates paired-end FASTQ files
* Configurable variation parameters
* Parallel execution support


Requirements
* Nextflow (≥ 22.04.0)
* Python 3 (with BioPython)
* bioawk
* ngsngs simulator

Setup:
<!-- Тут как будто не хватает bash Install.sh в конце. UPD: а он и не нужен -->
```
git clone https://github.com/Va01007/CHAOS-MutGBS.git
cd CHAOS-MutGBS
```

Configuration Parameters
Core Parameters (in main.nf)
| Parameter | Default | Description |
| --------- | --------- | ----------- |
| path_file | "files.txt" | 	Input file listing reference genomes |
| outdir    | 	"results" | Output directory |
| prefix     | "VA" | Output filename prefix |
| force_file | 	"NA" | File forcing specific variations (optional) |
| chr_changes| 	"1:10" | Chromosome:position for variations |
| min_len    | 	3000000 | 	Minimum chromosome length to process |
| threads    | 	1 | 	CPU threads for simulation |
