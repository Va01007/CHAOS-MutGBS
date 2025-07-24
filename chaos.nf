#!/usr/bin/env nextflow


/*
========================================================================================
Pipeline parameters
========================================================================================
*/

// Input/Output parameters
params.input_files = "files.txt"          // Path to file containing list of reference genome files
params.output_dir = './results'          // Output directory for pipeline results
params.output_prefix = "VA"              // Prefix for output filenames

// Introgression parameters
params.forced_regions = "NA"             // File with predefined introgression regions (NA = not specified)
params.introgression_range = "1:10"      // Range of introgressions per chromosome (min:max)
params.min_region_length = 3000000       // Minimum introgression region length (base pairs)

// Read simulation parameters
params.read_length = 120                 // Simulated read length (base pairs)
params.coverage_depth = 0.05             // Sequencing coverage depth (fractional)
params.base_quality = 36                 // Simulated read quality (Phred score)

// Execution parameters
params.threads = 1                       // Number of CPU threads for ngsngs simulator

/*
PARAMETER REFERENCE:

Input/Output Configuration:
- input_files:       Text file containing paths to reference genome FASTA files
- output_dir:        Directory path for pipeline output files
- output_prefix:     Prefix for all output filenames

Introgression Settings:
- forced_regions:    BED file specifying forced introgression regions ("NA" for auto-selection)
- introgression_range: Number of introgressions per chromosome as "min:max" 
- min_region_length: Minimum length for introgression regions in base pairs

Read Simulation:
- read_length:      Length of simulated sequencing reads (typical: 100-150bp)
- coverage_depth:   Target sequencing coverage (0.05 = 5% of genome)
- base_quality:     Mean base quality score for simulated reads

Performance:
- threads:         CPU cores allocated for ngsngs read simulation
*/

process Getstats {
    /*
    Process: Getstats
    Purpose: Generates BED files with chromosome lengths from input reference genomes
    Input: File containing paths to reference genome files
    Output: One BED file per reference genome with chromosome coordinates
    */
    input:
    path input_file

    output:
    path "*.bed"

    script:
    """
    while read -r m_line
    do
        filename=\$(basename "\${m_line}")
        filename="\${filename%.*}" 
        bioawk -c fastx '{print \$name"\t0\t"length(\$seq)}' \${m_line} > \${filename}.bed
    done < $input_file
    """
}


process Randomize {
    /*
    Process: Randomize
    Purpose: Selects random regions for introgression simulation
    Input: BED files from Getstats, optional forced regions file
    Output: Modified BED files with selected regions and log file
    */
    publishDir "${params.output_dir}/${params.prefix}", mode: 'move', pattern: '*.txt'

    input:
    path bed_files
    path force_file
    val chr_changes
    val min_len
    path(input_file)

    output:
    path "*_edited.bed", emit: BD
    path "log.txt"

    script:
    """
    python3 "${projectDir}/bin/Randomizer.py" ${force_file} ${chr_changes} ${min_len} ${input_file} ${bed_files}
    """
}



process Simulate {
    /*
    Process: Simulate
    Purpose: Simulates paired-end reads for selected regions
    Input: Modified BED files, reference genomes, simulation parameters
    Output: Gzipped FASTQ files (R1 and R2) for each sample
    */
    input:
    path new_bed_files
    path input_file
    val threads
    val length
    val cov

    output:
    path "*R1.fq.gz" , emit: R1
    path "*R2.fq.gz", emit: R2

    script:
    """
    for file in $new_bed_files
    do
        while read -r m_line
            do
                filename=\$(basename "\${m_line}")
                filename="\${filename%.*}" 
                if [ *\${filename}* == \${file} ]
                then
                    ngsngs -i \${m_line} -t ${threads} -c ${cov} -l ${length} -seq PE -f fq.gz -qs 36 -incl \${file} -o \${filename}
                fi
            done < $input_file
    done
    """
}


process OUT {
    /*
    Process: OUT
    Purpose: Merges all simulated reads into final output files
    Input: All simulated read pairs from Simulate process
    Output: Consolidated FASTQ files with specified prefix
    */
    publishDir params.output_dir, mode: 'copy', pattern: '*.fq.gz'

    input:
    tuple path(r1), path(r2)
    val prefix

    output:
    path "${prefix}_R1.fq.gz", emit: final_R1
    path "${prefix}_R2.fq.gz", emit: final_R2

    script:
    """
    zcat ${r1} >> ${prefix}_R1.fq.gz
    zcat ${r2} >> ${prefix}_R2.fq.gz
    """
}


workflow {
    // Generate BED files from reference genomes
    beds = Getstats(Channel.fromPath(params.input_files))
    
    // Randomize introgression regions
    Randomize(
        beds.collect(), 
        Channel.fromPath(params.forced_regions), 
        params.introgression_range, 
        params.min_region_length, 
        Channel.fromPath(params.input_files)
    )
    
    // Simulate reads for each region
    Simulate(
        Randomize.out.BD.collect(), 
        Channel.fromPath(params.input_files),
        params.threads,
        params.read_length,
        params.coverage_depth
    )
    
    // Combine paired reads
    Paired_reads = Simulate.out.R1.combine(Simulate.out.R2.collect())
    
    // Merge all reads into final output
    OUT(Paired_reads, params.output_prefix)
}