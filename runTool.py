import argparse
import shutil
import tempfile
import os
import socket
import random
import string
import subprocess
import bioc

class TempDir:
	def __init__(self,debug=False):
		self.debug = debug

	def __enter__(self):
		if self.debug:
			self.tempDir = os.path.abspath('temp')
			if os.path.isdir(self.tempDir):
				shutil.rmtree(self.tempDir)
			os.makedirs(self.tempDir)
		else:
			self.tempDir = tempfile.mkdtemp()
		return self.tempDir

	def __exit__(self, type, value, traceback):
		if not self.debug:
			shutil.rmtree(self.tempDir)
		#pass

def randomBiocFilename():
	hostname = socket.gethostname()
	processid = os.getpid()
	randomstring = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(10))
	return "%s-%d-%s.bioc.xml" % (hostname,processid,randomstring)

def splitBioc(inBioc,outDir,maxLength,stripAnnotations=False):
	assert os.path.isfile(inBioc)
	assert os.path.isdir(outDir)

	pmids = set()

	textLength = 0
	docNumber = 0
	docName = os.path.join(outDir,"%08d.bioc.xml" % docNumber)
	writer = bioc.BioCXMLDocumentWriter(docName)
	with open(inBioc,'rb') as f:
		parser = bioc.BioCXMLDocumentReader(f)
		for i,doc in enumerate(parser):
			if 'pmid' in doc.infons:
				if doc.infons['pmid'] in pmids:
					continue
				pmids.add(doc.infons['pmid'])
			
			thisDocLength = sum( len(passage.text) for passage in doc.passages )

			assert len(doc.passages) > 0 and thisDocLength > 0, "Corpus file cannot contain empty documents"

			if stripAnnotations:
				for passage in doc.passages:
					passage.annotations = []
					passage.relations = []

			if textLength > 0 and maxLength and (textLength + thisDocLength) > maxLength:
				textLength = 0
				docNumber += 1
				docName = os.path.join(outDir,"%08d.bioc.xml" % docNumber)
				writer.close()
				writer = bioc.BioCXMLDocumentWriter(docName)

			textLength += thisDocLength

			writer.write_document(doc)

	writer.close()
	if textLength == 0:
		os.remove(docName)

def symlinkDirectoryContents(fromDir,toDir,skipTmp=False):
	for f in os.listdir(fromDir):
		if skipTmp and f == 'tmp':
			continue

		os.symlink(os.path.join(fromDir,f),os.path.join(toDir,f))


def mergeBiocWithMetadata(metaDir,inDir,outBioc):
	filenames = sorted( [ filename for filename in os.listdir(inDir) if filename.lower().endswith('.xml') and not filename.lower().endswith('.ga.xml') ] )

	with bioc.BioCXMLDocumentWriter(outBioc) as writer:
		for filename in filenames:
			inBioc = os.path.join(inDir,filename)
			metaBioc = os.path.join(metaDir,filename)

			with open(inBioc,'rb') as f1, open(metaBioc,'rb') as f2:
				inParser = bioc.BioCXMLDocumentReader(f1)
				metaParser = bioc.BioCXMLDocumentReader(f2)

				for inDoc,metaDoc in zip(inParser,metaParser):
					assert len(inDoc.passages) == len(metaDoc.passages)
					for inP,metaP in zip(inDoc.passages, metaDoc.passages):
						assert inP.text == metaP.text
						inP.infons.update(metaP.infons)

					inDoc.infons.update(metaDoc.infons)
					writer.write_document(inDoc)

