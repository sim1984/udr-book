<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="d"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:d="http://docbook.org/ns/docbook"
  xmlns:fo="http://www.w3.org/1999/XSL/Format"
  xmlns:axf="http://www.antennahouse.com/names/XSL/Extensions"
  version='1.0'>



<!-- Altered this template so that for <chapter>, two fo:blocks are
     generated: one with the label, and one with the title proper.
     For chapter-level appendices there are also some customizations. -->
     
<!-- TODO:
     The whole possibly-labeled-title / label / title business could be organized more transparently! -->

<xsl:template name="component.title">
  <xsl:param name="node" select="."/>
  <xsl:param name="pagewide" select="0"/>

  <xsl:variable name="id">
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="$node"/>
    </xsl:call-template>
  </xsl:variable>

  <!-- 1 if it concerns an appendix at chapter level (i.e. not in an article) -->
  <xsl:variable name="is-chapterlevel-appendix">
    <xsl:if test="$node/self::d:appendix and not($node/parent::d:article)">1</xsl:if>
  </xsl:variable>

  <!-- This one was simply "title" in the original, for all elems.
       Here it will not be used for chapters and chapter-level appendices.
  -->
  <xsl:variable name="possibly-labeled-title">
    <xsl:apply-templates select="$node" mode="object.title.markup">
      <xsl:with-param name="allow-anchors" select="1"/>
    </xsl:apply-templates>
  </xsl:variable>

  <!-- This var will only be assigend for chapters, although we'll generate
       a label for chapter-level appendices later on.
  -->
  <xsl:variable name="label">
    <xsl:if test="$node/self::d:chapter and $chapter.autolabel != 0">
      <fo:block xsl:use-attribute-sets="chapter.label.properties">
        <xsl:apply-templates select="$node" mode="xref-number.markup"/>
        <!-- This returns stuff like "Chapter&#160;%n" etc.
             Any explicit label is deliberately ignored. -->
      </fo:block>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="title">
    <xsl:choose>
      <!--
        For a chapter, $title contains just the unlabeled title, with chapter.title.properties:
      -->
      <xsl:when test="$node/self::d:chapter">
        <fo:block xsl:use-attribute-sets="chapter.title.properties">
          <xsl:apply-templates select="$node" mode="unlabeled.title.markup">
            <xsl:with-param name="allow-anchors" select="1"/>
          </xsl:apply-templates>
        </fo:block>
      </xsl:when>
      <!--
        For a chapter-level appendix, we include the (conditional) autolabel and the
        title together in the $title variable, with chapter.title.properties for the two:
      -->
      <xsl:when test="$is-chapterlevel-appendix = 1">
        <fo:block xsl:use-attribute-sets="chapter.title.properties">
          <xsl:if test="$appendix.autolabel != ''">
            <xsl:apply-templates select="$node" mode="xref-number.markup"/>
            <!-- This returns stuff like "Appendix&#160;A" etc.
                 Any explicit label is deliberately ignored. -->
            <xsl:text>:</xsl:text>
            <fo:block/>
          </xsl:if>
          <xsl:apply-templates select="$node" mode="unlabeled.title.markup">
            <xsl:with-param name="allow-anchors" select="1"/>
          </xsl:apply-templates>
        </fo:block>
      </xsl:when>
      <!--
        For al other components, $title contains the possibly labeled title:
      -->
      <xsl:otherwise>
        <xsl:copy-of select="$possibly-labeled-title"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="titleabbrev">
    <xsl:apply-templates select="$node" mode="titleabbrev.markup"/>
  </xsl:variable>

  <xsl:if test="$passivetex.extensions != 0">
    <fotex:bookmark xmlns:fotex="http://www.tug.org/fotex"
                    fotex-bookmark-level="2"
                    fotex-bookmark-label="{$id}">
      <xsl:value-of select="$titleabbrev"/>
    </fotex:bookmark>
  </xsl:if>

  <xsl:variable name="label-plus-title">
    <fo:block keep-with-next.within-column="always"
              space-before.optimum="{$body.font.master}pt"
              space-before.minimum="{$body.font.master * 0.8}pt"
              space-before.maximum="{$body.font.master * 1.2}pt"
              hyphenate="false">
      <xsl:if test="$pagewide != 0">
        <!-- Doesn't work to use 'all' here since not a child of fo:flow -->
        <xsl:attribute name="span">inherit</xsl:attribute>
      </xsl:if>
      <xsl:attribute name="hyphenation-character">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-character'"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="hyphenation-push-character-count">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-push-character-count'"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="hyphenation-remain-character-count">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-remain-character-count'"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:if test="$axf.extensions != 0">
        <xsl:attribute name="axf:outline-level">
          <xsl:value-of select="count($node/ancestor::*)"/>
        </xsl:attribute>
        <xsl:attribute name="axf:outline-expand">false</xsl:attribute>
        <xsl:attribute name="axf:outline-title">
          <xsl:value-of select="$possibly-labeled-title"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:copy-of select="$label"/>
      <xsl:copy-of select="$title"/>
    </fo:block>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$node/self::d:chapter or $is-chapterlevel-appendix = 1">
      <fo:block xsl:use-attribute-sets="chapter.label-plus-title.properties">
        <xsl:copy-of select="$label-plus-title"/>
      </fo:block>
    </xsl:when>
    <xsl:otherwise> <!-- $node is no chapter or chapter-level appendix: -->
      <xsl:copy-of select="$label-plus-title"/>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


