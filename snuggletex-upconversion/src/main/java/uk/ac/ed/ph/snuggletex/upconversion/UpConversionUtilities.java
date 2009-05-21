/* $Id$
 *
 * Copyright 2009 University of Edinburgh.
 * All Rights Reserved
 */
package uk.ac.ed.ph.snuggletex.upconversion;

import uk.ac.ed.ph.snuggletex.ErrorCode;
import uk.ac.ed.ph.snuggletex.SnuggleConstants;
import uk.ac.ed.ph.snuggletex.SnuggleLogicException;
import uk.ac.ed.ph.snuggletex.internal.util.ConstraintUtilities;
import uk.ac.ed.ph.snuggletex.internal.util.XMLUtilities;
import uk.ac.ed.ph.snuggletex.utilities.MathMLUtilities;
import uk.ac.ed.ph.snuggletex.utilities.MessageFormatter;

import java.util.ArrayList;
import java.util.List;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Some static utility methods for the up-conversion process, including methods for extracting
 * errors.
 *
 * @author  David McKain
 * @version $Revision$
 */
public final class UpConversionUtilities {
    
    /**
     * Returns a full error message for the given {@link UpConversionFailure}, using
     * the SnuggleTeX {@link MessageFormatter} class to do the hard work.
     * 
     * @param failure
     */
    public static String getErrorMessage(UpConversionFailure failure) {
        return MessageFormatter.getErrorMessage(failure.getErrorCode().toString(), failure.getArguments());
    }
    
    /**
     * Populates and returns an {@link UpConversionFailure} for the given {@link Element},
     * which is assumed to be a <tt>s:fail</tt> element having the appropriate structure.
     * 
     * @param sFailElement
     */
    public static UpConversionFailure extractUpConversionFailure(final Element sFailElement) {
        ConstraintUtilities.ensureNotNull(sFailElement, "sFailElement");
        if (!(sFailElement.getNamespaceURI().equals(SnuggleConstants.SNUGGLETEX_NAMESPACE) && sFailElement.getLocalName().equals("fail"))) {
            throw new IllegalArgumentException("Element is not an <s:fail/> element");
        }
        /* Yay! This is one of our <s:fail/> elements. First extract ErrorCode */
        String codeAttribute = sFailElement.getAttribute("code");
        ErrorCode errorCode;
        try {
            errorCode = ErrorCode.valueOf(codeAttribute);
        }
        catch (IllegalArgumentException e) {
            throw new SnuggleLogicException("Error code '" + codeAttribute + "' not defined");
        }
        /* Now get arguments and context */
        NodeList childNodes = sFailElement.getChildNodes();
        Node child;
        List<String> arguments = new ArrayList<String>();
        String context = null;
        for (int i=0, size=childNodes.getLength(); i<size; i++) {
            child = childNodes.item(i);
            if (child.getNodeType()==Node.ELEMENT_NODE) {
                if (!child.getNamespaceURI().equals(SnuggleConstants.SNUGGLETEX_NAMESPACE)) {
                    throw new SnuggleLogicException("Didn't expect child of <s:fail/> in namespace " + child.getNamespaceURI());
                }
                if (child.getLocalName().equals("arg")) {
                    arguments.add(XMLUtilities.extractTextElementValue((Element) child));
                }
                else if (child.getLocalName().equals("context")) {
                    if (context!=null) {
                        throw new SnuggleLogicException("Did not expect more than 1 <s:context/> element inside <s:fail/>");
                    }
                    context = MathMLUtilities.serializeElement((Element) child);
                }
                else {
                    throw new SnuggleLogicException("Didn't expect child of <s:fail/> with local name " + child.getLocalName());
                }
            }
        }
        if (context==null) {
            throw new SnuggleLogicException("No <s:context/> element found inside <s:fail/>");
        }
        return new UpConversionFailure(errorCode, context, arguments.toArray(new String[arguments.size()]));
    }
    
    public static List<UpConversionFailure> extractUpConversionFailures(Document upConvertedDocument) {
        return extractUpConversionFailures(upConvertedDocument.getDocumentElement());
    }
    
    public static List<UpConversionFailure> extractUpConversionFailures(Element startSearchElement) {
        List<UpConversionFailure> result = new ArrayList<UpConversionFailure>();
        walkDOM(startSearchElement, result);
        return result;
    }

    /**
     * Checks to see whether the given element is of the form:
     * 
     * <![CDATA[
     * <s:fail code="...">
     *   <s:arg>...</s:arg>
     *   ...
     *   <s:context>...</s:context>
     * </s:fail>
     * ]]>
     * 
     * If so, creates an {@link UpConversionFailure} for this and adds to the result. If not,
     * traverses downwards recursively.
     * 
     * @param searchElement
     * @param resultBuilder
     */
    private static void walkDOM(Element searchElement, List<UpConversionFailure> resultBuilder) {
        if (searchElement.getNamespaceURI().equals(SnuggleConstants.SNUGGLETEX_NAMESPACE) && searchElement.getLocalName().equals("fail")) {
            resultBuilder.add(extractUpConversionFailure(searchElement));
        }
        else {
            /* Descend into child elements */
            NodeList childNodes = searchElement.getChildNodes();
            Node child;
            for (int i=0, size=childNodes.getLength(); i<size; i++) {
                child = childNodes.item(i);
                if (child.getNodeType()==Node.ELEMENT_NODE) {
                    walkDOM((Element) child, resultBuilder);
                }
            }
        }
    }

}
