#!/usr/bin/bash
#SBATCH -N 1 -n 16 -p short --mem 16gb --out logs/make_cov.%a.log

module load bwa
module load samtools/1.9
N=${SLURM_ARRAY_TASK_ID}
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
 CPU=$SLURM_CPUS_ON_NODE
fi


if [ -z $N ]; then
 N=$1
fi

if [ -z $N ]; then
 echo "need to provide a number by --array or cmdline"
 exit
fi
mkdir -p bam
ASSEMBLY=$(ls genomes/*.sorted.fasta | sed -n ${N}p)
BASE=$(basename $ASSEMBLY .sorted.fasta)
BAM=bam/$BASE.remap.bam
FWD=fastq/${BASE}_R1.fq.gz
REV=fastq/${BASE}_R2.fq.gz
if [ ! -f $BAM ]; then
	if [ ! -f $ASSEMBLY.bwt ]; then
		bwa index $ASSEMBLY
	fi
	bwa mem -t $CPU $ASSEMBLY $FWD $REV | samtools sort --threads $CPU -T /scratch -O bam -o $BAM -
fi
if [ ! -f $BAM.bai ]; then
	samtools index $BAM
fi
