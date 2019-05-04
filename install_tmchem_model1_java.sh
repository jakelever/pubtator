set -ex

rm -fr tmChemM1-0.0.2
rm -fr Ab3P-v1.5
rm -f tmChemM1-0.0.2.tgz
rm -f Ab3P-v1.5.tar.gz

wget https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/tmTools/download/tmChem/tmChemM1-0.0.2.tgz
tar xvf tmChemM1-0.0.2.tgz 
cd tmChemM1-0.0.2

cp ../patches/tmChemM1-0.0.2/Run.java ./src/ncbi/Run.java
cp ../patches/tmChemM1-0.0.2/AbbreviationIdentifier.java ./src/ncbi/chemdner/AbbreviationIdentifier.java
cp ../patches/tmChemM1-0.0.2/MultiTokenRegexMatcher.java ./src/ncbi/chemdner/MultiTokenRegexMatcher.java

cp ../patches/tmChemM1-0.0.2/build.xml ./build.xml
cp ../patches/tmChemM1-0.0.2/Run.sh ./Run.sh

rm -fr bin
ant build.project

cd -
rm tmChemM1-0.0.2.tgz

wget ftp://ftp.ncbi.nlm.nih.gov/pub/wilbur/Ab3P-v1.5.tar.gz
tar xvf Ab3P-v1.5.tar.gz 
cd Ab3P-v1.5
make
export PATH=$PWD:$PATH
cd -
rm Ab3P-v1.5.tar.gz
