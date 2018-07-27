#!/bin/bash

base_path=/ifs/res/taylorlab/impact_facets/all
dmp_list=DMPs.txt

while IFS=$'\t' read line
do
  set $line
  dmp=$1
  file_path=$(ls $base_path | grep $dmp)
  echo ${base_path}'/'${file_path}
done < <(cat $dmp_list)

