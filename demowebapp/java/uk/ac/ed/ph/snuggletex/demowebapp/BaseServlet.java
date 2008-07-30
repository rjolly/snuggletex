/* $Id: org.eclipse.jdt.ui.prefs 3 2008-04-25 12:10:29Z davemckain $
 *
 * Copyright 2008 University of Edinburgh.
 * All Rights Reserved
 */
package uk.ac.ed.ph.snuggletex.demowebapp;

import uk.ac.ed.ph.snuggletex.conversion.XMLUtilities;

import java.io.InputStream;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.xml.transform.Source;
import javax.xml.transform.Templates;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.URIResolver;
import javax.xml.transform.stream.StreamSource;

/**
 * Trivial base class for servlets in the demo webapp
 *
 * @author  David McKain
 * @version $Revision: 3 $
 */
abstract class BaseServlet extends HttpServlet {
    
    /**
     * Helper that reads in a resource from the webapp hierarchy, throwing a {@link ServletException}
     * if the resource could not be found.
     * 
     * @param resourcePathInsideWebpp path of Resource to load, relative to base of webapp.
     * @return resulting {@link InputStream}, which will not be null
     * @throws ServletException
     */
    protected InputStream ensureReadResource(String resourcePathInsideWebpp) throws ServletException {
        InputStream result = getServletContext().getResourceAsStream(resourcePathInsideWebpp);
        if (result==null) {
            throw new ServletException("Could not read in required web resource at " + resourcePathInsideWebpp);
        }
        return result;
    }
    
    /**
     * Compiles the XSLT stylesheet at the given location within the webapp. This uses a
     * {@link CheapoURIResolver} to resolve any other stylesheets referenced using
     * <tt>xsl:import</tt> and friends.
     * 
     * @param xsltPathInsideWebapp location of XSLT to compile.
     * @return resulting {@link Templates} representing the compiled stylesheet.
     * @throws ServletException if XSLT could not be found or could not be compiled.
     */
    protected Templates compileStylesheet(String xsltPathInsideWebapp) throws ServletException {
        StreamSource xsltSource = new StreamSource(ensureReadResource(xsltPathInsideWebapp));
        TransformerFactory transformerFactory = XMLUtilities.createTransformerFactory();

        /* Create a cheap URIResolver to help with xsl:import and friends. */
        transformerFactory.setURIResolver(new CheapoURIResolver());
        
        /* Then compile the XSLT */
        try {
            return transformerFactory.newTemplates(xsltSource);
        }
        catch (TransformerConfigurationException e) {
            throw new ServletException("Could not compile stylesheet at " + xsltPathInsideWebapp);
        }
    }

    /**
     * Trivial implementation of {@link URIResolver} that assumes that all lookups will be
     * absolute paths resolved against the base of the webapp.
     * <p>
     * This is quite a poor state of affairs in general but is all we need here!
     */
    protected final class CheapoURIResolver implements URIResolver {
        
        public Source resolve(String href, String base) throws TransformerException {
            InputStream resource = getServletContext().getResourceAsStream(href);
            if (resource==null) {
                throw new TransformerException("Could not resolve resource at href=" + href
                        + " using cheap resolver");
            }
            return new StreamSource(resource);
        }
    }
}
