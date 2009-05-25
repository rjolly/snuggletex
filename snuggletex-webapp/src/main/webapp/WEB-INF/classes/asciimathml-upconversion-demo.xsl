<?xml version="1.0"?>
<!--

$Id$

Overrides format-output.xsl to add in functionality for
demonstrating ASCIIMathML -> Presentation MathML -> Content MathML -> Maxima
up-conversion process.

Copyright (c) 2009 University of Edinburgh.
All Rights Reserved

-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  xmlns:s="http://www.ph.ed.ac.uk/snuggletex"
  xmlns:mu="ext://uk.ac.ed.ph.snuggletex.utilities.MathMLUtilities"
  xmlns="http://www.w3.org/1999/xhtml"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs m s mu">

  <!-- Import basic formatting stylesheet -->
  <xsl:import href="format-output.xsl"/>

  <xsl:param name="is-new-form" as="xs:boolean" required="yes"/>
  <xsl:param name="ascii-math-input" as="xs:string?" select="'e^(i pi)+1 = 0'"/>
  <xsl:param name="ascii-math-output" as="xs:string?"/>
  <xsl:param name="parallel-mathml-element" as="element()?"/>
  <xsl:param name="parallel-mathml" as="xs:string?"/>
  <xsl:param name="pmathml-upconverted" as="xs:string?"/>
  <xsl:param name="cmathml" as="xs:string?"/>
  <xsl:param name="maxima-input" as="xs:string?"/>

  <!-- Override page ID -->
  <xsl:variable name="pageId" select="'asciiMathMLUpConversionDemo'" as="xs:string"/>

  <!-- Override title -->
  <xsl:variable name="title" select="'ASCIIMathML Up-Conversion Demo'" as="xs:string"/>

  <xsl:template match="head">
    <xsl:apply-imports/>
    <script type="text/javascript" src="{$context-path}/includes/ASCIIMathML.js"></script>
    <script type="text/javascript" src="{$context-path}/includes/ASCIIMathMLeditor.js"></script>
    <script type="text/javascript" src="{$context-path}/includes/ASCIIMathMLcustomisations.js"></script>
    <script type="text/javascript"><![CDATA[
      function updatePreview() {
        AMdisplayQuoted('asciiMathInput','preview',true);
      }
      window.onload = updatePreview;
    ]]></script>
  </xsl:template>

  <xsl:template match="body" mode="make-content">
    <h2><xsl:value-of select="$title"/></h2>

    <!-- Input Form -->
    <p>
      Enter some ASCIIMathML into the box below. You should see a real time preview
      of this while you type. Hit <tt>Go!</tt> to see the resulting outputs, which take
      the MathML produced by ASCIIMathML and do stuff to it.
    </p>
    <form method="post" onsubmit="submitMathML('preview', 'asciiMathML')">
      ASCIIMath Input:
      <input id="asciiMathInput" name="asciiMathInput" type="text" value="{$ascii-math-input}"
        onkeyup="updatePreview()" />
      <input type="hidden" id="asciiMathML" name="asciiMathML" />
      <input type="submit" value="Go!" />
    </form>
    <div class="result">
      Live Preview: <div id="preview"><xsl:text> </xsl:text></div>
    </div>

    <xsl:if test="not($is-new-form)">
      <xsl:apply-templates select="." mode="handle-successful-input"/>
    </xsl:if>
  </xsl:template>

  <!--
  This template shows the details when the input has been
  successfully passed through SnuggleTeX, though with the
  possibility that up-conversion has not been entirely successful.
  -->
  <xsl:template match="body" mode="handle-successful-input">
    <h3>Raw ASCIIMathML Output</h3>
    <pre class="result">
      <xsl:value-of select="$ascii-math-output"/>
    </pre>

    <h3>Enhanced Presentation MathML</h3>
    <pre class="result">
      <xsl:value-of select="$pmathml-upconverted"/>
    </pre>

    <h3>Content MathML</h3>
    <xsl:variable name="content-failures" as="element(s:fail)*" select="$parallel-mathml-element/m:semantics/m:annotation-xml[@encoding='MathML-Content-upconversion-failures']/*"/>
    <xsl:choose>
      <xsl:when test="exists($content-failures)">
        <p>
          The conversion from Presentation MathML to Content MathML was not successful
          for this input.
        </p>
        <xsl:call-template name="format-upconversion-failures">
          <xsl:with-param name="failures" select="$content-failures"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <pre class="result">
          <xsl:value-of select="$cmathml"/>
        </pre>
      </xsl:otherwise>
    </xsl:choose>

    <h3>Maxima Input Form</h3>
    <xsl:variable name="maxima-failures" as="element(s:fail)*" select="$parallel-mathml-element/m:semantics/m:annotation-xml[@encoding='Maxima-upconversion-failures']/*"/>
    <xsl:choose>
      <xsl:when test="exists($content-failures)">
        <p>
          Conversion to Maxima Input is reliant on the conversion to Content MathML
          being successful, which was not the case here.
        </p>
      </xsl:when>
      <xsl:when test="exists($maxima-failures)">
        <p>
          The conversion from Content MathML to Maxima Input was not successful for
          this input.
        </p>
        <xsl:call-template name="format-upconversion-failures">
          <xsl:with-param name="failures" select="$maxima-failures"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <pre class="result">
          <xsl:value-of select="$maxima-input"/>
        </pre>
      </xsl:otherwise>
    </xsl:choose>

    <h3>Fully annotated MathML Element</h3>
    <pre class="result">
      <xsl:value-of select="$parallel-mathml"/>
    </pre>
  </xsl:template>

  <xsl:template name="format-upconversion-failures">
    <xsl:param name="failures" as="element(s:fail)+"/>
    <table class="failures">
      <thead>
        <tr>
          <th>Failure Code</th>
          <th>Message</th>
          <th>Context</th>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="$failures">
          <tr>
            <td>
              <xsl:call-template name="make-error-code-link">
                <xsl:with-param name="error-code" select="@code"/>
              </xsl:call-template>
            </td>
            <td><xsl:value-of select="@message"/></td>
            <td>
              <pre>
                <!--
                We'll strip off the enclosing <s:fail/>, which also conveniently
                removes namespace declarations.
                -->
                <xsl:value-of select="replace(
                  replace(
                    replace(mu:serializeElement(s:context), '^&lt;s:context.+?&gt; ?[\n\r]+', '', 's'),
                    '[\n\r]+ ?&lt;/s:context&gt;$', '', 's'),
                    '^   ', '', 'm') (: de-indent 1 level :)
                  "/>
              </pre>
            </td>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template name="make-error-code-link">
    <xsl:param name="error-code" as="xs:string"/>
    <a href="{$context-path}/documentation/error-codes.html#{$error-code}">
      <xsl:value-of select="$error-code"/>
    </a>
  </xsl:template>

</xsl:stylesheet>