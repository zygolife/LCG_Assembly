n=1
while read strain domain; do 
	if [ ! -f mapping_report/$strain.bbmap_covstats.txt ]; then echo "$n $strain"; fi; 
	n=$(expr $n + 1);
done < samples.dat
n=1
m=$(while read strain domain; do 
if [ ! -f mapping_report/$strain.bbmap_covstats.txt ]; then   echo "$n"; fi; 
n=$(expr $n + 1); 
done < samples.dat | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')
echo "sbatch --array=$m pipeline/04_read_count.sh"