<!-- chapter subtitles pick up the attribute set we've introduced: -->

<xsl:template match="d:chapter/d:chapterinfo/d:subtitle
                     | d:chapter/d:docinfo/d:subtitle
                     | d:chapter/d:info/d:subtitle
                     | d:chapter/d:subtitle" 
              mode="titlepage.mode">
  <fo:block xsl:use-attribute-sets="chapter.subtitle.properties">
    <xsl:apply-templates mode="titlepage.mode"/>
  </fo:block>
</xsl:template>



<!-- ==================================================================== -->



  <!-- Split article in top level articles and others. 
       Top level articles get "cover pages" just like books. -->

  <xsl:template match="d:article">
    <xsl:variable name="id">
      <xsl:call-template name="object.id"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="not(parent::*) or $id=$rootid">
        <xsl:apply-templates select="." mode="article.toplevel.mode"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="article.nontoplevel.mode"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="d:article" mode="article.toplevel.mode">  <!-- with coverpage etc. -->
    <xsl:variable name="id">
      <xsl:call-template name="object.id"/>
    </xsl:variable>

    <xsl:variable name="preamble"
                  select="d:title|d:subtitle|d:titleabbrev|d:artheader|d:articleinfo"/>

    <xsl:variable name="content"
                  select="*[not(self::d:title
                             or self::d:subtitle
                             or self::d:titleabbrev
                             or self::d:artheader
                             or self::d:articleinfo
                             or self::d:index)]"/>

    <xsl:variable name="titlepage-master-reference">
      <xsl:call-template name="select.pagemaster">
        <xsl:with-param name="pageclass" select="'titlepage'"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- Preamble largely copied from <set>, but changed set.titlepage to
         article.titlepage near the end.
         <book> also has initial-page-number="1" as a page-sequence attribute.
    -->

    <xsl:if test="$preamble">
      <fo:page-sequence hyphenate="{$hyphenate}"
                        master-reference="{$titlepage-master-reference}">
        <xsl:attribute name="language">
          <xsl:call-template name="l10n.language"/>
        </xsl:attribute>
        <xsl:attribute name="format">
          <xsl:call-template name="page.number.format"/>
        </xsl:attribute>
        <xsl:choose>
          <xsl:when test="$double.sided != 0">
            <xsl:attribute name="initial-page-number">auto-odd</xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="force-page-count">no-force</xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:attribute name="hyphenation-character">
          <xsl:call-template name="gentext">
            <xsl:with-param name="key" select="'hyphenation-character'"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="hyphenation-push-character-count">
          <xsl:call-template name="gentext">
            <xsl:with-param name="key" select="'hyphenation-push-character-count'"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="hyphenation-remain-character-count">
          <xsl:call-template name="gentext">
            <xsl:with-param name="key" select="'hyphenation-remain-character-count'"/>
          </xsl:call-template>
        </xsl:attribute>

        <xsl:apply-templates select="." mode="running.head.mode">
          <xsl:with-param name="master-reference" select="$titlepage-master-reference"/>
        </xsl:apply-templates>

        <xsl:apply-templates select="." mode="running.foot.mode">
          <xsl:with-param name="master-reference" select="$titlepage-master-reference"/>
        </xsl:apply-templates>

        <fo:flow flow-name="xsl-region-body">
          <fo:block id="{$id}">
            <xsl:call-template name="article.titlepage"/>
          </fo:block>
        </fo:flow>
      </fo:page-sequence>
    </xsl:if>

    <!-- toc stuff largely copied from <set>, but changed set.toc to
         article.toc near the end.
         <book>'s toc stuff is almost the same as <set>'s,
         except near the end (see comments there)
    -->

    <xsl:variable name="lot-master-reference">
      <xsl:call-template name="select.pagemaster">
        <xsl:with-param name="pageclass" select="'lot'"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="toc.params">
      <xsl:call-template name="find.path.params">
        <xsl:with-param name="table" select="normalize-space($generate.toc)"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="contains($toc.params, 'toc')">
      <fo:page-sequence hyphenate="{$hyphenate}"
                        format="i"
                        master-reference="{$lot-master-reference}">
        <xsl:attribute name="language">
          <xsl:call-template name="l10n.language"/>
        </xsl:attribute>
        <xsl:attribute name="format">
          <xsl:call-template name="page.number.format">
            <xsl:with-param name="element" select="'toc'"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:choose>
          <xsl:when test="$double.sided != 0">
            <xsl:attribute name="initial-page-number">auto-odd</xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="force-page-count">no-force</xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:attribute name="hyphenation-character">
          <xsl:call-template name="gentext">
            <xsl:with-param name="key" select="'hyphenation-character'"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="hyphenation-push-character-count">
          <xsl:call-template name="gentext">
            <xsl:with-param name="key" select="'hyphenation-push-character-count'"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="hyphenation-remain-character-count">
          <xsl:call-template name="gentext">
            <xsl:with-param name="key" select="'hyphenation-remain-character-count'"/>
          </xsl:call-template>
        </xsl:attribute>

        <xsl:apply-templates select="." mode="running.head.mode">
          <xsl:with-param name="master-reference" select="$lot-master-reference"/>
          <!-- set doesn't have the following line, book has: -->
          <xsl:with-param name="gentext-key" select="'TableofContents'"/>
        </xsl:apply-templates>

        <xsl:apply-templates select="." mode="running.foot.mode">
          <xsl:with-param name="master-reference" select="$lot-master-reference"/>
          <!-- set doesn't have the following line, book has: -->
          <xsl:with-param name="gentext-key" select="'TableofContents'"/>
        </xsl:apply-templates>

        <fo:flow flow-name="xsl-region-body">
          <xsl:call-template name="component.toc"/>  <!-- set has set.toc here, book division.toc -->
        </fo:flow>
      </fo:page-sequence>
    </xsl:if>


    <!-- copied from default article template, but removed article.titlepage
         and toc stuff, changed apply-templates to apply-templates select="$content",
         and leave initial-page-number to auto (implicitly) if double.sided is false:
    -->

    <xsl:variable name="master-reference">
      <xsl:call-template name="select.pagemaster"/>
    </xsl:variable>

    <fo:page-sequence hyphenate="{$hyphenate}"
                      master-reference="{$master-reference}">
      <xsl:attribute name="language">
        <xsl:call-template name="l10n.language"/>
      </xsl:attribute>
      <xsl:attribute name="format">
        <xsl:call-template name="page.number.format"/>
      </xsl:attribute>

      <xsl:choose>
        <xsl:when test="$double.sided != 0">
          <xsl:attribute name="initial-page-number">auto-odd</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="force-page-count">no-force</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:attribute name="hyphenation-character">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-character'"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="hyphenation-push-character-count">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-push-character-count'"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="hyphenation-remain-character-count">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-remain-character-count'"/>
        </xsl:call-template>
      </xsl:attribute>
  
      <xsl:apply-templates select="." mode="running.head.mode">
        <xsl:with-param name="master-reference" select="$master-reference"/>
      </xsl:apply-templates>
  
      <xsl:apply-templates select="." mode="running.foot.mode">
        <xsl:with-param name="master-reference" select="$master-reference"/>
      </xsl:apply-templates>

      <fo:flow flow-name="xsl-region-body">
        <xsl:apply-templates select="$content"/>
      </fo:flow>
    </fo:page-sequence>

    <xsl:apply-templates select="d:index"/>  <!-- makes its own page-sequence -->

  </xsl:template>



  <xsl:template match="d:article" mode="article.nontoplevel.mode">  
  <!-- almost same as default article template, but took index apart -->
    <xsl:variable name="id">
      <xsl:call-template name="object.id"/>
    </xsl:variable>

    <xsl:variable name="master-reference">
      <xsl:call-template name="select.pagemaster"/>
    </xsl:variable>

    <fo:page-sequence hyphenate="{$hyphenate}"
                      master-reference="{$master-reference}">
      <xsl:attribute name="language">
        <xsl:call-template name="l10n.language"/>
      </xsl:attribute>
      <xsl:attribute name="format">
        <xsl:call-template name="page.number.format"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="not(preceding::d:chapter
                            or preceding::d:preface
                            or preceding::d:appendix
                            or preceding::d:article
                            or preceding::d:dedication
                            or parent::d:part
                            or parent::d:reference)">
          <!-- if there is a preceding component or we're in a part, the -->
          <!-- page numbering will already be adjusted -->
          <xsl:attribute name="initial-page-number">1</xsl:attribute>
        </xsl:when>
        <xsl:when test="$double.sided != 0">
          <xsl:attribute name="initial-page-number">auto-odd</xsl:attribute>
        </xsl:when>
      </xsl:choose>

      <xsl:if test="$double.sided = 0">
        <xsl:attribute name="force-page-count">no-force</xsl:attribute>
      </xsl:if>

      <xsl:attribute name="hyphenation-character">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-character'"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="hyphenation-push-character-count">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-push-character-count'"/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:attribute name="hyphenation-remain-character-count">
        <xsl:call-template name="gentext">
          <xsl:with-param name="key" select="'hyphenation-remain-character-count'"/>
        </xsl:call-template>
      </xsl:attribute>

      <xsl:apply-templates select="." mode="running.head.mode">
        <xsl:with-param name="master-reference" select="$master-reference"/>
      </xsl:apply-templates>

      <xsl:apply-templates select="." mode="running.foot.mode">
        <xsl:with-param name="master-reference" select="$master-reference"/>
      </xsl:apply-templates>

      <fo:flow flow-name="xsl-region-body">
        <fo:block id="{$id}">
          <xsl:call-template name="article.titlepage"/>
        </fo:block>

        <xsl:variable name="toc.params">
          <xsl:call-template name="find.path.params">
            <xsl:with-param name="table" select="normalize-space($generate.toc)"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:if test="contains($toc.params, 'toc')">
          <xsl:call-template name="component.toc"/>
          <xsl:call-template name="component.toc.separator"/>
        </xsl:if>
        <xsl:apply-templates select="*[not(self::d:index)]"/>
      </fo:flow>
    </fo:page-sequence>

    <xsl:apply-templates select="d:index"/>  <!-- makes its own page-sequence -->

  </xsl:template>



  <!-- By default, appendices have their own page-sequence.
       This is not the case for article/appendix.
       But at least we want it to start on a fresh page! -->

  <xsl:template match="d:article/d:appendix">
    <xsl:variable name="id">
      <xsl:call-template name="object.id"/>
    </xsl:variable>

    <xsl:variable name="xref-label">
      <xsl:apply-templates select="." mode="xref-number.markup"/>
    </xsl:variable>

    <xsl:variable name="title">
      <xsl:apply-templates select="." mode="title.markup">
        <xsl:with-param name="allow-anchors" select="1"/>
          <!-- allow-anchors 1 is our addition. Without it,
          indexterms within article/appendix/title will lead to
          broken index entries -->
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="titleabbrev">
      <xsl:apply-templates select="." mode="titleabbrev.markup"/>
    </xsl:variable>

    <fo:block id='{$id}' break-before="page">  <!-- break-before is our addition -->

      <xsl:if test="$passivetex.extensions != 0">
        <fotex:bookmark xmlns:fotex="http://www.tug.org/fotex"
                        fotex-bookmark-level="{count(ancestor::*)+2}"
                        fotex-bookmark-label="{$id}">
          <xsl:value-of select="$titleabbrev"/>
        </fotex:bookmark>
      </xsl:if>

      <xsl:if test="$axf.extensions != 0">
        <xsl:attribute name="axf:outline-level">
          <xsl:value-of select="count(ancestor::*)+2"/>
        </xsl:attribute>
        <xsl:attribute name="axf:outline-expand">false</xsl:attribute>
        <xsl:attribute name="axf:outline-title">
          <xsl:value-of select="$titleabbrev"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:if test="$fop-093=1">
        <fo:block keep-with-next.within-page="always">&#x200B;</fo:block>  <!-- to get spacing right with FOP 0.93 -->
      </xsl:if>

      <fo:block xsl:use-attribute-sets="article.appendix.title.properties">
        <fo:marker marker-class-name="section.head.marker">
          <xsl:choose>
            <xsl:when test="$titleabbrev = ''">
              <xsl:value-of select="$title"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$titleabbrev"/>
            </xsl:otherwise>
          </xsl:choose>
        </fo:marker>
        <xsl:copy-of select="$xref-label"/>
        <xsl:text>:</xsl:text>
        <fo:block/>  <!-- force newline -->
        <xsl:copy-of select="$title"/>
      </fo:block>

      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <!-- Стиль для заголовка введения -->
  <xsl:template name="preface.titlepage.recto">
    <fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format"
      xsl:use-attribute-sets="preface.titlepage.recto.style"
      margin-left="{$title.margin.left}" 
      font-size="24pt" 
      font-family="{$title.fontset}"
      font-weight="bold" 
      color="{$midlevel.title.color}"
      padding="2pt"
      text-align="center"
      background-color="#D0D0D0">
      <xsl:call-template name="component.title">
        <xsl:with-param name="node" select="ancestor-or-self::d:preface[1]"/>
      </xsl:call-template>
    </fo:block>
    <xsl:choose>
      <xsl:when test="d:prefaceinfo/d:subtitle">
        <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
          select="d:prefaceinfo/d:subtitle"/>
      </xsl:when>
      <xsl:when test="d:docinfo/d:subtitle">
        <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
          select="d:docinfo/d:subtitle"/>
      </xsl:when>
      <xsl:when test="d:info/d:subtitle">
        <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
          select="d:info/d:subtitle"/>
      </xsl:when>
      <xsl:when test="d:subtitle">
        <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:subtitle"/>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:corpauthor"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:docinfo/d:corpauthor"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:corpauthor"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:authorgroup"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:docinfo/d:authorgroup"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:authorgroup"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:author"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:docinfo/d:author"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:author"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:othercredit"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:docinfo/d:othercredit"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:othercredit"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:releaseinfo"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:docinfo/d:releaseinfo"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:releaseinfo"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:copyright"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:docinfo/d:copyright"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:copyright"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:legalnotice"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:docinfo/d:legalnotice"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:legalnotice"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:pubdate"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:docinfo/d:pubdate"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:pubdate"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:revision"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:docinfo/d:revision"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:revision"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:revhistory"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:docinfo/d:revhistory"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:revhistory"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:abstract"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:docinfo/d:abstract"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:abstract"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode"
      select="d:prefaceinfo/d:itermset"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:docinfo/d:itermset"/>
    <xsl:apply-templates mode="preface.titlepage.recto.auto.mode" select="d:info/d:itermset"/>
  </xsl:template>
  <!-- Стиль для заголовка оглавления -->
  <xsl:template name="table.of.contents.titlepage.recto">
    <fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format"
      xsl:use-attribute-sets="table.of.contents.titlepage.recto.style"
      margin-left="{$title.margin.left}" 
      font-size="16pt" 
      font-family="{$title.fontset}"
      font-weight="bold" 
      color="{$midlevel.title.color}"
      padding="2pt">
      <xsl:call-template name="gentext">
        <xsl:with-param name="key" select="'TableofContents'"/>
      </xsl:call-template>
    </fo:block>
  </xsl:template>
  <!-- Стиль для заголовка списка таблиц -->
  <xsl:template name="list.of.tables.titlepage.recto">
    <fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format"
      xsl:use-attribute-sets="list.of.tables.titlepage.recto.style" 
      margin-left="{$title.margin.left}" 
      font-size="16pt" 
      font-family="{$title.fontset}"
      font-weight="bold" 
      color="{$midlevel.title.color}"
      padding="2pt">
      <xsl:call-template name="gentext">
        <xsl:with-param name="key" select="'ListofTables'"/>
      </xsl:call-template>
    </fo:block>
  </xsl:template>
  <!-- Стиль для заголовка списка примеров -->
  <xsl:template name="list.of.examples.titlepage.recto">
    <fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format"
      xsl:use-attribute-sets="list.of.examples.titlepage.recto.style"
      margin-left="{$title.margin.left}" 
      font-size="16pt" 
      font-family="{$title.fontset}"
      font-weight="bold" 
      color="{$midlevel.title.color}"
      padding="2pt">
      <xsl:call-template name="gentext">
        <xsl:with-param name="key" select="'ListofExamples'"/>
      </xsl:call-template>
    </fo:block>
  </xsl:template>
  <!-- Стиль для заголовка алфавитного указателя -->
  <xsl:template name="index.titlepage.recto">
    <fo:block xmlns:fo="http://www.w3.org/1999/XSL/Format"
      xsl:use-attribute-sets="index.titlepage.recto.style" 
      margin-left="{$title.margin.left}" 
      font-size="24pt"
      font-family="{$title.fontset}" 
      font-weight="bold" 
      text-align="center"
      background-color="#D0D0D0"
      color="{$midlevel.title.color}">
      <xsl:call-template name="component.title">
        <xsl:with-param name="node" select="ancestor-or-self::d:index[1]"/>
        <xsl:with-param name="pagewide" select="1"/>
      </xsl:call-template>
    </fo:block>
    <xsl:choose>
      <xsl:when test="d:indexinfo/d:subtitle">
        <xsl:apply-templates mode="index.titlepage.recto.auto.mode"
          select="d:indexinfo/d:subtitle"/>
      </xsl:when>
      <xsl:when test="d:docinfo/d:subtitle">
        <xsl:apply-templates mode="index.titlepage.recto.auto.mode"
          select="d:docinfo/d:subtitle"/>
      </xsl:when>
      <xsl:when test="d:info/d:subtitle">
        <xsl:apply-templates mode="index.titlepage.recto.auto.mode"
          select="d:info/d:subtitle"/>
      </xsl:when>
      <xsl:when test="d:subtitle">
        <xsl:apply-templates mode="index.titlepage.recto.auto.mode" select="d:subtitle"/>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates mode="index.titlepage.recto.auto.mode" select="d:indexinfo/d:itermset"/>
    <xsl:apply-templates mode="index.titlepage.recto.auto.mode" select="d:docinfo/d:itermset"/>
    <xsl:apply-templates mode="index.titlepage.recto.auto.mode" select="d:info/d:itermset"/>
  </xsl:template>
  <!-- Стиль для заголовков formalpara -->
  <xsl:template match="d:formalpara/d:title|d:formalpara/d:info/d:title">
    <xsl:variable name="titleStr">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:variable name="lastChar">
      <xsl:if test="$titleStr != ''">
        <xsl:value-of select="substring($titleStr,string-length($titleStr),1)"/>
      </xsl:if>
    </xsl:variable>
    
    <fo:inline font-style="italic"
      keep-with-next.within-line="always"
      padding-end="1em">
      <xsl:copy-of select="$titleStr"/>
      <xsl:if test="$lastChar != ''
        and not(contains($runinhead.title.end.punct, $lastChar))">
        <xsl:value-of select="$runinhead.default.title.end.punct"/>
      </xsl:if>
      <xsl:text>&#160;</xsl:text>
    </fo:inline>
  </xsl:template>
</xsl:stylesheet>
