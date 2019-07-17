#!/usr/bin/bash
#SBATCH -p batch --time 8:00:00 --mem 8gb -N 1 -n 1 --out logs/extract_hits.log
module load hmmer/3
module load glimmer

module unload perl
module unload miniconda2
module load miniconda3
source activate GAL

EVALUECUTOFF=1e-20
IN=blobOut
OUT1=viral_explore
OUT2=bacteria_explore
mkdir -p $OUT1 $OUT2
GLIMMERRUN=$(realpath scripts/g3-iterated.csh)
GFFCONVERT=$(realpath scripts/glimmer2gff.pl)
HMMFOLDER=$(realpath lib/viralHMM)
for genome in $(ls genomes/*.sorted.fasta)
do
    base=$(basename $genome .sorted.fasta)
    if [ ! -f $genome.ssi ]; then
	esl-sfetch --index $genome
    fi
    if [ -f $IN/$base.AA.blobDB.table.txt ]; then
	mkdir -p $OUT1/$base
	mkdir -p $OUT2/$base
	if [ ! -f $OUT1/$base/No-hit_contigs.fa ]; then
	    grep -v Eukaryota $IN/$base.AA.blobDB.table.txt | grep -v '^#' | grep 'no-hit' | cut -f1 | esl-sfetch -f $genome - > $OUT1/$base/No-hit_contigs.fa
	fi
	if [ ! -f $OUT1/$base/Virus_contigs.fa ]; then
	    grep -v Eukaryota $IN/$base.AA.blobDB.table.txt | grep -v '^#' | grep Virus | cut -f1 | esl-sfetch -f $genome - > $OUT1/$base/Virus_contigs.fa
	fi
	if [ ! -f $OUT2/$base/Bacteria_contigs.fa ]; then
	    grep Bacteria $IN/$base.AA.blobDB.table.txt | grep -v '^#' | cut -f1 | esl-sfetch -f $genome - > $OUT2/$base/Bacteria_contigs.fa
	fi
    fi
done

find $OUT1 -size 0 | xargs rm -rf
find $OUT2 -size 0 | xargs rm -rf

rmdir $OUT1/*
rmdir $OUT2/*

pushd $OUT1
for f in $(ls)
do
    pushd $f
    for CTGTYPE in Virus No-hit
    do
	if [ -f ${CTGTYPE}_contigs.fa ]; then 
	    if [ ! -f $f.$CTGTYPE.predict ]; then
		$GLIMMERRUN ${CTGTYPE}_contigs.fa $f.$CTGTYPE		
	    fi
	    if [ ! -s $f.$CTGTYPE.predict ]; then
		$GFFCONVERT -g $f.$CTGTYPE.run1.predict -f  ${CTGTYPE}_contigs.fa -o $f.${CTGTYPE}.glimmerORFs -p $f
	    else
		$GFFCONVERT -g $f.$CTGTYPE.predict -f  ${CTGTYPE}_contigs.fa -o $f.${CTGTYPE}.glimmerORFs -p $f
	    fi
	    
	    for hmm in $(ls $HMMFOLDER)
	    do
		nm=$(basename $hmm .hmm)
		if [ ! -f $f.$CTGTYPE.glimmerORFs.$nm.hmmsearch ]; then		    
		    hmmsearch -E $EVALUECUTOFF --domtblout $f.$CTGTYPE.glimmerORFs.$nm.domtbl \
			$HMMFOLDER/$hmm  $f.$CTGTYPE.glimmerORFs.aa.fasta > $f.$CTGTYPE.glimmerORFs.$nm.hmmsearch
		    grep -v '^#' $f.$CTGTYPE.glimmerORFs.$nm.domtbl | awk '{print $1}' | sort | uniq >  $f.$CTGTYPE.glimmerORFs.$nm.list.txt
		    esl-sfetch --index  $f.$CTGTYPE.glimmerORFs.aa.fasta
		    esl-sfetch -f $f.$CTGTYPE.glimmerORFs.aa.fasta  $f.$CTGTYPE.glimmerORFs.$nm.list.txt >  $f.$CTGTYPE.glimmerORFs.$nm.hits.fasta
		fi
	    done
	fi
    done
    popd
done
popd

pushd $OUT2
for f in $(ls)
do
    pushd $f
    CTGTYPE=Bacteria
    if [ -f ${CTGTYPE}_contigs.fa ]; then 
	if [ ! -f $f.$CTGTYPE.predict ]; then
	    $GLIMMERRUN ${CTGTYPE}_contigs.fa $f.$CTGTYPE
	    if [ ! -s $f.$CTGTYPE.predict ]; then
		$GFFCONVERT -g $f.$CTGTYPE.run1.predict -f  ${CTGTYPE}_contigs.fa -o $f.${CTGTYPE}.glimmerORFs -p $f
	    else
		$GFFCONVERT -g $f.$CTGTYPE.predict -f  ${CTGTYPE}_contigs.fa -o $f.${CTGTYPE}.glimmerORFs -p $f
	    fi
	     for hmm in $(ls $HMMFOLDER)
	    do
		nm=$(basename $hmm .hmm)
		if [ ! -f $f.$CTGTYPE.glimmerORFs.$nm.hmmsearch ]; then		    
		    hmmsearch -E $EVALUECUTOFF --domtblout $f.$CTGTYPE.glimmerORFs.$nm.domtbl \
			$HMMFOLDER/$hmm  $f.$CTGTYPE.glimmerORFs.aa.fasta > $f.$CTGTYPE.glimmerORFs.$nm.hmmsearch
		    grep -v '^#' $f.$CTGTYPE.glimmerORFs.$nm.domtbl | awk '{print $1}' | sort | uniq >  $f.$CTGTYPE.glimmerORFs.$nm.list.txt
		    esl-sfetch --index $f.$CTGTYPE.glimmerORFs.aa.fasta
		    esl-sfetch -f $f.$CTGTYPE.glimmerORFs.aa.fasta  $f.$CTGTYPE.glimmerORFs.$nm.list.txt >  $f.$CTGTYPE.glimmerORFs.$nm.hits.fasta
		fi
	    done

	fi
    fi    
    popd
done
popd
