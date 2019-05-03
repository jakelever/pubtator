set -ex

wget https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/tmTools/download/GNormPlus/GNormPlusJava.zip
unzip GNormPlusJava.zip 
cd GNormPlusJava
sh Installation.sh 
chmod +x Ab3P 
cd -
rm GNormPlusJava.zip

