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
		let lastProp = null;
		for (let i = 0; i < lines.length; i++) {
			const line = lines[i];
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
					doc.ext[attrs.id] = { path: resToRel(attrs.path), type: attrs.type };
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

	return { scan, findSection, parseValue, formatFloat, formatValue, setProp, parseScript, parseCsv, resToRel };
})();

if (typeof module !== "undefined") {
	module.exports = Tres;
}
