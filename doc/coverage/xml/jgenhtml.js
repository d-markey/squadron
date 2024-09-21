/*
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
 */
(function()
{
	"use strict";  // is there any other mode?

	/**
	 * Common "global" stuff goes in this scope.
	 */

	(function(){
		/**
		 * Remove the "noscript" class if we are able to execute javascript.
		 */
		if (document.addEventListener)
		{
			document.addEventListener("DOMContentLoaded", function(){document.body.classList.remove("noscript");}, false);
		}
	})();

	(function()
	{
		/**
		 * Everything in this scope is related to the feature controls.
		 */
		var timer;

		if (document.addEventListener)  // the one and only concession to IE8, no functionality but no JS error either
		{
			document.addEventListener("DOMContentLoaded", initialize, false);
		}

		/**
		 * Wire up event listeners etc when the document is ready.
		 */
		function initialize()
		{
			var container = getContainer();
			if (container)
			{
				container.addEventListener("click", clickEvent, false);
			}
		}

		/**
		 * @return The container element for the feature controls.
		 */
		function getContainer()
		{
			return document.querySelector("div.controls");
		}

		/**
		 * Checks the state of all the controls and applies the necessary css classes.
		 */
		function updateState()
		{
			var chkboxes, len, i, next, action, container = getContainer();
			if (container)
			{
				chkboxes = container.querySelectorAll("input[type='checkbox']");
				if ((len = chkboxes.length))
				{
					for(i=0; i<len; i++)
					{
						next = chkboxes[i];
						if (next.checked)
						{
							action = "remove";
						}
						else
						{
							action = "add";
						}
						document.body.classList[action](next.id);
					}
				}
			}
		}

		/**
		 * Handle click events on controls.
		 */
		function clickEvent($event)
		{
			var element = $event.target;
			if (element.type == "checkbox")
			{
				if (timer)
				{
					window.clearTimeout(timer);
				}
				timer = window.setTimeout(updateState, 250);
			}
		}
	})();

	(function()
	{
		/**
		 * Show Details control.
		 */
		if (document.addEventListener)
		{
			document.addEventListener("DOMContentLoaded", initialize, false);
		}

		/**
		 * Wire up event listeners etc when the document is ready.
		 */
		function initialize()
		{
			document.body.addEventListener("click", clickEvent, true);
		}

		/**
		 * Handle click events on show details button.
		 */
		function clickEvent($event)
		{
			var element = $event.target;
			if (element.type === "button" && element.classList.contains("showDetails"))
			{
				$event.preventDefault();
				document.body.classList.toggle("showDetails");
			}
		}
	})();

	(function(){

		/**
		 * Idiotically generic table sort.
		 * TODO I went a bit overboard here. Simplify it by tailoring it to the specific sorting needed.
		 */
		var type = {
				NUMERIC:1,
				ALPHA:2,
				OTHER:4,
				EMPTY:8,
				DUPLICATE: 16
			};

		if (document.addEventListener)  // the one and only concession to IE8, no functionality but no JS error either
		{
			document.addEventListener("DOMContentLoaded", initialize, false);
		}

		/**
		 * Wire up the event listeners etc
		 */
		function initialize()
		{
			var container = getContainer();
			if (container)
			{
				document.body.classList.remove("noscript");
				container.addEventListener("click", clickEvent, false);
			}
		}

		/**
		 * Get the container which contains sortable columns.
		 * Could be anything, even the body element.
		 */
		function getContainer()
		{
			return document.querySelector("table.index, table.coverage, table.functionCoverage");
		}

		/**
		 * Handle the click event - works out if you clicked on a sortable table header or not.
		 */
		function clickEvent($event)
		{
			if (!$event.defaultPrevented)
			{
				var element = getAncestorOrSelf($event.target, "th");
				if (element && element.classList.contains("sortable"))
				{
					sortForHeaderCell(element);
				}
			}
		}

		/**
		 * For the given header cell sort the table based on its column/s.
		 */
		function sortForHeaderCell(element)
		{
			var i, j, col, cell, descending, prevSorted, sortedCol, len, text, same,
				cols = [],
				indices = getStartAndEnd(element),
				table = getAncestorOrSelf(element, "table"),
				rows = table.querySelectorAll("tbody tr:not(.bound)");

			for(i = indices.start; i <= indices.end; i++)
			{
				cols[cols.length] = (col= []);
				col.type = 0;
				same = true;
				for(j=0, len=rows.length; j<len; j++)
				{
					cell = getCellAtIdx(rows[j], i);
					if (cell)
					{
						text = cell.textContent;
						col.type |= getTypeForContent(text);
						if (same && col.length > 0)
						{
							if (col[col.length - 1].textContent !== text)
							{
								same = false;
							}
						}
						col[col.length] = cell;
					}
				}
				if (same)
				{
					col.type |= type.DUPLICATE;
				}
			}
			if (element.hasAttribute("aria-sort"))
			{
				descending = (element.getAttribute("aria-sort") === "ascending");
			}
			else
			{
				prevSorted = table.querySelector("thead th[aria-sort]");
				if (prevSorted)
				{
					descending = (prevSorted.getAttribute("aria-sort") === "ascending");
					prevSorted.removeAttribute("aria-sort");
				}
				else
				{
					prevSorted = false;
				}
			}
			sortedCol = sortColumns(cols, descending);
			element.setAttribute("aria-sort", descending? "descending" : "ascending");
			if (!(sortedCol.type & (type.EMPTY | type.DUPLICATE)))
			{
				rearrangeRows(sortedCol);
			}
		}

		/**
		 * Rearranged the table rows based on the order of the cells in this array.
		 * @param {array} sortedCol A sorted array of table cells.
		 */
		function rearrangeRows(sortedCol)
		{
			var i, cell, row, tbody, len, next, saved, rowPtr;
			if (sortedCol)
			{
				for(i = 0, len = sortedCol.length; i < len; i++)
				{
					cell = sortedCol[i];
					row = cell.parentNode;
					tbody = row.parentNode;
					rowPtr = tbody.rows[i];
					while ((next = row.nextElementSibling))
					{
						if (next.classList.contains("bound"))
						{
							saved = row["data-savedrows"] || (row["data-savedrows"] = []);
							saved[saved.length] = next.parentNode.removeChild(next);
							window.setTimeout(rejoinRow.bind(row), 0);
						}
						else
						{
							break;
						}
					}
					if (rowPtr !== row)
					{
						tbody.insertBefore(row, rowPtr);
					}
				}
			}
		}

		function rejoinRow()
		{
			var next, saved = this["data-savedrows"];
			while ((next = saved.pop()))
			{
				if (this.nextSibling)
				{
					this.parentNode.insertBefore(next, this.nextSibling);
				}
				else
				{
					this.parentNode.appendChild(next);
				}
			}

		}

		/**
		 * Find the best column to sort on and sort it.
		 * @param {array} cols An array of arrays of table cells.
		 * @param {boolean} desc True if the sort should be descending.
		 * @return {array} The column chosen for sorting - sorted.
		 */
		function sortColumns(cols, desc)
		{
			var i, col, bestType = 0, bestCol, result;
			for(i=0; i<cols.length; i++)
			{
				col = cols[i];
				if (col.type === type.NUMERIC)
				{
					result = col.sort(compareNumeric);
					break;  // go home, numeric is great
				}
				else if (!bestType || col.type < bestType)
				{
					bestCol = col;
				}
			}
			result = result || (bestCol? bestCol.sort(compareDictionary) : null);
			if (result && desc)
			{
				result = result.reverse();
			}
			return result;
		}

		/**
		 * A sort function for comparing cells as strings.
		 * @param {Element} a A table cell.
		 * @param {Element} b A table cell.
		 * @return The result of the comparison as required for an array sort.
		 */
		function compareDictionary(a, b)
		{
			var result, sA = a.textContent,
				sB = b.textContent;
			if (sA < sB)
			{
				result = -1;
			}
			else if (sA > sB)
			{
				result = 1;
			}
			else
			{
				result = 0;
			}
			return result;
		}

		/**
		 * A sort function for comparing cells as numbers.
		 * @param {Element} a A table cell.
		 * @param {Element} b A table cell.
		 * @return The result of the comparison as required for an array sort.
		 */
		function compareNumeric(a, b)
		{
			var numA = getNumeric(a.textContent),
				numB = getNumeric(b.textContent);
			return numA - numB;
		}

		/**
		 * Get the best sort type for this data.
		 * @param {string} text the text content of a table cell.
		 * @return a sort type from the "type" bitmask.
		 */
		function getTypeForContent(text)
		{
			var result = type.EMPTY;
			if (text || text === 0)
			{
				if (getNumeric(text) !== null)
				{
					result = type.NUMERIC;
				}
				else if (/^[a-z]+$/i.test(text))
				{
					result = type.ALPHA;
				}
				else
				{
					result = type.OTHER;
				}
			}
			return result;
		}

		/**
		 * Get the numeric value of the arg.
		 * @param {string} arg A string which may contain a numeric value.
		 * @return {number|null} The numeric value or null if it can not be parsed.
		 */
		function getNumeric(arg)
		{
			var result = null, len;
			if (isNaN(arg * 1))
			{
				len = arg.length;
				if (len && (arg.substr(len - 1, 1) === "%"))
				{
					result = arg.substr(0, len -1);
				}
			}
			else
			{
				result = arg;
			}
			return result;
		}

		/**
		 * Gets the table cell at the given index, ACCOUNTING FOR COLSPANS.
		 * This is NOT the same thing as cellIndex. If a cell spans two columns
		 * it will be returned for both the indices it spans. Since it spans two
		 * columns it should be involved in a sort for either/both of those cols.
		 * @param {element} row A table row
		 * @param {number} idx The index of the cell to return.
		 * @return {Element} The table cell at the specified index.
		 */
		function getCellAtIdx(row, idx)
		{
			var result, next, i, len, fakeIdx = 0, cells = row.querySelectorAll("td, th");
			for(i=0, len=cells.length; i < len; i++)
			{
				next = cells[i];
				if (fakeIdx === idx)
				{
					result = next;
					break;
				}
				else if (next.colSpan)
				{
					fakeIdx += next.colSpan;
					if (idx < fakeIdx)
					{
						result = next;
						break;
					}
				}
				else
				{
					fakeIdx++;
				}
			}
			return result;
		}

		/**
		 * Get the indices spanned by this cell - intended for use with TH elements.
		 * @param {Element} cell A table cell, especially a th cell.
		 * @return An object with two properties:
		 * start - the first index spanned by the cell,
		 * end - the last index spanned by the cell.
		 * These values may (most likely will) be the same value.
		 */
		function getStartAndEnd(cell)
		{
			var next, i, row = cell.parentNode, len,
				cellIdx = 0, start = -1, end = -1, cells = row.querySelectorAll("td, th");
			for(i=0, len = cells.length; i < len; i++)
			{
				next = cells[i];
				if (next === cell)
				{
					start = cellIdx;
					end = cellIdx + ((next.colSpan - 1) || 0);
					break;
				}
				cellIdx += ((next.colSpan) || 1);
			}
			return { start:start, end:end };
		}
	})();

	/**
	 * @param element The starting element.
	 * @param tagName The tag name we are looking for.
	 */
	function getAncestorOrSelf(element, tagName)
	{
		var next = element,
			tn = tagName.toLowerCase();
		while (next && (next.nodeType === Node.ELEMENT_NODE || (next = null)) && next.tagName.toLowerCase() !== tn)
		{
			next = next.parentNode;
		}
		return next;
	}

})();
