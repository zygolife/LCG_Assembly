#!/usr/bin/bash
#SBATCH --time 2-0:0:0 --mem 512G -p highmem --nodes 1 --ntasks 24 -J spadesConPum --out logs/spades_ConPum.log 
MEM=512
CPU=24
module load SPAdes
SCRATCH=/scratch/jstajich/3644648
mkdir -p $SCRATCH

#spades.py --threads $CPU --cov-cutoff auto --mem $MEM --careful -o working_AAFTF/spades_Conidiobolus_pumilus_ARSEF_6383 --tmp-dir $SCRATCH  --pe1-1 /bigdata/stajichlab/shared/projects/ZyGoLife/LCG/Assembly/working_AAFTF/Conidiobolus_pumilus_ARSEF_6383_filtered_1.fastq.gz --pe1-2 /bigdata/stajichlab/shared/projects/ZyGoLife/LCG/Assembly/working_AAFTF/Conidiobolus_pumilus_ARSEF_6383_filtered_2.fastq.gz 

spades.py --restart-from last --threads $CPU --cov-cutoff auto --careful --mem $MEM -o working_AAFTF/spades_Conidiobolus_pumilus_ARSEF_6383

#--pe1-1 /bigdata/stajichlab/shared/projects/ZyGoLife/LCG/Assembly/working_AAFTF/Conidiobolus_pumilus_ARSEF_6383_filtered_1.fastq.gz --pe1-2 /bigdata/stajichlab/shared/projects/ZyGoLife/LCG/Assembly/working_AAFTF/Conidiobolus_pumilus_ARSEF_6383_filtered_2.fastq.gz
