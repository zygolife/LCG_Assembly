#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/genemark_train.%a.log
module unload perl
module unload perl
module load perl/5.20.2
module load genemarkHMM

GMFOLDER=`dirname $(which gmhmme3)`

if [ ! -f ~/.gm_key ]; then
	ln -s $GMFOLDER/.gm_key ~/.gm_key
fi
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=annotate

SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi
IFS=,
cat $SAMPFILE | sed -n ${N}p | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
	name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g; ')
	if [ ! -f $INDIR/$name.masked.fasta ]; then
		echo "No genome for $INDIR/$name.masked.fasta yet - run 00_mash.sh $N"
		exit
	fi
	if [ ! -d $OUTDIR/$name/predict_misc ]; then
		echo "need to have run an initial funannotate"
		exit
	fi
	if [ -f $OUTDIR/$name/predict_misc/gmhmm.mod ]; then
		echo "already have a gmhmm.mod file"
		popd
		exit
	fi
	mkdir -p $OUTDIR/$name/predict_misc/genemark
	pushd $OUTDIR/$name/predict_misc/genemark
	gmes_petap.pl --min_contig 10000 --ES --fungus --sequence ../genome.softmasked.fa --cores $CPU
	if [ -f output/gmhmm.mod ]; then
		#/opt/linux/centos/7.x/x86_64/pkgs/funannotate/1.5.2-30c1166/util/genemark_gtf2gff3.pl genemark.gtf > ../genemark.gff
		rsync output/gmhmm.mod ..
	else
		echo "cannot find genemark.gtf"
	fi
	popd
done