def mergeBioc(inDir,outBioc):
	inBiocs = sorted( [ os.path.join(inDir,filename) for filename in os.listdir(inDir) if filename.lower().endswith('.xml') and not filename.lower().endswith('.ga.xml') ] )

	with bioc.BioCXMLDocumentWriter(outBioc) as writer:
		for inBioc in inBiocs:
			with open(inBioc,'rb') as f:
				parser = bioc.BioCXMLDocumentReader(f)
				for doc in parser:
					writer.write_document(doc)

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Run an NER tool on a BioC XML file')
	parser.add_argument('--tool',required=True,type=str,help='Which tool to run (GNormPlus/tmChem/tmVar)')
	parser.add_argument('--inBioc',required=True,type=str,help='Input BioC XML file')
	parser.add_argument('--outBioc',required=True,type=str,help='Output BioC XML file')
	parser.add_argument('--mem',type=int,default=10,help='GB of RAM to use for Java')
	parser.add_argument('--maxLength',type=int,default=1000000,help='Max size (in characters) of documents to put in a single file for processing')
	parser.add_argument('--debug', action='store_true',help='Whether to use the "temp" directory and not delete intermediate files')
	args = parser.parse_args()

	tool = args.tool.lower()

	acceptedTools = ['dnorm','gnormplus_java','gnormplus_perl','tmchem','tmvar']

	assert tool in acceptedTools, "--tool must be %s" % str(acceptedTools)

	inBioc = os.path.abspath(args.inBioc)
	outBioc = os.path.abspath(args.outBioc)

	assert os.path.isfile(inBioc), "Could not access input: %s" % inBioc

	here = os.path.abspath(os.path.dirname(__file__))

	toolDirs = {'dnorm':'DNorm-0.0.7','gnormplus_java':'GNormPlusJava','gnormplus_perl':'GNormPlus','tmchem':'tmChemM1-0.0.2','tmvar':'tmVarJava'}
	#jarFiles = {'gnormplus':'GNormPlus.jar','tmvar':'tmVar.jar'}

	toolDir = os.path.join(here,toolDirs[tool])
	#os.chdir(toolDir)



	with TempDir(args.debug) as tempDir:

		#if tool == 'gnormplus' or tool == 'tmvar':
		inputDir = os.path.join(tempDir,'input')
		outputDir = os.path.join(tempDir,'output')
		workingDir = os.path.join(tempDir,'working')
		#workingDir = os.path.join(tempDir,'w')


		os.mkdir(inputDir)
		os.mkdir(outputDir)
		os.mkdir(workingDir)

		splitBioc(inBioc,inputDir,args.maxLength,stripAnnotations=False)

		symlinkDirectoryContents(toolDir,workingDir,skipTmp=True)
		os.mkdir(os.path.join(workingDir,'tmp'))
		os.chdir(workingDir)
		
		

			#tempFilename = randomBiocFilename()
			#inFile = os.path.join(inputDir,tempFilename)

			#shutil.copyfile(inBioc, inFile)

		if tool == 'dnorm':
			ab3pDir = os.path.join(here,'Ab3P-v1.5')

			command = ['sh', 'ApplyDNorm_BioC.sh','config/banner_NCBIDisease_UMLS2013AA_TEST.xml','data/CTD_diseases.tsv','output/simmatrix_NCBIDisease_e4.bin',ab3pDir, os.path.join(workingDir,'tmp'),inputDir,outputDir]
		elif tool == 'gnormplus_java':
			jarFile = os.path.join(toolDir,'GNormPlus.jar')
			setupFile = os.path.join(toolDir,'setup.txt')
			command = ['java','-Xmx%dG' % args.mem ,'-Xms%dG' % args.mem,'-jar',jarFile,inputDir, outputDir,setupFile]
		elif tool == 'gnormplus_perl':
			biocPerlLib = os.path.join(here,'Ext','Perl')
			os.environ['PERL5LIB'] = '.:%s' % biocPerlLib
			setupFile = os.path.join(toolDir,'setup.txt')
			command = ['perl','GNormPlus.pl','-i',inputDir,'-o',outputDir,'-s','setup.txt']
		elif tool == 'tmchem':
			ab3pDir = os.path.join(here,'Ab3P-v1.5')
			command = ['sh', 'Run.sh','config/banner_JOINT.xml','data/dict.txt',ab3pDir,os.path.join(workingDir,'tmp'),inputDir,outputDir,str(args.mem)]
		elif tool == 'tmvar':
			jarFile = os.path.join(toolDir,'tmVar.jar')
			command = ['java','-Xmx%dG' % args.mem,'-Xms%dG' % args.mem,'-jar',jarFile,inputDir, outputDir]

		# java -Xmx10G -Xms10G -jar $jar $workingDir/input $workingDir/output
		print("Executing %s" % str(command))
		retval = subprocess.call(command)

		assert retval == 0, 'Command exited with error (%s)' % str(command)

		# Remove unneeded files
		if tool == 'gnormplus_perl':
			for f in os.listdir(outputDir):
				if f.endswith('ga.xml'):
					pass
					#os.remove(os.path.join(outputDir,f))

		mergeBiocWithMetadata(inputDir,outputDir,outBioc)



