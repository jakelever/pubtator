set -ex

rm -fr DNorm-0.0.7

wget https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/tmTools/download/DNorm/DNorm-0.0.7.tgz
tar xvf DNorm-0.0.7.tgz
cd DNorm-0.0.7
#sh Installation.sh 

cp ../patches/DNorm-0.0.7/AbbreviationIdentifier.java src/dnorm/util/AbbreviationIdentifier.java
cp ../patches/DNorm-0.0.7/ApplyDNorm_BioC.java src/dnorm/ApplyDNorm_BioC.java

ant build.project

cd -
rm DNorm-0.0.7.tgz



