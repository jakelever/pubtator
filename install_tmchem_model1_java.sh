set -ex

rm -fr tmChemM1-0.0.2
rm -fr Ab3P-v1.5
rm -f tmChemM1-0.0.2.tgz
rm -f Ab3P-v1.5.tar.gz

#cp ../PGmine/tmChemM1-0.0.2/src/ncbi/chemdner/AbbreviationIdentifier.java tmChemUpdates
#cp ../PGmine/tmChemM1-0.0.2/src/ncbi/Run.java tmChemUpdates


wget https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/tmTools/download/tmChem/tmChemM1-0.0.2.tgz
tar xvf tmChemM1-0.0.2.tgz 
cd tmChemM1-0.0.2

cp ../tmChemUpdates/Run.java ./src/ncbi/Run.java
cp ../tmChemUpdates/AbbreviationIdentifier.java ./src/ncbi/chemdner/AbbreviationIdentifier.java
cp ../tmChemUpdates/MultiTokenRegexMatcher.java ./src/ncbi/chemdner/MultiTokenRegexMatcher.java

cp ../tmChemUpdates/build.xml ./build.xml
cp ../tmChemUpdates/Run.sh ./Run.sh

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
