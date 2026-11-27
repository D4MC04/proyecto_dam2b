// Tabla ordenable con celdas editables. Cada columna es:
// {id, label, title, group, ref(row) -> ref editable, get(row) -> valor calculado, format(v, row),
//  cellTitle(row) -> tooltip, shared(row) -> aviso si el archivo lo comparten varias filas, sticky, cls,
//  warn(row) -> true para marcar la celda en rojo}
// options: {onRowClick(row), isSelected(row)} para tablas con una fila elegida.
"use strict";

const BalanceTable = (() => {
	function formatNumber(value, decimals) {
		if (typeof value !== "number" || !isFinite(value)) {
			return value === undefined || value === null ? "" : String(value);
		}
		return value.toLocaleString("es-ES", { maximumFractionDigits: decimals === undefined ? 2 : decimals });
	}

	function cellValue(col, row) {
		if (col.ref) {
			const r = col.ref(row);
			return r ? Project.value(r) : undefined;
		}
		return col.get ? col.get(row) : undefined;
	}

	function isEmpty(value) {
		return value === undefined || value === null || value === "" || (typeof value === "number" && !isFinite(value));
	}

	function compare(a, b) {
		if (typeof a === "number" && typeof b === "number") {
			return a - b;
		}
		return String(a).localeCompare(String(b), "es");
	}

	function create(container, columns, rows, options) {
		const table = { columns, rows, options: options || {}, sortIndex: -1, sortDir: 0, cells: [], trs: [] };
		const el = document.createElement("table");
		el.className = "balance-table";
		el.appendChild(buildHead(table));
		const tbody = document.createElement("tbody");
		rows.forEach((row, rowIndex) => {
			const tr = document.createElement("tr");
			tr.className = row.rowClass || "";
			columns.forEach((col) => tr.appendChild(buildCell(table, col, row)));
			if (table.options.onRowClick) {
				tr.classList.add("clickable");
				tr.addEventListener("click", () => table.options.onRowClick(row));
			}
			table.trs.push({ tr, row, rowIndex });
			tbody.appendChild(tr);
		});
		el.appendChild(tbody);
		table.tbody = tbody;
		container.replaceChildren(el);
		refresh(table);
		return { refresh: () => refresh(table) };
	}

	function buildHead(table) {
		const thead = document.createElement("thead");
		const hasGroups = table.columns.some((c) => c.group);
		if (hasGroups) {
			const groupRow = document.createElement("tr");
			groupRow.className = "group-row";
			let i = 0;
			while (i < table.columns.length) {
				const group = table.columns[i].group || "";
				let span = 1;
				while (i + span < table.columns.length && (table.columns[i + span].group || "") === group) {
					span++;
				}
				const th = document.createElement("th");
				th.colSpan = span;
				th.textContent = group;
				if (group) {
					th.className = "group";
				}
				if (table.columns[i].sticky) {
					th.classList.add("sticky");
				}
				groupRow.appendChild(th);
				i += span;
			}
			thead.appendChild(groupRow);
		}
		const labelRow = document.createElement("tr");
		table.columns.forEach((col, index) => {
			const th = document.createElement("th");
			th.textContent = col.label;
			th.title = (col.title ? col.title + "\n" : "") + "Pulsa para ordenar.";
			th.className = (col.sticky ? "sticky " : "") + (col.ref ? "editable" : col.get ? "computed" : "");
			th.addEventListener("click", () => sortBy(table, index));
			col.th = th;
			labelRow.appendChild(th);
		});
		thead.appendChild(labelRow);
		return thead;
	}

	function buildCell(table, col, row) {
		const td = document.createElement("td");
		if (col.sticky) {
			td.classList.add("sticky");
		}
		if (col.cls) {
			td.classList.add(col.cls);
		}
		const r = col.ref ? col.ref(row) : null;
		const cell = { td, col, row, ref: r, input: null };
		if (r) {
			const input = document.createElement("input");
			input.type = "number";
			input.step = r.type === "int" ? "1" : "any";
			input.addEventListener("input", () => onInput(cell));
			input.addEventListener("keydown", (e) => {
				if (e.key === "Enter") {
					input.blur();
				}
			});
			// Al salir de una celda inválida vuelve a enseñar el valor guardado.
			input.addEventListener("blur", () => refreshCell(cell, true));
			td.appendChild(input);
			cell.input = input;
			td.classList.add("editable");
		} else if (col.ref) {
			td.classList.add("empty");
		} else {
			td.classList.add("computed");
		}
		table.cells.push(cell);
		return td;
	}

	function onInput(cell) {
		const text = cell.input.value.trim();
		const value = Number(text);
		const valid = text !== "" && isFinite(value) && (cell.ref.type !== "int" || Number.isInteger(value));
		cell.td.classList.toggle("invalid", !valid);
		if (valid) {
			Project.setValue(cell.ref, value);
		}
	}

	function refreshCell(cell, force) {
		const { td, col, row, ref, input } = cell;
		if (input) {
			const value = Project.value(ref);
			if (force || document.activeElement !== input) {
				input.value = value === undefined ? "" : String(value);
				td.classList.remove("invalid");
			}
			td.classList.toggle("changed", Project.isEdited(ref));
			td.classList.toggle("default", Project.isDefault(ref) && !Project.isEdited(ref));
		} else if (!col.ref) {
			const value = col.get ? col.get(row) : undefined;
			td.textContent = col.format ? col.format(value, row) : formatNumber(value);
		}
		const tips = [];
		if (input && Project.isDefault(ref)) {
			tips.push("No está en el .tres: vale lo de por defecto del script. Al guardar se añade la línea.");
		}
		td.classList.toggle("warn", !!(col.warn && col.warn(row)));
		const shared = col.shared ? col.shared(row) : null;
		td.classList.toggle("shared", !!shared);
		if (shared) {
			tips.push(shared);
		}
		if (col.cellTitle) {
			const tip = col.cellTitle(row);
			if (tip) {
				tips.push(tip);
			}
		}
		td.title = tips.join("\n");
	}

	function refresh(table) {
		for (const cell of table.cells) {
			refreshCell(cell, false);
		}
		if (table.options.isSelected) {
			for (const item of table.trs) {
				item.tr.classList.toggle("selected", !!table.options.isSelected(item.row));
			}
		}
	}

	// Ascendente, descendente y vuelta al orden agrupado.
	function sortBy(table, index) {
		if (table.sortIndex === index) {
			table.sortDir = table.sortDir === 1 ? -1 : table.sortDir === -1 ? 0 : 1;
		} else {
			table.sortIndex = index;
			table.sortDir = 1;
		}
		table.columns.forEach((col, i) => {
			col.th.classList.toggle("sort-asc", i === index && table.sortDir === 1);
			col.th.classList.toggle("sort-desc", i === index && table.sortDir === -1);
		});
		const col = table.columns[index];
		const ordered = table.trs.slice();
		if (table.sortDir !== 0) {
			ordered.sort((a, b) => {
				const valueA = cellValue(col, a.row);
				const valueB = cellValue(col, b.row);
				const emptyA = isEmpty(valueA);
				const emptyB = isEmpty(valueB);
				// Los vacíos siempre al final, ordene hacia donde ordene.
				if (emptyA || emptyB) {
					return emptyA === emptyB ? a.rowIndex - b.rowIndex : emptyA ? 1 : -1;
				}
				return compare(valueA, valueB) * table.sortDir || a.rowIndex - b.rowIndex;
			});
		}
		table.tbody.classList.toggle("sorted", table.sortDir !== 0);
		for (const item of ordered) {
			table.tbody.appendChild(item.tr);
		}
	}

	return { create, formatNumber };
})();
