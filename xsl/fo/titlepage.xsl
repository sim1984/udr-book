<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet 
  xmlns:d="http://docbook.org/ns/docbook"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:fo="http://www.w3.org/1999/XSL/Format"
  exclude-result-prefixes="d"
  version='1.0'>

  <xsl:template match="*" mode="chapter.titlepage.recto.mode">
    <!-- if an element isn't found in this mode, -->
    <!-- try the generic titlepage.mode -->
    <xsl:apply-templates select="." mode="titlepage.mode"/>
  </xsl:template>
  
  <xsl:template match="*" mode="chapter.titlepage.verso.mode">
    <!-- if an element isn't found in this mode, -->
    <!-- try the generic titlepage.mode -->
    <xsl:apply-templates select="." mode="titlepage.mode"/>
  </xsl:template>

  <!-- Титульная страница -->
  <xsl:template name="book.titlepage.recto">
    <!-- Логотип -->
    <fo:block margin-top="1cm" text-align="center">
      <fo:external-graphic src="url('fb.png')"/>
    </fo:block>
    <xsl:choose>
      <xsl:when test="d:info/d:title">
        <fo:inline color="#FB2400">
          <xsl:apply-templates mode="book.titlepage.recto.auto.mode"
            select="d:info/d:title"/>
        </fo:inline>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="d:info/d:subtitle">
        <xsl:apply-templates mode="book.titlepage.recto.auto.mode"
          select="d:info/d:subtitle"/>
      </xsl:when>
    </xsl:choose>
    <!-- Редакция -->
    <fo:block margin-top="0.2cm" text-align="center" hyphenate="false" font-family="Arial"
      font-size="10pt">
      <xsl:apply-templates mode="book.titlepage.recto.auto.mode" select="d:info/d:edition"/>
    </fo:block>
    <!-- Блок с надписью -->
    <fo:block margin-top="4cm" text-align="right" font-family="Arial" font-size="14pt"
      hyphenate="false">
      <xsl:text>Спонсоры документации:</xsl:text>
    </fo:block>
    <!-- Блок с надписью -->
    <fo:block text-align="right" font-family="Arial" font-size="12pt" font-style="italic"
      hyphenate="false">
      <xsl:text>Platinum Sponsor</xsl:text>
    </fo:block>
    <!-- Логотип спонсора -->
    <fo:block margin-top="0.2cm" text-align="right">
      <fo:basic-link external-destination="http://moex.com/">
        <fo:external-graphic src="url('moex.png')"/>
      </fo:basic-link>
    </fo:block>
    <!-- Блок с надписью -->
    <fo:block text-align="right" font-family="Arial" font-size="12pt" font-style="italic"
      hyphenate="false">
      <xsl:text>Gold Sponsor</xsl:text>
    </fo:block>
    <!-- Логотип спонсора -->
    <fo:block margin-top="0.2cm" text-align="right">
      <fo:basic-link external-destination="http://www.ib-aid.com/">
        <fo:external-graphic src="url('ibsurgeon.png')"/>
      </fo:basic-link>
    </fo:block>
  </xsl:template>
  <!-- Титульная страница оборотна сторона -->
  <xsl:template name="book.titlepage.verso">
    <xsl:choose>
      <xsl:when test="d:info/d:title">
        <fo:inline color="#103090">
          <xsl:apply-templates mode="book.titlepage.verso.auto.mode"
            select="d:info/d:title"/>
        </fo:inline>
      </xsl:when>
    </xsl:choose>
    <fo:block margin-top="0.2cm" margin-bottom="0.1cm" font-weight="bold"> Над документом
      работали: </fo:block>
    <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="d:info/d:authorgroup"/>
    <fo:block margin-top="0.2cm" margin-bottom="0.1cm" font-weight="bold"> Редактор: </fo:block>
    <xsl:apply-templates mode="book.titlepage.verso.auto.mode" select="d:info/d:editor"/>
  </xsl:template>
  

</xsl:stylesheet>
