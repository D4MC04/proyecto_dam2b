// Pestaña Niveles: una fila por resources/level_data/*.tres; al elegir un nivel, sus oleadas; al elegir una
// oleada, sus grupos (editables: nave, cuántas, pausa y camino; se añaden, quitan y reordenan).
// Las oleadas y los grupos se copian, pegan y duplican (también entre niveles) con un portapapeles del panel.
"use strict";

const LevelsTab = (() => {
	const LEVEL_DIR = "resources/level_data";
	const ENEMY_DIR = "resources/enemy_data";
	const WAVE_DIR = "resources/wave_data";
	const SPAWN_GROUP_SCRIPT = "scripts/resources/SpawnGroup.gd";
	const WAVE_DATA_SCRIPT = "scripts/resources/WaveData.gd";
	// La separación entre naves no es del grupo: sale de spawn_spacing.tres según la velocidad de la nave.
	const GROUP_FIELDS = ["count", "pause_after", "path_index"];

	const PERFECT_WAVE_BONUS = 25; // LevelState.PERFECT_WAVE_BONUS

	// Botón Jugar: protocolo registrado por tools/balance/launcher/registrar.ps1.
	const PLAY_PROTOCOL = "astro-artillery://play";
	const PLAY_CHECK_MS = 2500; // si en este tiempo el navegador no pierde el foco, el protocolo no respondió
	const LAUNCHER_HELP_KEY = "astro-artillery-launcher-help-shown";

	let levels = [];
	let enemyPaths = [];
	let selectedLevel = null;
	let selectedWave = null;
	let newGroupCounter = 0;
	let selectedGroupKeys = new Set();
	// Portapapeles del panel: grupos sueltos y una oleada entera (grupos sin sub y health_multiplier).
	let groupClipboard = [];
	let waveClipboard = null;
	const el = {};
	let levelsTable = null;
	let wavesTable = null;
	let wavesSignature = null;
	let groupsEditor = null;

	// --- Carga ---

	async function load() {
		levels = [];
		enemyPaths = await Project.loadDir(ENEMY_DIR);
		const paths = await Project.loadDir(LEVEL_DIR);
		for (const path of paths) {
			const n = Project.node(path, null);
			if (!n) {
				continue;
			}
			const level = { path, waves: [], waveCache: {}, turrets: [], name: levelName(path, n) };
			level.wavesRef = { path, sub: null, key: "waves", type: "waves", read: () => readWavePaths(path), write: (text, value) => writeWavePaths(text, value) };
			for (const value of Project.rawValue(n, "turrets") || []) {
				const turret = value && value.ext && n.doc.ext[value.ext];
				if (turret) {
					await Project.loadDoc(turret.path);
					level.turrets.push(turret.path);
				}
			}
			for (const wavePath of readWavePaths(path)) {
				await Project.loadDoc(wavePath);
			}
			syncWaves(level);
			levels.push(level);
		}
		// Los niveles por número y el de emergencia (sector 0) delante.
		levels.sort((a, b) => levelOrder(a.path) - levelOrder(b.path));
		levels.forEach((level, index) => (level.rowClass = `group-${index % 2}`));
		if (!selectedLevel || !levels.some((l) => l.path === selectedLevel.path)) {
			selectedLevel = levels[0] || null;
		} else {
			selectedLevel = levels.find((l) => l.path === selectedLevel.path);
		}
		selectedWave = selectedLevel ? selectedLevel.waves.find((w) => selectedWave && w.path === selectedWave.path) || selectedLevel.waves[0] || null : null;
	}

	function levelOrder(path) {
		const m = Project.fileName(path).match(/^level_(\d+)$/);
		return m ? Number(m[1]) : 0;
	}

	function levelName(path, n) {
		const number = levelOrder(path);
		const sector = Project.translate(Project.rawValue(n, "sector_name"));
		if (number === 0) {
			return Project.fileName(path) === "emergency" ? "Emergencia" : Project.fileName(path);
		}
		return sector ? `Nivel ${number} · ${sector}` : `Nivel ${number}`;
	}

	function makeWave(level, path) {
		return {
			level,
			path,
			index: 0,
			rowClass: "",
			hmRef: Project.ref(Project.node(path, null), "health_multiplier"),
			groupsRef: { path, sub: null, key: "groups", type: "groups", read: () => readGroups(path), write: (text, value) => writeGroups(text, value) },
		};
	}

	// Rehace level.waves con la lista waves actual (con cambios pendientes). Reusa los objetos de oleada.
	function syncWaves(level) {
		const paths = (Project.value(level.wavesRef) || []).filter((path) => Project.node(path, null));
		level.waves = paths.map((path, index) => {
			if (!level.waveCache[path]) {
				level.waveCache[path] = makeWave(level, path);
			}
			const wave = level.waveCache[path];
			wave.index = index;
			wave.rowClass = `group-${index % 2}` + (Project.isCreated(path) ? " new-group" : "");
			return wave;
		});
	}

	// --- Lista de oleadas de un nivel: leer y escribir ---

	// Rutas de las oleadas tal como están en el level_N.tres.
	function readWavePaths(levelPath) {
		const n = Project.node(levelPath, null);
		if (!n) {
			return [];
		}
		return (Project.rawValue(n, "waves") || []).map((v) => v && v.ext && n.doc.ext[v.ext] && n.doc.ext[v.ext].path).filter((path) => path);
	}

	// Reescribe la lista waves: las oleadas que ya estaban guardan su ext_resource; las nuevas, uno con id nuevo.
	// Se quita el ext_resource de una oleada que ya no está en la lista.
	function writeWavePaths(text, paths) {
		let doc = Tres.scan(text);
		const extIdFor = (relPath) => Object.keys(doc.ext).find((id) => doc.ext[id].path === relPath);
		const resource = Tres.findSection(doc, null);
		const raw = resource && resource.props.waves ? resource.props.waves.raw : "";
		let scriptId = (raw.match(/^Array\[ExtResource\("([^"]+)"\)\]/) || [])[1] || extIdFor(WAVE_DATA_SCRIPT);
		if (!scriptId) {
			({ text, id: scriptId } = Tres.addExtResource(text, "Script", scriptUid(WAVE_DATA_SCRIPT), WAVE_DATA_SCRIPT));
			doc = Tres.scan(text);
		}
		const ids = [];
		for (const path of paths) {
			let id = extIdFor(path);
			if (!id) {
				const waveNode = Project.node(path, null);
				({ text, id } = Tres.addExtResource(text, "Resource", waveNode ? waveNode.doc.header.uid || null : null, path));
				doc = Tres.scan(text);
			}
			ids.push(id);
		}
		const list = ids.map((id) => `ExtResource("${id}")`).join(", ");
		text = Tres.setProp(text, null, "waves", `Array[ExtResource("${scriptId}")]([${list}])`);
		doc = Tres.scan(text);
		const used = Tres.usedExtIds(doc);
		for (const [id, ext] of Object.entries(doc.ext)) {
			if (ext.path.startsWith(`${WAVE_DIR}/`) && !used.has(id)) {
				text = Tres.removeExtResource(text, id);
			}
		}
		return text;
	}

	// --- Grupos: leer y escribir ---

	// Grupos tal como están en el archivo: [{key, sub, enemy, count, pause_after, path_index}].
	function readGroups(path) {
		const n = Project.node(path, null);
		if (!n) {
			return [];
		}
		return (Project.rawValue(n, "groups") || [])
			.filter((v) => v && v.sub)
			.map((v) => {
				const g = Project.node(path, v.sub);
				const enemyRaw = g && g.section.props.enemy_data ? Tres.parseValue(g.section.props.enemy_data.raw) : null;
				const enemy = enemyRaw && enemyRaw.ext && n.doc.ext[enemyRaw.ext] ? n.doc.ext[enemyRaw.ext].path : null;
				const group = { key: v.sub, sub: v.sub, enemy };
				for (const field of GROUP_FIELDS) {
					group[field] = Project.rawValue(g, field);
				}
				return group;
			});
	}

	function spawnGroupDefaults() {
		const defaults = {};
		for (const field of GROUP_FIELDS) {
			defaults[field] = Project.fieldDefault("SpawnGroup", field);
		}
		return defaults;
	}

	function fieldType(field) {
		return field === "count" || field === "path_index" ? "int" : "float";
	}

	// Uid de un script (SpawnGroup.gd, WaveData.gd), sacado de cualquier nivel u oleada que lo enlace.
	function scriptUid(scriptPath) {
		for (const level of levels) {
			for (const path of [level.path, ...level.waves.map((w) => w.path)]) {
				const n = Project.node(path, null);
				const ext = n && Object.values(n.doc.ext).find((e) => e.path === scriptPath && e.uid);
				if (ext) {
					return ext.uid;
				}
			}
		}
		return null;
	}

	// Reescribe los grupos de una oleada: cambia las líneas de los que ya estaban, quita los borrados y añade
	// los nuevos (sub_resource con id nuevo) y las naves nuevas (ext_resource con id nuevo). Los ids y uid que
	// ya existen no cambian. Quita los ext_resource de naves que la oleada ya no usa.
	function writeGroups(text, groups) {
		const defaults = spawnGroupDefaults();
		let doc = Tres.scan(text);
		const extIdFor = (relPath) => Object.keys(doc.ext).find((id) => doc.ext[id].path === relPath);

		let scriptId = extIdFor(SPAWN_GROUP_SCRIPT);
		if (!scriptId) {
			({ text, id: scriptId } = Tres.addExtResource(text, "Script", scriptUid(SPAWN_GROUP_SCRIPT), SPAWN_GROUP_SCRIPT));
			doc = Tres.scan(text);
		}
		const enemyIds = {};
		for (const group of groups) {
			if (enemyIds[group.enemy]) {
				continue;
			}
			let id = extIdFor(group.enemy);
			if (!id) {
				const enemyNode = Project.node(group.enemy, null);
				({ text, id } = Tres.addExtResource(text, "Resource", enemyNode ? enemyNode.doc.header.uid : null, group.enemy));
				doc = Tres.scan(text);
			}
			enemyIds[group.enemy] = id;
		}

		// Grupos que estaban y ya no están.
		const kept = new Set(groups.filter((g) => g.sub).map((g) => g.sub));
		const resource = Tres.findSection(doc, null);
		const oldSubs = (resource && resource.props.groups ? Tres.parseValue(resource.props.groups.raw) : []).filter((v) => v && v.sub).map((v) => v.sub);
		for (const sub of oldSubs) {
			if (!kept.has(sub)) {
				text = Tres.removeSubResource(text, sub);
			}
		}

		const subIds = [];
		for (const group of groups) {
			const enemyLine = `ExtResource("${enemyIds[group.enemy]}")`;
			if (group.sub) {
				const section = Tres.findSection(Tres.scan(text), group.sub);
				text = Tres.setProp(text, group.sub, "enemy_data", enemyLine);
				for (const field of GROUP_FIELDS) {
					// Las líneas que faltan valen lo de por defecto: solo se añaden si el valor cambia.
					if (section.props[field] || group[field] !== defaults[field]) {
						text = Tres.setProp(text, group.sub, field, Tres.formatValue(fieldType(field), group[field]));
					}
				}
				subIds.push(group.sub);
			} else {
				const lines = [`script = ExtResource("${scriptId}")`, `enemy_data = ${enemyLine}`];
				for (const field of GROUP_FIELDS) {
					if (group[field] !== defaults[field]) {
						lines.push(`${field} = ${Tres.formatValue(fieldType(field), group[field])}`);
					}
				}
				let id;
				({ text, id } = Tres.addSubResource(text, "Resource", lines, "Resource_"));
				subIds.push(id);
			}
		}
		const list = subIds.map((id) => `SubResource("${id}")`).join(", ");
		text = Tres.setProp(text, null, "groups", `Array[ExtResource("${scriptId}")]([${list}])`);

		// Naves que ya no usa ningún grupo.
		doc = Tres.scan(text);
		const used = Tres.usedExtIds(doc);
		for (const [id, ext] of Object.entries(doc.ext)) {
			if (ext.path.startsWith(`${ENEMY_DIR}/`) && !used.has(id)) {
				text = Tres.removeExtResource(text, id);
			}
		}
		return text;
	}

	// --- Cálculos ---

	function enemyValue(path, key) {
		return Project.value(Project.ref(Project.node(path, null), key));
	}

	// Vida y recompensa de una nave contando sus trozos (split_into), sin el multiplicador.
	function shipTotals(path, depth) {
		const n = Project.node(path, null);
		const totals = { hp: enemyValue(path, "hp") || 0, reward: enemyValue(path, "reward") || 0 };
		if (n && (depth || 0) < 4) {
			for (const piece of Project.linkedList(n, "split_into")) {
				const p = shipTotals(piece.path, (depth || 0) + 1);
				totals.hp += p.hp;
				totals.reward += p.reward;
			}
		}
		return totals;
	}

	// Segundos entre dos naves del grupo (WaveData.group_spacing): los de la velocidad de su nave.
	function groupSpacing(group) {
		return group.enemy ? Project.spacingFor(enemyValue(group.enemy, "speed")) : Project.DEFAULT_SPACING;
	}

	function waveStats(wave) {
		const groups = Project.value(wave.groupsRef) || [];
		const hm = Project.value(wave.hmRef);
		const stats = { ships: 0, reward: 0, hp: 0, duration: 0, starts: [] };
		let start = 0;
		for (const g of groups) {
			stats.starts.push(start);
			const totals = shipTotals(g.enemy);
			stats.ships += g.count;
			stats.reward += g.count * totals.reward;
			stats.hp += g.count * totals.hp * hm;
			// Como WaveData.get_entries(): la separación sale de la velocidad de la nave.
			const spacing = groupSpacing(g);
			if (g.count > 0) {
				stats.duration = Math.max(stats.duration, start + spacing * (g.count - 1));
			}
			start += spacing * Math.max(g.count - 1, 0) + g.pause_after;
		}
		return stats;
	}

	// Estadísticas de todas las oleadas del nivel, con el dinero antes de cada una.
	function levelStats(level) {
		const startMoney = Project.value(Project.ref(Project.node(level.path, null), "starting_money")) || 0;
		let earned = 0;
		return level.waves.map((wave, k) => {
			const stats = waveStats(wave);
			stats.money = startMoney + earned + PERFECT_WAVE_BONUS * k;
			earned += stats.reward;
			return stats;
		});
	}

	function sum(list, key) {
		return list.reduce((total, item) => total + item[key], 0);
	}

	function waveStatsOf(wave) {
		return levelStats(wave.level)[wave.index];
	}

	// --- Tablas ---

	function levelColumns() {
		const f = BalanceTable.formatNumber;
		return [
			{ id: "name", label: "Nivel", sticky: true, get: (l) => l.name, format: (v) => v, cellTitle: (l) => l.path },
			{
				id: "play",
				label: "Jugar",
				title: "Abre el juego (sin editor) ya en este nivel, con los .tres guardados de la carpeta elegida",
				cls: "actions",
				build: (td, l) => {
					const arg = levelArg(l.path);
					if (arg) {
						td.append(button("▶ Jugar", `Abre el juego en este nivel (--level=${arg})`, (e) => {
							e.stopPropagation();
							play(l);
						}));
					}
				},
			},
			{ id: "file", label: "Archivo", get: (l) => Project.fileName(l.path), format: (v) => v, cls: "file" },
			{ id: "starting_money", label: "Dinero", title: "starting_money (€)", ref: (l) => Project.ref(Project.node(l.path, null), "starting_money") },
			{ id: "waves", label: "Oleadas", group: "Calculado", get: (l) => l.waves.length },
			{ id: "ships", label: "Naves", group: "Calculado", get: (l) => sum(levelStats(l), "ships") },
			{ id: "reward", label: "Recompensa", group: "Calculado", title: "Suma de las recompensas de todas las naves (con sus trozos), sin las de oleada perfecta", get: (l) => sum(levelStats(l), "reward"), format: (v) => f(v, 0) },
			{ id: "hp", label: "Vida total", group: "Calculado", title: "Suma de count × hp × health_multiplier de todas las oleadas (con los trozos)", get: (l) => sum(levelStats(l), "hp"), format: (v) => f(v, 0) },
			{
				id: "turrets",
				label: "Torretas",
				title: "turrets (solo se ven)",
				get: (l) => l.turrets.map((path) => Project.translate(Project.rawValue(Project.node(path, null), "name"))).join(", "),
				format: (v) => v,
				cls: "text",
			},
		];
	}

	function waveColumns() {
		const f = BalanceTable.formatNumber;
		return [
			{ id: "index", label: "Oleada", sticky: true, get: (w) => w.index + 1, cellTitle: (w) => w.path },
			{ id: "file", label: "Archivo", get: (w) => Project.fileName(w.path), format: (v) => v, cls: "file" },
			{ id: "health_multiplier", label: "Vida ×", title: "health_multiplier", ref: (w) => w.hmRef },
			{ id: "ships", label: "Naves", group: "Calculado", get: (w) => waveStatsOf(w).ships },
			{ id: "reward", label: "Recompensa", group: "Calculado", title: "Recompensas de sus naves (con sus trozos)", get: (w) => waveStatsOf(w).reward, format: (v) => f(v, 0) },
			{ id: "hp", label: "Vida total", group: "Calculado", title: "count × hp × health_multiplier, con los trozos de split_into", get: (w) => waveStatsOf(w).hp, format: (v) => f(v, 0) },
			{ id: "duration", label: "Salida (s)", group: "Calculado", title: "Tiempo de la última nave desde la primera (con la separación de spawn_spacing.tres según la velocidad de cada nave y pause_after)", get: (w) => waveStatsOf(w).duration, format: (v) => f(v, 1) },
			{ id: "money", label: "Dinero antes", group: "Calculado", title: "Inicial + recompensas anteriores + 25 por oleada perfecta", get: (w) => waveStatsOf(w).money, format: (v) => f(v, 0) },
		];
	}

	// --- Jugar ---

	// Argumento --level de DevLaunch.gd: el número del nivel o "emergency" (null si el archivo no es de nivel).
	function levelArg(path) {
		const name = Project.fileName(path);
		if (name === "emergency") {
			return "emergency";
		}
		const number = levelOrder(path);
		return number >= 1 && number <= 9 ? String(number) : null;
	}

	// El juego lee los .tres del disco: con cambios sin guardar, se guardan antes o no se juega.
	async function play(level) {
		const pending = Project.pendingCount;
		if (pending > 0) {
			if (!window.confirm(`Hay ${pending} cambios sin guardar y el juego lee los archivos guardados.

Aceptar: guardar y jugar.
Cancelar: no jugar.`)) {
				return;
			}
			if (!(await BalanceApp.save())) {
				return;
			}
		}
		const params = new URLSearchParams({ level: levelArg(level.path), folder: Project.rootName });
		launch(`${PLAY_PROTOCOL}?${params}`, level.name);
	}

	// Una página file:// no puede abrir programas: se abre el protocolo y Windows llama al lanzador.
	// Si el protocolo no está registrado, el navegador no hace nada: se nota en que no pierde el foco.
	function launch(url, levelName) {
		let answered = false;
		const onBlur = () => (answered = true);
		window.addEventListener("blur", onBlur, { once: true });
		const link = document.createElement("a");
		link.href = url;
		link.click();
		BalanceApp.setStatus(`Abriendo el juego en ${levelName}… (la primera vez el navegador pide permiso)`, "ok");
		window.setTimeout(() => {
			window.removeEventListener("blur", onBlur);
			if (answered || document.hidden) {
				localStorage.setItem(LAUNCHER_HELP_KEY, "1");
			} else if (!localStorage.getItem(LAUNCHER_HELP_KEY)) {
				localStorage.setItem(LAUNCHER_HELP_KEY, "1");
				el.launcherHelp.hidden = false;
			}
		}, PLAY_CHECK_MS);
	}

	// --- Editor de grupos ---

	function enemyLabel(path) {
		const n = Project.node(path, null);
		const name = n ? Project.translate(Project.rawValue(n, "name")) : "";
		return `${name || Project.fileName(path)} (${Project.fileName(path)})`;
	}

	function currentGroups() {
		return (Project.value(selectedWave.groupsRef) || []).map((g) => ({ ...g }));
	}

	function setGroups(groups) {
		Project.setValue(selectedWave.groupsRef, groups);
	}

	function addGroup() {
		const groups = currentGroups();
		const last = groups[groups.length - 1];
		groups.push({ key: `new-${++newGroupCounter}`, sub: null, enemy: last ? last.enemy : enemyPaths[0], ...spawnGroupDefaults() });
		setGroups(groups);
	}

	function removeGroup(index) {
		const groups = currentGroups();
		groups.splice(index, 1);
		setGroups(groups);
	}

	function moveGroup(index, delta) {
		const groups = currentGroups();
		const target = index + delta;
		if (target < 0 || target >= groups.length) {
			return;
		}
		[groups[index], groups[target]] = [groups[target], groups[index]];
		setGroups(groups);
	}

	// Datos de un grupo sin su sub_resource, para el portapapeles.
	function groupData(group) {
		const data = { enemy: group.enemy };
		for (const field of GROUP_FIELDS) {
			data[field] = group[field];
		}
		return data;
	}

	// Grupos listos para pegar: claves nuevas y sin sub (al guardar son sub_resource con id nuevo).
	function freshGroups(list) {
		return list.map((data) => ({ ...data, key: `new-${++newGroupCounter}`, sub: null }));
	}

	function duplicateGroup(index) {
		const groups = currentGroups();
		const [copy] = freshGroups([groupData(groups[index])]);
		groups.splice(index + 1, 0, copy);
		setGroups(groups);
	}

	function copyGroups() {
		const groups = currentGroups().filter((g) => selectedGroupKeys.has(g.key));
		if (groups.length === 0) {
			return;
		}
		groupClipboard = groups.map(groupData);
		BalanceApp.setStatus(`Copiados ${groups.length} grupo(s) de ${Project.fileName(selectedWave.path)}.`, "ok");
		updateGroupActions();
	}

	// Pega los grupos copiados detrás del último grupo seleccionado (o al final) y deja elegidos los pegados.
	function pasteGroups() {
		if (groupClipboard.length === 0) {
			return;
		}
		const groups = currentGroups();
		let at = groups.length;
		groups.forEach((g, index) => {
			if (selectedGroupKeys.has(g.key)) {
				at = index + 1;
			}
		});
		const pasted = freshGroups(groupClipboard);
		groups.splice(at, 0, ...pasted);
		selectedGroupKeys = new Set(pasted.map((g) => g.key));
		setGroups(groups);
	}

	function toggleGroup(key, checked) {
		if (checked) {
			selectedGroupKeys.add(key);
		} else {
			selectedGroupKeys.delete(key);
		}
		refreshGroupSelection();
	}

	function toggleAllGroups(checked) {
		const groups = Project.value(selectedWave.groupsRef) || [];
		selectedGroupKeys = new Set(checked ? groups.map((g) => g.key) : []);
		refreshGroupSelection();
	}

	function refreshGroupSelection() {
		if (groupsEditor) {
			const groups = Project.value(selectedWave.groupsRef) || [];
			groups.forEach((group, index) => {
				const row = groupsEditor.rows[index];
				if (row) {
					row.check.checked = selectedGroupKeys.has(group.key);
					row.tr.classList.toggle("selected", row.check.checked);
				}
			});
			groupsEditor.checkAll.checked = groups.length > 0 && groups.every((g) => selectedGroupKeys.has(g.key));
		}
		updateGroupActions();
	}

	function updateGroupActions() {
		const count = selectedWave ? (Project.value(selectedWave.groupsRef) || []).filter((g) => selectedGroupKeys.has(g.key)).length : 0;
		el.copyGroups.disabled = count === 0;
		el.copyGroups.textContent = count > 0 ? `Copiar ${count} grupo(s)` : "Copiar grupos";
		el.pasteGroups.disabled = groupClipboard.length === 0;
		el.pasteGroups.textContent = groupClipboard.length > 0 ? `Pegar ${groupClipboard.length} grupo(s)` : "Pegar grupos";
	}

	// --- Oleadas: copiar, pegar y duplicar ---

	function waveData(wave) {
		return {
			groups: (Project.value(wave.groupsRef) || []).map(groupData),
			hm: Project.value(wave.hmRef),
			label: `${wave.level.name}, oleada ${wave.index + 1}`,
		};
	}

	// Siguiente nombre libre para una oleada del nivel: level_N_K.tres (o emergency_K.tres) con K desde 2.
	async function nextWavePath(level) {
		const prefix = Project.fileName(level.path);
		for (let k = 2; ; k++) {
			const path = `${WAVE_DIR}/${prefix}_${k}.tres`;
			if (!(await Project.fileExists(path))) {
				return path;
			}
		}
	}

	function newWaveText() {
		const uid = scriptUid(WAVE_DATA_SCRIPT);
		return [
			'[gd_resource type="Resource" script_class="WaveData" format=3]',
			"",
			`[ext_resource type="Script"${uid ? ` uid="${uid}"` : ""} path="res://${WAVE_DATA_SCRIPT}" id="1_wave"]`,
			"",
			"[resource]",
			'script = ExtResource("1_wave")',
			"",
		].join("\n");
	}

	// Crea una oleada nueva (un .tres sin uid, pendiente hasta guardar) con esos datos y la pone en el nivel
	// detrás de la oleada afterIndex (-1: la primera).
	async function insertWave(level, afterIndex, data) {
		const path = await nextWavePath(level);
		Project.createFile(path, newWaveText());
		const wave = makeWave(level, path);
		level.waveCache[path] = wave;
		Project.setValue(wave.groupsRef, freshGroups(data.groups));
		if (wave.hmRef && data.hm !== undefined) {
			Project.setValue(wave.hmRef, data.hm);
		}
		const paths = (Project.value(level.wavesRef) || []).slice();
		paths.splice(afterIndex + 1, 0, path);
		selectedWave = wave;
		selectedGroupKeys = new Set();
		Project.setValue(level.wavesRef, paths);
		BalanceApp.setStatus(`Oleada nueva ${Project.fileName(path)}.tres (${data.label}): se crea al guardar.`, "ok");
	}

	async function addEmptyWave() {
		if (selectedLevel) {
			await insertWave(selectedLevel, selectedWave ? selectedWave.index : selectedLevel.waves.length - 1, { groups: [], hm: undefined, label: "vacía" });
		}
	}

	// Quita la oleada elegida del nivel y borra su .tres al guardar (si ningún otro nivel la usa).
	function removeWave() {
		if (!selectedWave) {
			return;
		}
		const wave = selectedWave;
		const level = wave.level;
		if (!window.confirm(`¿Quitar la oleada ${wave.index + 1} (${Project.fileName(wave.path)}.tres) de ${level.name}? Su archivo se borra al guardar.`)) {
			return;
		}
		const paths = (Project.value(level.wavesRef) || []).filter((path) => path !== wave.path);
		selectedWave = level.waves[wave.index + 1] || level.waves[wave.index - 1] || null;
		selectedGroupKeys = new Set();
		Project.setValue(level.wavesRef, paths);
		const usedElsewhere = levels.some((other) => other !== level && (Project.value(other.wavesRef) || []).includes(wave.path));
		if (!usedElsewhere) {
			Project.deleteFile(wave.path);
		}
		BalanceApp.setStatus(`Oleada ${Project.fileName(wave.path)}.tres quitada${usedElsewhere ? "" : ": su archivo se borra al guardar"}.`, "ok");
	}

	async function duplicateWave() {
		if (selectedWave) {
			await insertWave(selectedLevel, selectedWave.index, waveData(selectedWave));
		}
	}

	function copyWave() {
		if (selectedWave) {
			waveClipboard = waveData(selectedWave);
			BalanceApp.setStatus(`Copiada la oleada: ${waveClipboard.label}.`, "ok");
			updateWaveActions();
		}
	}

	async function pasteWaveAfter() {
		if (waveClipboard && selectedLevel) {
			await insertWave(selectedLevel, selectedWave ? selectedWave.index : selectedLevel.waves.length - 1, waveClipboard);
		}
	}

	// Sustituye los grupos y el health_multiplier de la oleada elegida por los copiados.
	function pasteWaveOver() {
		if (!waveClipboard || !selectedWave) {
			return;
		}
		const target = `${selectedLevel.name}, oleada ${selectedWave.index + 1} (${Project.fileName(selectedWave.path)}.tres)`;
		if (!window.confirm(`¿Sustituir los grupos y la vida × de ${target} por los de ${waveClipboard.label}?`)) {
			return;
		}
		selectedGroupKeys = new Set();
		Project.setValue(selectedWave.groupsRef, freshGroups(waveClipboard.groups));
		if (selectedWave.hmRef && waveClipboard.hm !== undefined) {
			Project.setValue(selectedWave.hmRef, waveClipboard.hm);
		}
	}

	function updateWaveActions() {
		el.addWave.disabled = !selectedLevel;
		el.removeWave.disabled = !selectedWave;
		el.duplicateWave.disabled = !selectedWave;
		el.copyWave.disabled = !selectedWave;
		el.pasteWaveAfter.disabled = !waveClipboard || !selectedLevel;
		el.pasteWaveOver.disabled = !waveClipboard || !selectedWave;
		const from = waveClipboard ? `\nCopiada: ${waveClipboard.label}` : "";
		el.pasteWaveAfter.title = "Crea una oleada nueva con la copiada, detrás de la elegida" + from;
		el.pasteWaveOver.title = "Sustituye los grupos y la vida × de la oleada elegida por los de la copiada (pregunta antes)" + from;
	}

	function setGroupField(index, field, value) {
		const groups = currentGroups();
		groups[index][field] = value;
		setGroups(groups);
	}

	function button(text, title, onClick) {
		const b = document.createElement("button");
		b.className = "small";
		b.textContent = text;
		b.title = title;
		b.addEventListener("click", onClick);
		return b;
	}

	// Construye la tabla de grupos de la oleada elegida. Se reconstruye solo si cambian los grupos (añadir,
	// quitar, reordenar); al escribir en una celda solo se actualizan valores, para no perder el foco.
	function buildGroups() {
		const container = el.groups;
		const groups = Project.value(selectedWave.groupsRef) || [];
		const signature = selectedWave.path + "|" + groups.map((g) => g.key).join(",");
		if (groupsEditor && groupsEditor.signature === signature) {
			refreshGroups();
			refreshGroupSelection();
			return;
		}
		selectedGroupKeys = new Set(groups.filter((g) => selectedGroupKeys.has(g.key)).map((g) => g.key));
		const table = document.createElement("table");
		table.className = "balance-table groups-table";
		const head = document.createElement("thead");
		head.innerHTML =
			"<tr>" +
			'<th class="select" title="Elegir grupos para copiarlos; se pega detrás del último elegido"><input type="checkbox" class="check-all"></th>' +
			'<th class="sticky">#</th>' +
			'<th class="editable" title="enemy_data: la nave del grupo (resources/enemy_data/)">Nave</th>' +
			'<th class="editable" title="count: naves del grupo">Cuántas</th>' +
			'<th class="editable" title="pause_after (s): desde su última nave hasta la primera del siguiente grupo. Negativo: se solapan">Pausa después</th>' +
			'<th class="editable" title="path_index: camino del mapa">Camino</th>' +
			'<th class="computed" title="Tiempo de su primera nave desde el inicio de la oleada">Sale a (s)</th>' +
			'<th class="computed" title="count × (reward + trozos)">Recompensa</th>' +
			"<th></th>" +
			"</tr>";
		table.appendChild(head);
		const checkAll = head.querySelector(".check-all");
		checkAll.addEventListener("change", () => toggleAllGroups(checkAll.checked));
		const body = document.createElement("tbody");
		const rows = [];
		groups.forEach((group, index) => {
			const tr = document.createElement("tr");
			tr.className = `group-${index % 2}`;
			const cells = {};

			const checkTd = document.createElement("td");
			checkTd.className = "select";
			const check = document.createElement("input");
			check.type = "checkbox";
			check.title = "Elegir el grupo (copiar, y pegar detrás)";
			check.addEventListener("change", () => toggleGroup(group.key, check.checked));
			checkTd.appendChild(check);
			tr.appendChild(checkTd);

			const number = document.createElement("td");
			number.className = "sticky computed";
			number.textContent = String(index + 1);
			tr.appendChild(number);

			const enemyTd = document.createElement("td");
			enemyTd.className = "editable text";
			const select = document.createElement("select");
			for (const path of enemyPaths) {
				const option = document.createElement("option");
				option.value = path;
				option.textContent = enemyLabel(path);
				select.appendChild(option);
			}
			select.addEventListener("change", () => setGroupField(index, "enemy", select.value));
			enemyTd.appendChild(select);
			tr.appendChild(enemyTd);
			cells.enemy = { td: enemyTd, input: select };

			for (const field of GROUP_FIELDS) {
				const td = document.createElement("td");
				td.className = "editable";
				const input = document.createElement("input");
				input.type = "number";
				input.step = fieldType(field) === "int" ? "1" : "any";
				input.addEventListener("input", () => {
					const text = input.value.trim();
					const value = Number(text);
					let valid = text !== "" && isFinite(value) && (fieldType(field) !== "int" || Number.isInteger(value));
					if (field === "count" || field === "path_index") {
						valid = valid && value >= 0;
					}
					td.classList.toggle("invalid", !valid);
					if (valid) {
						setGroupField(index, field, value);
					}
				});
				input.addEventListener("keydown", (e) => {
					if (e.key === "Enter") {
						input.blur();
					}
				});
				input.addEventListener("blur", () => refreshGroups(true));
				td.appendChild(input);
				tr.appendChild(td);
				cells[field] = { td, input };
			}

			const startTd = document.createElement("td");
			startTd.className = "computed";
			tr.appendChild(startTd);
			const rewardTd = document.createElement("td");
			rewardTd.className = "computed";
			tr.appendChild(rewardTd);

			const actions = document.createElement("td");
			actions.className = "actions";
			actions.append(
				button("↑", "Subir el grupo (sale antes)", () => moveGroup(index, -1)),
				button("↓", "Bajar el grupo (sale después)", () => moveGroup(index, 1)),
				button("⧉", "Duplicar el grupo (la copia va justo debajo)", () => duplicateGroup(index)),
				button("✕", "Quitar el grupo", () => removeGroup(index)),
			);
			tr.appendChild(actions);

			body.appendChild(tr);
			rows.push({ tr, cells, startTd, rewardTd, check });
		});
		table.appendChild(body);
		container.replaceChildren(table);
		groupsEditor = { signature, rows, checkAll };
		refreshGroups(true);
		refreshGroupSelection();
	}

	function refreshGroups(force) {
		if (!groupsEditor || !selectedWave) {
			return;
		}
		const f = BalanceTable.formatNumber;
		const groups = Project.value(selectedWave.groupsRef) || [];
		const original = {};
		for (const g of readGroups(selectedWave.path)) {
			original[g.key] = g;
		}
		const stats = waveStats(selectedWave);
		groups.forEach((group, index) => {
			const row = groupsEditor.rows[index];
			if (!row) {
				return;
			}
			const before = original[group.key];
			row.tr.classList.toggle("new-group", !before);
			row.tr.title = before ? `sub_resource ${group.sub}` : "Grupo nuevo: se añade al guardar";
			for (const field of ["enemy", ...GROUP_FIELDS]) {
				const { td, input } = row.cells[field];
				if (force || document.activeElement !== input) {
					input.value = group[field] === undefined || group[field] === null ? "" : String(group[field]);
					td.classList.remove("invalid");
				}
				td.classList.toggle("changed", !before || before[field] !== group[field]);
			}
			row.startTd.textContent = f(stats.starts[index], 1);
			row.rewardTd.textContent = f(group.count * shipTotals(group.enemy).reward, 0);
		});
	}

	// --- Pintar ---

	function render(container) {
		container.innerHTML = `
			<p class="launcher-help warning" hidden>
				Si «▶ Jugar» no abre nada, falta registrar el lanzador (una vez): en PowerShell, en la carpeta del juego,
				<code>powershell -NoProfile -ExecutionPolicy Bypass -File tools/balance/launcher/registrar.ps1</code>.
				La primera vez el navegador pregunta si abrir «astro-artillery»: marca que lo recuerde y acepta.
				<button class="small launcher-help-close" title="Ocultar este aviso">✕</button>
			</p>
			<div class="levels-layout">
				<div class="levels-list"></div>
				<div class="levels-detail">
					<section class="detail-box">
						<h2 class="waves-title"></h2>
						<div class="waves-table"></div>
						<p class="waves-actions"></p>
					</section>
					<section class="detail-box">
						<h2 class="groups-title"></h2>
						<div class="groups-table"></div>
						<p class="groups-actions"></p>
					</section>
				</div>
			</div>`;
		el.launcherHelp = container.querySelector(".launcher-help");
		container.querySelector(".launcher-help-close").addEventListener("click", () => (el.launcherHelp.hidden = true));
		el.levels = container.querySelector(".levels-list");
		el.wavesTitle = container.querySelector(".waves-title");
		el.waves = container.querySelector(".waves-table");
		el.groupsTitle = container.querySelector(".groups-title");
		el.groups = container.querySelector(".groups-table");
		el.groupsActions = container.querySelector(".groups-actions");
		el.wavesActions = container.querySelector(".waves-actions");
		el.duplicateWave = button("⧉ Duplicar oleada", "Crea una oleada nueva igual que la elegida, justo detrás", duplicateWave);
		el.copyWave = button("Copiar oleada", "Guarda la oleada elegida (grupos y vida ×) en el portapapeles del panel", copyWave);
		el.pasteWaveAfter = button("Pegar detrás", "", pasteWaveAfter);
		el.pasteWaveOver = button("Pegar encima", "", pasteWaveOver);
		el.addWave = button("+ Nueva oleada", "Crea una oleada sin grupos detrás de la elegida (o al final)", addEmptyWave);
		el.removeWave = button("✕ Quitar oleada", "Quita la oleada elegida del nivel; su .tres se borra al guardar (pregunta antes)", removeWave);
		el.wavesActions.append(el.addWave, el.duplicateWave, el.copyWave, el.pasteWaveAfter, el.pasteWaveOver, el.removeWave);
		el.copyGroups = button("Copiar grupos", "Guarda los grupos elegidos en el portapapeles del panel", copyGroups);
		el.pasteGroups = button("Pegar grupos", "Pega los grupos copiados detrás del último elegido (o al final), en cualquier oleada de cualquier nivel", pasteGroups);
		el.groupsActions.append(button("+ Añadir grupo", "Añade un grupo al final (con la nave del último)", addGroup), el.copyGroups, el.pasteGroups);
		levelsTable = BalanceTable.create(el.levels, levelColumns(), levels, {
			onRowClick: selectLevel,
			isSelected: (l) => l === selectedLevel,
		});
		renderLevel();
	}

	function selectLevel(level) {
		if (level === selectedLevel) {
			return;
		}
		selectedLevel = level;
		selectedWave = level.waves[0] || null;
		selectedGroupKeys = new Set();
		levelsTable.refresh();
		renderLevel();
	}

	function selectWave(wave) {
		if (wave === selectedWave) {
			return;
		}
		selectedWave = wave;
		selectedGroupKeys = new Set();
		wavesTable.refresh();
		renderWave();
	}

	function renderLevel() {
		wavesSignature = null;
		if (!selectedLevel) {
			el.wavesTitle.textContent = "No hay niveles.";
			el.waves.replaceChildren();
			wavesTable = null;
			el.wavesActions.hidden = true;
			renderWave();
			return;
		}
		el.wavesActions.hidden = false;
		el.wavesTitle.textContent = `${selectedLevel.name}: oleadas`;
		wavesSignature = waveListSignature();
		wavesTable = BalanceTable.create(el.waves, waveColumns(), selectedLevel.waves, {
			onRowClick: selectWave,
			isSelected: (w) => w === selectedWave,
		});
		renderWave();
	}

	function waveListSignature() {
		return selectedLevel ? selectedLevel.waves.map((w) => w.path + (Project.isCreated(w.path) ? "*" : "")).join(",") : "";
	}

	function renderWave() {
		groupsEditor = null;
		updateWaveActions();
		if (!selectedWave) {
			el.groupsTitle.textContent = "";
			el.groups.replaceChildren();
			el.groupsActions.hidden = true;
			return;
		}
		el.groupsActions.hidden = false;
		el.groupsTitle.textContent = `Oleada ${selectedWave.index + 1}: grupos (${Project.fileName(selectedWave.path)}.tres)`;
		buildGroups();
	}

	function refresh() {
		if (!levelsTable) {
			return;
		}
		// La lista de oleadas cambia al pegar o duplicar una oleada y al descartar.
		for (const level of levels) {
			syncWaves(level);
		}
		if (selectedLevel && !selectedLevel.waves.includes(selectedWave)) {
			selectedWave = selectedLevel.waves[0] || null;
			selectedGroupKeys = new Set();
		}
		levelsTable.refresh();
		if (waveListSignature() !== wavesSignature) {
			renderLevel();
			return;
		}
		if (wavesTable) {
			wavesTable.refresh();
		}
		if (selectedWave) {
			buildGroups();
		}
	}

	return { id: "levels", label: "Niveles", load, render, refresh };
})();

if (typeof module !== "undefined") {
	module.exports = LevelsTab;
}
