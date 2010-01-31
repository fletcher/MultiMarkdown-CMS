<?xml version='1.0' encoding='utf-8'?>

<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="xhtml xsl"
	version="1.0">

	<xsl:output method='html' indent="no" omit-xml-declaration="yes"/>

	<xsl:strip-space elements="*" />

	<xsl:template match="/">
		<ul>
		<xsl:apply-templates select="tagHierarchy"/>
		</ul>
	</xsl:template>

	<xsl:template match="tagHierarchy">
		<xsl:apply-templates select="tag"/>
	</xsl:template>
	
	<xsl:template match="tag">
		<li>
			<a href="/tags/{@title}"><xsl:value-of select="@title"/></a>
			<xsl:if test="count(child::tag) &gt; 0">
				<ul>
					<xsl:apply-templates/>
				</ul>
			</xsl:if>
		</li>
	</xsl:template>

	<xsl:template match="object"/>
</xsl:stylesheet>