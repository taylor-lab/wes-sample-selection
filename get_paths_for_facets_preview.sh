#!/bin/bash

base_path=/ifs/res/taylorlab/impact_facets/all
#dmp_list=DMPs.txt

if [ "$1" == "-h" ]
then
    echo "Usage: ./get_paths_for_facets_preview.sh DMPid.txt"
    exit 0
else
    dmp_list=$1
fi

while IFS=$'\t' read line
do
  set $line
  dmp=$1
  file_path=$(ls $base_path | grep $dmp)
  echo ${base_path}'/'${file_path}
done < <(cat $dmp_list)

