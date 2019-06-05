set -ex

rm -fr Ext BioC-SWIG.tar.gz

wget https://sourceforge.net/projects/bioc/files/BioC-SWIG.tar.gz
tar xvf BioC-SWIG.tar.gz
rm BioC-SWIG.tar.gz

cd Ext

cp ../patches/BioC-SWIG/BioC_libxml.cpp BioC/BioC_libxml.cpp
cp ../patches/BioC-SWIG/Makefile Perl/Makefile

make clean

make perl

