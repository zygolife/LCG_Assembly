#!/usr/bin/bash
#SBATCH --ntasks 2 --mem 16G --time 8:00:00 --out logs/ssu-align.log

module load python/3

module load RDPTools
module load ssu-align
module load hmmer/3

./scripts/combine_barrnap_seqs.py

pushd parsed_seqs/barrnap
java -jar $RDP_JAR_PATH classify -c 0.5 -o meta_16S_rRNA.classify.tab meta_16S_rRNA.fasta
java -jar $RDP_JAR_PATH classify -c 0.5 -o spades_16S_rRNA.classify.tab spades_16S_rRNA.fasta

ssu-align meta_16S_rRNA.fasta barrnap/meta_16S_rRNA
ssu-align spades_16S_rRNA.fasta spades_16S_rRNA

pushd meta_16S_rRNA
esl-reformat --replace=Uun:TtN afa meta_16S_rRNA.bacteria.stk  > meta_16S_rRNA.bacteria.fasaln
esl-reformat --replace=Uun:TtN afa meta_16S_rRNA.archaea.stk  > meta_16S_rRNA.archaea.fasaln
esl-reformat --replace=Uun:TtN afa meta_16S_rRNA.eukarya.stk  > meta_16S_rRNA.eukarya.fasaln
popd

pushd spades_16S_rRNA
esl-reformat --replace=Uun:TtN afa spades_16S_rRNA.bacteria.stk > spades_16S_rRNA.bacteria.fasaln
esl-reformat --replace=Uun:TtN afa spades_16S_rRNA.archaea.stk  > spades_16S_rRNA.archaea.fasaln
esl-reformat --replace=Uun:TtN afa spades_16S_rRNA.eukarya.stk  > spades_16S_rRNA.eukarya.fasaln
popd

popd

./scripts/add_taxinfo.py

