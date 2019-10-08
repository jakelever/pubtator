#include "BioC_libxml.hpp"

#include <iostream>
#include <vector>
#include <sstream>

using std::cerr;
using std::cout;
using std::istringstream;
using std::ostream;
using std::ostringstream;
using std::vector;

namespace BioC {

  void Connector_libxml::read(const string & docname, Collection & collection ) {
  
    xml_doc = xmlParseFile(docname.c_str());
    if (xml_doc == NULL ) {
      cerr << "Document not parsed successfully. \n";
      parse_error(0);
    }

    /*
      This does not work properly. It appears you have to request
      validation get the DTD name.

    //    dtd =  (char*)xml_doc->intSubset->name;
    dtd =  (char*)xml_doc->extSubset->name;
    dtd += ".dtd";
    */

    xmlNodePtr cur = xmlDocGetRootElement(xml_doc);
    if (cur == NULL) {
      cerr << "empty document\n";
      xmlFreeDoc(xml_doc);
      parse_error(0);
    }

    if ( !xmlStrcmp( cur->name, (const xmlChar* )"collection" ) ) {
      from_XML( cur, collection );
    }
  
    xmlFreeDoc(xml_doc);
    return;
  }


  void Connector_libxml::from_XML( xmlNodePtr cur, Collection & collection ) {
    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
      getValue( cur, "source", collection.source );
      getValue( cur, "date", collection.date );
      getValue( cur, "key", collection.key );
      getValue( cur, "infon", collection.infons );

      if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>("document") ) ) {
        Document document;
        from_XML( cur, document );
        collection.documents.push_back( document );
      }
		 
      cur = cur->next;
    }
  }


  void Connector_libxml::from_XML( xmlNodePtr cur, Document & document ) {
    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
      getValue( cur, "id", document.id );
      getValue( cur, "infon", document.infons );

      if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>("passage") ) ) {
        Passage passage;
        from_XML( cur, passage );
        document.passages.push_back( passage );
      }

      if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>("relation") ) ) {
        Relation relation;
        from_XML( cur, relation );
        document.relations.push_back( relation );
      }
		 
      cur = cur->next;
    }

  }


  void Connector_libxml::from_XML( xmlNodePtr cur, Passage & passage ) {
    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
      getValue( cur, "infon", passage.infons );
      getValue( cur, "offset", passage.offset );
      getValue( cur, "text", passage.text );

      if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>("sentence") ) ) {
        Sentence sentence;
        from_XML( cur, sentence );
        passage.sentences.push_back( sentence );
      }

      if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>("annotation") ) ) {
        Annotation annotation;
        from_XML( cur, annotation );
        passage.annotations.push_back( annotation );
      }

      if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>("relation") ) ) {
        Relation relation;
        from_XML( cur, relation );
        passage.relations.push_back( relation );
      }
		 
      cur = cur->next;
    }
  }


  void Connector_libxml::from_XML( xmlNodePtr cur, Sentence & sentence ) {
  	
    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
      getValue( cur, "infon", sentence.infons );
      getValue( cur, "offset", sentence.offset );
      getValue( cur, "text", sentence.text );

      if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>("annotation") ) ) {
        Annotation annotation;
        from_XML( cur, annotation );
        sentence.annotations.push_back( annotation );
      }

      if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>("relation") ) ) {
        Relation relation;
        from_XML( cur, relation );
        sentence.relations.push_back( relation );
      }

      cur = cur->next;
    }
    
  }


  bool Connector_libxml::getAttribute( xmlNodePtr cur, const string & name,
                                       string & value ) {

    xmlChar * id = xmlGetProp( cur, BAD_CAST name.c_str() );
    if ( id ) {
      value = string( (char*) id );
      xmlFree(id);
      return true;
    }
    return false;
  }

  bool Connector_libxml::getAttribute( xmlNodePtr cur, const string & name,
                                       int & value ) {

    string str_value;
    if ( getAttribute( cur, name, str_value ) ) {
      istringstream ist(str_value);
      ist >> value;
      return true;
    }
    return false;
  }


  void Connector_libxml::from_XML( xmlNodePtr cur, Annotation & annotation ) {

    xmlChar * id = xmlGetProp( cur, BAD_CAST "id");
    if ( id ) {
      annotation.id = string( (char*) id );
      xmlFree(id);
    }

    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
      getValue( cur, "infon", annotation.infons );
      getValue( cur, "location", annotation.locations );
      getValue( cur, "text", annotation.text );
      
      cur = cur->next;
    }
  }

  void Connector_libxml::from_XML( xmlNodePtr cur, Relation & relation ) {

    xmlChar * id = xmlGetProp( cur, BAD_CAST "id");
    if ( id ) {
      relation.id = string( (char*) id );
      xmlFree(id);
    }

    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
      getValue( cur, "infon", relation.infons );
      getValue( cur, "node", relation.nodes );
      
      cur = cur->next;
    }
  }


  bool Connector_libxml::getValue( xmlNodePtr cur, const char * element,
                                   string & value ) {
    if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>(element) )
         and ! xmlNodeIsText(cur) ) {
      xmlChar * text =
        xmlNodeListGetString( xml_doc, cur->xmlChildrenNode, 1 );
      value = string( (char*)text );
      xmlFree(text);
      return true;
    }
    return false;
  }

  bool Connector_libxml::getValue( xmlNodePtr cur, const char * element,
                                   int & value ) {
    string str_value;
    bool present = getValue( cur, element, str_value );
    if ( present ) {
      if ( not str_value.empty() ) {
        istringstream ist( str_value );
        ist >> value;
      }
    }
    return present;
  }

  bool Connector_libxml::getValue( xmlNodePtr cur, const char * element,
                                   vector<string> & value ) {
    string str_value;
    bool present = getValue( cur, element, str_value );
    if ( present )
      value.push_back(str_value);
    return present;
  }

  bool Connector_libxml::getValue( xmlNodePtr cur, const char * element,
                                   vector<Location> & value ) {
    if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>(element) ) ) {
      int offset;
      int length;
      getAttribute( cur, "offset", offset );
      getAttribute( cur, "length", length );
      value.push_back( Location(offset,length) );
      return true;
    }
    return false;
  }

  bool Connector_libxml::getValue( xmlNodePtr cur, const char * element,
                                   vector<Node> & value ) {
    if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>(element) ) ) {
      string refid;
      string role;
      getAttribute( cur, "refid", refid );
      getAttribute( cur, "role", role );
      value.push_back( Node(refid,role) );
      return true;
    }
    return false;
  }

  bool Connector_libxml::getValue( xmlNodePtr cur, const char * element,
                                   map<string,string> & hash ) {
    if ( !xmlStrcmp( cur->name, reinterpret_cast<const xmlChar *>(element) )
         and ! xmlNodeIsText(cur) ) {
      xmlChar * text =
        xmlNodeListGetString( xml_doc, cur->xmlChildrenNode, 1 );
      string value;
      if ( text ) 
        value = string( (char*)text );
      else
        value = "";
      xmlFree(text);

      string key;
      getAttribute( cur, "key", key );
      hash[key] = value;

      return true;
    }
    return false;
  }

  /** simply use the serial interface to write the entire collection
   **/
  void Connector_libxml::write(const string & docname,
                               const Collection & collection ) {
    start_write( docname, collection);
    for ( int i = 0; i < collection.documents.size(); ++i )
      write_next( collection.documents[i] );
    end_write();
  }

  
  template<>
  xmlNodePtr Connector_libxml::setValue<string>( xmlNodePtr parent,
                                                 const string & name,
                                                 const string & value ) {
    if ( value.empty() )
      return 0;

    return xmlNewTextChild( parent, NULL, BAD_CAST name.c_str(),
                            BAD_CAST value.c_str() );
  }


  template<>
  xmlNodePtr Connector_libxml::setValue<int>( xmlNodePtr parent,
                                              const string & name,
                                              const int & value ) {
    ostringstream ost;
    ost << value;
    setValue( parent, name, ost.str() );
  }

  
  template<>
  xmlNodePtr
  Connector_libxml::setValue<map<string,string> >( xmlNodePtr parent,
                                                   const string & name,
                                                   const map<string,string> & value ) {
    if ( value.empty() )
      return 0;

    xmlNodePtr result;

    map<string,string>::const_iterator iter;
    for ( iter = value.begin(); iter != value.end(); ++iter ) {
      result =  xmlNewTextChild( parent, NULL, BAD_CAST name.c_str(),
                                 BAD_CAST (iter->second).c_str() );
      setAttribute( result, "key", (iter->first).c_str() );
    }
    return result;
  }


  void Connector_libxml::to_XML( const Collection & collection ) {
  
    xmlNodePtr root_node = xmlNewNode(NULL, BAD_CAST "collection");
    xmlDocSetRootElement( xml_doc, root_node );
  
    setValue( root_node, "source", collection.source );
    setValue( root_node, "date", collection.date );
    setValue( root_node, "key", collection.key );
    setValue( root_node, "infon", collection.infons );
    setValue( root_node, "", collection.documents );
  }


  void Connector_libxml::to_XML( xmlNodePtr root,
                                 const Document & document ) {
  
    xmlNodePtr doc_xml = xmlNewChild( root, NULL, BAD_CAST "document",
                                      NULL );

    setValue( doc_xml, "id", document.id );
    setValue( doc_xml, "infon", document.infons );
    setValue( doc_xml, "", document.passages );
    setValue( doc_xml, "", document.relations );
  }


  void Connector_libxml::to_XML( xmlNodePtr document_xml,
                                 const Passage & passage ) {
  
    xmlNodePtr passage_xml = xmlNewChild( document_xml, NULL,
                                          BAD_CAST "passage", NULL );

    setValue( passage_xml, "infon", passage.infons );
    setValue( passage_xml, "offset", passage.offset );
    setValue( passage_xml, "text", passage.text );
    setValue( passage_xml, "", passage.sentences );
    setValue( passage_xml, "", passage.annotations );
    setValue( passage_xml, "", passage.relations );
  
  }


  void Connector_libxml::to_XML( xmlNodePtr passage_xml,
                                 const Sentence & sentence ) {
  
    xmlNodePtr sentence_xml = xmlNewChild( passage_xml, NULL,
                                           BAD_CAST "sentence", NULL );
  
    setValue( sentence_xml, "infon", sentence.infons );
    setValue( sentence_xml, "offset", sentence.offset );
    setValue( sentence_xml, "text", sentence.text );
    setValue( sentence_xml, "", sentence.annotations );
    setValue( sentence_xml, "", sentence.relations );
  }


  void Connector_libxml::setAttribute( xmlNodePtr xml_node, const string & name,
                                       const string & value ) {
    xmlNewProp( xml_node, BAD_CAST name.c_str(),
                BAD_CAST value.c_str() );
  }


  void Connector_libxml::setAttribute( xmlNodePtr xml_node, const string & name,
                                       int value ) {
    ostringstream ost;
    ost << value;
    setAttribute( xml_node, name, ost.str() );
  }


  void Connector_libxml::to_XML( xmlNodePtr sentence_xml,
                                 const Annotation & annotation ) {
    xmlNodePtr xml_node = xmlNewChild( sentence_xml, NULL,
                                       BAD_CAST "annotation", NULL );

    if ( ! annotation.id.empty() )
      xmlNewProp( xml_node, BAD_CAST "id",
                  BAD_CAST annotation.id.c_str() );
  
    setValue( xml_node, "infon", annotation.infons );
    setValue( xml_node, "location", annotation.locations );
    setValue( xml_node, "text", annotation.text );
  }

  void Connector_libxml::to_XML( xmlNodePtr annotation_xml,
                                 const Location & location ) {
    xmlNodePtr xml_node = xmlNewChild( annotation_xml, NULL,
                                       BAD_CAST "location", NULL );
    setAttribute( xml_node, "offset", location.offset );
    setAttribute( xml_node, "length", location.length );
  }

  void Connector_libxml::to_XML( xmlNodePtr sentence_xml,
                                 const Relation & relation ) {
    xmlNodePtr xml_node = xmlNewChild( sentence_xml, NULL,
                                       BAD_CAST "relation", NULL );

    xmlNewProp( xml_node, BAD_CAST "id", BAD_CAST relation.id.c_str() );
  
    setValue( xml_node, "infon", relation.infons );
    for ( int i = 0; i < relation.nodes.size(); ++i )
      to_XML( xml_node, relation.nodes[i] );
  }

  void Connector_libxml::to_XML( xmlNodePtr relation_xml,
                                 const Node & node ) {
    xmlNodePtr xml_node = xmlNewChild( relation_xml, NULL,
                                       BAD_CAST "node", NULL );
    setAttribute( xml_node, "refid", node.refid );
    setAttribute( xml_node, "role", node.role );
  }

  int Connector_libxml::getDocument( Document & document ) {
    document.clear();
    xmlNodePtr node = xmlTextReaderExpand(reader);
    from_XML( node, document);
    return 1;
  }


  int Connector_libxml::getValue( const string & element, string & value ) {
    value = "";

    int ret = xmlTextReaderRead(reader);
    while (ret == 1) {
      xmlChar* name = xmlTextReaderName(reader);

      if ( xmlTextReaderNodeType(reader) == XML_READER_TYPE_END_ELEMENT and
           (xmlStrcmp(name, (const xmlChar *) element.c_str() ) == 0 ) ) {
        xmlFree(name);
        return 1;
      }

      if ( xmlTextReaderNodeType(reader) == XML_READER_TYPE_TEXT ) {
        xmlChar * text = xmlTextReaderValue(reader);
        value += (char*)text;
        xmlFree(text);
      }
    
      xmlFree(name);

      ret = xmlTextReaderRead(reader);
    }
    return ret;
  }

  int Connector_libxml::getValue( const string & element, int & value ) {

    string str_value;
    int ret = getValue( element, str_value );
    if ( ret == 1 ) {
      std::istringstream ist( str_value );
      ist >> value;
      return 1;
    }
  
    return ret;
  }


  void Connector_libxml::start_read( const string & docname,
                                     Collection & collection ) {
    reader = xmlNewTextReaderFilename( docname.c_str() );
    if ( reader == NULL ) {
      cerr << "unable to open " << docname << '\n';
      parse_error(0);
    }
  
    bool in_collection = false;
    bool in_document = false;
    int ret = xmlTextReaderRead(reader);
    xml_doc = xmlTextReaderCurrentDoc(reader);
    //dtd =  (char*)xml_doc->intSubset->name;
    dtd = "bioc.dtd";
    while (ret == 1 and not in_document ) {
    
      xmlChar* name = xmlTextReaderName(reader);
    
      if ( xmlTextReaderNodeType(reader) == XML_READER_TYPE_ELEMENT and
           (xmlStrcmp(name, (const xmlChar *) "collection") == 0 ) ) {
        in_collection = true;
      }
      else if ( in_collection and
                xmlTextReaderNodeType(reader) == XML_READER_TYPE_ELEMENT and
                (xmlStrcmp(name, (const xmlChar *) "source") == 0 ) ) {
        ret = getValue( "source", collection.source );
        if ( ret != 1 )
          parse_error(ret);
      }
      else if ( in_collection and
                xmlTextReaderNodeType(reader) == XML_READER_TYPE_ELEMENT and
                (xmlStrcmp(name, (const xmlChar *) "date") == 0 ) ) {
        ret = getValue( "date", collection.date );
        if ( ret != 1 )
          parse_error(ret);
      }
      else if ( in_collection and
                xmlTextReaderNodeType(reader) == XML_READER_TYPE_ELEMENT and
                (xmlStrcmp(name, (const xmlChar *) "key") == 0 ) ) {
        ret = getValue( "key", collection.key );
        if ( ret != 1 )
          parse_error(ret);
      }
      else if ( in_collection and
                xmlTextReaderNodeType(reader) == XML_READER_TYPE_ELEMENT and
                (xmlStrcmp(name, (const xmlChar *) "infon") == 0 ) ) {
        xmlNodePtr node = xmlTextReaderExpand(reader);
        getValue( node, "infon", collection.infons );
      }
      else if ( in_collection and
                xmlTextReaderNodeType(reader) == XML_READER_TYPE_ELEMENT and
                (xmlStrcmp(name, (const xmlChar *) "document") == 0 ) ) {
        in_document = true;
      }
    
      xmlFree(name);
      if ( not in_document )
        ret = xmlTextReaderRead(reader);
    }

  }


  bool Connector_libxml::read_next( Document & document ) {

    bool done = false;
    bool return_value = false;
    int ret = 1;

    while ( ret == 1 and not done ) {
      xmlChar* name = xmlTextReaderName(reader);

      if ( xmlTextReaderNodeType(reader) == XML_READER_TYPE_ELEMENT and
           (xmlStrcmp(name, (const xmlChar *) "document") == 0 ) ) {
    
        int ret = getDocument( document );
        if ( ret != 1 )
          parse_error(ret);
        return_value = true;
        done = true;
      }
      else if ( xmlTextReaderNodeType(reader) == XML_READER_TYPE_END_ELEMENT and
                (xmlStrcmp(name, (const xmlChar *) "collection") == 0 ) ) {
        xmlFree(name);
        xmlFreeTextReader(reader);
        reader = NULL;
        xmlFreeDoc(xml_doc);
        xml_doc = NULL;
        return false;
      }

      xmlFree(name);
      ret = xmlTextReaderRead(reader);
    }
    if ( ret != 1 )
      parse_error(ret);

    return return_value;
  }


  void Connector_libxml::parse_error( int error_code ) {
    cerr << "error with libxml. Error code: " << error_code << '\n';
    exit(-1);
  }


  void Connector_libxml::endElement( void ) {

    int rc = xmlTextWriterEndElement(writer);
    if (rc < 0) {
      cerr << "xmllib::endElement: Error at xmlTextWriterEndElement\n";
      parse_error(rc);
    }
  }


  void Connector_libxml::startElement( const string & name ) {

    int rc = xmlTextWriterStartElement(writer, BAD_CAST name.c_str() );
    if (rc < 0) {
      cerr << "xmllib::startElement: Error at xmlTextWriterStartElement "
           << name << '\n';
      parse_error(rc);
    }
  }


  void Connector_libxml::writeAttribute( const string & name,
                                         const string & value ) {
    if ( value.empty() )
      return;

    int rc = xmlTextWriterWriteAttribute(writer, BAD_CAST name.c_str(),
                                         BAD_CAST value.c_str() );
    if (rc < 0) {
      cerr << "xmllib::writeAttribute: Error at xmlTextWriterWriteAttribute "
           << name << '\n';
      parse_error(rc);
    }
  }

  void Connector_libxml::writeAttribute( const string & name, int value ) {

    ostringstream ost;
    ost << value;
    writeAttribute( name, ost.str() );
  }


  void Connector_libxml::writeElement( const string & name,
                                       const string & value ) {

    int rc = xmlTextWriterWriteElement(writer, BAD_CAST name.c_str(),
                                       BAD_CAST value.c_str() );
    if (rc < 0) {
      cerr << "xmllib::writeElement: Error at xmlTextWriterWriteElement "
           << name << '\n';
      parse_error(rc);
    }
  }


  void Connector_libxml::writeElement( const string & name, int value ) {
    ostringstream ost;
    ost << value;
    writeElement(name, ost.str() );
  }

  void Connector_libxml::writeElement( const string & name,
                                       const vector<string> & value ) {
    for ( int i = 0; i < value.size(); ++i )
      writeElement(name, value[i] );
  }

  void Connector_libxml::writeElement( const string & name,
                                       const map<string,string> & value ) {
    map<string,string>::const_iterator iter;
    for ( iter = value.begin(); iter != value.end(); ++iter ) {
      startElement(name);
      writeAttribute( "key", iter->first );
      xmlTextWriterWriteString( writer, BAD_CAST (iter->second).c_str() );
      endElement();
    }
  }


  void Connector_libxml::start_write( const string & docname,
                                      const Collection & collection ) {
    writer = xmlNewTextWriterFilename(docname.c_str(), 0);
    if (writer == NULL) {
      cerr << "xmllib::start_write: Error creating the xml writer\n";
      parse_error(0);
    }

    int rc = xmlTextWriterStartDocument(writer, NULL, "UTF-8", NULL);
    if (rc < 0) {
      cerr << "testXmlwriterStartDocument: Error at xmlTextWriterStartDocument\n";
      parse_error(rc);
    }
    rc = xmlTextWriterWriteDTD( writer, BAD_CAST "collection", NULL,
                                BAD_CAST dtd.c_str(), NULL);
    if (rc < 0) {
      cerr << "xmllib::start_write: Error at xmlTextWriterWriteDTD\n";
      parse_error(rc);
    }

    // this makes the XML easier to compare with XML made by the DOM writer
    xmlTextWriterWriteString( writer, BAD_CAST "\n" );

    startElement( "collection" );

    writeElement( "source", collection.source );
    writeElement( "date", collection.date );
    writeElement( "key", collection.key );
    writeElement( "infon", collection.infons );
  }


  void Connector_libxml::write_next( const Document & document ) {

    startElement( "document" );
    writeElement( "id", document.id );
    writeElement( "infon", document.infons );
    for ( int i = 0; i < document.passages.size(); ++i )
      write_next( document.passages[i] );
    for ( int i = 0; i < document.relations.size(); ++i )
      write_next( document.relations[i] );
    endElement();
  }


  void Connector_libxml::write_next( const Passage & passage ) {

    startElement( "passage" );
    writeElement( "infon", passage.infons );
    writeElement( "offset", passage.offset );
    if ( ! passage.text.empty() )
      writeElement( "text", passage.text );
    for ( int i = 0; i < passage.sentences.size(); ++i )
      write_next( passage.sentences[i] );
    for ( int i = 0; i < passage.annotations.size(); ++i )
      write_next( passage.annotations[i] );
    for ( int i = 0; i < passage.relations.size(); ++i )
      write_next( passage.relations[i] );
    endElement();
  }


  void Connector_libxml::write_next( const Sentence & sentence ) {

    startElement( "sentence" );
    writeElement( "infon", sentence.infons );
    writeElement( "offset", sentence.offset );
    if ( ! sentence.text.empty() )
      writeElement( "text", sentence.text );
    for ( int i = 0; i < sentence.annotations.size(); ++i )
      write_next( sentence.annotations[i] );
    for ( int i = 0; i < sentence.relations.size(); ++i )
      write_next( sentence.relations[i] );
    endElement();
  }


  void Connector_libxml::write_next( const Annotation & annotation ) {

    startElement( "annotation" );
    writeAttribute( "id", annotation.id );
    writeElement( "infon", annotation.infons );
    for ( int i = 0; i < annotation.locations.size(); ++i )
      write_next( annotation.locations[i] );
    writeElement( "text", annotation.text );
    endElement();
  }


  void Connector_libxml::write_next( const Location & location ) {

    startElement( "location" );
    writeAttribute( "offset", location.offset );
    writeAttribute( "length", location.length );
    endElement();
  }


  void Connector_libxml::write_next( const Relation & relation ) {

    startElement( "relation" );
    writeAttribute( "id", relation.id );
    writeElement( "infon", relation.infons );
    for ( int i = 0; i < relation.nodes.size(); ++i )
      write_next( relation.nodes[i] );
    endElement();
  }

  void Connector_libxml::write_next( const Node & node ) {

    startElement( "node" );
    writeAttribute( "refid", node.refid );
    writeAttribute( "role", node.role );
    endElement();
  }


  void Connector_libxml::end_write( void ) {
    int rc = xmlTextWriterEndDocument(writer);
    if (rc < 0) {
      cerr << "xmllib::close_write: Error at xmlTextWriterEndDocument\n";
      parse_error(rc);
    }

    xmlFreeTextWriter(writer);
    writer = NULL;
  }

}
