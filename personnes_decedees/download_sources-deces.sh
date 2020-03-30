#!/bin/bash

export LC_CTYPE=C
export LANG=C

raw_directory="deces_raw"
destination_directory="deces_csv"

rm -rf $raw_directory
rm -rf $destination_directory

mkdir $raw_directory
mkdir $destination_directory

for line in `cat sources-deces.txt`
do
  year=`echo "$line" | cut -f1 -d";"`
  url=`echo "$line" | cut -f2 -d";"`
  raw_filename="${raw_directory}/${year}_raw"
  wget $url -O $raw_filename

  sex=sex_${year}
  birth_date=birth_date_${year}
  death_date=death_date_${year}
  death_location=death_location_${year}
  cat $raw_filename | cut -c155-162 > $death_date
  cat $raw_filename | cut -c163-167 > $death_location
  cat $raw_filename | cut -c81 > $sex
  cat $raw_filename | cut -c82-89 > $birth_date
  rm $raw_filename

  csv_filepath="${destination_directory}/concat_${year}.csv"
  paste -d ";" $sex $birth_date $death_date $death_location > $csv_filepath
  ./code_commune_to_code_dep.rb $csv_filepath

  rm $sex
  rm $birth_date
  rm $death_date
  rm $death_location
  echo "$year done"
done

rmdir $raw_directory
