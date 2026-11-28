// Lector y escritor mínimo de archivos .tres de Godot 4, de scripts .gd (para los @export) y de CSV.
// Al escribir solo toca la línea del campo: uid, ext_resource y el resto del archivo quedan igual.
"use strict";

const Tres = (() => {
	const HEADER_RE = /^\[(\w+)(.*)\]\s*$/;
	const ATTR_RE = /(\w+)=("([^"]*)"|[^\s\]]+)/g;
	const PROP_RE = /^([A-Za-z_][\w/]*)\s*=\s*(.*)$/;

	// Cuenta las comillas sin escapar para saber si una cadena sigue abierta en la línea siguiente.
	function countQuotes(text) {
		let count = 0;
		for (let i = 0; i < text.length; i++) {
			if (text[i] === "\\") {
				i++;
			} else if (text[i] === '"') {
				count++;
			}
		}
		return count;
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
		let inString = false;
		let openBrackets = 0;
		let lastProp = null;
		for (let i = 0; i < lines.length; i++) {
			const line = lines[i];
			if (openBrackets > 0) {
				// Continuación de un valor entre paréntesis o llaves (un Dictionary se guarda en varias líneas).
				lastProp.raw += "\n" + line;
				lastProp.endLine = i;
				openBrackets += bracketDepth(line);
				if (current) {
					current.end = i + 1;
				}
				continue;
			}
			if (inString) {
				// Continuación de una cadena de varias líneas: se añade al valor crudo.
				lastProp.raw += "\n" + line;
				lastProp.endLine = i;
				if (countQuotes(line) % 2 === 1) {
					inString = false;
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
				if (countQuotes(prop[2]) % 2 === 1) {
					inString = true;
				} else {
					openBrackets = Math.max(bracketDepth(prop[2]), 0);
				}
			}
		}
		return doc;
	}

	// Paréntesis, corchetes y llaves abiertos menos cerrados en un trozo de texto (sin contar los de las cadenas).
	function bracketDepth(text) {
		let depth = 0;
		let inString = false;
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
		return depth;
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

	// Valor crudo de una línea .tres -> número, cadena, booleano, referencia o array.
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

	// Escribe un valor según el tipo del @export: "int", "float" o "Array[float]".
	function formatValue(type, value) {
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
		const newLine = `${key} = ${rawValue}`;
		const prop = section.props[key];
		if (prop) {
			lines.splice(prop.line, prop.endLine - prop.line + 1, newLine);
		} else {
			let insertAt = section.end;
			for (const [name, p] of Object.entries(section.props)) {
				if (name.startsWith("metadata/") && p.line < insertAt) {
					insertAt = p.line;
				}
			}
			lines.splice(insertAt, 0, newLine);
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
		const exportRe = /^@export\w*(?:\([^)]*\))?\s+var\s+(\w+)\s*:\s*([\w\[\]]+)\s*(?:=\s*([^#\n]*?))?\s*(?:#.*)?$/gm;
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
