#!/bin/bash
set -x

# Reference transcriptome setup
if [ ! -r ref/gencode.v46.transcripts.fa.idx gencode.v46.transcripts.fa.idx ] ; then
  mkdir ref
  cd ref
  wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_46/gencode.v46.transcripts.fa.gz
  kallisto index -i gencode.v46.transcripts.fa.idx gencode.v46.transcripts.fa
  cd ..
fi

# FASTQC
ls rawdata/*gz | grep fastq.gz$ | parallel fastqc {}
# MULTIQC
multiqc rawdata

IDX=ref/gencode.v46.transcripts.fa.idx

for FQZ1 in rawdata/*_R1.fastq.gz ; do
  FQZ2=$(echo $FQZ1 | sed 's#_R1.#_R2.#')
  echo $FQZ1 $FQZ2
  skewer -q 20 -t 16 $FQZ1 $FQZ2
  FQT1=$(echo $FQZ1 | sed 's#fastq.gz#fastq-trimmed-pair1.fastq#')
  FQT2=$(echo $FQZ1 | sed 's#fastq.gz#fastq-trimmed-pair2.fastq#')
  BASE=$(echo $FQZ1 | cut -d '_' -f1)
  kallisto quant -o $BASE -i $IDX -t 16 $FQT1 $FQT2
done

for TSV in $(find rawdata/ | grep abundance.tsv$) ; do
  NAME=$(echo $TSV | cut -d '/' -f2 )
  cut -f1,4 $TSV | sed 1d | sed "s/^/${NAME}\t/"
done | pigz > 3col.tsv.gz
