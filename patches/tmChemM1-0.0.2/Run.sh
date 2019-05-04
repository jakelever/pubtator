CP=libs/CHEMDNER.jar
CP=${CP}:libs/trove-3.0.3.jar
CP=${CP}:libs/commons-configuration-1.6.jar
CP=${CP}:libs/commons-collections-3.2.1.jar
CP=${CP}:libs/commons-lang-2.4.jar
CP=${CP}:libs/commons-logging-1.1.1.jar
CP=${CP}:libs/banner.jar
CP=${CP}:libs/dragontool.jar
CP=${CP}:libs/heptag.jar
CP=${CP}:libs/mallet.jar
CP=${CP}:libs/mallet-deps.jar
CP=${CP}:libs/bioc.jar
CP=${CP}:libs/stax-utils.jar
CP=${CP}:libs/stax2-api-3.1.1.jar
CP=${CP}:libs/woodstox-core-asl-4.2.0.jar
CONFIG=$1
DICTIONARY=$2
ABBREV=$3
TEMP=$4
INPUT=$5
OUTPUT=$6
MEM=$7"G"
java -Xmx$MEM -Xms$MEM -cp ${CP} ncbi.Run $CONFIG $DICTIONARY $ABBREV $TEMP $INPUT $OUTPUT

