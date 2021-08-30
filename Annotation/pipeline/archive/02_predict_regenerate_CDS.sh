#!/bin/bash
#SBATCH -p short --ntasks 2 --nodes 1 --mem 4G --out logs/predict_regenerate.%a.log
module unload miniconda2
module unload miniconda3
module load funannotate
module load workspace/scratch

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
#
#GMFOLDER=`dirname $(which gmhmme3)`

# make genemark key link required to run it
#if [ ! -f ~/.gm_key ]; then
#    ln -s $GMFOLDER/.gm_key ~/.gm_key
#fi

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=$(realpath genomes)
OUTDIR=$(realpath annotate)
INFORMANT=$(realpath lib/informant.2.aa)
SAMPFILE=samples_prefix.csv
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
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
    name=$(echo "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
    species=$(echo "$SPECIES" | perl -p -e "s/\Q$STRAIN\E//")
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
    prefix=$LOCUSTAG
    if [ -z $prefix ]; then
	prefix=$JGILIBRARY
    fi

    pushd $SCRATCH
    funannotate predict --cpus $CPU --keep_no_stops --SeqCenter JGI \
	--busco_db fungi_odb9 --strain "$STRAIN" \
	--min_training_models 30 --AUGUSTUS_CONFIG_PATH $AUGUSTUS_CONFIG_PATH \
	-i $INDIR/$name.masked.fasta --name $prefix \
	--protein_evidence $INFORMANT \
	-s "$species"  -o $OUTDIR/$name --busco_seed_species $SEED_SPECIES \
	--keep_evm
    popd

done
