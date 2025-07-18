#!/usr/bin/env nextflow


/*
========================================================================================
Pipeline parameters
========================================================================================
*/

params.path_file = "files.txt"
params.outdir = './results'
params.counts = 1
params.prefix = "VA"
params.force_file = "NA"
params.chr_changes = "1:10"
params.min_len = 3000000
params.read_length = 120
params.coverage = 0.05
params.threads = 1


process Getstats {

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
    publishDir "${params.outdir}/${params.prefix}", mode: 'move', pattern: '*.txt'

    input:
    path bed_files
    path force_file
    val chr_changes
    val min_len
    val prefix

    output:
    path "*_edited.bed"
    path "log.txt"

    script:
    """
    python3 "${projectDir}/bin/Randomizer.py" ${force_file} ${chr_changes} ${min_len} ${bed_files}
    """
}



process Simulate {

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
    publishDir params.outdir, mode: 'move', pattern: '*.fq.gz'

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
    beds = Getstats(Channel.fromPath(params.path_file))
    randomizer = Randomize(beds.collect(), Channel.fromPath(params.force_file), params.chr_changes, params.min_len, params.prefix)
    Simulate(randomizer.collect(), Channel.fromPath(params.path_file),  params.threads, params.read_length, params.coverage)
    Paired_reads = Simulate.out.R1.combine(Simulate.out.R2.collect())
    OUT(Paired_reads, params.prefix)
}