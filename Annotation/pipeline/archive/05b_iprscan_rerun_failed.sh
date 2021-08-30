#!/usr/bin/bash
#SBATCH --ntasks 48 --nodes 1 --mem 96G -p short --out iprscan_rerun.log

# -p intel --time 72:00:00 --out iprscan_rerun.log
module unload miniconda2
module unload miniconda3
module load anaconda3
module load funannotate/development
module unload perl
module unload python
source activate funannotate
module load iprscan
module unload perl
CPU=1
date
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
	    CPU=$SLURM_CPUS_ON_NODE
fi
# let's pick this more hard-codeed based on the number of embeded workers that will run
SPLIT_CPU=4
PARALLEL=12
runipr() {
    f=$1
    if [ ! -s $f.xml ]; then
	# time interproscan.sh -f xml -i $f --cpu $SPLIT_CPU --disable-precalc > $f.log
	time interproscan.sh -f xml -i $f --cpu $SPLIT_CPU > $f.log
    fi
}
export -f runipr
export SPLIT_CPU
parallel -j $PARALLEL runipr ::: $(ls *.fasta)
../scripts/combine_iprxml.py
#mv iprscan.xml iprscan.xml.old
#perl ../scripts/fix_iprscan_xml.pl iprscan.xml.old > iprscan.xml

date
