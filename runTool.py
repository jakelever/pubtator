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
	def __init__(self):
		pass

	def __enter__(self):
		self.tempDir = tempfile.mkdtemp()
		return self.tempDir

	def __exit__(self, type, value, traceback):
		shutil.rmtree(self.tempDir)
		#pass

def randomBiocFilename():
	hostname = socket.gethostname()
	processid = os.getpid()
	randomstring = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(10))
	return "%s-%d-%s.bioc.xml" % (hostname,processid,randomstring)

def splitBiocAndStripAnnotations(inBioc,outDir,maxLength):
	assert os.path.isfile(inBioc)
	assert os.path.isdir(outDir)

	pmids = set()

	textLength = 0
	docNumber = 0
	docName = os.path.join(outDir,"%08d.bioc.xml" % docNumber)
	writer = bioc.iterwrite(docName)
	with bioc.iterparse(inBioc) as parser:
		for i,doc in enumerate(parser):
			if 'pmid' in doc.infons:
				if doc.infons['pmid'] in pmids:
					continue
				pmids.add(doc.infons['pmid'])
			
			thisDocLength = sum( len(passage.text) for passage in doc.passages )

			assert len(doc.passages) > 0 and thisDocLength > 0, "Corpus file cannot contain empty documents"

			for passage in doc.passages:
				passage.annotations = []
				passage.relations = []

			if maxLength and (textLength + thisDocLength) > maxLength:
				textLength = 0
				docNumber += 1
				docName = os.path.join(outDir,"%08d.bioc.xml" % docNumber)
				writer.close()
				writer = bioc.iterwrite(docName)

			textLength += thisDocLength

			writer.writedocument(doc)

	writer.close()
	if textLength == 0:
		os.remove(docName)

def symlinkDirectoryContents(fromDir,toDir,skipTmp=False):
	for f in os.listdir(fromDir):
		if skipTmp and f == 'tmp':
			continue

		os.symlink(os.path.join(fromDir,f),os.path.join(toDir,f))



def mergeBioc(inDir,outBioc):
	inBiocs = sorted( [ os.path.join(inDir,filename) for filename in os.listdir(inDir) if filename.lower().endswith('.xml') ] )

	with bioc.iterwrite(outBioc) as writer:
		for inBioc in inBiocs:
			with bioc.iterparse(inBioc) as parser:
				for doc in parser:
					writer.writedocument(doc)

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Run an NER tool on a BioC XML file')
	parser.add_argument('--tool',required=True,type=str,help='Which tool to run (GNormPlus/tmChem/tmVar)')
	parser.add_argument('--inBioc',required=True,type=str,help='Input BioC XML file')
	parser.add_argument('--outBioc',required=True,type=str,help='Output BioC XML file')
	parser.add_argument('--mem',type=int,default=10,help='GB of RAM to use for Java')
	parser.add_argument('--maxLength',type=int,default=1000000,help='Max size (in characters) of documents to put in a single file for processing')
	args = parser.parse_args()

	tool = args.tool.lower()

	assert tool in ['dnorm','gnormplus','tmchem','tmvar'], "--tool must be DNorm, GNormPlus, tmChem or tmVar"

	inBioc = os.path.abspath(args.inBioc)
	outBioc = os.path.abspath(args.outBioc)

	assert os.path.isfile(inBioc), "Could not access input: %s" % inBioc

	here = os.path.abspath(os.path.dirname(__file__))

	toolDirs = {'dnorm':'DNorm-0.0.7','gnormplus':'GNormPlusJava','tmchem':'tmChemM1-0.0.2','tmvar':'tmVarJava'}
	#jarFiles = {'gnormplus':'GNormPlus.jar','tmvar':'tmVar.jar'}

	toolDir = os.path.join(here,toolDirs[tool])
	#os.chdir(toolDir)



	with TempDir() as tempDir:

		#if tool == 'gnormplus' or tool == 'tmvar':
		inputDir = os.path.join(tempDir,'input')
		outputDir = os.path.join(tempDir,'output')
		workingDir = os.path.join(tempDir,'working')
		#workingDir = os.path.join(tempDir,'w')


		os.mkdir(inputDir)
		os.mkdir(outputDir)
		os.mkdir(workingDir)

		splitBiocAndStripAnnotations(inBioc,inputDir,args.maxLength)

		symlinkDirectoryContents(toolDir,workingDir,skipTmp=True)
		os.mkdir(os.path.join(workingDir,'tmp'))
		os.chdir(workingDir)
		
		

			#tempFilename = randomBiocFilename()
			#inFile = os.path.join(inputDir,tempFilename)

			#shutil.copyfile(inBioc, inFile)

		if tool == 'dnorm':
			ab3pDir = os.path.join(here,'Ab3P-v1.5')

			command = ['sh', 'ApplyDNorm_BioC.sh','config/banner_NCBIDisease_UMLS2013AA_TEST.xml','data/CTD_diseases.tsv','output/simmatrix_NCBIDisease_e4.bin',ab3pDir, os.path.join(workingDir,'tmp'),inputDir,outputDir]
		if tool == 'gnormplus':
			jarFile = os.path.join(toolDir,'GNormPlus.jar')
			setupFile = os.path.join(toolDir,'setup.txt')
			command = ['java','-Xmx%dG' % args.mem ,'-Xms%dG' % args.mem,'-jar',jarFile,inputDir, outputDir,setupFile]
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

		mergeBioc(outputDir,outBioc)



