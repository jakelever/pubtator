#!/bin/bash
set -ex

rm -fr GNormPlus GNormPlus.zip
wget https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/tmTools/download/GNormPlus/GNormPlus.zip
unzip GNormPlus
rm GNormPlus.zip

cd GNormPlus

#cp ../patches/GNormPlus/Species_Name_Recognition.pm Library/Species_Name_Recognition.pm
#cp ../patches/GNormPlus/Tagger.pm Library/Lingua/EN/Tagger.pm

sh Installation.sh

