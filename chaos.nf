#!/usr/bin/env nextflow


/*
========================================================================================
Pipeline parameters
========================================================================================
*/

params.path_file = "files.txt"
params.outdir = "results"
params.counts = 1
params.prefix = "VA"
params.force_file = "NA"
params.chr_changes = "1:10"
params.min_len = 3000000
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

    input:
    path bed_files
    path force_file
    val chr_changes
    val min_len

    output:
    path "*_edited.bed"

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

    output:
    path "*R1.fq" , emit: R1
    path "*R2.fq", emit: R2

    script:
    """
    for file in $new_bed_files
    do
        filename=\$(basename "\${file}")
        filename="\${filename%.*}" 
        while read -r m_line
            do
                anotherfname=\$(basename "\${file}")
                anotherfname="\${anotherfname%.*}" 
                if [ \${filename} == \${anotherfname} ]
                then
                    ngsngs -i \${m_line} -c 10 -t ${threads} -l 120 -seq PE -f fq -qs 30 -incl \${file} -o ${filename}
                fi
            done < $input_file
    done
    """
}


process OUT {
    publishDir params.outdir, mode: 'copy', pattern: '*.fq'

    input:
    tuple path(r1), path(r2)
    val prefix

    output:
    path "*.fq"

    script:
    """
    cat ${r1} > ${prefix}_R1.fq
    cat ${r2} > ${prefix}_R2.fq
    """
}


workflow {
    beds = Getstats(Channel.fromPath(params.path_file))
    randomizer = Randomize(beds.collect(), Channel.fromPath(params.force_file), params.chr_changes, params.min_len)
    Simulate(randomizer.collect(), Channel.fromPath(params.path_file),  params.threads)
    Paired_reads = Simulate.out.R1.combine(Simulate.out.R2)
    OUT(Paired_reads, params.prefix)
}