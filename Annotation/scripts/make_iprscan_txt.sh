#!/usr/bin/bash -l
#SBATCH -p short -N 1 -n 16 --mem 292gb  --out logs/make_iprscan_txt.log -C xeon

CPU=16
module load funannotate
module load parallel
INDIR=annotate

make_ipr() {
	SCRIPT=/opt/linux/centos/7.x/x86_64/pkgs/miniconda3/4.3.31/envs/funannotate-1.8/lib/python3.8/site-packages/funannotate/aux_scripts/iprscan2annotations.py
    xml=$1
    txt=$(dirname $xml)/annotations.iprscan.txt
    if [ ! -f $txt ]; then
	python3.8 $SCRIPT $xml $txt
    fi
}

export -f make_ipr

parallel -j $CPU make_ipr ::: $(ls $INDIR/*/annotate_misc/iprscan.xml)
