#!/usr/bin/env nextflow

// Ensure correct version for nextflow
nextflow.enable.dsl = 2
// Define parameters with default values
params.reads = "$baseDir/Raw_FastQs/*_{1,2}.fastq.gz"
// Main results directory: Sub directory for data includes data_results/fastp_results, data_results/assembly_results, data_results/seqkit_results, data_results/contig_analysis_subsequences
params.outdir = "$baseDir/data_results"
// Initialize help parmeter
params.help = false


// Show help message
if (params.help) {
    log.info"""
    Usage:
    nextflow run workflow_parallel_sequential.nf 
    Default provided reads argument is: reads = '$baseDir/Raw_FastQs/*_{1,2}.fastq.gz'
    
    Required arguments: (Default already provided in workflow script for data)
      --reads         Path to input fastq reads: Default $baseDir/Raw_FastQs/*_{1,2}.fastq.gz
    
    Optional arguments:
      --outdir        Output directory. default is $baseDir/data_results
      --help          Display this help message
    """
    exit 0
}

// Log parameters
log.info"""
Reads        : ${params.reads}
Output dir   : ${params.outdir}
"""

// Module 1: Quality control and trimming with fastp
process initial_fastp_step {
    publishDir "${params.outdir}/fastp_results", mode: 'copy'
    
    input:
    tuple val(sample_id), path(reads)
    
    output:
    tuple val(sample_id), path("revised_${sample_id}_1.fastq.gz"), path("revised_${sample_id}_2.fastq.gz"), emit: revised_reads
    path "${sample_id}_fastp.json", emit: json
    path "${sample_id}_fastp.html", emit: html
    
    script:
    """
    fastp \
        -i ${reads[0]} \
        -I ${reads[1]} \
        -o revised_${sample_id}_1.fastq.gz \
        -O revised_${sample_id}_2.fastq.gz \
        --json ${sample_id}_fastp.json \
        --html ${sample_id}_fastp.html \
    """
}

// Module 2: Parallel Process, Assembly with SKESA
process parallel_skesa_step {
    publishDir "${params.outdir}/assembly_results",mode: 'copy'
    
    input:
    tuple val(sample_id), path(revised_read1),path(revised_read2)
    
    output:
    tuple val(sample_id), path("${sample_id}_contigs.fasta"),emit: contigs
    
    script:
    """
    ## Gunzip files for skesa
    gunzip -c ${revised_read1} > read1_output.fastq
    gunzip -c ${revised_read2} > read2_output.fastq
    
    # Run SKESA
    skesa --reads read1_output.fastq,read2_output.fastq \
          --contigs_out ${sample_id}_contigs.fasta
    """
}

// Module 3: Parallel Process, same time as skesa (stats with seqkit)
process parallel_seqkit_step {
    publishDir "${params.outdir}/seqkit_results", mode: 'copy'
    
    input:
    tuple val(sample_id), path(revised_read1), path(revised_read2)
    
    output:
    tuple val(sample_id), path("${sample_id}_stats.txt"), emit: stats
    
    script:
    """
    # Run SeqKit stats on both trimmed read files
    seqkit stats -a ${revised_read1} ${revised_read2} > ${sample_id}_stats.txt
    """
}

// Module 4: Sequential analysis run on contig outputs using seqkit
process sequential_step_seqkit {
    publishDir "${params.outdir}/contig_analysis_sequential_stats", mode: 'copy'
    
    input:
    tuple val(sample_id), path(contigs)
    
    output:
    tuple val(sample_id), path("${sample_id}_contig_analysis_stats.txt"), emit: analysis
    
    script:
    """
    # Analyze contig stats with seqktit
    seqkit stats -Ta ${contigs} > ${sample_id}_contig_analysis_stats.txt

    """
}

// Workflow for sequential and parallel process
workflow {
    // Channel for fastq reads
    read_pairs_ch = Channel.fromFilePairs(params.reads, checkIfExists: true)
    
    // Run fastp on raw reads (this is initial step. to setup parallel process)
    initial_fastp_step(read_pairs_ch)
    
    // Skesa and seqkit are run using same output, ensuring that they are run in parallel
    parallel_skesa_step(initial_fastp_step.out.revised_reads)
    parallel_seqkit_step(initial_fastp_step.out.revised_reads)
    
    // Run analysis on skesa output (sequential) from previous parallel step
    sequential_step_seqkit(parallel_skesa_step.out.contigs)
}

// Workflow completion message
workflow.onComplete {
    log.info "Pipeline completed: $workflow.complete"
    log.info "Pipeline status for completion = ${ workflow.success }"
}