// Lector y escritor mínimo de archivos .tres de Godot 4, de scripts .gd (para los @export) y de CSV.
// Al escribir solo toca la línea del campo: uid, ext_resource y el resto del archivo quedan igual.
"use strict";

const Tres = (() => {
	const HEADER_RE = /^\[(\w+)(.*)\]\s*$/;
	const ATTR_RE = /(\w+)=("([^"]*)"|[^\s\]]+)/g;
	const PROP_RE = /^([A-Za-z_][\w/]*)\s*=\s*(.*)$/;

	// Sigue las comillas y los paréntesis, corchetes y llaves de un trozo de valor y devuelve el estado
	// {depth, inString} al final: si sigue abierto, el valor continúa en la línea siguiente.
	function openState(text, state) {
		let { depth, inString } = state || { depth: 0, inString: false };
		for (let i = 0; i < text.length; i++) {
			const c = text[i];
			if (inString) {
				if (c === "\\") {
					i++;
				} else if (c === '"') {
					inString = false;
				}
			} else if (c === '"') {
				inString = true;
			} else if (c === "(" || c === "[" || c === "{") {
				depth++;
			} else if (c === ")" || c === "]" || c === "}") {
				depth--;
			}
		}
		return { depth, inString };
	}

	function isOpen(state) {
		return state.inString || state.depth > 0;
	}

	function parseAttrs(text) {
		const attrs = {};
		for (const m of text.matchAll(ATTR_RE)) {
			attrs[m[1]] = m[3] !== undefined ? m[3] : m[2];
		}
		return attrs;
	}

	// "res://resources/x.tres" -> "resources/x.tres"
	function resToRel(path) {
		return (path || "").replace(/^res:\/\//, "");
	}

	// Escanea el texto: cabecera, ext_resource (id -> ruta) y secciones con la línea de cada propiedad.
	function scan(text) {
		const eol = text.includes("\r\n") ? "\r\n" : "\n";
		const lines = text.split(/\r?\n/);
		const doc = { lines, eol, header: {}, ext: {}, sections: [] };
		let current = null;
		// Estado del valor abierto (cadena, Dictionary o Array de varias líneas), o null.
		let open = null;
		let lastProp = null;
		for (let i = 0; i < lines.length; i++) {
			const line = lines[i];
			if (open) {
				// Continuación de un valor de varias líneas: se añade al valor crudo.
				lastProp.raw += "\n" + line;
				lastProp.endLine = i;
				open = openState(line, open);
				if (!isOpen(open)) {
					open = null;
				}
				if (current) {
					current.end = i + 1;
				}
				continue;
			}
			const header = line.match(HEADER_RE);
			if (header) {
				const attrs = parseAttrs(header[2]);
				current = null;
				if (header[1] === "gd_resource" || header[1] === "gd_scene") {
					doc.header = attrs;
				} else if (header[1] === "ext_resource") {
					doc.ext[attrs.id] = { path: resToRel(attrs.path), type: attrs.type, uid: attrs.uid || null, line: i };
				} else {
					current = { kind: header[1], id: attrs.id || null, attrs, headerLine: i, end: i + 1, props: {} };
					doc.sections.push(current);
				}
				continue;
			}
			if (!current) {
				continue;
			}
			const prop = line.match(PROP_RE);
			if (prop) {
				lastProp = { raw: prop[2], line: i, endLine: i };
				current.props[prop[1]] = lastProp;
				current.end = i + 1;
				const state = openState(prop[2]);
				if (isOpen(state)) {
					open = state;
				}
			}
		}
		return doc;
	}

	// Sección por id: null es la sección [resource].
	function findSection(doc, sectionId) {
		return doc.sections.find((s) => (sectionId === null ? s.kind === "resource" : s.kind === "sub_resource" && s.id === sectionId)) || null;
	}

	// Divide "a, b(c, d), e" por las comas de primer nivel.
	function splitTopLevel(text) {
		const parts = [];
		let depth = 0;
		let inString = false;
		let start = 0;
		for (let i = 0; i < text.length; i++) {
			const c = text[i];
			if (inString) {
				if (c === "\\") {
					i++;
				} else if (c === '"') {
					inString = false;
				}
			} else if (c === '"') {
				inString = true;
			} else if (c === "(" || c === "[" || c === "{") {
				depth++;
			} else if (c === ")" || c === "]" || c === "}") {
				depth--;
			} else if (c === "," && depth === 0) {
				parts.push(text.slice(start, i).trim());
				start = i + 1;
			}
		}
		const last = text.slice(start).trim();
		if (last !== "") {
			parts.push(last);
		}
		return parts;
	}

	// Interior de un Dictionary ("30: 0.68, 35: 0.5") -> objeto clave -> valor.
	function parseDictionary(inner) {
		const result = {};
		for (const pair of splitTopLevel(inner)) {
			// El ":" de primer nivel separa la clave del valor.
			let state = { depth: 0, inString: false };
			for (let i = 0; i < pair.length; i++) {
				if (pair[i] === ":" && !isOpen(state)) {
					result[parseValue(pair.slice(0, i))] = parseValue(pair.slice(i + 1));
					break;
				}
				state = openState(pair[i], state);
			}
		}
		return result;
	}

	// Valor crudo de una línea .tres -> número, cadena, booleano, referencia, array o diccionario.
	function parseValue(raw) {
		raw = raw.trim();
		let m = raw.match(/^ExtResource\("([^"]+)"\)$/);
		if (m) {
			return { ext: m[1] };
		}
		m = raw.match(/^SubResource\("([^"]+)"\)$/);
		if (m) {
			return { sub: m[1] };
		}
		m = raw.match(/^"([\s\S]*)"$/);
		if (m) {
			return m[1];
		}
		m = raw.match(/^Dictionary(?:\[[^\]]*\])?\(\{([\s\S]*)\}\)$/) || raw.match(/^\{([\s\S]*)\}$/);
		if (m) {
			return parseDictionary(m[1]);
		}
		m = raw.match(/^Array\[.*?\]\(\[([\s\S]*)\]\)$/) || raw.match(/^\[([\s\S]*)\]$/);
		if (m) {
			return splitTopLevel(m[1]).map(parseValue);
		}
		if (/^[-+]?(\d+\.?\d*|\.\d+)(e[-+]?\d+)?$/i.test(raw)) {
			return Number(raw);
		}
		if (raw === "inf") {
			return Infinity;
		}
		if (raw === "-inf") {
			return -Infinity;
		}
		if (raw === "true" || raw === "false") {
			return raw === "true";
		}
		if (raw === "null") {
			return null;
		}
		return raw;
	}

	// Float como lo guarda Godot: 500 -> "500.0", 0.4 -> "0.4", 1e-5 -> "1e-05".
	function formatFloat(value) {
		if (value === Infinity) {
			return "inf";
		}
		if (value === -Infinity) {
			return "-inf";
		}
		if (Number.isInteger(value) && Math.abs(value) < 1e15) {
			return value.toFixed(1);
		}
		return String(value).replace(/e([-+])(\d)$/, "e$10$2");
	}

	// Escribe un valor según el tipo del @export: "int", "float", "Array[float]" o "Dictionary[int, float]".
	function formatValue(type, value) {
		const dictMatch = type.match(/^Dictionary\[(\w+),\s*(\w+)\]$/);
		if (dictMatch) {
			// Como lo guarda Godot: un par por línea, claves ordenadas.
			const numericKeys = dictMatch[1] === "int" || dictMatch[1] === "float";
			const keys = Object.keys(value).sort((a, b) => (numericKeys ? Number(a) - Number(b) : a.localeCompare(b)));
			if (keys.length === 0) {
				return `${type}({})`;
			}
			const pairs = keys.map((k) => `${formatValue(dictMatch[1], numericKeys ? Number(k) : k)}: ${formatValue(dictMatch[2], value[k])}`);
			return `${type}({\n${pairs.join(",\n")}\n})`;
		}
		if (type === "int") {
			return String(Math.round(value));
		}
		if (type === "float") {
			return formatFloat(value);
		}
		const arrayMatch = type.match(/^Array\[(\w+)\]$/);
		if (arrayMatch) {
			const items = value.map((v) => formatValue(arrayMatch[1], v));
			return `${type}([${items.join(", ")}])`;
		}
		throw new Error(`Tipo sin escritor: ${type}`);
	}

	// Cambia (o inserta) una propiedad en el texto y devuelve el texto nuevo.
	// Si la línea no existe, se inserta en su sección antes de metadata/ (o al final de la sección).
	function setProp(text, sectionId, key, rawValue) {
		const doc = scan(text);
		const section = findSection(doc, sectionId);
		if (!section) {
			throw new Error(`No existe la sección ${sectionId === null ? "[resource]" : sectionId}`);
		}
		const lines = doc.lines.slice();
		// Un valor de varias líneas (Dictionary) se parte para que lleve el fin de línea del archivo.
		const newLines = `${key} = ${rawValue}`.split("\n");
		const prop = section.props[key];
		if (prop) {
			lines.splice(prop.line, prop.endLine - prop.line + 1, ...newLines);
		} else {
			let insertAt = section.end;
			for (const [name, p] of Object.entries(section.props)) {
				if (name.startsWith("metadata/") && p.line < insertAt) {
					insertAt = p.line;
				}
			}
			lines.splice(insertAt, 0, ...newLines);
		}
		return lines.join(doc.eol);
	}

	// --- Cambios de estructura (secciones y ext_resource nuevos o quitados) ---

	const ID_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789";

	// Id nuevo que no esté en el archivo: "<prefix><5 letras>", como los que pone Godot.
	function newId(doc, prefix) {
		const used = new Set([...Object.keys(doc.ext), ...doc.sections.map((s) => s.id).filter((id) => id)]);
		for (;;) {
			let suffix = "";
			for (let i = 0; i < 5; i++) {
				suffix += ID_CHARS[Math.floor(Math.random() * ID_CHARS.length)];
			}
			if (!used.has(prefix + suffix)) {
				return prefix + suffix;
			}
		}
	}

	// Añade un [ext_resource] detrás del último (o tras la cabecera). Devuelve {text, id}.
	function addExtResource(text, type, uid, relPath) {
		const doc = scan(text);
		const id = newId(doc, `${Object.keys(doc.ext).length + 1}_`);
		const uidAttr = uid ? ` uid="${uid}"` : "";
		const line = `[ext_resource type="${type}"${uidAttr} path="res://${relPath}" id="${id}"]`;
		const lines = doc.lines.slice();
		const extLines = Object.values(doc.ext).map((e) => e.line);
		if (extLines.length > 0) {
			lines.splice(Math.max(...extLines) + 1, 0, line);
		} else {
			// Sin ext_resource: tras la cabecera y su línea en blanco.
			lines.splice(1, 0, "", line);
		}
		return { text: lines.join(doc.eol), id };
	}

	// Quita la línea de un [ext_resource].
	function removeExtResource(text, id) {
		const doc = scan(text);
		if (!doc.ext[id]) {
			return text;
		}
		const lines = doc.lines.slice();
		lines.splice(doc.ext[id].line, 1);
		return lines.join(doc.eol);
	}

	// Quita una [sub_resource] entera (con la línea en blanco que la sigue).
	function removeSubResource(text, id) {
		const doc = scan(text);
		const section = findSection(doc, id);
		if (!section) {
			return text;
		}
		let end = section.end;
		while (end < doc.lines.length && doc.lines[end].trim() === "") {
			end++;
		}
		const lines = doc.lines.slice();
		lines.splice(section.headerLine, end - section.headerLine);
		return lines.join(doc.eol);
	}

	// Añade una [sub_resource] justo antes de [resource]. propLines: ["clave = valor", ...]. Devuelve {text, id}.
	function addSubResource(text, type, propLines, prefix) {
		const doc = scan(text);
		const id = newId(doc, prefix || `${type}_`);
		const resource = findSection(doc, null);
		if (!resource) {
			throw new Error("El archivo no tiene [resource]");
		}
		const lines = doc.lines.slice();
		lines.splice(resource.headerLine, 0, `[sub_resource type="${type}" id="${id}"]`, ...propLines, "");
		return { text: lines.join(doc.eol), id };
	}

	// Ids de ext_resource a los que apunta alguna propiedad del archivo.
	function usedExtIds(doc) {
		const used = new Set();
		for (const section of doc.sections) {
			for (const prop of Object.values(section.props)) {
				for (const m of prop.raw.matchAll(/ExtResource\("([^"]+)"\)/g)) {
					used.add(m[1]);
				}
			}
		}
		return used;
	}

	// Lee los @export de un script de recurso: nombre -> {type, default}.
	function parseScript(text) {
		const result = { className: null, fields: {} };
		const classMatch = text.match(/^class_name\s+(\w+)/m);
		if (classMatch) {
			result.className = classMatch[1];
		}
		const exportRe = /^@export\w*(?:\([^)]*\))?\s+var\s+(\w+)\s*:\s*(\w+(?:\[[\w,\s]*\])?)\s*(?:=\s*([^#\n]*?))?\s*(?:#.*)?$/gm;
		for (const m of text.matchAll(exportRe)) {
			const type = m[2];
			let def;
			if (m[3] !== undefined && m[3] !== "") {
				def = parseValue(m[3]);
			} else if (type === "int" || type === "float") {
				def = 0;
			} else if (type === "bool") {
				def = false;
			} else if (type.startsWith("Array")) {
				def = [];
			} else if (type.startsWith("Dictionary")) {
				def = {};
			} else if (type === "String") {
				def = "";
			} else {
				def = null;
			}
			result.fields[m[1]] = { type, default: def };
		}
		return result;
	}

	// CSV con comillas: devuelve filas de celdas.
	function parseCsv(text) {
		const rows = [];
		let row = [];
		let cell = "";
		let inQuotes = false;
		for (let i = 0; i < text.length; i++) {
			const c = text[i];
			if (inQuotes) {
				if (c === '"' && text[i + 1] === '"') {
					cell += '"';
					i++;
				} else if (c === '"') {
					inQuotes = false;
				} else {
					cell += c;
				}
			} else if (c === '"') {
				inQuotes = true;
			} else if (c === ",") {
				row.push(cell);
				cell = "";
			} else if (c === "\n" || c === "\r") {
				if (c === "\r" && text[i + 1] === "\n") {
					i++;
				}
				row.push(cell);
				rows.push(row);
				row = [];
				cell = "";
			} else {
				cell += c;
			}
		}
		if (cell !== "" || row.length > 0) {
			row.push(cell);
			rows.push(row);
		}
		return rows;
	}

	return {
		scan,
		findSection,
		parseValue,
		formatFloat,
		formatValue,
		setProp,
		newId,
		addExtResource,
		removeExtResource,
		removeSubResource,
		addSubResource,
		usedExtIds,
		parseScript,
		parseCsv,
		resToRel,
	};
})();

if (typeof module !== "undefined") {
	module.exports = Tres;
}
