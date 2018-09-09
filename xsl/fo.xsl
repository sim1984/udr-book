<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:d="http://docbook.org/ns/docbook"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:xslthl="http://xslthl.sf.net" 
    exclude-result-prefixes="xslthl d" 
    version="1.0">

    <xsl:import href="http://docbook.sourceforge.net/release/xsl-ns/current/fo/docbook.xsl"/>
    <xsl:import href="http://docbook.sourceforge.net/release/xsl-ns/current/fo/highlight.xsl"/>

    <!-- then include our own customizations: -->
    <xsl:include href="common/param.xsl"/>
    <xsl:include href="common/titles.xsl"/>
    <xsl:include href="common/gentext.xsl"/>
    <xsl:include href="common/inline.xsl"/>
    <xsl:include href="common/special-hyph.xsl"/>
    <xsl:include href="fo/param.xsl"/>
    <xsl:include href="fo/pagesetup.xsl"/>
    <xsl:include href="fo/verbatim.xsl"/>
    <xsl:include href="fo/inline.xsl"/>
    <xsl:include href="fo/lists.xsl"/>
    <xsl:include href="fo/formal.xsl"/>
    <xsl:include href="fo/block.xsl"/>
    <xsl:include href="fo/htmltbl.xsl"/>
    <!--
    <xsl:include href="fo/table.xsl"/>
    -->
    <xsl:include href="fo/sections.xsl"/>
    <xsl:include href="fo/titlepage.xsl"/>
<!--
    <xsl:include href="fo/titlepage.templates.xsl"/>
-->
    <xsl:include href="fo/admon.xsl"/>
    <xsl:include href="fo/index.xsl"/>    
    <xsl:include href="fo/xref.xsl"/>
    <!--
    <xsl:include href="fo/autotoc.xsl"/>   
    <xsl:include href="fo/fop1.xsl"/>
    -->
    <xsl:include href="fo/component.xsl"/> 
    


    <!-- Подсветка строк в теге programlising language="sql" -->
    <xsl:template match="xslthl:string" mode="xslthl">
        <fo:inline color="#000066">
            <xsl:apply-templates mode="xslthl"/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="xslthl:comment" mode="xslthl">
        <fo:inline font-style="italic" color="#005600">
            <xsl:apply-templates mode="xslthl"/>
        </fo:inline>
    </xsl:template>

</xsl:stylesheet>
