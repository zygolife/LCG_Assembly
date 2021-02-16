./scripts/update_samples_prefix.py
perl -i -p -e 's/\r\n/\n/g' samples_prefix.csv
cat samples_prefix.csv | (sed -u 1q; sort -t, -k1,1) > samples_prefix.sort.csv
mv samples_prefix.sort.csv samples_prefix.csv
