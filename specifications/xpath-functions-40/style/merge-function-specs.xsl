<?xml version='1.0'?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fos="http://www.w3.org/xpath-functions/spec/namespace"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="fos xs">

	<xsl:output method="xml" doctype-system="../../../schema/xsl-query.dtd"/>

	<!-- This stylesheet expects to take xpath-functions.xml as its principal input,
     and to write xpath-functions-expanded.xml as its output. It takes a secondary
     input from function-catalog.xml -->

	<!-- It is also used to expand the function definitions in the XSLT specification,
		using a different function catalog -->

	<xsl:param name="function-catalog" select="'function-catalog.xml'"/>
	<xsl:variable name="fosdoc" select="document($function-catalog, /)"/>

	<xsl:variable name="isFO" select="contains(/spec/header/title, 'Functions and Operators')"
		as="xs:boolean"/>

        <xsl:key name="id" match="*" use="@id"/>
        <xsl:variable name="new-functions"
                      select="key('id', 'new-functions')//code/string()"/>
        <xsl:variable name="changed-functions"
                      select="key('id', 'changes-to-existing-functions')//code/string()"/>

	<xsl:template match="/">
		<xsl:for-each select="1 to 20">
			<xsl:comment>DO NOT EDIT: GENERATED BY merge-function-specs.xsl</xsl:comment>
			<xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="*" mode="#default summary">
		<xsl:copy copy-namespaces="no">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates mode="#current"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="processing-instruction('doc')">
		<pre class="small">
      <xsl:variable name="doc" select="unparsed-text(resolve-uri(concat('../src/', string(.)), base-uri(/)), 'iso-8859-1')"/>
      <xsl:value-of select="translate($doc, '&#xD;', '')"/>
    </pre>
	</xsl:template>

	<xsl:template match="processing-instruction()">
		<xsl:copy/>
	</xsl:template>

	<xsl:function name="fos:get-function" as="element(fos:function)?">
		<xsl:param name="prefix" as="xs:string"/>
		<xsl:param name="local" as="xs:string"/>
		<xsl:variable name="fspec" select="
				$fosdoc/fos:functions/fos:function
				[@name = $local][(@prefix, 'fn')[1] = $prefix]"/>
		<xsl:if test="empty($fspec)">
			<xsl:message>Function not found in catalog: <xsl:value-of select="$prefix, $local"
					separator=":"/></xsl:message>
		</xsl:if>
		<xsl:if test="exists($fspec[2])">
			<xsl:message>Duplicate function found in catalog: <xsl:value-of select="$prefix, $local"
					separator=":"/></xsl:message>
		</xsl:if>
		<xsl:sequence select="$fspec"/>
	</xsl:function>

	<xsl:template match="head[processing-instruction('function')]">
		<xsl:variable name="lexname" select="processing-instruction('function')/normalize-space(.)"/>
		<xsl:variable name="fspec"
			select="fos:get-function(substring-before($lexname, ':'), substring-after($lexname, ':'))"/>

                <xsl:variable name="fqfn" select="$fspec/@prefix || ':' || $fspec/@name"/>

                <!-- on the current div -->
                <xsl:if test="$fqfn = $new-functions
                              or $fspec//ednote[contains(., 'New in 4.0')]">
                  <xsl:attribute name="role" select="'new-function'"/>
                </xsl:if>

                <xsl:if test="$fqfn = $changed-functions
                              or $fspec//ednote[contains(., 'Changed in 4.0')]">
                  <xsl:attribute name="role" select="'changed-function'"/>
                </xsl:if>

		<head>
			<xsl:value-of select="$lexname"/>
		</head>
		<glist>
			<gitem>
				<label>Summary</label>
				<def>
					<xsl:copy-of select="$fspec/fos:summary/(@diff, @at)"/>
					<xsl:apply-templates select="$fspec/fos:summary/node()" mode="summary"/>
				</def>
			</gitem>
			<xsl:if test="$fspec/fos:opermap">
				<gitem>
					<label>Operator Mapping</label>
					<def>
						<p>
							<xsl:copy-of select="$fspec/fos:opermap/(@diff, @at)"/>
							<xsl:copy-of select="$fspec/fos:opermap/node()" copy-namespaces="no"/>
						</p>
					</def>
				</gitem>
			</xsl:if>
			<gitem>
				<label>Signature<xsl:value-of select="'s'[$fspec/fos:signatures/fos:proto[2]]"/></label>
				<def>
					<xsl:copy-of select="$fspec/fos:signatures/(@diff, @at)"/>
					<xsl:apply-templates select="$fspec/fos:signatures/fos:proto"/>
					<xsl:apply-templates select="$fspec/fos:signatures/fos:record"/>
				</def>
			</gitem>
			<xsl:if test="$fspec/fos:properties">
				<gitem>
					<label>Properties</label>
					<def>
						<xsl:copy-of select="$fspec/fos:properties/(@diff, @at)"/>
						<xsl:for-each select="$fspec/fos:properties">
							<p>
								<xsl:choose>
									<xsl:when test="last() = 1">
										<xsl:text>This function is </xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>The </xsl:text>
										<xsl:number value="@arity" format="w"/>
										<xsl:text>-argument form of this function is </xsl:text>
									</xsl:otherwise>
								</xsl:choose>
								<xsl:for-each select="fos:property[not(. = 'special-streaming-rules')]">
									<xsl:call-template name="make-property-termref"/>
									<xsl:if test="position() != last()">, </xsl:if>
									<xsl:if test="position() = last() - 1"> and </xsl:if>
								</xsl:for-each>
								<xsl:text>. </xsl:text>
								<xsl:apply-templates select="fos:property/@dependency"/>
							</p>
						</xsl:for-each>
					</def>
				</gitem>
			</xsl:if>
			<gitem>
				<label>Rules</label>
				<def>
					<xsl:copy-of select="$fspec/fos:rules/(@diff, @at)"/>
					<xsl:apply-templates select="$fspec/fos:rules/node()"/>
				</def>
			</gitem>
			<xsl:if test="$fspec/fos:errors">
				<gitem>
					<label>Error Conditions</label>
					<def>
						<xsl:copy-of select="$fspec/fos:errors/(@diff, @at)"/>
						<xsl:copy-of select="$fspec/fos:errors/node()" copy-namespaces="no"/>
					</def>
				</gitem>
			</xsl:if>
			<xsl:if test="$fspec/fos:notes">
				<gitem>
					<label>Notes</label>
					<def>
						<xsl:copy-of select="$fspec/fos:notes/(@diff, @at)"/>
						<xsl:apply-templates select="$fspec/fos:notes/node()" mode="make-note"/>
					</def>
				</gitem>
			</xsl:if>

  <xsl:if test="$fspec/fos:examples">
    <gitem>
      <label>Examples</label>
      <def role="example">
	<xsl:copy-of select="$fspec/fos:examples/(@diff, @at)"/>
   <xsl:if test="$fspec//fos:variable">
   	<table role="medium">
   		<thead><tr><th>Variables</th></tr></thead>
   		<tbody>
   			<xsl:apply-templates select="$fspec/fos:examples/fos:variable"/>
   		</tbody>
   	</table>
   </xsl:if>
	<table role="medium">
	  <xsl:if test="fos:use-two-column-format($fspec/fos:examples)">
	    <thead>
	      <tr>
		<th>Expression</th>
		<th>Result</th>
	      </tr>
	    </thead>
	  </xsl:if>
	  <tbody>
	    <xsl:apply-templates select="$fspec/fos:examples/node()[not(self::fos:variable)]"/>
	  </tbody>
	</table>						
      </def>
    </gitem>
  </xsl:if>
			<xsl:if test="$fspec/fos:history">
				<gitem>
					<label>History</label>
					<def role="example">
						<p>
							<xsl:apply-templates select="$fspec/fos:history/fos:version/node()"/>
						</p>
					</def>
				</gitem>
			</xsl:if>
		</glist>
	</xsl:template>
	
	<xsl:function name="fos:use-two-column-format" as="xs:boolean">
		<xsl:param name="examples" as="element(fos:examples)"/>
		<xsl:sequence select="not(contains-token($examples/@role, 'wide'))
			and $examples//fos:result
			and not(max($examples//eg!tokenize(., '\n')!string-length(.)) gt 30)"/>			
	</xsl:function>

	<xsl:template match="*" mode="make-note">
		<xsl:copy copy-namespaces="no">
			<xsl:attribute name="role" select="'note'"/>
			<xsl:copy-of select="node()" copy-namespaces="no"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template name="make-property-termref">
		<xsl:choose>
			<xsl:when test="$isFO">
				<!-- Functions and Operators spec -->
				<termref def="dt-{.}">
					<xsl:value-of select="."/>
				</termref>
			</xsl:when>
			<xsl:otherwise>
				<!-- Typically the XSLT spec -->
				<xtermref spec="FO30" ref="dt-{.}">
					<xsl:value-of select="."/>
				</xtermref>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<xsl:template match="@dependency"> It depends on 
		<xsl:value-of
			select="replace(translate(string-join(tokenize(., '\s+'), ', and '), '-', ' '), 'uri', 'URI')"
		/>.
	</xsl:template>

	<xsl:template match="fos:proto">
		<xsl:variable name="isOp" as="xs:boolean" select="exists(../../fos:opermap)"/>
		<example role="signature">
			<xsl:variable name="prefix" select="../../@prefix"/>
			<proto isOp="{if ($isOp) then 'yes' else 'no'}" prefix="{if ($prefix)
                                        then $prefix
                                        else if ($isOp)
                                             then 'op'
                                             else 'fn'}">
				<xsl:copy-of select="@name, @return-type, @return-type-ref, @return-type-ref-occurs, @diff, @at"/>
				<xsl:apply-templates/>
			</proto>
		</example>
	</xsl:template>

	<xsl:template match="fos:arg">
		<arg>
			<xsl:copy-of select="@name, @type, @type-ref, @type-ref-occurs, @diff, @at, @default"/>
			<xsl:if test="not(following-sibling::fos:arg) and ancestor::fos:function//fos:property = 'variadic'">
				<xsl:attribute name="type" select="@type || ' ...'"/>
			</xsl:if>
		</arg>
	</xsl:template>

	<!--<xsl:template match="fos:arg[@type='record']">
		<!-\- Capture the details of the record into a JSON structure which we squeeze into the @type attribute -\->
		<arg name="{@name}" role="record">
			<xsl:attribute name="type">
				<xsl:variable name="fields" as="map(*)*">
					<xsl:for-each select="fos:record/fos:field">
						<xsl:sequence select="map{'name':string(@name), 'type':string(@type), 'required':xs:boolean(@required)}"/>
					</xsl:for-each>
					<xsl:sequence select="map{'extensible':xs:boolean(fos:record/@extensible)}"/>
				</xsl:variable>
				<xsl:value-of select="serialize(array{$fields}, map{'method':'json'})"/>
			</xsl:attribute>
			<xsl:copy-of select="@diff, @at, @default"/>
		</arg>
	</xsl:template>-->

	<xsl:template match="fos:record">
		<example role="record" id="{../@id}">
			<record>
				<xsl:copy-of select="@* except @extensible"/>
				<xsl:apply-templates/>
            <xsl:if test="xs:boolean(@extensible)"><arg name="*"/></xsl:if>
			</record>
		</example>
	</xsl:template>

	<xsl:template match="fos:field">
		<arg occur="{if (xs:boolean(@required)) then 'req' else 'opt'}">
			<xsl:copy-of select="@name, @type, @type-ref, @diff, @at"/>
		</arg>
	</xsl:template>

	<xsl:template match="fos:example">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="fos:variable" priority="5">
		<tr>
			<td colspan="2">
				<eg>
					<xsl:copy-of select="@diff, @at"/>
					<xsl:value-of select="concat('let $', @name, ' := ')"/>
					<xsl:if test="@select">
						<xsl:value-of select="@select"/>
					</xsl:if>
					<xsl:if test="child::node()">
						<xsl:apply-templates/>
					</xsl:if>
				</eg>
			</td>
		</tr>
	</xsl:template>
	
	<xsl:template match="fos:example/*" priority="4">
	  <tr>
	    <xsl:copy-of select="@diff, @at"/>
	    <td colspan="2">
	      <xsl:copy-of select="." copy-namespaces="no"/>
	    </td>
	  </tr>
	</xsl:template>

	<xsl:template match="fos:test[not(ancestor::fos:examples[fos:use-two-column-format(.)])]" priority="6">
	  <tr class="testdiv">
	    <xsl:copy-of select="@diff, @at"/>
            <th valign="top">Expression:</th>
	    <td valign="top">
	      <xsl:if test="fos:preamble">
		<p><xsl:copy-of select="fos:preamble/node()" copy-namespaces="no"/></p>
	      </xsl:if>
	      <xsl:choose>
		<xsl:when test="fos:expression/@xml:space = 'preserve'">
	          <p>
		    <code><xsl:value-of select="translate(fos:expression, ' ', '&#xa0;')"/></code>
                  </p>
		</xsl:when>
		<xsl:when test="fos:expression/eg">
		  <xsl:apply-templates select="fos:expression/node()"/>
		</xsl:when>
		<xsl:otherwise>
	          <p>
		    <code><xsl:value-of select="fos:expression"/></code>
                  </p>
		</xsl:otherwise>
	      </xsl:choose>
	    </td>
          </tr>
	  <tr>
	    <xsl:copy-of select="@diff, @at"/>
            <th valign="top">Result:</th>
	    <td valign="top">
	      <xsl:if test="fos:result[2]"><p>One of the following:</p></xsl:if>
	      <xsl:apply-templates select="fos:result|fos:error-result"/>
	      <xsl:if test="fos:result[@normalize-space = 'true']">
		<p>(with whitespace added for legibility)</p>
	      </xsl:if>
	      <xsl:if test="fos:result[@allow-permutation = 'true']">
		<p>(or some permutation thereof)</p>
	      </xsl:if>
	      <xsl:if test="fos:result[@approx = 'true']">
		<p>(approximately)</p>
	      </xsl:if>
	      <xsl:if test="fos:postamble">
		<p><emph>
		  <xsl:text>(</xsl:text>
		  <xsl:copy-of select="fos:postamble/node()" copy-namespaces="no"/>
		  <xsl:text>)</xsl:text>
		  <xsl:if test="not(ends-with(fos:postamble, '.'))">.</xsl:if>
		</emph></p>
	      </xsl:if>
	    </td>
	  </tr>
        </xsl:template>

	<xsl:template match="fos:test" priority="5">
	  <tr>
	    <xsl:copy-of select="@diff, @at"/>
	    <td valign="top">
	      <xsl:if test="fos:preamble">
		<p><xsl:copy-of select="fos:preamble/node()" copy-namespaces="no"/></p>
	      </xsl:if>
	      <xsl:choose>
		<xsl:when test="fos:expression/@xml:space = 'preserve'">
                  <p>
		    <code><xsl:value-of select="translate(fos:expression, ' ', '&#xa0;')"/></code>
                  </p>
		</xsl:when>
		<xsl:when test="fos:expression/eg">
		  <xsl:apply-templates select="fos:expression/node()"/>
		</xsl:when>
		<xsl:otherwise>
                  <eg>
		    <code><xsl:value-of select="fos:expression"/></code>
                  </eg>
		</xsl:otherwise>
	      </xsl:choose>
	    </td>
	    <td valign="top">
	      <xsl:if test="fos:result[2]"><p>One of the following:</p></xsl:if>
	      <xsl:apply-templates select="fos:result|fos:error-result"/>
	      <xsl:if test="fos:result[@normalize-space = 'true']">
		<p>(with whitespace added for legibility)</p>
	      </xsl:if>
	      <xsl:if test="fos:result[@allow-permutation = 'true']">
		<p>(or some permutation thereof)</p>
	      </xsl:if>
	      <xsl:if test="fos:result[@approx = 'true']">
		<p>(approximately)</p>
	      </xsl:if>
	      <xsl:if test="fos:postamble">
		<p><emph>
		  <xsl:text>(</xsl:text>
		  <xsl:copy-of select="fos:postamble/node()" copy-namespaces="no"/>
		  <xsl:text>)</xsl:text>
		  <xsl:if test="not(ends-with(fos:postamble, '.'))">.</xsl:if>
		</emph></p>
	      </xsl:if>
	    </td>
	  </tr>
	</xsl:template>
	
	<xsl:template match="fos:result">
		<xsl:choose>
			<xsl:when test="contains(., codepoints-to-string(10)) || ..//eg">
				<eg><xsl:value-of select="."/></eg>
			</xsl:when>
			<xsl:otherwise>
				<p><code><xsl:value-of select="."/></code></p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="fos:error-result">
		<p>Raises error <xsl:value-of select="@error-code"/>.</p>
	</xsl:template>

	<xsl:template match="text()" mode="summary">
		<xsl:value-of select="replace(., 'Summary: ', '')"/>
	</xsl:template>

	<xsl:template match="processing-instruction('local-function-index')">
		<table class="index">
			<thead>
				<tr>
					<th>Function</th>
					<th>Meaning</th>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each
					select="following-sibling::*[starts-with(local-name(), 'div')][head/processing-instruction()]">
					<xsl:variable name="lexname" select="string(head/processing-instruction())"/>
					<xsl:variable name="fspec"
						select="fos:get-function(substring-before($lexname, ':'), substring-after($lexname, ':'))"/>
					<tr>
						<td style="white-space:nowrap; vertical-align:top">
							<code style="padding-right: 10px">
								<xsl:value-of select="$lexname"/>
							</code>
						</td>
						<td>
							<xsl:apply-templates select="$fspec/fos:summary/*/node()" mode="summary"/>
						</td>
					</tr>
				</xsl:for-each>
			</tbody>
		</table>
	</xsl:template>

	<!-- remove dummy termdefs used in XSLT to ensure no dangling references -->
	<xsl:template match="p[termdef[@role = 'placemarker']]"/>

	<!-- Handle option parameter specifications -->

	<xsl:template match="fos:options">

	  <example role="record">
	    <record>
              <xsl:for-each select="fos:option">
                <arg name="{@key}" type="{fos:type}"/>
              </xsl:for-each>
              <arg name="*"/>
	    </record>
	  </example>

		<table style="border-collapse: collapse">
			<xsl:copy-of select="@diff, @at"/>
			<thead>
				<tr style="border-top: 2px solid black; border-bottom: 2px solid black">
					<th style="text-align:left; padding-right: 10px; ">Key</th>
					<xsl:if test="fos:option/fos:applies-to">
						<th style="text-align:left; padding-right: 10px; ">Applies to</th>
					</xsl:if>
					<xsl:if test="exists(.//fos:values)">
						<th style="text-align:left; padding-right: 10px; ">Value</th>
					</xsl:if>
					<th style="text-align:left">
						<!--<xsl:if test="exists(.//fos:values)">
							<xsl:attribute name="colspan">2</xsl:attribute>
						</xsl:if>-->
						<xsl:text>Meaning</xsl:text>
					</th>
				</tr>
			</thead>
			<tbody>
				<xsl:apply-templates select="fos:option"/>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template match="fos:option">
		<tr>
			<xsl:copy-of select="@diff, @at"/>
			<td
				style="white-space:nowrap; padding-right: 10px; vertical-align:top; border-bottom: 2px solid black"
				rowspan="{1 + count(fos:values/fos:value)}">
				<code>
					<xsl:value-of select="@key"/>
				</code>
			</td>
			<xsl:if test="../fos:option/fos:applies-to">
				<td
					style="white-space:nowrap; padding-right: 10px; vertical-align:top; border-bottom: 2px solid black"
					rowspan="{1 + count(fos:values/fos:value)}">
					<xsl:value-of select="fos:applies-to"/>
				</td>
			</xsl:if>
			<xsl:variable name="thickness" select="
					if (exists(fos:values)) then
						'1'
					else
						'2'"/>
			<td style="vertical-align:top; border-bottom: {$thickness}px solid black">
				<xsl:if test="exists(..//fos:values)">
					<xsl:attribute name="colspan">2</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates select="fos:meaning/node()"/>
				<ulist>
					<item>
						<p>
							<term>Type: </term>
							<code>
								<xsl:value-of select="fos:type"/>
							</code>
						</p>
					</item>
<xsl:if test="fos:default | fos:default-description">
  <xsl:choose>
    <xsl:when test="not(fos:default)">
      <item>
        <p>
          <term>Default: </term>
          <xsl:apply-templates select="fos:default-description/node()"/>
        </p>
      </item>
    </xsl:when>
    <xsl:otherwise>
      <item>
        <p>
          <term>Default: </term>
          <xsl:apply-templates select="fos:default"/>
        </p>
        <xsl:apply-templates select="fos:default-description"/>
      </item>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>
				</ulist>
			</td>
		</tr>

		<xsl:for-each select="fos:values/fos:value">
			<xsl:variable name="thickness" select="
					if (position() = last()) then
						'2'
					else
						'1'"/>
			<tr>
				<td
					style="white-space:nowrap; padding-right: 10px; vertical-align:top; border-bottom: {$thickness}px solid black">
					<code>
						<xsl:value-of select="@value"/>
					</code>
				</td>
				<td style="vertical-align:top; border-bottom: {$thickness}px solid black">
					<xsl:apply-templates/>
				</td>
			</tr>
		</xsl:for-each>

	</xsl:template>

<xsl:template match="fos:default">
  <code>
    <xsl:apply-templates/>
  </code>
</xsl:template>

<xsl:template match="fos:default-description">
  <p>
    <xsl:apply-templates/>
  </p>
</xsl:template>

	<xsl:template match="fos:history | fos:version"/>

	<xsl:template match="processing-instruction('type')" expand-text="yes">
		<xsl:variable name="target" select="$fosdoc//fos:type[@id = normalize-space(current())]"/>
		<xsl:if test="count($target) ne 1">
			<xsl:message expand-text="yes">Failed to locate record type {.}</xsl:message>
		</xsl:if>
		<xsl:variable name="verified-target" select="$target" as="element(fos:type)"/>
		<xsl:variable name="record" select="$target/fos:record" as="element(fos:record)"/>
		<xsl:apply-templates select="$record"/>
	</xsl:template>

</xsl:stylesheet>
