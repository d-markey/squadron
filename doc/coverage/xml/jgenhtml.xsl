<?xml version="1.0"?>
<!--
	Copyright (C) 2012  Rick Brown

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html"
				indent="yes"
				doctype-system="about:legacy-compat"/>

	<xsl:param name="ext" select="'.xml'"/>
	<xsl:param name="sourceFileSuffix" select="'.gcov'"/>
	<xsl:param name="funcFileSuffix" select="'.func'"/>
	<xsl:param name="cssName" select="'jgenhtml.css'"/>
	<xsl:param name="jsName" select="'jgenhtml.js'"/>
	<xsl:variable name="base">
		<xsl:value-of select="/coverage/base/@href"/>
	</xsl:variable>
	<xsl:variable name="hilimit" select="number(/coverage/config/@genhtml_hi_limit)"/>
	<xsl:variable name="medlimit" select="number(/coverage/config/@genhtml_med_limit)"/>
	<xsl:variable name="branchcov" select="not(/coverage/config[@branch-coverage='false'])"/>
	<xsl:variable name="funccov" select="not(/coverage/config[@function-coverage='false'])"/>
	<xsl:variable name="legend" select="/coverage/config[@legend='true']"/>
	<xsl:variable name="sort" select="not(/coverage/config[@no-sort='true'])"/>
	<xsl:variable name="showDetails" select="/coverage/config[@show-details='true']"/>

	<xsl:template match="descriptions">
		<html>
			<xsl:call-template name="buildHtmlHead"/>
			<body>
				<xsl:call-template name="buildHeader">
					<xsl:with-param name="buildLegend" select="false()"/>
					<xsl:with-param name="buildStats" select="false()"/>
				</xsl:call-template>
				<div class="descriptions">
					<h2>Test case descriptions - alphabetical list</h2>
					<xsl:apply-templates select="description">
						<xsl:sort select="@test-name"/>
					</xsl:apply-templates>
				</div>
				<xsl:call-template name="buildFooter"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="description">
		<dt>
			<xsl:if test="not(preceding-sibling::description/@test-name = @test-name)">
				<xsl:attribute name="id">
					<xsl:value-of select="@test-name"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:value-of select="@test-name"/>
		</dt>
		<xsl:apply-templates select="info"/>
	</xsl:template>

	<xsl:template match="info">
		<dd>
			<xsl:value-of select="."/>
		</dd>
	</xsl:template>

	<xsl:template match="coverage">
		<html>
			<xsl:call-template name="buildHtmlHead"/>
			<body>
				<xsl:attribute name="class">
					<xsl:text>noscript</xsl:text>
					<xsl:if test="not($branchcov)">
						<xsl:text> nobranch</xsl:text>
					</xsl:if>
					<xsl:if test="not($funccov)">
						<xsl:text> nofunc</xsl:text>
					</xsl:if>
					<xsl:if test="not($legend)">
						<xsl:text> nolegend</xsl:text>
					</xsl:if>
				</xsl:attribute>
				<xsl:call-template name="buildHeader"/>
				<xsl:apply-templates select="lines|sources|functions"/>
				<xsl:call-template name="buildFooter"/>
				<xsl:call-template name="buildControls"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="buildHtmlHead">
		<head>
			<xsl:apply-templates select="comment()"/>
			<xsl:variable name="cssPath">
				<xsl:value-of select="concat($base, $cssName)"/>
			</xsl:variable>
			<xsl:variable name="jsPath">
				<xsl:value-of select="concat($base, $jsName)"/>
			</xsl:variable>
			<link rel="stylesheet" type="text/css" href="{$cssPath}"/>
			<xsl:element name="script">
				<xsl:attribute name="type">
					<xsl:text>text/javascript</xsl:text>
				</xsl:attribute>
				<xsl:attribute name="src">
					<xsl:value-of select="$jsPath"/>
				</xsl:attribute>
			</xsl:element>
			<title><xsl:value-of select="concat('LCOV - ', @testname, ' ',  @filename)"/></title>
		</head>
	</xsl:template>

	<xsl:template name="buildHeader">
		<xsl:param name="buildLegend" select="true()"/>
		<xsl:param name="buildStats" select="true()"/>
		<xsl:variable name="totalLineCount">
			<xsl:choose>
				<xsl:when test="lines|functions">
					<xsl:value-of select="@lines-valid"/>
				</xsl:when>
				<xsl:when test="sources">
					<xsl:value-of select="sum(sources/source/@lines-valid)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="totalFuncCount">
			<xsl:choose>
				<xsl:when test="lines|functions">
					<xsl:value-of select="@functions-valid"/>
				</xsl:when>
				<xsl:when test="sources">
					<xsl:value-of select="sum(sources/source/@functions-valid)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="totalBranchCount">
			<xsl:choose>
				<xsl:when test="lines|functions">
					<xsl:value-of select="@branches-valid"/>
				</xsl:when>
				<xsl:when test="sources">
					<xsl:value-of select="sum(sources/source/@branches-valid)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="lineRatePc" select="format-number(@line-rate * 100, '0.0')"/>
		<xsl:variable name="branchRatePc" select="format-number(@branch-rate * 100, '0.0')"/>
		<xsl:variable name="funcRatePc" select="format-number(@function-rate * 100, '0.0')"/>
		<h1>LCOV - code coverage report</h1>
				<div class="header">
					<div class="row">
						<dl class="pageView">
							<dt>Current view</dt>
							<dd>
								<xsl:choose>
									<xsl:when test="@package">
										<a>
											<xsl:attribute name="href">
												<xsl:value-of select="concat($base, 'index', $ext)"/>
											</xsl:attribute>
											<xsl:text>top level</xsl:text>
										</a>
										<xsl:text> - </xsl:text>
										<xsl:choose>
											<xsl:when test="@filename and not(sources)">
												<a href="index{$ext}">
													<xsl:value-of select="@package"/>
												</a>
												<xsl:value-of select="concat(' - ', @filename)"/>
												<xsl:if test="string(number($funcRatePc))!='NaN'">
													<span class="functionNav">
														<xsl:text> (</xsl:text>
														<xsl:choose>
															<xsl:when test="functions">
																<xsl:call-template name="buildLinkToFile">
																	<xsl:with-param name="text" select="'source '"/>
																	<xsl:with-param name="suffix" select="$sourceFileSuffix"/>
																</xsl:call-template>
																<xsl:text>/ functions</xsl:text>
															</xsl:when>
															<xsl:otherwise>
																<xsl:text>source /</xsl:text>
																<xsl:call-template name="buildLinkToFile">
																	<xsl:with-param name="text" select="' functions'"/>
																	<xsl:with-param name="suffix" select="$funcFileSuffix"/>
																</xsl:call-template>
															</xsl:otherwise>
														</xsl:choose>
														<xsl:text>)</xsl:text>
													</span>
												</xsl:if>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="@package"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="self::descriptions">
										<a>
											<xsl:attribute name="href">
												<xsl:value-of select="concat('index', $ext)"/>
											</xsl:attribute>
											<xsl:text>top level</xsl:text>
										</a>
										<xsl:text> - test case descriptions</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>top level</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</dd>
							<dt>Test</dt>
							<dd>
								<xsl:value-of select="@testname"/>
								<xsl:if test="/coverage/config/@description-file='true'">
									<xsl:text> (</xsl:text>
									<a>
										<xsl:attribute name="href">
											<xsl:value-of select="concat($base, 'descriptions', $ext)"/>
										</xsl:attribute>
										<xsl:text>view descriptions</xsl:text>
									</a>
									<xsl:text>)</xsl:text>
								</xsl:if>
							</dd>
							<dt>Date</dt>
							<dd>
								<xsl:value-of select="@date"/>
							</dd>
							<xsl:if test="$buildLegend">
								<dt class="legend">Legend</dt>
								<dd class="legend">
									<dl class="legend">
										<xsl:choose>
											<xsl:when test="lines|functions">
												<dt>Lines</dt>
												<dd class="lineCov">
													<xsl:text>hit</xsl:text>
												</dd>
												<dd class="lineNoCov">
													<xsl:text>not hit</xsl:text>
												</dd>
												<dt>Branches</dt>
												<dd class="taken">
													<xsl:text> taken</xsl:text>
												</dd>
												<dd class="noTaken">
													<xsl:text> not taken</xsl:text>
												</dd>
												<dd class="lineNoCov">
													<xsl:text># not executed</xsl:text>
												</dd>
											</xsl:when>
											<xsl:otherwise>
												<dt class="low">low</dt>
												<dd class="low">
													<xsl:value-of select="concat('&lt;', $medlimit, '%')"/>
												</dd>
												<dt class="med">medium</dt>
												<dd class="med">
													<xsl:value-of select="concat('&gt;=', $medlimit, '%')"/>
												</dd>
												<dt class="high">high</dt>
												<dd class="high">
													<xsl:value-of select="concat('&gt;=', $hilimit, '%')"/>
												</dd>
											</xsl:otherwise>
										</xsl:choose>
									</dl>
								</dd>
							</xsl:if>
						</dl>
						<xsl:if test="$buildStats">
							<table class="stats">
								<thead>
									<tr>
										<td></td>
										<th scope="col">Hit</th>
										<th scope="col">Total</th>
										<th scope="col">Coverage</th>
									</tr>
								</thead>
								<tbody>
									<xsl:call-template name="buildSummaryRow">
										<xsl:with-param name="title" select="'Lines'"/>
										<xsl:with-param name="hit" select="@lines-covered"/>
										<xsl:with-param name="total" select="$totalLineCount"/>
										<xsl:with-param name="pc" select="$lineRatePc"/>
									</xsl:call-template>
									<xsl:call-template name="buildSummaryRow">
										<xsl:with-param name="title" select="'Functions'"/>
										<xsl:with-param name="hit" select="@functions-covered"/>
										<xsl:with-param name="total" select="$totalFuncCount"/>
										<xsl:with-param name="pc" select="$funcRatePc"/>
									</xsl:call-template>
									<xsl:call-template name="buildSummaryRow">
										<xsl:with-param name="title" select="'Branches'"/>
										<xsl:with-param name="hit" select="@branches-covered"/>
										<xsl:with-param name="total" select="$totalBranchCount"/>
										<xsl:with-param name="pc" select="$branchRatePc"/>
									</xsl:call-template>
								</tbody>
							</table>
						</xsl:if>
					</div>
				</div>
	</xsl:template>

	<xsl:template name="buildControls">
		<div class="controls">
			<fieldset>
				<legend>Choose Features</legend>
				<label for="nofunc">Function coverage</label>
				<input id="nofunc" type="checkbox">
					<xsl:if test="$funccov">
						<xsl:attribute name="checked">
							<xsl:text>checked</xsl:text>
						</xsl:attribute>
					</xsl:if>
				</input>
				<label for="nobranch">Branch coverage</label>
				<input id="nobranch" type="checkbox">
					<xsl:if test="$branchcov">
						<xsl:attribute name="checked">
							<xsl:text>checked</xsl:text>
						</xsl:attribute>
					</xsl:if>
				</input>
				<label for="nolegend">Legend</label>
				<input id="nolegend" type="checkbox">
					<xsl:if test="$legend">
						<xsl:attribute name="checked">
							<xsl:text>checked</xsl:text>
						</xsl:attribute>
					</xsl:if>
				</input>
			</fieldset>
		</div>
	</xsl:template>

	<xsl:template name="buildFooter">
		<div class="footer">
			<p>
				<xsl:text>Generated by: </xsl:text>
				<a href="https://github.com/ricksbrown/jgenhtml">
					<xsl:text>JGENHTML version </xsl:text>
					<xsl:value-of select="@version"/>
				</a>
			</p>
		</div>
	</xsl:template>

	<xsl:template name="buildSummaryRow">
		<xsl:param name="title"/>
		<xsl:param name="hit"/>
		<xsl:param name="total"/>
		<xsl:param name="pc"/>
		<tr>
			<th scope="row">
				<xsl:value-of select="$title"/>
			</th>
			<td>
				<xsl:value-of select="$hit"/>
			</td>
			<td>
				<xsl:value-of select="$total"/>
			</td>
			<td>
				<xsl:attribute name="class">
					<xsl:call-template name="getClassForRate">
						<xsl:with-param name="pc" select="$pc"/>
					</xsl:call-template>
				</xsl:attribute>
				<xsl:choose>
					<xsl:when test="string(number($pc))='NaN'">
						<xsl:text>-</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat($pc, '%')"/>
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="sources">
		<xsl:variable name="sourceType">
			<xsl:choose>
				<xsl:when test="source/@pathname">
					<xsl:text>directory</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>filename</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<table class="index">
			<xsl:attribute name="class">
				<xsl:text>index</xsl:text>
				<xsl:if test="$showDetails">
					<xsl:text> showDetails</xsl:text>
				</xsl:if>
			</xsl:attribute>
			<xsl:variable name="canSort" select="(count(source) &gt; 1 and $sort)"/>
			<thead>
				<tr>
					<th id="{$sourceType}">
						<xsl:if test="$canSort">
							<xsl:attribute name="class">
								<xsl:text>sortable</xsl:text>
							</xsl:attribute>
							<xsl:attribute name="aria-sort">
								<xsl:text>ascending</xsl:text>
							</xsl:attribute>
							<xsl:call-template name="sortControl"/>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="$sourceType='directory'">
								<xsl:text>Directory</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>Filename</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</th>
					<th colspan="3" id="lineCoverage">
						<xsl:if test="$canSort">
							<xsl:attribute name="class">
								<xsl:text>sortable</xsl:text>
							</xsl:attribute>
							<xsl:call-template name="sortControl"/>
						</xsl:if>
						<xsl:text>Line Coverage</xsl:text>
						<xsl:if test="count(source/testCase) &gt; 0">
							<button class="showDetails" type="button">Show/Hide Details</button>
						</xsl:if>
					</th>
					<th colspan="2" id="functions">
						<xsl:if test="$canSort">
							<xsl:attribute name="class">
								<xsl:text>sortable</xsl:text>
							</xsl:attribute>
							<xsl:call-template name="sortControl"/>
						</xsl:if>
						<xsl:text>Functions</xsl:text>
					</th>
					<th colspan="2" id="branches">
						<xsl:if test="$canSort">
							<xsl:attribute name="class">
								<xsl:text>sortable</xsl:text>
							</xsl:attribute>
							<xsl:call-template name="sortControl"/>
						</xsl:if>
						<xsl:text>Branches</xsl:text>
					</th>
				</tr>
				<tr>
					<th></th>
					<th id="line-indicator">Indicator</th>
					<th id="line-percent">Percent</th>
					<th id="line-ratio">Hit/Total</th>
					<th id="function-percent">Percent</th>
					<th id="function-ratio">Hit/Total</th>
					<th id="bsourceLineranch-percent">Percent</th>
					<th id="branch-ratio">Hit/Total</th>
				</tr>
			</thead>
			<tbody>
				<xsl:apply-templates select="source">
					<xsl:sort select="@pathname|@filename"/>
					<xsl:with-param name="sourceType" select="$sourceType"/>
				</xsl:apply-templates>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template name="sortControl">
		<button type="button" class="sort"><!-- You don't actually have to click this button, it's here for keyboard users -->
			<span class="offscreen">Sort the table on this column</span>
		</button>
	</xsl:template>

	<xsl:template match="source">
		<xsl:param name="sourceType" select="'filename'"/>
		<tr>
			<td headers="{$sourceType}">
				<xsl:choose>
					<xsl:when test="@pathname">
						<a>
							<xsl:attribute name="href">
								<xsl:if test="starts-with(@pathname, '/')">
									<xsl:text>.</xsl:text>
								</xsl:if>
								<xsl:value-of select="concat(@pathname, '/index', $ext)"/>
							</xsl:attribute>
							<xsl:attribute name="title">
								<xsl:choose>
									<xsl:when test="@prefix">
										<xsl:value-of select="concat(@prefix, @pathname)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="@pathname"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:value-of select="@pathname"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="tag">
							<xsl:choose>
								<xsl:when test="//config[@no-source='true']">
									<xsl:text>span</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>a</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:element name="{$tag}">
							<xsl:if test="$tag='a'">
								<xsl:attribute name="href">
									<xsl:value-of select="concat(@filename, $sourceFileSuffix, $ext)"/>
								</xsl:attribute>
							</xsl:if>
							<xsl:attribute name="title">
								<xsl:choose>
									<xsl:when test="@prefix">
										<xsl:value-of select="concat(@prefix, '/', @filename)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="@filename"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:value-of select="@filename"/>
						</xsl:element>
					</xsl:otherwise>
				</xsl:choose>
			</td>
			<xsl:call-template name="hitSummaryCells">
				<xsl:with-param name="linesValid" select="@lines-valid"/>
				<xsl:with-param name="functionsValid" select="@functions-valid"/>
				<xsl:with-param name="branchesValid" select="@branches-valid"/>
				<xsl:with-param name="colorCode" select="true()"/>
			</xsl:call-template>
		</tr>
		<xsl:apply-templates select="testCase">
			<xsl:sort select="@name" order="descending"/>
		</xsl:apply-templates>
	</xsl:template>
	
	
	<xsl:template match="testCase">
		<tr class="bound">
			<!-- This is to implement the 'showDetails' flag of genhtml -->
			<td></td>
			<xsl:call-template name="hitSummaryCells">
				<xsl:with-param name="linesValid" select="../@lines-valid"/>
				<xsl:with-param name="functionsValid" select="../@functions-valid"/>
				<xsl:with-param name="branchesValid" select="../@branches-valid"/>
				<xsl:with-param name="colorCode" select="false()"/>
			</xsl:call-template>
		</tr>
	</xsl:template>
	
	<xsl:template name="hitSummaryCells">
		<xsl:param name="linesValid"/>
		<xsl:param name="functionsValid"/>
		<xsl:param name="branchesValid"/>
		<xsl:param name="colorCode" select="true()"/>
		
		<xsl:variable name="lineRate" select="@lines-hit div $linesValid"/>
		<xsl:variable name="lineRatePc" select="format-number($lineRate * 100, '0.0')"/>
		
		<xsl:variable name="funcRate" select="@functions-hit div $functionsValid"/>
		<xsl:variable name="funcRatePc" select="format-number($funcRate * 100, '0.0')"/>
		
		<xsl:variable name="branchRate" select="@branches-hit div $branchesValid"/>
		<xsl:variable name="branchRatePc" select="format-number($branchRate * 100, '0.0')"/>
		
		<xsl:variable name="lineClass">
			<xsl:call-template name="getClassForRate">
				<xsl:with-param name="pc" select="$lineRatePc"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="funcClass">
			<xsl:call-template name="getClassForRate">
				<xsl:with-param name="pc" select="$funcRatePc"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="branchClass">
			<xsl:call-template name="getClassForRate">
				<xsl:with-param name="pc" select="$branchRatePc"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="@name">
				<td headers="line-indicator lineCoverage">
					<xsl:value-of select="@name"/>
				</td>
			</xsl:when>
			<xsl:otherwise>
				<td headers="line-indicator lineCoverage">
					<meter value="{$lineRatePc}" min="0" max="100" low="{$medlimit}" high="{$hilimit}" optimum="100">
						<xsl:value-of select="concat($lineRatePc, '%')"/>
					</meter>
				</td>
			</xsl:otherwise>
		</xsl:choose>
		<td headers="line-percent lineCoverage">
			<xsl:if test="$colorCode">
				<xsl:attribute name="class">
					<xsl:value-of select="$lineClass"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:value-of select="concat($lineRatePc, '%')"/>
		</td>
		<td headers="line-ratio lineCoverage">
			<xsl:if test="$colorCode">
				<xsl:attribute name="class">
					<xsl:value-of select="$lineClass"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:value-of select="concat(@lines-hit, '/', $linesValid)"/>
		</td>
		
		<td headers="function-percent functions">
			<xsl:if test="$colorCode">
				<xsl:attribute name="class">
					<xsl:value-of select="$funcClass"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="string(number($funcRatePc))='NaN'">
					<xsl:text>-</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($funcRatePc, '%')"/>
				</xsl:otherwise>
			</xsl:choose>
		</td>
		<td headers="function-ratio functions">
			<xsl:if test="$colorCode">
				<xsl:attribute name="class">
					<xsl:value-of select="$funcClass"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:value-of select="concat(@functions-hit, '/', $functionsValid)"/>
		</td>
		
		<td headers="branch-percent branches">
			<xsl:if test="$colorCode">
				<xsl:attribute name="class">
					<xsl:value-of select="$branchClass"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="string(number($branchRatePc))='NaN'">
					<xsl:text>-</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($branchRatePc, '%')"/>
				</xsl:otherwise>
			</xsl:choose>
		</td>
		<td headers="branch-ratio branches">
			<xsl:if test="$colorCode">
				<xsl:attribute name="class">
					<xsl:value-of select="$branchClass"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:value-of select="concat(@branches-hit, '/', $branchesValid)"/>
		</td>
	</xsl:template>

	<xsl:template match="functions">
		<xsl:variable name="canSort" select="(count(function) &gt; 1 and $sort)"/>
		<table class="functionCoverage">
			<thead>
				<tr>
					<th>
						<xsl:if test="$canSort">
							<xsl:attribute name="class">
								<xsl:text>sortable</xsl:text>
							</xsl:attribute>
							<xsl:attribute name="aria-sort">
								<xsl:text>ascending</xsl:text>
							</xsl:attribute>
							<xsl:call-template name="sortControl"/>
						</xsl:if>
						<xsl:text>Function Name</xsl:text>
					</th>
					<th>
						<xsl:if test="$canSort">
							<xsl:attribute name="class">
								<xsl:text>sortable</xsl:text>
							</xsl:attribute>
							<xsl:call-template name="sortControl"/>
						</xsl:if>
						<xsl:text>Hits</xsl:text>
					</th>
				</tr>
			</thead>
			<tbody>
				<xsl:apply-templates select="function">
					<xsl:sort select="@name"/>
				</xsl:apply-templates>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template match="function">
		<tr>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="@hits = 0">
						<xsl:text>coverFnLo</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>coverFn</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<td>
				<xsl:call-template name="buildLinkToFile">
					<xsl:with-param name="text" select="@name"/>
					<xsl:with-param name="suffix" select="$sourceFileSuffix"/>
					<xsl:with-param name="anchor" select="concat('#line', @line-number)"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:value-of select="@hits"/>
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="lines">
		<table class="coverage" title="Each row represents a line of source code">
			<caption>Each row represents a line of source code</caption>
			<thead>
				<tr>
					<th>Line</th>
					<th>Branch</th>
					<th>Hits</th>
					<th>Source code</th>
				</tr>
			</thead>
			<tbody>
				<xsl:choose>
					<xsl:when test="count(line) &gt; 0">
						<xsl:apply-templates select="line"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="writeSourceLine">
							<xsl:with-param name="hits" select="0"/>
							<xsl:with-param name="text" select="'(missing file)'"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template match="line">
		<xsl:call-template name="writeSourceLine">
			<xsl:with-param name="hits" select="@hits"/>
			<xsl:with-param name="text" select="code"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="writeSourceLine">
		<xsl:param name="hits"/>
		<xsl:param name="text"/>
		<tr>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="$hits = 0">
						<xsl:text>lineNoCov</xsl:text>
					</xsl:when>
					<xsl:when test="$hits &gt; 0">
						<xsl:text>lineCov</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>noop</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="title">
				<xsl:value-of select="concat('Line ', position())"/>
			</xsl:attribute>
			<xsl:attribute name="id">
				<xsl:value-of select="concat('line', position())"/>
			</xsl:attribute>
			<td>
				<xsl:value-of select="position()"/>
			</td>
			<td>
				<xsl:apply-templates select="branch"/>
			</td>
			<td>
				<xsl:value-of select="$hits"/>
			</td>
			<td>
				<code>
					<xsl:value-of select="$text"/>
				</code>
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="branch">
		<xsl:variable name="summary">
			<xsl:value-of select="concat('Branch ', @number, ' was ')"/>
			<xsl:choose>
				<xsl:when test="@taken &gt; 0">
					<xsl:value-of select="concat('taken ', @taken, ' times')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>not taken</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<span title="{$summary}">
			<xsl:attribute name="class">
				<xsl:text>branch</xsl:text>
				<xsl:choose>
					<xsl:when test="@taken &gt; 0">
						<xsl:text> taken</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> noTaken</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<!--<xsl:value-of select="$summary"/>-->
		</span>
	</xsl:template>

	<xsl:template name="getClassForRate">
		<xsl:param name="pc"/>
		<xsl:choose>
			<xsl:when test="string(number($pc))='NaN'">
				<xsl:text>high</xsl:text>
			</xsl:when>
			<xsl:when test="$pc &lt; $medlimit">
				<xsl:text>low</xsl:text>
			</xsl:when>
			<xsl:when test="$pc &lt; $hilimit">
				<xsl:text>med</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>high</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="comment()">
		<xsl:copy-of select="."/>
	</xsl:template>

	<xsl:template name="buildLinkToFile">
		<xsl:param name="text"/>
		<xsl:param name="suffix"/>
		<xsl:param name="anchor" select="''"/>
		<a>
			<xsl:attribute name="href">
				<xsl:value-of select="concat(/coverage/@filename, $suffix, $ext, $anchor)"/>
			</xsl:attribute>
			<xsl:value-of select="$text"/>
		</a>
	</xsl:template>

</xsl:stylesheet>
