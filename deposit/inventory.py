#!/usr/bin/env python3
"""LCG deposit inventory: one row per genome in Annotation/samples_prefix.csv.

For each row it records
- local files: reads (Assembly/input/<stem>_R1/R2.fq.gz), assembly
  (Assembly/genomes/<stem>.sorted.fasta), annotation (Annotation/annotate/<stem>/
  annotate_results/*.sqn and .gbk), where <stem> = SPECIES with spaces -> "_";
- NCBI, public records only (E-utilities; a private or missing record is "not found"):
  BioSample, SRA run(s) for the BioSample, genome assembly for the BioSample
  (accession, submission date, annotation yes/no);
- MATPredict name-check findings (optional inputs): taxon overrides, B12 flags.

Writes deposit/inventory.tsv and prints counts. Run with Python 3.11+ (requests).
No e-mail is sent to NCBI; set NCBI_API_KEY to raise the rate limit.

    python3 deposit/inventory.py --lcg /bigdata/stajichlab/shared/projects/ZyGoLife/LCG \
        [--overrides .../MATPredict/db/taxon_overrides.tsv] [--flags .../flags.tsv]
"""
import argparse, csv, json, os, sys, time
from pathlib import Path
import requests

EU = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
KEY = os.environ.get("NCBI_API_KEY")
PAUSE = 0.12 if KEY else 0.4


def eu(endpoint, **params):
    params.update(tool="LCG_deposit_inventory", retmode="json")
    if KEY:
        params["api_key"] = KEY
    for attempt in range(6):
        r = requests.post(f"{EU}/{endpoint}.fcgi", data=params, timeout=120)
        time.sleep(PAUSE)
        if r.status_code == 200:
            return r.json()
        time.sleep(2 ** attempt)
    r.raise_for_status()


def search_summary(db, term):
    ids = eu("esearch", db=db, term=term, retmax=10000)["esearchresult"]["idlist"]
    out = []
    for i in range(0, len(ids), 200):
        res = eu("esummary", db=db, id=",".join(ids[i:i + 200]))["result"]
        out += [res[u] for u in res.get("uids", [])]
    return out


def batched(xs, n):
    for i in range(0, len(xs), n):
        yield xs[i:i + n]


def stem(species):
    return species.strip().replace(" ", "_")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lcg", required=True)
    ap.add_argument("--overrides")
    ap.add_argument("--flags")
    ap.add_argument("--out", default="deposit/inventory.tsv")
    a = ap.parse_args()
    L = Path(a.lcg)
    rows = list(csv.DictReader(open(L / "Annotation/samples_prefix.csv")))
    ov = {}
    if a.overrides:
        for r in csv.DictReader((l for l in open(a.overrides) if not l.startswith("#")), delimiter="\t"):
            ov[r["genome_id"]] = r
    flags = {}
    if a.flags:
        for r in csv.DictReader(open(a.flags), delimiter="\t"):
            flags[r["genome"]] = r

    bs = sorted({r["BIOSAMPLE"].strip() for r in rows if r["BIOSAMPLE"].strip()})
    pub_bs, asm, sra = {}, {}, {}
    for chunk in batched(bs, 150):
        for d in search_summary("biosample", " OR ".join(f"{b}[accn]" for b in chunk)):
            pub_bs[d.get("accession")] = d.get("publicationdate", "")
        for d in search_summary("assembly", " OR ".join(f"{b}[BioSample]" for b in chunk)):
            asm.setdefault(d.get("biosampleaccn"), []).append(
                (d.get("assemblyaccession"), d.get("submissiondate", "")[:10],
                 "has_annotation" in (d.get("propertylist") or []), d.get("assemblystatus", "")))
        for d in search_summary("sra", " OR ".join(f"{b}[BioSample]" for b in chunk)):
            ex = d.get("expxml", "")
            runs = d.get("runs", "")
            b = next((x for x in chunk if x in ex), None)
            if b:
                for part in runs.split("acc=\"")[1:]:
                    sra.setdefault(b, set()).add(part.split("\"")[0])
        print(f"queried {min(len(bs), bs.index(chunk[-1]) + 1)}/{len(bs)} biosamples", file=sys.stderr)

    out = []
    for r in rows:
        s = stem(r["SPECIES"])
        b = r["BIOSAMPLE"].strip()
        ann = L / "Annotation/annotate" / s
        sqn = list((ann / "annotate_results").glob("*.sqn")) if (ann / "annotate_results").is_dir() else []
        a_rows = asm.get(b, [])
        o = ov.get(s, {})
        f = flags.get(s, {})
        out.append(dict(
            stem=s, species=r["SPECIES"], subphylum=r["Subphylum"], strain=r["STRAIN"],
            biosample=b, bioproject=r["BIOPROJECT"].strip(), taxid=r["TAXONOMY_ID"].strip(),
            ncbi_organism=r["ORGANISM_NAME_NCBI_LOOKUP"], sra_run_sheet=r["SRA_RUNID"].strip(),
            locus_tag=r["LOCUSTAG"].strip(), keep_in_paper=r["Keep in LCG Paper"].strip(),
            deposit_flag=r["Deposit in NCBI"].strip(), note=r.get("", "").strip(),
            reads_local=(L / f"Assembly/input/{s}_R1.fq.gz").exists(),
            assembly_local=(L / f"Assembly/genomes/{s}.sorted.fasta").exists(),
            annotation_gbk=(ann / "annotate_results" / f"{s}.gbk").exists() or bool(list(ann.glob("annotate_results/*.gbk"))),
            annotation_sqn=bool(sqn),
            biosample_public=b in pub_bs, biosample_pubdate=pub_bs.get(b, ""),
            sra_runs_public=";".join(sorted(sra.get(b, set()))),
            assembly_ncbi=";".join(x[0] for x in a_rows),
            assembly_date=";".join(x[1] for x in a_rows),
            assembly_annotated=";".join(str(x[2]) for x in a_rows),
            override=(o.get("likely_identity", "") + (f" ({o.get('status')})" if o else "")),
            override_use=o.get("use", ""),
            b12_flag=f.get("fungi_status", "") if f else "",
        ))
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    with open(a.out, "w") as fo:
        w = csv.DictWriter(fo, fieldnames=list(out[0]), delimiter="\t", lineterminator="\n")
        w.writeheader(); w.writerows(out)
    from collections import Counter as C
    print("rows", len(out))
    for k in ("reads_local", "assembly_local", "annotation_sqn", "biosample_public"):
        print(k, C(r[k] for r in out))
    print("SRA run public", C(bool(r["sra_runs_public"]) for r in out))
    print("assembly at NCBI", C(bool(r["assembly_ncbi"]) for r in out))
    print("deposit_flag x assembly at NCBI", C((r["deposit_flag"], bool(r["assembly_ncbi"])) for r in out))


if __name__ == "__main__":
    main()
