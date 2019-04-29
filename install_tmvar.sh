set -ex

wget ftp://ftp.ncbi.nlm.nih.gov/pub/lu/Suppl/tmVar2/tmVarJava.zip
unzip tmVarJava.zip
cd tmVarJava
sh Installation.sh 
cd -
rm tmVarJava.zip

