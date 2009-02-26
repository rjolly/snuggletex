<!--

$Id$

This stylesheet enhances a raw Presentation MathML <math/> element
generated by SnuggleTeX, attempting to infer semantics within basic
mathematical expressions.

This is the first step in any attempts to up-convert to Content MathML
or Maxima input.

See the local:process-group template to see how groupings/precedence
are established.

TODO: Think about plus-or-minus operator??
TODO: Other infix operators from set theory such as \in and stuff like that?
TODO: Should we specify precedence for other infix operators? (Later... nothing to do with MathAssess... actually maybe not!)
TODO: <mstyle/> is essentially being treated as neutering its contents... is this a good idea? It's a hard problem to solve in general.

Copyright (c) 2009 The University of Edinburgh
All Rights Reserved

-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://www.ph.ed.ac.uk/snuggletex"
  xmlns:sho="http://www.ph.ed.ac.uk/snuggletex/higher-order"
  xmlns:local="http://www.ph.ed.ac.uk/snuggletex/pmathml-enhancer"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  xmlns="http://www.w3.org/1998/Math/MathML"
  exclude-result-prefixes="xs m s sho local"
  xpath-default-namespace="http://www.w3.org/1998/Math/MathML">

  <xsl:strip-space elements="m:*"/>

  <!-- ************************************************************ -->

  <!-- Entry point -->
  <xsl:template name="s:enhance-pmathml">
    <xsl:param name="elements" as="element()*"/>
    <xsl:call-template name="local:process-group">
      <xsl:with-param name="elements" select="$elements"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ************************************************************ -->

  <xsl:variable name="local:invertible-elementary-functions" as="xs:string+"
    select="('sin', 'cos', 'tan',
             'sec', 'csc' ,'cot',
             'sinh', 'cosh', 'tanh',
             'sech', 'csch', 'coth')"/>

  <xsl:variable name="local:elementary-functions" as="xs:string+"
    select="($local:invertible-elementary-functions,
            'arcsin', 'arccos', 'arctan',
            'arcsec', 'arccsc', 'arccot',
            'arcsinh', 'arccosh', 'arctanh',
            'arcsech', 'arccsch', 'arccoth',
            'ln', 'log', 'exp')"/>

  <xsl:variable name="local:explicit-multiplication-characters" as="xs:string+"
    select="('*', '&#xd7;', '&#x22c5;')"/>

  <xsl:variable name="local:explicit-division-characters" as="xs:string+"
    select="('/', '&#xf7;')"/>

  <xsl:variable name="local:prefix-operators" as="xs:string+"
    select="('&#xac;')"/>

  <!-- NOTE: Currently, the only postfix operator is factorial, which is handled in a special way.
       But I'll keep this more general logic for the time being as it gives nicer symmetry with prefix
       operators. -->
  <xsl:variable name="local:postfix-operators" as="xs:string+"
    select="('!')"/>

  <xsl:function name="local:is-operator" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean($element[self::mo])"/>
  </xsl:function>

  <xsl:function name="local:is-infix-operator" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:variable name="previous" as="element()?" select="$element/preceding-sibling::*[1]"/>
    <xsl:sequence select="local:is-operator($element) and exists($previous) and not(local:is-operator($previous))"/>
  </xsl:function>

  <xsl:function name="local:is-plus-operator" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean($element[self::mo and .='+'])"/>
  </xsl:function>

  <xsl:function name="local:is-minus-operator" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean($element[self::mo and .='-'])"/>
  </xsl:function>

  <xsl:function name="local:is-factorial-operator" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean($element[self::mo and .='!'])"/>
  </xsl:function>

  <xsl:function name="local:is-elementary-function" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean($element[self::mi and $local:elementary-functions=string(.)])"/>
  </xsl:function>

  <!-- Tests for the equivalent of \sin, \sin^{.} or \log_a. Result need not make any actual sense! -->
  <xsl:function name="local:is-supported-function" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="local:is-elementary-function($element)
      or $element[self::msup and local:is-elementary-function(*[1])]
      or $element[self::msub and *[1][self::mi and .='log']]"/>
  </xsl:function>

  <xsl:function name="local:is-prefix-operator" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean($element[self::mo and $local:prefix-operators=string(.)])"/>
  </xsl:function>

  <xsl:function name="local:is-prefix-or-function" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean(local:is-supported-function($element) or local:is-prefix-operator($element))"/>
  </xsl:function>

  <xsl:function name="local:is-postfix-operator" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:sequence select="boolean($element[self::mo and $local:postfix-operators=string(.)])"/>
  </xsl:function>

  <!--
  We'll say that an element starts a "no-infix group" if:

  1. It is either the first in a sequence of siblings
  OR 2. It is a prefix operator or function and doesn't immediately follow a prefix operator or function
  OR 3. It is neither a prefix operator/function nor postfix operator and follows a postfix operator

  Such an element will thus consist of:

  prefix-operator-or-function* implicit-multiplication* postfix-opeator*

  -->
  <xsl:function name="local:is-no-infix-group-starter" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:variable name="previous" as="element()?" select="$element/preceding-sibling::*[1]"/>
    <xsl:sequence select="boolean(
      not(exists($previous))
      or (local:is-prefix-or-function($element) and not(local:is-prefix-or-function($previous)))
      or (not(local:is-prefix-or-function($element)) and not(local:is-postfix-operator($element))
        and local:is-postfix-operator($previous)))"/>
  </xsl:function>

  <!-- ************************************************************ -->
  <!-- Grouping by implied precedence -->

  <xsl:template name="local:process-group">
    <xsl:param name="elements" as="element()*" required="yes"/>
    <xsl:choose>
      <xsl:when test="$elements[local:is-matching-infix-mo(., ('='))]">
        <!-- Equals -->
        <xsl:call-template name="local:group-associative-infix-mo">
          <xsl:with-param name="elements" select="$elements"/>
          <xsl:with-param name="match" select="('=')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$elements[local:is-matching-infix-mo(., ('+'))]">
        <!-- Infix Addition -->
        <xsl:call-template name="local:group-associative-infix-mo">
          <xsl:with-param name="elements" select="$elements"/>
          <xsl:with-param name="match" select="('+')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$elements[local:is-matching-infix-mo(., ('-'))]">
        <!-- Infix Subtraction -->
        <xsl:call-template name="local:group-left-associative-infix-mo">
          <xsl:with-param name="elements" select="$elements"/>
          <xsl:with-param name="match" select="('-')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$elements[1][local:is-operator(.) and .=('+', '-')]">
        <!-- Special case of '+' or '-' Operator used in prefix mode -->
        <xsl:call-template name="local:apply-prefix-operator">
          <xsl:with-param name="elements" select="$elements"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$elements[local:is-matching-infix-mo(., $local:explicit-multiplication-characters)]">
        <!-- Explicit Multiplication, detected in various ways -->
        <xsl:call-template name="local:group-associative-infix-mo">
          <xsl:with-param name="elements" select="$elements"/>
          <xsl:with-param name="match" select="$local:explicit-multiplication-characters"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$elements[local:is-matching-infix-mo(., $local:explicit-division-characters)]">
        <!-- Explicit Division -->
        <xsl:call-template name="local:group-left-associative-infix-mo">
          <xsl:with-param name="elements" select="$elements"/>
          <xsl:with-param name="match" select="$local:explicit-division-characters"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$elements[self::mspace]">
        <!-- Any <mspace/> is kept but interpreted as an implicit multiplication as well -->
        <xsl:call-template name="local:handle-mspace-group">
          <xsl:with-param name="elements" select="$elements"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="count($elements) &gt; 1">
        <!-- Need to infer function applications and multiplications, leave other operators as-is -->
        <xsl:call-template name="local:handle-no-infix-group">
          <xsl:with-param name="elements" select="$elements"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="count($elements)=1">
        <!-- "Atom" -->
        <xsl:apply-templates select="$elements[1]" mode="enhance-pmathml"/>
      </xsl:when>
      <xsl:when test="empty($elements)">
        <!-- Empty -> empty -->
      </xsl:when>
      <xsl:otherwise>
        <!-- Based on the logic above, this can't actually happen! -->
        <xsl:message terminate="yes">
          Unexpected logic branch in local:process-group template
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Tests whether the given element is a <mo/> applied infix -->
  <xsl:function name="local:is-matching-infix-mo" as="xs:boolean">
    <xsl:param name="element" as="element()"/>
    <xsl:param name="match" as="xs:string+"/>
    <xsl:sequence select="boolean(local:is-infix-operator($element) and $element=$match)"/>
  </xsl:function>

  <!-- Groups an associative infix <mo/> operator -->
  <xsl:template name="local:group-associative-infix-mo">
    <xsl:param name="elements" as="element()+" required="yes"/>
    <xsl:param name="match" as="xs:string+" required="yes"/>
    <xsl:for-each-group select="$elements" group-adjacent="local:is-matching-infix-mo(., $match)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <!-- Copy the matching operator -->
          <xsl:copy-of select="."/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="s:maybe-wrap-in-mrow">
            <xsl:with-param name="elements" as="element()*">
              <xsl:call-template name="local:process-group">
                <xsl:with-param name="elements" select="current-group()"/>
              </xsl:call-template>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <!-- Groups a left- but not right-associative infix <mo/> operator -->
  <xsl:template name="local:group-left-associative-infix-mo">
    <xsl:param name="elements" as="element()+" required="yes"/>
    <xsl:param name="match" as="xs:string+" required="yes"/>
    <xsl:variable name="operators" select="$elements[local:is-matching-infix-mo(., $match)]" as="element()+"/>
    <xsl:variable name="operator-count" select="count($operators)" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$operator-count != 1">
        <!-- Something like 'a o b o c'. We handle this recursively as '(a o b) o c' -->
        <xsl:variable name="last-operator" select="$operators[position()=last()]" as="element()"/>
        <xsl:variable name="before-last-operator" select="$elements[. &lt;&lt; $last-operator]" as="element()+"/>
        <xsl:variable name="after-last-operator" select="$elements[. &gt;&gt; $last-operator]" as="element()*"/>
        <mrow>
          <xsl:call-template name="local:group-left-associative-infix-mo">
            <xsl:with-param name="elements" select="$before-last-operator"/>
            <xsl:with-param name="match" select="$match"/>
          </xsl:call-template>
        </mrow>
        <xsl:copy-of select="$last-operator"/>
        <xsl:call-template name="local:process-group">
          <xsl:with-param name="elements" select="$after-last-operator"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- Only one operator, so it'll be 'a o b' (or more pathologically 'a o').
             We will allow the pathological cases here. -->
        <xsl:variable name="operator" select="$operators[1]" as="element()"/>
        <xsl:variable name="left-operand" select="$elements[. &lt;&lt; $operator]" as="element()+"/>
        <xsl:variable name="right-operand" select="$elements[. &gt;&gt; $operator]" as="element()*"/>
        <xsl:call-template name="local:process-group">
          <xsl:with-param name="elements" select="$left-operand"/>
        </xsl:call-template>
        <xsl:copy-of select="$operator"/>
        <xsl:call-template name="local:process-group">
          <xsl:with-param name="elements" select="$right-operand"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Groups a Prefix operator -->
  <xsl:template name="local:apply-prefix-operator">
    <xsl:param name="elements" as="element()+" required="yes"/>
    <mrow>
      <xsl:copy-of select="$elements[1]"/>
      <xsl:call-template name="s:maybe-wrap-in-mrow">
        <xsl:with-param name="elements" as="element()*">
          <xsl:call-template name="local:process-group">
            <xsl:with-param name="elements" select="$elements[position()!=1]"/>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
    </mrow>
  </xsl:template>

  <!-- <mspace/> as explicit multiplication -->
  <xsl:template name="local:handle-mspace-group">
    <xsl:param name="elements" as="element()+" required="yes"/>
    <xsl:for-each-group select="$elements" group-adjacent="boolean(self::mspace)">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:copy-of select="."/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="position()!=1">
            <!-- Add in InvisibleTimes -->
            <mo>&#x2062;</mo>
          </xsl:if>
          <!-- Then process as normal -->
          <xsl:call-template name="s:maybe-wrap-in-mrow">
            <xsl:with-param name="elements" as="element()*">
              <xsl:call-template name="local:process-group">
                <xsl:with-param name="elements" select="current-group()"/>
              </xsl:call-template>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template name="local:handle-no-infix-group">
    <xsl:param name="elements" as="element()+" required="yes"/>
    <xsl:for-each-group select="$elements" group-starting-with="*[local:is-no-infix-group-starter(.)]">
      <!-- Add an invisible times if we're the second multiplicative group -->
      <xsl:if test="position()!=1">
        <mo>&#x2062;</mo>
      </xsl:if>
      <!-- Apply prefix operators and functions from start of group -->
      <xsl:call-template name="s:maybe-wrap-in-mrow">
        <xsl:with-param name="elements" as="element()*">
          <xsl:call-template name="local:apply-prefix-functions-and-operators">
            <xsl:with-param name="elements" select="current-group()"/>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template name="local:apply-prefix-functions-and-operators">
    <xsl:param name="elements" as="element()+" required="yes"/>
    <xsl:variable name="first-element" as="element()" select="$elements[1]"/>
    <xsl:variable name="after-first-element" as="element()*" select="$elements[position()!=1]"/>
    <xsl:choose>
      <xsl:when test="local:is-supported-function($first-element) and exists($after-first-element)">
        <!-- This is a (prefix) function application. Copy the operator as-is -->
        <xsl:copy-of select="$first-element"/>
        <!-- Add an "Apply Function" operator -->
        <mo>&#x2061;</mo>
        <!-- Process the rest recursively -->
        <xsl:call-template name="local:apply-prefix-functions-and-operators">
          <xsl:with-param name="elements" select="$after-first-element"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="local:is-prefix-operator($first-element)">
        <!-- This is a prefix operator. Apply to everything that follows. -->
        <xsl:copy-of select="$first-element"/>
        <xsl:call-template name="local:apply-prefix-functions-and-operators">
          <xsl:with-param name="elements" select="$after-first-element"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- This is everything after any prefixes but before any postfixes -->
        <xsl:call-template name="s:maybe-wrap-in-mrow">
          <xsl:with-param name="elements" as="element()*">
            <xsl:call-template name="local:apply-postfix-operators">
              <xsl:with-param name="elements" select="$elements"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="local:apply-postfix-operators">
    <xsl:param name="elements" as="element()*" required="yes"/>
    <xsl:variable name="last-element" as="element()?" select="$elements[position()=last()]"/>
    <xsl:variable name="before-last-element" as="element()*" select="$elements[position()!=last()]"/>
    <xsl:choose>
      <xsl:when test="$last-element[local:is-factorial-operator(.)]">
        <!-- The factorial operator only binds to the last resulting subexpression -->
        <xsl:call-template name="local:apply-factorial">
          <xsl:with-param name="elements" as="element()*">
            <xsl:call-template name="local:apply-postfix-operators">
              <xsl:with-param name="elements" select="$before-last-element"/>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$last-element[local:is-postfix-operator(.)]">
        <!-- General Postfix operator. Bind to everything preceding -->
        <xsl:call-template name="local:apply-postfix-operators">
          <xsl:with-param name="elements" select="$before-last-element"/>
        </xsl:call-template>
        <xsl:copy-of select="$last-element"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- We're in the "middle" of the expression, which we assume is implicit multiplication -->
        <xsl:call-template name="local:handle-implicit-multiplicative-group">
          <xsl:with-param name="elements" select="$elements"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="local:apply-factorial">
    <xsl:param name="elements" as="element()*" required="yes"/>
    <xsl:variable name="last-element" as="element()?" select="$elements[position()=last()]"/>
    <xsl:variable name="before-last-element" as="element()*" select="$elements[position()!=last()]"/>
    <xsl:copy-of select="$before-last-element"/>
    <xsl:choose>
      <xsl:when test="$last-element[self::mrow]">
        <mrow>
          <xsl:copy-of select="$last-element/*[position()!=last()]"/>
          <mrow>
            <xsl:copy-of select="$last-element/*[position()=last()]"/>
            <mo>!</mo>
          </mrow>
        </mrow>
      </xsl:when>
      <xsl:when test="exists($last-element)">
        <mrow>
          <xsl:copy-of select="$last-element"/>
          <mo>!</mo>
        </mrow>
      </xsl:when>
      <xsl:otherwise>
        <mo>!</mo>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="local:handle-implicit-multiplicative-group">
    <xsl:param name="elements" as="element()*" required="yes"/>
    <xsl:call-template name="s:maybe-wrap-in-mrow">
      <xsl:with-param name="elements" as="element()*">
        <xsl:for-each select="$elements">
          <xsl:if test="position()!=1">
            <!-- Add an "Invisible Times" -->
            <mo>&#x2062;</mo>
          </xsl:if>
          <!-- Descend into the element itself -->
          <xsl:apply-templates select="." mode="enhance-pmathml"/>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- ************************************************************ -->
  <!-- Templates for explicit MathML elements -->

  <!-- Container elements with unrestricted content -->
  <xsl:template match="mrow|msqrt" mode="enhance-pmathml">
    <!-- Process contents as normal -->
    <xsl:variable name="processed-contents" as="element()*">
      <xsl:call-template name="local:process-group">
        <xsl:with-param name="elements" select="*"/>
      </xsl:call-template>
    </xsl:variable>
    <!-- If contents consists of a single <mrow/>, strip it off and descend down -->
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:choose>
        <xsl:when test="count($processed-contents)=1 and $processed-contents[1][self::mrow]">
          <xsl:copy-of select="$processed-contents/*"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$processed-contents"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <!-- Default template for other MathML elements -->
  <xsl:template match="*" mode="enhance-pmathml">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="enhance-pmathml"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="text()" mode="enhance-pmathml">
    <xsl:copy-of select="."/>
  </xsl:template>


  <!-- ************************************************************ -->

  <xsl:template name="s:maybe-wrap-in-mrow">
    <xsl:param name="elements" as="element()*" required="yes"/>
    <xsl:choose>
      <xsl:when test="count($elements)=1">
        <xsl:copy-of select="$elements"/>
      </xsl:when>
      <xsl:otherwise>
        <mrow>
          <xsl:copy-of select="$elements"/>
        </mrow>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

