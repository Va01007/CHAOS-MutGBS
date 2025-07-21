#!/bin/bash

# Create and activate Conda environment
# Стоит создать yaml файл для среды и создавать через него.
conda create -y -n CHAOS_MutGBS python=3.9 \
    bioconda::nextflow \
    bioconda::bioawk \
    conda-forge::make \
    conda-forge::automake \
    conda-forge::autoconf \
    conda-forge::libtool \
    conda-forge::zlib \
    conda-forge::bzip2 \
    conda-forge::r-renv \
    conda-forge::xz \
    conda-forge::curl \
    conda-forge::gcc \
    -c conda-forge -c bioconda

conda activate CHAOS_MutGBS
# conda activate внутри скрипта не работает без conda init потому что в момент начала выполнения скрипта открывается новый терминал которые не знает про conda. Соответственно, при запуске скрипта у меня вылетела ошибка "CondaError: Run 'conda init' before 'conda activate'".
# К сожалению, выполнение скрипта на это не остановилось. Стоит использовать bash strict mode (погугли) для таких ситуаций.

# Clone repositories
# Разве запуск самого этого скрипта не подразумевает, что эта команда уже выполнена?
# git clone https://github.com/Va01007/CHAOS-MutGBS.git
# cd CHAOS-MutGBS

# Почему нельзя установить ngsngs прямо из репозиториев конды? htslib сразу подтянется как зависимость.
# В результате весь этот скрипт сводится к тому, что нужно создать окружение конды, а это делается через yaml файл и можно вообще этот скрипт удалить и вместо него сделать yaml файл с фиксацией версий софта в окружении.
git clone https://github.com/samtools/htslib.git
git clone https://github.com/RAHenriksen/NGSNGS.git
cd htslib

git submodule update --init --recursive
make
cd ../NGSNGS; make HTSSRC=../htslib


# Add to PATH within environment
mkdir -p $CONDA_PREFIX/envs/CHAOS_MutGBS/bin
cp ngsngs $CONDA_PREFIX/envs/CHAOS_MutGBS/bin/
cd ../..

echo "Installation complete!"
echo "Activate environment with: conda activate CHAOS_MutGBS"
echo "Verify with: ngsngs --help"