#!/bin/bash

# Create and activate Conda environment
conda create -y -n CHAOS_MutGBS python=3.9 \
    bioconda::nextflow \
    bioconda::bioawk \
    conda-forge::make \
    conda-forge::automake \
    conda-forge::autoconf \
    conda-forge::libtool \
    conda-forge::zlib \
    conda-forge::bzip2 \
    conda-forge::r-renv
    conda-forge::xz \
    conda-forge::curl \
    conda-forge::gcc \
    -c conda-forge -c bioconda

conda activate CHAOS_MutGBS

# Clone repositories
git clone https://github.com/Va01007/CHAOS-MutGBS.git
cd CHAOS-MutGBS

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