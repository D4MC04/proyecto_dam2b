// Pestaña Diálogos: textos de translations/textos.csv (keys,es,en) agrupados por diálogo, es y en lado a lado.
// Guardar cambia solo las filas editadas: el resto del archivo se queda byte a byte igual.
"use strict";

const DialogsTab = (() => {
	const CSV_PATH = "translations/textos.csv";
	const LANGS = ["es", "en"];
	// Cada diálogo, en el orden en que se enseñan. Lo que no encaja en ninguno va a "el resto de claves".
	const GROUPS = [
		{ id: "intro", label: "Llamada de NOVA (INTRO_CALL_*)", test: (k) => k.startsWith("INTRO_CALL_") },
		{ id: "station", label: "Tutorial: estación (TUTORIAL_STATION*)", test: (k) => k.startsWith("TUTORIAL_STATION") },
		{ id: "upgrade", label: "Tutorial: mejora (TUTORIAL_UPGRADE_*)", test: (k) => k.startsWith("TUTORIAL_UPGRADE_") },
		{ id: "powers", label: "Tutorial: poderes (TUTORIAL_POWERS_*)", test: (k) => k.startsWith("TUTORIAL_POWERS_") },
		{ id: "tutorial", label: "Tutorial del nivel de emergencia (TUTORIAL_*)", test: (k) => k.startsWith("TUTORIAL_") },
		{ id: "office", label: "Tutorial de la oficina (OFFICE_TUTORIAL_*)", test: (k) => k.startsWith("OFFICE_TUTORIAL_") },
	];
	// Una línea es "bastante más larga" si pasa de LONG_FACTOR veces la media de las demás de su diálogo.
	const LONG_FACTOR = 1.5;
	const LONG_MIN = 60;

	let header = [];
	let rows = []; // {key, cells: {es, en}} en el orden del archivo
	let container = null;
	let bodyEl = null;
	let query = "";
	let showAll = false;
	let savedNotice = false;
	const widgets = []; // {row, lang, group, area, counter, cell}

	// --- CSV con posiciones: cada celda recuerda su trozo exacto del texto ---

	// Devuelve filas de celdas {value, start, end} (end exclusivo, comillas incluidas).
	function scanCsv(src) {
		const out = [];
		let i = 0;
		while (i < src.length) {
			const row = { cells: [] };
			while (true) {
				const cell = { start: i, value: "", end: i };
				if (src[i] === '"') {
					i++;
					while (i < src.length) {
						if (src[i] === '"' && src[i + 1] === '"') {
							cell.value += '"';
							i += 2;
						} else if (src[i] === '"') {
							i++;
							break;
						} else {
							cell.value += src[i++];
						}
					}
				} else {
					while (i < src.length && src[i] !== "," && src[i] !== "\n" && src[i] !== "\r") {
						cell.value += src[i++];
					}
				}
				cell.end = i;
				row.cells.push(cell);
				if (src[i] === ",") {
					i++;
					continue;
				}
				break;
			}
			if (src[i] === "\r" && src[i + 1] === "\n") {
				i += 2;
			} else if (src[i] === "\n" || src[i] === "\r") {
				i++;
			}
			out.push(row);
		}
		return out;
	}

	// Una celda lleva comillas solo si las necesita (coma, comilla o salto de línea).
	function quoteCell(value, lineEnd) {
		const v = value.replace(/\r\n|\r|\n/g, "\n");
		const body = v.replace(/\n/g, lineEnd);
		if (/[",\n]/.test(v)) {
			return '"' + body.replace(/"/g, '""') + '"';
		}
		return body;
	}

	// Cambia una celda de la fila de la clave dada, sin tocar nada más.
	function replaceCell(src, key, column, value) {
		const lineEnd = src.includes("\r\n") ? "\r\n" : "\n";
		const parsed = scanCsv(src);
		const row = parsed.find((r, idx) => idx > 0 && r.cells[0].value === key);
		if (!row || !row.cells[column]) {
			throw new Error(`No encuentro la clave ${key} en ${CSV_PATH}.`);
		}
		const cell = row.cells[column];
		return src.slice(0, cell.start) + quoteCell(value, lineEnd) + src.slice(cell.end);
	}

	// --- Carga ---

	async function load() {
		const text = await Project.readText(CSV_PATH);
		const parsed = scanCsv(text);
		header = parsed.length ? parsed[0].cells.map((c) => c.value) : [];
		if (!header.includes("es") || !header.includes("en")) {
			throw new Error(`${CSV_PATH} no tiene las columnas es y en.`);
		}
		rows = [];
		for (const r of parsed.slice(1)) {
			const key = r.cells[0].value;
			if (key === "") {
				continue;
			}
			const cells = {};
			for (const lang of LANGS) {
				const column = header.indexOf(lang);
				cells[lang] = r.cells[column] ? r.cells[column].value.replace(/\r\n|\r/g, "\n") : "";
			}
			rows.push({ key, cells });
		}
	}

	// --- Referencias editables (una por clave e idioma) ---

	function refFor(row, lang) {
		const column = header.indexOf(lang);
		return {
			path: CSV_PATH,
			sub: "csv",
			key: `${row.key}|${lang}`,
			type: "string",
			read: () => row.cells[lang],
			write: (src, value) => replaceCell(src, row.key, column, value),
		};
	}

	// --- Agrupar ---

	function trailingNumber(key) {
		const m = /_(\d+)$/.exec(key);
		return m ? parseInt(m[1], 10) : null;
	}

	function buildGroups() {
		const groups = GROUPS.map((g) => ({ ...g, rows: [] }));
		const others = { id: "others", label: "Resto de claves", rows: [], extra: true };
		for (const row of rows) {
			const group = groups.find((g) => g.test(row.key));
			(group || others).rows.push(row);
		}
		for (const g of groups) {
			// En el orden de sus números si todas lo llevan; si no, el del archivo (que es el del tutorial).
			if (g.rows.length > 1 && g.rows.every((r) => trailingNumber(r.key) !== null)) {
				g.rows.sort((a, b) => trailingNumber(a.key) - trailingNumber(b.key));
			}
		}
		return [...groups, others];
	}

	// Caracteres de un texto; si lleva "|" (páginas del tutorial) cuenta también la página más larga.
	function measure(value) {
		const pages = value.split("|");
		return { total: value.length, longest: Math.max(...pages.map((p) => p.length)), pages: pages.length };
	}

	// ¿Es la línea bastante más larga que la media de las demás de su diálogo?
	function isLong(group, row, lang) {
		const mine = measure(Project.value(refFor(row, lang))).longest;
		const others = group.rows.filter((r) => r !== row).map((r) => measure(Project.value(refFor(r, lang))).longest);
		if (group.extra || others.length < 2 || mine < LONG_MIN) {
			return false;
		}
		const mean = others.reduce((a, b) => a + b, 0) / others.length;
		return mine > mean * LONG_FACTOR;
	}

	// --- Pintar ---

	function matches(row) {
		if (query === "") {
			return true;
		}
		const q = query.toLowerCase();
		const value = (lang) => Project.value(refFor(row, lang)).toLowerCase();
		return row.key.toLowerCase().includes(q) || value("es").includes(q) || value("en").includes(q);
	}

	function counterText(group, row, lang) {
		const m = measure(Project.value(refFor(row, lang)));
		const base = m.pages > 1 ? `${m.total} car. · página más larga ${m.longest}` : `${m.total} car.`;
		return isLong(group, row, lang) ? `${base} ⚠ larga` : base;
	}

	function buildToolbar() {
		const bar = document.createElement("div");
		bar.className = "dialogs-toolbar";
		const search = document.createElement("input");
		search.type = "search";
		search.placeholder = "Buscar por clave o texto…";
		search.value = query;
		search.addEventListener("input", () => {
			query = search.value;
			renderBody();
		});
		const label = document.createElement("label");
		const toggle = document.createElement("input");
		toggle.type = "checkbox";
		toggle.checked = showAll;
		toggle.addEventListener("change", () => {
			showAll = toggle.checked;
			renderBody();
		});
		label.append(toggle, " Todos los textos");
		bar.append(search, label);
		return bar;
	}

	function render(panel) {
		container = panel || container;
		container.innerHTML = "";
		const note = document.createElement("p");
		note.className = "dialogs-notice";
		note.id = "dialogs-notice";
		const hint = document.createElement("p");
		hint.className = "hint-line";
		hint.textContent = "El juego lee los .translation que Godot genera al importar textos.csv: tras guardar hay que reimportar (ver docs/CLAUDE-CODE.md). El recuadro del diálogo es fijo: una línea marcada ⚠ es bastante más larga que las demás de su diálogo. «|» separa páginas.";
		bodyEl = document.createElement("div");
		container.append(note, hint, buildToolbar(), bodyEl);
		renderBody();
		updateNotice();
	}

	function renderBody() {
		bodyEl.innerHTML = "";
		widgets.length = 0;
		let shown = 0;
		for (const group of buildGroups()) {
			if (group.extra && !showAll) {
				continue;
			}
			const visible = group.rows.filter(matches);
			if (visible.length === 0) {
				continue;
			}
			const section = document.createElement("section");
			section.className = "dialog-group";
			const h = document.createElement("h3");
			h.textContent = `${group.label} · ${visible.length}`;
			section.appendChild(h);
			for (const row of visible) {
				section.appendChild(buildRow(group, row));
				shown++;
			}
			bodyEl.appendChild(section);
		}
		if (shown === 0) {
			const empty = document.createElement("p");
			empty.className = "placeholder";
			empty.textContent = query ? "Ningún texto coincide con la búsqueda (prueba «Todos los textos»)." : "No hay textos.";
			bodyEl.appendChild(empty);
		}
	}

	function buildRow(group, row) {
		const wrap = document.createElement("div");
		wrap.className = "dialog-row";
		const key = document.createElement("div");
		key.className = "dialog-key";
		key.textContent = row.key;
		wrap.appendChild(key);
		for (const lang of LANGS) {
			const cell = document.createElement("div");
			cell.className = "dialog-cell";
			const area = document.createElement("textarea");
			const value = Project.value(refFor(row, lang));
			area.rows = Math.max(2, Math.min(8, Math.ceil(value.length / 48) + value.split("\n").length - 1));
			area.value = value;
			area.title = `${row.key} (${lang})`;
			const counter = document.createElement("div");
			counter.className = "dialog-counter";
			cell.append(area, counter);
			wrap.appendChild(cell);
			area.addEventListener("input", () => {
				Project.setValue(refFor(row, lang), area.value);
			});
			const widget = { row, lang, group, area, counter, cell };
			widgets.push(widget);
			paintWidget(widget);
		}
		return wrap;
	}

	function paintWidget(w) {
		const r = refFor(w.row, w.lang);
		w.cell.classList.toggle("changed", Project.isEdited(r));
		const text = counterText(w.group, w.row, w.lang);
		w.counter.textContent = text;
		w.counter.classList.toggle("long", text.includes("⚠"));
		// Tras descartar, el textarea vuelve al valor original (sin pisar lo que se está escribiendo).
		if (document.activeElement !== w.area && w.area.value !== Project.value(r)) {
			w.area.value = Project.value(r);
		}
	}

	function refresh() {
		for (const w of widgets) {
			paintWidget(w);
		}
		updateNotice();
	}

	function updateNotice() {
		const el = document.getElementById("dialogs-notice");
		if (!el) {
			return;
		}
		el.hidden = true;
		if (Project.pendingPaths.includes(CSV_PATH)) {
			el.textContent = "Cambios sin guardar en textos.csv.";
			el.hidden = false;
		} else if (savedNotice) {
			el.textContent = "Guardado. El juego aún usa los textos viejos: hay que reimportar textos.csv para regenerar los .translation (abre el editor de Godot una vez, o ejecuta «Godot --headless --import --path .» en la carpeta del juego).";
			el.hidden = false;
		}
	}

	// Tras guardar el CSV se vuelve a leer y se avisa de que hay que reimportar.
	async function onSaved(paths) {
		if (paths.includes(CSV_PATH)) {
			await load();
			savedNotice = true;
			if (container) {
				render();
			}
		}
	}

	return { id: "dialogs", label: "Diálogos", load, render, refresh, onSaved, replaceCell, scanCsv };
})();

if (typeof module !== "undefined") {
	module.exports = DialogsTab;
}
