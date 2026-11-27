// Proyecto abierto: lee los .tres de la carpeta elegida, guarda los cambios pendientes y los escribe.
// Un "ref" apunta a un campo concreto: {path, sub, key, type, def, index?}. sub es null para [resource].
// Un ref puede traer read() (valor original) y write(text, value) (texto nuevo) para campos con estructura,
// como los grupos de una oleada, que no se escriben en una sola línea.
"use strict";

const Project = (() => {
	// Valores por defecto de los recursos de Godot que no tienen script (solo los que usa el panel).
	const BUILTIN_FIELDS = {
		CircleShape2D: { radius: { type: "float", default: 10.0 } },
	};

	const state = {
		root: null,
		docs: {},
		scripts: {},
		scriptsByPath: {},
		names: {},
		edits: new Map(),
		listeners: [],
	};

	// --- Acceso a archivos (File System Access API) ---

	async function getDir(relDir) {
		let dir = state.root;
		for (const part of relDir.split("/").filter((p) => p !== "")) {
			dir = await dir.getDirectoryHandle(part);
		}
		return dir;
	}

	async function getFileHandle(relPath, create) {
		const parts = relPath.split("/");
		const name = parts.pop();
		const dir = await getDir(parts.join("/"));
		return dir.getFileHandle(name, { create: !!create });
	}

	async function readText(relPath) {
		const handle = await getFileHandle(relPath);
		const file = await handle.getFile();
		return file.text();
	}

	async function writeText(relPath, text) {
		const handle = await getFileHandle(relPath);
		const writable = await handle.createWritable();
		await writable.write(text);
		await writable.close();
	}

	async function listFiles(relDir, extension) {
		const dir = await getDir(relDir);
		const names = [];
		for await (const [name, entry] of dir.entries()) {
			if (entry.kind === "file" && name.endsWith(extension)) {
				names.push(`${relDir}/${name}`);
			}
		}
		return names.sort();
	}

	async function exists(relPath) {
		try {
			await getFileHandle(relPath);
			return true;
		} catch (e) {
			return false;
		}
	}

	// --- Carga ---

	async function openWithHandle(handle) {
		state.root = handle;
		if (!(await exists("project.godot"))) {
			state.root = null;
			throw new Error("Esa carpeta no tiene project.godot: elige la carpeta del juego.");
		}
		state.docs = {};
		state.scripts = {};
		state.scriptsByPath = {};
		state.names = {};
		state.edits.clear();
		await loadScripts();
		await loadNames();
		notify();
	}

	async function loadScripts() {
		for (const path of await listFiles("scripts/resources", ".gd")) {
			const info = Tres.parseScript(await readText(path));
			if (info.className) {
				state.scripts[info.className] = info;
				state.scriptsByPath[path] = info.className;
			}
		}
	}

	async function loadNames() {
		if (!(await exists("translations/textos.csv"))) {
			return;
		}
		const rows = Tres.parseCsv(await readText("translations/textos.csv"));
		const header = rows[0] || [];
		const column = header.indexOf("es");
		for (const row of rows.slice(1)) {
			if (row[0] && column >= 0 && row[column] !== undefined) {
				state.names[row[0]] = row[column];
			}
		}
	}

	// Carga (una vez) un .tres y lo devuelve escaneado.
	async function loadDoc(path) {
		if (!state.docs[path]) {
			state.docs[path] = Tres.scan(await readText(path));
		}
		return state.docs[path];
	}

	async function loadDir(relDir) {
		const paths = await listFiles(relDir, ".tres");
		for (const path of paths) {
			await loadDoc(path);
		}
		return paths;
	}

	// --- Nodos (un recurso dentro de un archivo) y campos ---

	// Clase de un recurso: script_class de la cabecera, script de la sub_resource o tipo nativo.
	function nodeClass(doc, section) {
		if (section.kind === "resource" && doc.header.script_class) {
			return doc.header.script_class;
		}
		const script = section.props.script ? Tres.parseValue(section.props.script.raw) : null;
		if (script && script.ext && doc.ext[script.ext]) {
			return state.scriptsByPath[doc.ext[script.ext].path] || null;
		}
		return section.kind === "resource" ? doc.header.type : section.attrs.type;
	}

	function node(path, sub) {
		const doc = state.docs[path];
		if (!doc) {
			return null;
		}
		const section = Tres.findSection(doc, sub === undefined ? null : sub);
		if (!section) {
			return null;
		}
		return { path, sub: sub === undefined ? null : sub, doc, section, cls: nodeClass(doc, section) };
	}

	function fieldInfo(cls, key) {
		const fields = (state.scripts[cls] && state.scripts[cls].fields) || BUILTIN_FIELDS[cls] || {};
		return fields[key] || null;
	}

	// Valor por defecto de un @export de una clase (o undefined).
	function fieldDefault(cls, key) {
		const info = fieldInfo(cls, key);
		return info ? info.default : undefined;
	}

	// Ref editable de un campo numérico de un nodo (null si el campo no existe en su clase).
	function ref(n, key, index) {
		if (!n) {
			return null;
		}
		const info = fieldInfo(n.cls, key);
		if (!info) {
			return null;
		}
		return { path: n.path, sub: n.sub, key, type: info.type, def: info.default, index };
	}

	// Nodo al que apunta un campo ExtResource/SubResource (o null).
	function linked(n, key) {
		if (!n || !n.section.props[key]) {
			return null;
		}
		return resolveValue(n, Tres.parseValue(n.section.props[key].raw));
	}

	function resolveValue(n, value) {
		if (value && value.ext && n.doc.ext[value.ext]) {
			return node(n.doc.ext[value.ext].path, null);
		}
		if (value && value.sub) {
			return node(n.path, value.sub);
		}
		return null;
	}

	// Carga el archivo al que apunta un campo ExtResource (si hace falta) y devuelve su nodo.
	async function loadLinked(n, key) {
		if (!n || !n.section.props[key]) {
			return null;
		}
		const value = Tres.parseValue(n.section.props[key].raw);
		if (value && value.ext && n.doc.ext[value.ext]) {
			await loadDoc(n.doc.ext[value.ext].path);
		}
		return resolveValue(n, value);
	}

	// Lista de nodos de un campo Array de referencias (split_into).
	function linkedList(n, key) {
		if (!n || !n.section.props[key]) {
			return [];
		}
		const value = Tres.parseValue(n.section.props[key].raw);
		return Array.isArray(value) ? value.map((v) => resolveValue(n, v)).filter((x) => x) : [];
	}

	// Valor crudo (sin cambios pendientes) de un campo, o su valor por defecto.
	function rawValue(n, key) {
		if (!n) {
			return undefined;
		}
		if (n.section.props[key]) {
			return Tres.parseValue(n.section.props[key].raw);
		}
		const info = fieldInfo(n.cls, key);
		return info ? info.default : undefined;
	}

	function editKey(r) {
		return `${r.path}|${r.sub}|${r.key}`;
	}

	function originalValue(r) {
		if (r.read) {
			return r.read();
		}
		return rawValue(node(r.path, r.sub), r.key);
	}

	// Valor actual de un ref, con los cambios pendientes.
	function value(r) {
		if (!r) {
			return undefined;
		}
		const k = editKey(r);
		const whole = state.edits.has(k) ? state.edits.get(k).value : originalValue(r);
		if (r.index !== undefined) {
			return Array.isArray(whole) ? whole[r.index] : undefined;
		}
		return whole;
	}

	function sameValue(a, b) {
		return JSON.stringify(a) === JSON.stringify(b);
	}

	function setValue(r, newValue) {
		const k = editKey(r);
		let whole = newValue;
		if (r.index !== undefined) {
			const current = state.edits.has(k) ? state.edits.get(k).value : originalValue(r);
			whole = (current || []).slice();
			whole[r.index] = newValue;
		}
		if (sameValue(whole, originalValue(r))) {
			state.edits.delete(k);
		} else {
			state.edits.set(k, { ref: r, value: whole });
		}
		notify();
	}

	// ¿Este ref (o este elemento del array) tiene un cambio pendiente?
	function isEdited(r) {
		const k = editKey(r);
		if (!state.edits.has(k)) {
			return false;
		}
		if (r.index === undefined) {
			return true;
		}
		const original = originalValue(r) || [];
		return !sameValue(state.edits.get(k).value[r.index], original[r.index]);
	}

	// ¿Falta la línea en el .tres? (vale lo de por defecto)
	function isDefault(r) {
		const n = node(r.path, r.sub);
		return !!n && !n.section.props[r.key];
	}

	// --- Guardar y descartar ---

	// Escribe todos los cambios: relee cada archivo, cambia solo sus líneas y lo guarda.
	async function save() {
		const byPath = new Map();
		for (const edit of state.edits.values()) {
			if (!byPath.has(edit.ref.path)) {
				byPath.set(edit.ref.path, []);
			}
			byPath.get(edit.ref.path).push(edit);
		}
		const saved = [];
		for (const [path, edits] of byPath) {
			let text = await readText(path);
			for (const edit of edits) {
				if (edit.ref.write) {
					text = edit.ref.write(text, edit.value);
				} else {
					text = Tres.setProp(text, edit.ref.sub, edit.ref.key, Tres.formatValue(edit.ref.type, edit.value));
				}
			}
			await writeText(path, text);
			state.docs[path] = Tres.scan(text);
			for (const edit of edits) {
				state.edits.delete(editKey(edit.ref));
			}
			saved.push(path);
		}
		notify();
		return saved;
	}

	function discard() {
		state.edits.clear();
		notify();
	}

	// --- Avisos de cambio ---

	function onChange(listener) {
		state.listeners.push(listener);
	}

	function notify() {
		for (const listener of state.listeners) {
			listener();
		}
	}

	// Nombre traducido (columna es de textos.csv) de una clave.
	function translate(key) {
		return state.names[key] || key || "";
	}

	function fileName(path) {
		return path.split("/").pop().replace(/\.tres$/, "");
	}

	return {
		openWithHandle,
		loadDir,
		loadDoc,
		node,
		ref,
		fieldDefault,
		linked,
		loadLinked,
		linkedList,
		rawValue,
		value,
		setValue,
		isEdited,
		isDefault,
		save,
		discard,
		onChange,
		translate,
		fileName,
		get isOpen() {
			return state.root !== null;
		},
		get rootName() {
			return state.root ? state.root.name : "";
		},
		get pendingCount() {
			return state.edits.size;
		},
		get pendingPaths() {
			return [...new Set([...state.edits.values()].map((e) => e.ref.path))];
		},
	};
})();

if (typeof module !== "undefined") {
	module.exports = Project;
}
