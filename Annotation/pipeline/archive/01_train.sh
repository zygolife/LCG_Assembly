#MAKE THIS GENEMARK TRAINING

#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/predict.%a.log
module unload python
module unload perl
module unload perl
module load perl/5.24.0
module load miniconda2
module load funannotate/git-live
module switch mummer/4.0
module unload augustus
module load augustus/3.3
module load lp_solve
module load genemarkHMM
module load diamond
module unload rmblastn
module load ncbi-rmblast/2.6.0
export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=annotate

SAMPFILE=samples.dat
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
sed -n ${N}p $SAMPFILE | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note:wq
do
 name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
 species=$(echo "$Species" | perl -p -e "s/$Strain//")
 mkdir $name.predict.$$
 pushd $name.predict.$$
    funannotate predict --cpus $CPU --keep_no_stops --SeqCenter JGI --busco_db fungi_odb9 --strain "$Strain" \
      -i ../$INDIR/$name.masked.fasta --name $JGIProjName --protein_evidence ../informant.aa \
      -s "$species"  -o ../$OUTDIR/$Species
 rmdir $name.predict.$$
done
