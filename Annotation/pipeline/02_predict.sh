#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 8 --nodes 1 --mem 24G --out logs/predict.%a.log
module unload miniconda2
module unload miniconda3
module load anaconda3
#module load miniconda3
#module load funannotate/1.5.2-30c1166
module load funannotate/development
module unload perl
module unload python
source activate funannotate

#module switch mummer/4.0
#module unload augustus
#module load augustus/3.3
#module load lp_solve
#module load diamond
module load genemarkESET/4.38
module unload rmblastn
module load ncbi-rmblast/2.6.0
#export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)

GMFOLDER=`dirname $(which gmhmme3)`
#genemark key is needed
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
 	species=$(echo "$Species" | perl -p -e "s/$Strain//")
 	SEED_SPECIES="anidulans"
	if [[ $SubPhyla == "Mucoromycotina" ]]; then
		SEED_SPECIES="mucor_circinelloides_f._lusitanicus__nrrl_3629"
	elif [[ $SubPhyla == "Mortirellomycotina" ]]; then
		SEED_SPECIES="Mortierella_verticillata_CRF"
	elif [[ $SubPhyla == "Entomophthoromycotina" ]]; then
		SEED_SPECIES="Conidiobolus_coronatus"
	elif [[ $SubPhyla == "Kickxellomycotina" ]]; then
		SEED_SPECIES="coemansia_umbellata__bcrc_34882"
	fi
	if [ ! -f $INDIR/$name.masked.fasta ]; then
		echo "No genome for $INDIR/$name.masked.fasta yet - run 00_mash.sh $N"
		exit
	fi
	LOCUSTAG=$(python scripts/get_locus.py $name)
	if [ -z $LOCUSTAG ]; then
		echo " no LOCUSTAG for $Species"
		LOCUSTAG=$JGIProjName
	fi
 	mkdir $name.predict.$$
 	pushd $name.predict.$$
    	funannotate predict --cpus $CPU --keep_no_stops --SeqCenter JGI --busco_db fungi_odb9 --strain "$Strain" \
      -i ../$INDIR/$name.masked.fasta --name $LOCUSTAG --protein_evidence ../lib/informant.2.aa \
      -s "$species"  -o ../$OUTDIR/$name --busco_seed_species $SEED_SPECIES
	popd
 	rmdir $name.predict.$$
done
