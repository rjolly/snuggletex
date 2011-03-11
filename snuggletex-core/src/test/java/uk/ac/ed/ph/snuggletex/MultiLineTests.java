/* $Id:MultiLineTests.java 179 2008-08-01 13:41:24Z davemckain $
 *
 * Copyright (c) 2008-2011, The University of Edinburgh.
 * All Rights Reserved
 */
package uk.ac.ed.ph.snuggletex;

import uk.ac.ed.ph.snuggletex.SnuggleTeXCaller.DOMVerifyCallback;
import uk.ac.ed.ph.snuggletex.definitions.W3CConstants;
import uk.ac.ed.ph.snuggletex.testutil.TestFileHelper;

import java.util.Collection;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import org.w3c.dom.Document;

/**
 * Set of multiple line tests, defined in <tt>{@link #TEST_RESOURCE_NAME}</tt>. See this file
 * for examples of how it all works.
 * 
 * @author  David McKain
 * @version $Revision:179 $
 */
@RunWith(Parameterized.class)
public class MultiLineTests implements DOMVerifyCallback {
    
    public static final String TEST_RESOURCE_NAME = "multiline-tests.txt";
    
    @Parameters
    public static Collection<String[]> data() throws Exception {
        return TestFileHelper.readAndParseMultiLineInputTestResource(TEST_RESOURCE_NAME);
    }
    
    private final String inputLaTeX;
    private final String expectedXML;
    
    public MultiLineTests(final String inputLaTeX, final String expectedXMLContent) {
        this.inputLaTeX = inputLaTeX;
        this.expectedXML = "<body xmlns='" + W3CConstants.XHTML_NAMESPACE + "'>"
                + expectedXMLContent.replaceAll("(?m)^ +", "").replaceAll("(?m) +$", "")
                    .replace("\n", "")
                    .replace("%n", "\n")
                + "</body>";
    }
    
    @Test
    public void runTest() throws Throwable {
        SnuggleEngine engine = new SnuggleEngine();
        
        SnuggleTeXCaller caller = new SnuggleTeXCaller(engine);
        caller.setShowTokensOnFailure(true);
        caller.setDomVerifyCallback(this);
        
        caller.run(inputLaTeX, expectedXML);
    }
    
    public void verifyDOM(Document document) throws Throwable {
        /* Check XML verifies against what we expect */
        TestUtilities.verifyXML(expectedXML, document);
    }
}
