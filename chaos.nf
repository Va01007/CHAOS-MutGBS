#!/usr/bin/env nextflow


/*
========================================================================================
Pipeline parameters
========================================================================================
*/

params.path_file = "files.txt"
params.outdir = './results'
params.counts = 1 // Этот параметр нигде не используется
params.prefix = "VA"
params.force_file = "NA"  // Название не понятно. Не ясно почему NA строкой.
params.chr_changes = "1:10" // Видимо это границы количества интрогрессий. Лучше разбить на два параметра - минимальное и максимальное значение. Легче будет проверять граничные условия. Например, -1.
params.min_len = 3000000 // Тоже сходу не ясно минимальная длина чего именно.
params.read_length = 120 // Немного необычное дефолтное значение, мне кажется.
params.coverage = 0.05 // В документации не увидел описания что это такое. Стоит дать более говорящее название.
params.threads = 1 // Задокументируй лучше. Это не просто для симуляции количество ядер, а именно для ngsngs


process Getstats {
    // Не хвататет описания что делает каждый процесс.

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
    publishDir "${params.outdir}/${params.prefix}", mode: 'move', pattern: '*.txt' // Перемещение файлов не ломает пайплайн?

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
                    // Почему qs именно 36? Почему это тоже не вынес в параметры пайплайна?
                    ngsngs -i \${m_line} -t ${threads} -c ${cov} -l ${length} -seq PE -f fq.gz -qs 36 -incl \${file} -o \${filename}
                fi
            done < $input_file
    done
    """
}


process OUT {
    // Нужно процессам давать более понятные названия
    publishDir params.outdir, mode: 'move', pattern: '*.fq.gz'

    input:
    tuple path(r1), path(r2)
    val prefix

    output:
    path "${prefix}_R1.fq.gz", emit: final_R1 // Зачем здесь эмитить если никуда дальше не идет это?
    path "${prefix}_R2.fq.gz", emit: final_R2 // Такой же вопрос

    script:
    """
    zcat ${r1} >> ${prefix}_R1.fq.gz
    zcat ${r2} >> ${prefix}_R2.fq.gz
    """
}


workflow {
    beds = Getstats(Channel.fromPath(params.path_file))
    Randomize(beds.collect(), Channel.fromPath(params.force_file), params.chr_changes, params.min_len, Channel.fromPath(params.path_file))
    Simulate(Randomize.out.BD.collect(), Channel.fromPath(params.path_file),  params.threads, params.read_length, params.coverage)
    Paired_reads = Simulate.out.R1.combine(Simulate.out.R2.collect())
    OUT(Paired_reads, params.prefix)
}