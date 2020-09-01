import argparse
import shutil
import tempfile
import os
import socket
import random
import string
import subprocess
import bioc

def splitBioc(inBioc,outDir,maxLength):
	assert os.path.isfile(inBioc)
	assert os.path.isdir(outDir)

	prefix = os.path.basename(inBioc).replace('.bioc.xml','')

	textLength = 0
	docNumber = 0
	docName = os.path.join(outDir,"%s.%04d.bioc.xml" % (prefix,docNumber))
	writer = bioc.BioCXMLDocumentWriter(docName)
	with bioc.BioCXMLDocumentReader(inBioc) as parser:
		for i,doc in enumerate(parser):
			thisDocLength = sum( len(passage.text) for passage in doc.passages )

			assert len(doc.passages) > 0 and thisDocLength > 0, "Corpus file cannot contain empty documents"

			if textLength > 0 and maxLength and (textLength + thisDocLength) > maxLength:
				textLength = 0
				docNumber += 1
				docName = os.path.join(outDir,"%s.%04d.bioc.xml" % (prefix,docNumber))
				writer.close()
				writer = bioc.BioCXMLDocumentWriter(docName)

			textLength += thisDocLength

			writer.write_document(doc)

	writer.close()
	if textLength == 0:
		docNumber -= 1
		os.remove(docName)

	print("Split into %d files" % (docNumber+1))


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Run an NER tool on a BioC XML file')
	parser.add_argument('--inBioc',required=True,type=str,help='Input BioC XML file')
	parser.add_argument('--outDir',required=True,type=str,help='Output direcotry')
	parser.add_argument('--maxLength',type=int,default=1000000,help='Max size (in characters) of documents to put in a single file for processing')
	args = parser.parse_args()

	#if not os.path.isdir(args.outDir):
	#	os.makedirs(args.outDir)

	assert os.path.isdir(args.outDir)

	splitBioc(args.inBioc,args.outDir,args.maxLength)

