<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">


     <!-- OVERRIDDEN STYLESHEET PARAMETERS: -->

     <!-- These two have been moved here because they should be the same
       for each build target (HTML, PDF etc.) -->
     <xsl:param name="runinhead.default.title.end.punct" select="':'"/>
     <xsl:param name="runinhead.title.end.punct" select="'.!?:-'"/>


     <!-- PARAMETERS INTRODUCED BY US -->

     <xsl:param name="fb-home.url" select="'index.html'"/>
     <xsl:param name="fb-home.title" select="'Firebird'"/>

     <xsl:param name="fb-docindex.url" select="'index.html'"/>
     <xsl:param name="fb-docindex.title" select="'Руководство по языку SQL СУБД Firebird 3.0'"/>

     <xsl:param name="runinhead.bold" select="1"/>
     <xsl:param name="runinhead.italic" select="0"/>

</xsl:stylesheet>
