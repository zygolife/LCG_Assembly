IFS=,
ODIR=annotate
N=1
list=`tail -n +2 samples.csv | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do 
	name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g; ')
	if [[ ! -f "$ODIR/$name/predict_misc/genemark/output/gmhmm.mod" &&
		! -f "$ODIR/$name/predict_misc/gmhmm.mod" ]]; then
		echo -n "$N,"
	fi
	N=$(expr $N + 1)
done`

echo "sbatch --array=$list pipeline/01_genemark.sh"
