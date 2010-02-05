<?xml version='1.0' encoding='utf-8'?>

<!-- 
	Copyright (C) 2010  Fletcher T. Penney <fletcher@fletcherpenney.net>

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the
	   Free Software Foundation, Inc.
	   59 Temple Place, Suite 330
	   Boston, MA 02111-1307 USA
-->


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
			<a href="tags/{@title}"><xsl:value-of select="@title"/></a>
			<xsl:if test="count(child::tag) &gt; 0">
				<ul>
					<xsl:apply-templates/>
				</ul>
			</xsl:if>
		</li>
	</xsl:template>

	<xsl:template match="object"/>
</xsl:stylesheet>