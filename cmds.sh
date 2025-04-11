#!/usr/bin/env bash

## Create an environment (Currently on OS)
conda create -n nf -c bioconda nextflow -y;

## Due to arm64 architectyre, conda environment created with osx-64
CONDA_SUBDIR=osx-64 conda create -n nf -y;

## Install Relevant packages to assignment
conda activate nf;
conda install -c bioconda -c conda-forge entrez-direct sra-tools fastqc trimmomatic skesa spades pigz tree nextflow fastp csvtk -y;
conda install bioconda::seqkit;

## Create separate environment for tools. Environment also includes nextflow

## Check nextflow Version:  nextflow version 24.10.5.5935
nextflow -v;

## Make directory for output raw fastqs. 
mkdir -p Raw_FastQs;
mkdir -p AssemblyData;

## Send all workflow output to this folder
mkdir -p data_results;
mkdir -p data_results/fastp_results;
mkdir -p data_results/assembly_results;
mkdir -p data_results/seqkit_results;
mkdir -p data_results/contig_analysis_sequential_stats
cd Raw_FastQs;

## Downloaded fastq files
for accession in SRR1556289 SRR1556296 SRR1556290; do
    prefetch "${accession}"
done;
for accession in SRR1556289 SRR1556296 SRR1556290; do
  fasterq-dump \
   "${accession}" \
   --outdir . \
   --split-files \
   --skip-technical
done
pigz -9 *.fastq;



nextflow run main.nf;

## Tools using:

# Workflow must have both: 

#1. Sequential processing: where output of one step (in a nextflow "module") gets passed onto the next

#2. Parallel processing: where two independent "modules" (tasks) are done at the same time


#Workflow Overview:

## Setup conda environment with all 3 of these tools:


# Yes! You can combine sequential and parallel requirements with as 
# little as three modules: 
# 1. From raw FastQ, run fastp on it ("Module 1") 
# 2. Output from fastp then used to run spades (for assembly, "Module 2"), 
# and output from fastp also used to run seqkit (for read metrics, "Module 3") 
# at the same time (in parallel)
