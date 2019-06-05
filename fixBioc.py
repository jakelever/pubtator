import argparse
import bioc

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Make some minor fixes to BioC files to make them play nicely with some NER tools')
	parser.add_argument('--inBiocXML',type=str,required=True,help='Input BioC XML file')
	parser.add_argument('--outBiocXML',type=str,required=True,help='Output BioC XML file')
	args = parser.parse_args()

	pmids = set()

	textLength = 0

	with bioc.iterparse(args.inBiocXML) as parser, bioc.iterwrite(args.outBiocXML) as writer:
		for i,doc in enumerate(parser):
			if doc.infons['pmid'] in pmids:
				continue
			pmids.add(doc.infons['pmid'])

			for passage in doc.passages:
				if 'section' in passage.infons:
					passage.infons['type'] = passage.infons['section']
				else:
					passage.infons['type'] = 'unknown'

				passage.text = passage.text.strip()

			thisDocLength = sum( len(passage.text) for passage in doc.passages )

			if len(doc.passages) == 0 or thisDocLength == 0:
				continue

			textLength += thisDocLength
			
			writer.writedocument(doc)

	print("textLength = %d" % textLength)

