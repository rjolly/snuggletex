/* $Id$
 *
 * Copyright (c) 2003 - 2008 University of Edinburgh.
 * All Rights Reserved
 */
package uk.ac.ed.ph.snuggletex.conversion;

import uk.ac.ed.ph.snuggletex.SnuggleRuntimeException;

import java.io.StringWriter;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Node;

/**
 * Some trivial little helpers for creating suitably-configured {@link TransformerFactory}
 * instances.
 * <p>
 * (This is based on similar utility methods in Aardvark.)
 *
 * @author  David McKain
 * @version $Revision$
 */
public final class XMLUtilities {

    public static TransformerFactory createTransformerFactory() {
        TransformerFactory transformerFactory = null;
        try {
            transformerFactory = TransformerFactory.newInstance();
        }
        catch (TransformerFactoryConfigurationError e) {
            throw new SnuggleRuntimeException(e);
        }
        /* Make sure we have DOM-based features */
        requireFeature(transformerFactory, DOMSource.FEATURE);
        requireFeature(transformerFactory, DOMResult.FEATURE);
        
        /* Must have been OK! */
        return transformerFactory;
    }
    
    private static void requireFeature(TransformerFactory transformerFactory, String feature) {
        if (!transformerFactory.getFeature(feature)) {
            throw new SnuggleRuntimeException("TransformerFactory "
                    + transformerFactory.getClass().getName()
                    + " needs to support feature "
                    + feature
                    + " in order to be used with SnuggleTeX");
        }   
    }
    
    /**
     * Creates a (namespace-aware) DOM {@link DocumentBuilder}, throwing a {@link SnuggleRuntimeException}
     * if such a thing cannot be created/configured.
     */
    public static DocumentBuilder createNSAwareDocumentBuilder() {
        DocumentBuilderFactory documentBuilderFactory = DocumentBuilderFactory.newInstance();
        documentBuilderFactory.setNamespaceAware(true);
        try {
            return documentBuilderFactory.newDocumentBuilder();
        }
        catch (ParserConfigurationException e) {
            throw new SnuggleRuntimeException("Could not create Namespace-aware DocumentBuilder", e);
        }
    }
    
    public static String serializeXMLFragment(final Node node) {
        TransformerFactory transformerFactory = createTransformerFactory();
        StringWriter resultWriter = new StringWriter();
        try {
            Transformer transformer = transformerFactory.newTransformer();
            transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
            transformer.transform(new DOMSource(node), new StreamResult(resultWriter));
        }
        catch (Exception e) {
            throw new SnuggleRuntimeException("Could not serialize DOM subtree", e);
        }
        return resultWriter.toString();
    }
}