## Workflow Description

## Environment Setup
``` 
## Create an environment (Currently on OS)
conda create -n nf -c bioconda nextflow -y;
## Due to arm64 architecture, conda environment created with osx-64
CONDA_SUBDIR=osx-64 conda create -n nf -y;
## Install Relevant packages to assignment
conda activate nf;
conda install -c bioconda -c conda-forge entrez-direct sra-tools fastqc trimmomatic skesa spades pigz tree nextflow fastp csvtk -y;
conda install bioconda::seqkit;
```

## Nextflow Version:
* Nextflow version 24.10.5.5935

## Operating System (MacOS) 
* Tools Selected include fastp, skesa, and seqkit
* Fastp was initially ran on raw Fastq sequences. These sequences were downloaded by the commands in `cmds.sh`.
* After revising and trimming the reads using 

## Workflow Image
![output_workflow_chart](https://github.com/user-attachments/assets/efacd15b-da7d-4308-9621-7ea5a991f0de)
