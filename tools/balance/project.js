// Proyecto abierto: lee los .tres de la carpeta elegida, guarda los cambios pendientes y los escribe.
// Un "ref" apunta a un campo concreto: {path, sub, key, type, def, index?}. sub es null para [resource].
// Un ref puede traer read() (valor original) y write(text, value) (texto nuevo) para campos con estructura,
// como los grupos de una oleada, que no se escriben en una sola línea.
// Los archivos nuevos (createFile) y los que se borran (deleteFile) también quedan pendientes hasta guardar.
"use strict";

const Project = (() => {
	// Valores por defecto de los recursos de Godot que no tienen script (solo los que usa el panel).
	const BUILTIN_FIELDS = {
		CircleShape2D: { radius: { type: "float", default: 10.0 } },
	};

	const NAMES_CSV = "translations/textos.csv";

	const state = {
		root: null,
		docs: {},
		scripts: {},
		scriptsByPath: {},
		names: {},
		edits: new Map(),
		created: new Map(),
		deleted: new Set(),
		listeners: [],
		savedListeners: [],
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

	async function writeText(relPath, text, create) {
		const handle = await getFileHandle(relPath, create);
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

	// ¿Existe el archivo, en disco o como archivo nuevo pendiente?
	async function fileExists(relPath) {
		return state.created.has(relPath) || (await exists(relPath));
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
		state.created.clear();
		state.deleted.clear();
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

	// --- Archivos nuevos ---

	// Crea un .tres nuevo con su texto inicial: se puede leer y editar ya, y se escribe al guardar.
	function createFile(relPath, text) {
		state.created.set(relPath, text);
		state.docs[relPath] = Tres.scan(text);
		notify();
	}

	function isCreated(relPath) {
		return state.created.has(relPath);
	}

	// Borra un archivo al guardar (uno nuevo sin guardar se olvida ya). Sus cambios pendientes se pierden.
	function deleteFile(relPath) {
		for (const [k, edit] of state.edits) {
			if (edit.ref.path === relPath) {
				state.edits.delete(k);
			}
		}
		if (state.created.has(relPath)) {
			state.created.delete(relPath);
			delete state.docs[relPath];
		} else {
			state.deleted.add(relPath);
		}
		notify();
	}

	// --- Guardar y descartar ---

	// Escribe todos los cambios: relee cada archivo, cambia solo sus líneas y lo guarda.
	async function save() {
		const saved = [];
		// Primero los archivos nuevos, con su texto inicial; sus cambios se escriben después, como los demás.
		for (const [path, text] of [...state.created]) {
			await writeText(path, text, true);
			state.created.delete(path);
			saved.push(path);
		}
		const byPath = new Map();
		for (const edit of state.edits.values()) {
			if (!byPath.has(edit.ref.path)) {
				byPath.set(edit.ref.path, []);
			}
			byPath.get(edit.ref.path).push(edit);
		}
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
			if (path.endsWith(".tres")) {
				state.docs[path] = Tres.scan(text);
			}
			for (const edit of edits) {
				state.edits.delete(editKey(edit.ref));
			}
			if (!saved.includes(path)) {
				saved.push(path);
			}
		}
		for (const path of [...state.deleted]) {
			const parts = path.split("/");
			const name = parts.pop();
			await (await getDir(parts.join("/"))).removeEntry(name);
			state.deleted.delete(path);
			delete state.docs[path];
			saved.push(`${path} (borrado)`);
		}
		if (saved.includes(NAMES_CSV)) {
			await loadNames();
		}
		notify();
		for (const listener of state.savedListeners) {
			await listener(saved);
		}
		return saved;
	}

	function discard() {
		state.edits.clear();
		for (const path of state.created.keys()) {
			delete state.docs[path];
		}
		state.created.clear();
		state.deleted.clear();
		notify();
	}

	// --- Avisos de cambio ---

	function onChange(listener) {
		state.listeners.push(listener);
	}

	// Avisa después de guardar, con las rutas escritas.
	function onSaved(listener) {
		state.savedListeners.push(listener);
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
		onSaved,
		readText,
		fileExists,
		createFile,
		isCreated,
		deleteFile,
		translate,
		fileName,
		get isOpen() {
			return state.root !== null;
		},
		get rootName() {
			return state.root ? state.root.name : "";
		},
		get pendingCount() {
			return state.edits.size + state.created.size + state.deleted.size;
		},
		get pendingPaths() {
			return [...new Set([...state.created.keys(), ...state.deleted, ...[...state.edits.values()].map((e) => e.ref.path)])];
		},
	};
})();

if (typeof module !== "undefined") {
	module.exports = Project;
}
