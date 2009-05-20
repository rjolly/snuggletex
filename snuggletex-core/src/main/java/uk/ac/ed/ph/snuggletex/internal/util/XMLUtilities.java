/* $Id$
 *
 * Copyright (c) 2003 - 2009 University of Edinburgh.
 * All Rights Reserved
 */
package uk.ac.ed.ph.snuggletex.internal.util;

import uk.ac.ed.ph.snuggletex.SnuggleRuntimeException;
import uk.ac.ed.ph.snuggletex.definitions.Globals;
import uk.ac.ed.ph.snuggletex.utilities.ClassPathURIResolver;
import uk.ac.ed.ph.snuggletex.utilities.StylesheetManager;

import java.io.StringWriter;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Some trivial little helpers for creating suitably-configured {@link TransformerFactory}
 * instances.
 * <p>
 * (This is based on similar utility methods in <tt>ph-commons</tt>.)
 *
 * @author  David McKain
 * @version $Revision$
 */
public final class XMLUtilities {
    
    /** Explicit name of the SAXON 9.X TransformerFactoryImpl Class, as used by the up-conversion extensions */
    public static final String SAXON_TRANSFORMER_FACTORY_CLASS_NAME = "net.sf.saxon.TransformerFactoryImpl";

    /**
     * Creates an instance of the currently specified JAXP {@link TransformerFactory}, ensuring
     * that the result supports the {@link DOMSource#FEATURE} and {@link DOMResult#FEATURE}
     * features.
     */
    public static TransformerFactory createJAXPTransformerFactory() {
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
    
    private static void requireFeature(final TransformerFactory transformerFactory, final String feature) {
        if (!transformerFactory.getFeature(feature)) {
            throw new SnuggleRuntimeException("TransformerFactory "
                    + transformerFactory.getClass().getName()
                    + " needs to support feature "
                    + feature
                    + " in order to be used with SnuggleTeX");
        }   
    }

    /**
     * Explicitly creates a Saxon 9 {@link TransformerFactory}, as used by the up-conversion
     * extensions.
     */
    public static TransformerFactory createSaxonTransformerFactory() {
        try {
            /* We call up SAXON explicitly without going through the usual factory path */
            return (TransformerFactory) Class.forName(SAXON_TRANSFORMER_FACTORY_CLASS_NAME).newInstance();
        }
        catch (Exception e) {
            throw new SnuggleRuntimeException("Failed to explicitly instantiate SAXON "
                    + SAXON_TRANSFORMER_FACTORY_CLASS_NAME
                    + " class - check your ClassPath!", e);
        }
    }
    
    /**
     * Compiles an "internal" stylesheet located via the ClassPath at the given location.
     * <p>
     * (This takes an explicit {@link TransformerFactory} as the first argument as some extensions
     * require XSLT 2.0 so will have created an explicit instance of SAXON's {@link TransformerFactory}
     * to pass to this.)
     *
     * @param transformerFactory
     * @param classPathUri absolute URI specifying the location of the stylesheet in the ClassPath,
     *   specified via the scheme mentioned in {@link ClassPathURIResolver}.
     */
    public static Templates compileInternalStylesheet(final TransformerFactory transformerFactory,
            String classPathUri) {
        ClassPathURIResolver uriResolver = ClassPathURIResolver.getInstance();
        transformerFactory.setURIResolver(uriResolver);
        Source resolved;
        try {
            resolved = uriResolver.resolve(classPathUri, "");
            return transformerFactory.newTemplates(resolved);
        }
        catch (TransformerConfigurationException e) {
            throw new SnuggleRuntimeException("Could not compile internal stylesheet at " + classPathUri, e);
        }
        catch (TransformerException e) {
            throw new SnuggleRuntimeException("Could not resolve internal stylesheet location " + classPathUri, e);
        }
    }
    
    /**
     * Tests whether the given {@link Transformer} is known to support XSLT 2.0.
     * <p>
     * Currently, this involves checking for a suitable version of SAXON; this will
     * change once more processors become available.
     */
    public static boolean supportsXSLT20(final Transformer tranformer) {
        return tranformer.getClass().getName().startsWith("net.sf.saxon.");
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

    /**
     * Trivial convenience method to extract the value of a (text) Element, coping with the
     * possibility that text child Nodes may not have been coalesced.
     * 
     * @param textElement
     */
    public static String extractTextElementValue(final Element textElement) {
        NodeList childNodes = textElement.getChildNodes();
        String result;
        if (childNodes.getLength()==1) {
            /* Text Nodes have been coalesced */
            result = ensureExtractTextNodeValue(childNodes.item(0));
        }
        else {
            /* Need to coalesce manually */
            StringBuilder resultBuilder = new StringBuilder();
            for (int i=0; i<childNodes.getLength(); i++) {
                resultBuilder.append(ensureExtractTextNodeValue(childNodes.item(i)));
            }
            result = resultBuilder.toString();
        }
        return result;
    }
    
    private static String ensureExtractTextNodeValue(final Node node) {
        if (node.getNodeType()==Node.TEXT_NODE) {
            return node.getNodeValue();
        }
        throw new IllegalArgumentException("Node is not a text Node");
    }
    
    /**
     * Serializes the given {@link Node} to a well-formed external parsed entity.
     * (If the given Node is an {@link Element} or a {@link Document} then the result
     * will be a well-formed XML String.)
     *
     * @param node DOM Node to serialize.
     * @param indent whether to indent the results or not
     * @param omitXMLDeclaration whether to omit the XML declaration or not.
     */
    public static String serializeNode(final Node node, final boolean indent,
            final boolean omitXMLDeclaration) {
        StringWriter resultWriter = new StringWriter();
        try {
            Transformer serializer = createJAXPTransformerFactory().newTransformer();
            serializer.setOutputProperty(OutputKeys.INDENT, StringUtilities.toYesNo(indent));
            serializer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, StringUtilities.toYesNo(omitXMLDeclaration));
            serializer.transform(new DOMSource(node), new StreamResult(resultWriter));
        }
        catch (Exception e) {
            throw new SnuggleRuntimeException("Could not serialize DOM", e);
        }
        return resultWriter.toString();
    }
    
    /**
     * Serializes the <tt>children</tt> of given {@link Node} to a well-formed external parsed entity.
     * <p>
     * (This uses a little XSLT stylesheet to help, hence the requirement for a {@link StylesheetManager}).
     *
     * @param node DOM Node to serialize.
     * @param indent whether to indent the results or not
     * @param omitXMLDeclaration whether to omit the XML declaration or not.
     */
    public static String serializeNodeChildren(final Node node, final boolean indent,
            final boolean omitXMLDeclaration, StylesheetManager stylesheetManager) {
        StringWriter resultWriter = new StringWriter();
        try {
            Transformer serializer = stylesheetManager.getStylesheet(Globals.EXTRACT_CHILD_NODES_XSL_RESOURCE_NAME).newTransformer();
            serializer.setOutputProperty(OutputKeys.INDENT, StringUtilities.toYesNo(indent));
            serializer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, StringUtilities.toYesNo(omitXMLDeclaration));
            serializer.transform(new DOMSource(node), new StreamResult(resultWriter));
        }
        catch (Exception e) {
            throw new SnuggleRuntimeException("Could not serialize DOM", e);
        }
        return resultWriter.toString();
    }
}