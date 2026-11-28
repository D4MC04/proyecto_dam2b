// Pestaña Sprites: torretas (base, fusión y nivel 3 juntos) y naves, a escala entera y con sus animaciones.
// Solo se ve: lee los SpriteFrames de los .tres y los PNG de la carpeta elegida; no escribe nada.
"use strict";

const SpritesTab = (() => {
	const TURRET_DIR = "resources/turret_data";
	const ENEMY_DIR = "resources/enemy_data";
	const ZOOMS = [1, 2, 3, 4, 6, 8];
	const DEFAULT_ZOOM = 4;
	// Huecos de vista de una torreta, de izquierda a derecha.
	const TURRET_KINDS = ["main", "fx"];
	const TIERS = [
		{ id: "base", label: "Base" },
		{ id: "fusion", label: "Fusión" },
		{ id: "level3", label: "Nivel 3" },
	];

	let families = [];
	let enemies = [];
	let images = new Map();
	let frameModels = new Map();
	let views = [];
	let cards = [];
	let zoom = DEFAULT_ZOOM;
	let playButton = null;
	let lastTime = null;
	let animationHandle = null;

	// --- Lectura de SpriteFrames ---

	// Lee un valor de Godot (array, diccionario, cadena, &"nombre", número, SubResource, ...) desde la posición i.
	function parseVariant(text, start) {
		let i = start;
		function skipSpaces() {
			while (i < text.length && /\s/.test(text[i])) {
				i++;
			}
		}
		function readString() {
			let out = "";
			i++;
			while (i < text.length && text[i] !== '"') {
				if (text[i] === "\\") {
					i++;
				}
				out += text[i];
				i++;
			}
			i++;
			return out;
		}
		function readValue() {
			skipSpaces();
			const c = text[i];
			if (c === "[") {
				i++;
				const list = [];
				for (;;) {
					skipSpaces();
					if (text[i] === "]" || i >= text.length) {
						i++;
						return list;
					}
					list.push(readValue());
					skipSpaces();
					if (text[i] === ",") {
						i++;
					}
				}
			}
			if (c === "{") {
				i++;
				const dict = {};
				for (;;) {
					skipSpaces();
					if (text[i] === "}" || i >= text.length) {
						i++;
						return dict;
					}
					const key = readValue();
					skipSpaces();
					i++; // ":"
					dict[key] = readValue();
					skipSpaces();
					if (text[i] === ",") {
						i++;
					}
				}
			}
			if (c === '"') {
				return readString();
			}
			if (c === "&" && text[i + 1] === '"') {
				i++;
				return readString();
			}
			const word = /^[A-Za-z_][\w.]*|^[-+]?[\d.]+(?:e[-+]?\d+)?/i.exec(text.slice(i));
			if (!word) {
				throw new Error(`SpriteFrames: no entiendo «${text.slice(i, i + 20)}»`);
			}
			i += word[0].length;
			if (/^[-+\d.]/.test(word[0])) {
				return Number(word[0]);
			}
			if (text[i] === "(") {
				// Llamada tipo SubResource("id") o ExtResource("id").
				const close = text.indexOf(")", i);
				const args = text.slice(i + 1, close).trim().replace(/^"|"$/g, "");
				i = close + 1;
				if (word[0] === "SubResource") {
					return { sub: args };
				}
				if (word[0] === "ExtResource") {
					return { ext: args };
				}
				return { call: word[0], args };
			}
			if (word[0] === "true" || word[0] === "false") {
				return word[0] === "true";
			}
			return word[0] === "null" ? null : word[0];
		}
		return readValue();
	}

	// Textura de un frame: {path, x, y, w, h} (w y h null si es la imagen entera) o null.
	function frameTexture(doc, value) {
		if (value && value.ext && doc.ext[value.ext]) {
			return { path: doc.ext[value.ext].path, x: 0, y: 0, w: null, h: null };
		}
		if (value && value.sub) {
			const section = Tres.findSection(doc, value.sub);
			if (!section || !section.props.atlas) {
				return null;
			}
			const atlas = Tres.parseValue(section.props.atlas.raw);
			if (!atlas || !atlas.ext || !doc.ext[atlas.ext]) {
				return null;
			}
			const rect = section.props.region ? /Rect2\(([^)]*)\)/.exec(section.props.region.raw) : null;
			if (!rect) {
				return { path: doc.ext[atlas.ext].path, x: 0, y: 0, w: null, h: null };
			}
			const [x, y, w, h] = rect[1].split(",").map(Number);
			return { path: doc.ext[atlas.ext].path, x, y, w, h };
		}
		return null;
	}

	// Modelo de un .tres de SpriteFrames: {names, anims: {nombre: {speed, loop, frames: [{duration, tex}]}}}.
	function buildFrames(n) {
		if (frameModels.has(n.path)) {
			return frameModels.get(n.path);
		}
		const model = { names: [], anims: {} };
		const prop = n.section.props.animations;
		if (prop) {
			const text = n.doc.lines.slice(prop.line).join("\n").replace(/^\s*animations\s*=\s*/, "");
			const list = parseVariant(text, 0);
			for (const anim of Array.isArray(list) ? list : []) {
				const name = String(anim.name);
				model.names.push(name);
				model.anims[name] = {
					speed: Number(anim.speed),
					loop: !!anim.loop,
					frames: (anim.frames || []).map((f) => ({ duration: Number(f.duration) || 1, tex: frameTexture(n.doc, f.texture) })),
				};
			}
		}
		frameModels.set(n.path, model);
		return model;
	}

	// Nodos de SpriteFrames a los que apunta un campo (uno o una lista), con su archivo ya cargado.
	async function framesNodes(n, key) {
		const raw = Project.rawValue(n, key);
		const values = Array.isArray(raw) ? raw : [raw];
		const found = [];
		for (const v of values) {
			if (v && v.ext && n.doc.ext[v.ext]) {
				const path = n.doc.ext[v.ext].path;
				await Project.loadDoc(path);
				const target = Project.node(path, null);
				if (target) {
					found.push(target);
				}
			}
		}
		return found;
	}

	// --- Imágenes ---

	function modelPaths(model) {
		const paths = new Set();
		for (const name of model.names) {
			for (const frame of model.anims[name].frames) {
				if (frame.tex) {
					paths.add(frame.tex.path);
				}
			}
		}
		return paths;
	}

	async function loadImage(path) {
		if (images.has(path)) {
			return;
		}
		let bitmap = null;
		try {
			bitmap = await createImageBitmap(await Project.readBlob(path));
		} catch (e) {
			console.warn(`Sprites: no se pudo leer ${path}`, e);
		}
		images.set(path, bitmap);
	}

	// --- Carga ---

	// Huecos de una torreta: torreta (base + cañón) y efectos (fogonazo y animación de mejora, los que tenga).
	async function turretSlots(n) {
		const layers = [];
		for (const node of await framesNodes(n, "sprite_frames")) {
			layers.push({ label: "Base", model: buildFrames(node), preferred: ["default"] });
		}
		for (const node of await framesNodes(n, "cannon")) {
			layers.push({ label: "Cañón", model: buildFrames(node), preferred: ["default"] });
		}
		const slots = { main: { title: "Torreta", layers } };
		const variants = [];
		for (const [key, label] of [["muzzle_flash", "Fogonazo"], ["upgrade_frames", "Mejora"]]) {
			for (const node of await framesNodes(n, key)) {
				variants.push({ label, model: buildFrames(node), preferred: ["default"] });
			}
		}
		if (variants.length > 0) {
			slots.fx = { title: "Efectos", layers: [{ label: variants[0].label, variants, model: variants[0].model, preferred: variants[0].preferred }] };
		}
		return slots;
	}

	// Una ficha por nave y una más por cada sprite de desgaste (drain_frames), todas con un solo hueco.
	async function enemyEntries(path, n) {
		const entries = [];
		for (const node of await framesNodes(n, "sprite_frames")) {
			entries.push({ path, node: n, slots: { enemy: { title: "Nave", layers: [{ label: "Nave", model: buildFrames(node), preferred: ["up", "default"] }] } } });
		}
		let index = 1;
		for (const node of await framesNodes(n, "drain_frames")) {
			const tag = `desgaste ${index}`;
			entries.push({ path, node: n, tag, slots: { enemy: { title: `Nave (${tag})`, layers: [{ label: "Nave", model: buildFrames(node), preferred: ["up", "default"] }] } } });
			index++;
		}
		return entries;
	}

	async function load() {
		stopAnimation();
		families = [];
		enemies = [];
		images = new Map();
		frameModels = new Map();
		const byFamily = new Map();
		for (const path of await Project.loadDir(TURRET_DIR)) {
			const n = Project.node(path, null);
			if (!n) {
				continue;
			}
			const stem = Project.fileName(path);
			const tier = stem.endsWith("_fusion") ? "fusion" : stem.endsWith("_level3") ? "level3" : "base";
			const family = stem.replace(/_(fusion|level3)$/, "");
			if (!byFamily.has(family)) {
				byFamily.set(family, { id: family, tiers: {} });
				families.push(byFamily.get(family));
			}
			byFamily.get(family).tiers[tier] = { path, node: n, slots: await turretSlots(n) };
		}
		for (const path of await Project.loadDir(ENEMY_DIR)) {
			const n = Project.node(path, null);
			if (n) {
				enemies.push(...(await enemyEntries(path, n)));
			}
		}
		const paths = new Set();
		const entries = [...enemies, ...families.flatMap((f) => Object.values(f.tiers))];
		for (const entry of entries) {
			for (const view of Object.values(entry.slots)) {
				for (const layer of view.layers) {
					layerModels(layer).forEach((model) => modelPaths(model).forEach((p) => paths.add(p)));
				}
			}
		}
		await Promise.all([...paths].map(loadImage));
	}

	// --- Animación ---

	function animationLength(anim) {
		if (!anim || anim.speed <= 0) {
			return 0;
		}
		return anim.frames.reduce((sum, f) => sum + f.duration, 0) / anim.speed;
	}

	// Frame que toca en el instante t: con bucle da la vuelta, sin bucle se queda en el último.
	function frameAt(anim, t) {
		if (!anim || anim.frames.length === 0) {
			return null;
		}
		const total = animationLength(anim);
		if (total <= 0) {
			return anim.frames[0];
		}
		let time = anim.loop ? t % total : Math.min(t, total);
		for (const frame of anim.frames) {
			const length = frame.duration / anim.speed;
			if (time < length) {
				return frame;
			}
			time -= length;
		}
		return anim.frames[anim.frames.length - 1];
	}

	function textureSize(tex) {
		if (tex.w !== null) {
			return { w: tex.w, h: tex.h };
		}
		const bitmap = images.get(tex.path);
		return bitmap ? { w: bitmap.width, h: bitmap.height } : { w: 16, h: 16 };
	}

	// Modelos que puede mostrar una capa: uno, o uno por variante (fogonazo / mejora).
	function layerModels(layer) {
		return layer.variants ? layer.variants.map((v) => v.model) : [layer.model];
	}

	// Tamaño en px del lienzo de una vista: el frame más grande de todas sus capas y animaciones.
	function viewSize(view) {
		let w = 1;
		let h = 1;
		for (const layer of view.layers) {
			for (const model of layerModels(layer)) {
				for (const name of model.names) {
					for (const frame of model.anims[name].frames) {
						if (frame.tex) {
							const size = textureSize(frame.tex);
							w = Math.max(w, size.w);
							h = Math.max(h, size.h);
						}
					}
				}
			}
		}
		return { w, h };
	}

	function drawView(v) {
		const ctx = v.canvas.getContext("2d");
		ctx.imageSmoothingEnabled = false;
		ctx.clearRect(0, 0, v.canvas.width, v.canvas.height);
		for (const layer of v.layers) {
			const frame = frameAt(layer.model.anims[layer.current], v.time);
			if (!frame || !frame.tex) {
				continue;
			}
			const size = textureSize(frame.tex);
			const dx = Math.floor((v.canvas.width - size.w * zoom) / 2);
			const dy = Math.floor((v.canvas.height - size.h * zoom) / 2);
			const bitmap = images.get(frame.tex.path);
			if (bitmap) {
				ctx.drawImage(bitmap, frame.tex.x, frame.tex.y, size.w, size.h, dx, dy, size.w * zoom, size.h * zoom);
			} else {
				// Falta el PNG: un recuadro rojo con aspa.
				ctx.strokeStyle = "#f0323c";
				ctx.strokeRect(dx + 0.5, dy + 0.5, size.w * zoom - 1, size.h * zoom - 1);
				ctx.beginPath();
				ctx.moveTo(dx, dy);
				ctx.lineTo(dx + size.w * zoom, dy + size.h * zoom);
				ctx.moveTo(dx + size.w * zoom, dy);
				ctx.lineTo(dx, dy + size.h * zoom);
				ctx.stroke();
			}
		}
	}

	function resizeView(v) {
		v.canvas.width = v.size.w * zoom;
		v.canvas.height = v.size.h * zoom;
		drawView(v);
	}

	// ¿Acaba sola la animación de esta vista? (todas las capas sin bucle y ya al final)
	function isFinished(v) {
		return v.layers.every((l) => {
			const anim = l.model.anims[l.current];
			return !anim || (!anim.loop && v.time >= animationLength(anim));
		});
	}

	function setPlaying(v, playing) {
		if (playing && isFinished(v)) {
			v.time = 0;
		}
		v.playing = playing;
		v.playButton.textContent = playing ? "⏸" : "▶";
		v.playButton.title = playing ? "Pausar" : "Reproducir con los fps y el bucle de la animación";
		if (playing) {
			startAnimation();
		}
		drawView(v);
	}

	function tick(now) {
		const dt = lastTime === null ? 0 : (now - lastTime) / 1000;
		lastTime = now;
		let any = false;
		for (const v of views) {
			if (!v.playing) {
				continue;
			}
			v.time += dt;
			drawView(v);
			if (isFinished(v)) {
				setPlaying(v, false);
			} else {
				any = true;
			}
		}
		animationHandle = any ? requestAnimationFrame(tick) : null;
		if (!any) {
			lastTime = null;
		}
		updateAllButton();
	}

	function startAnimation() {
		if (animationHandle === null) {
			lastTime = null;
			animationHandle = requestAnimationFrame(tick);
		}
	}

	function stopAnimation() {
		if (animationHandle !== null) {
			cancelAnimationFrame(animationHandle);
		}
		animationHandle = null;
		lastTime = null;
		views = [];
		cards = [];
	}

	function updateAllButton() {
		if (playButton) {
			const anyPlaying = views.some((v) => v.playing);
			playButton.textContent = anyPlaying ? "⏸ Pausar todo" : "▶ Reproducir todo";
		}
	}

	// --- Interfaz ---

	// Ancho mínimo de una vista (para que quepan el desplegable y el texto aunque el sprite sea pequeño).
	const MIN_VIEW_WIDTH = 150;
	// Alto de los controles de una capa (con y sin selector de variante).
	const LAYER_HEIGHT = 40;
	const LAYER_HEIGHT_VARIANTS = 68;
	// Por tipo de vista (main, flash, enemy): el mayor sprite y el mayor número de capas de todas las filas.
	// Así todas las vistas del mismo tipo miden lo mismo y las filas quedan alineadas.
	let kindInfo = {};
	let panel = null;

	function computeKinds(entries) {
		kindInfo = {};
		for (const entry of entries) {
			for (const [kind, view] of Object.entries(entry.slots)) {
				const size = viewSize(view);
				const info = kindInfo[kind] || (kindInfo[kind] = { w: 1, h: 1, controls: 0 });
				info.w = Math.max(info.w, size.w);
				info.h = Math.max(info.h, size.h);
				info.controls = Math.max(info.controls, view.layers.reduce((sum, l) => sum + (l.variants && l.variants.length > 1 ? LAYER_HEIGHT_VARIANTS : LAYER_HEIGHT), 0));
			}
		}
	}

	// Medidas de cada tipo de vista según el zoom, como variables CSS del panel.
	function applyLayout() {
		for (const [kind, info] of Object.entries(kindInfo)) {
			panel.style.setProperty(`--w-${kind}`, `${Math.max(MIN_VIEW_WIDTH, info.w * zoom + 12)}px`);
			panel.style.setProperty(`--h-${kind}`, `${info.controls}px`);
			panel.style.setProperty(`--hs-${kind}`, `${info.h * zoom + 8}px`);
			panel.style.setProperty(`--hv-${kind}`, `${26 + info.h * zoom + 8 + 4 + info.controls}px`);
		}
	}

	function element(tag, className, text) {
		const e = document.createElement(tag);
		if (className) {
			e.className = className;
		}
		if (text !== undefined) {
			e.textContent = text;
		}
		return e;
	}

	function animationInfo(layer) {
		const anim = layer.model.anims[layer.current];
		if (!anim) {
			return "sin animación";
		}
		return `${anim.frames.length} ${anim.frames.length === 1 ? "frame" : "frames"} · ${anim.speed} fps · ${anim.loop ? "bucle" : "sin bucle"}`;
	}

	function buildView(data, kind) {
		const info = kindInfo[kind];
		const v = { layers: data.layers.map((l) => ({ ...l, current: l.preferred.find((p) => l.model.anims[p]) || l.model.names[0] })), size: { w: info.w, h: info.h }, time: 0, playing: false };
		const box = element("div", "sprite-view");
		box.style.width = `var(--w-${kind})`;
		const bar = element("div", "sprite-view-bar");
		const titleEl = element("span", "sprite-view-title", data.layers[0].variants ? data.layers[0].variants[0].label : data.title);
		bar.appendChild(titleEl);
		v.playButton = element("button", "sprite-play", "▶");
		v.playButton.addEventListener("click", () => setPlaying(v, !v.playing));
		bar.appendChild(v.playButton);
		box.appendChild(bar);
		const stage = element("div", "sprite-stage");
		stage.style.height = `var(--hs-${kind})`;
		v.canvas = element("canvas", "sprite-canvas");
		stage.appendChild(v.canvas);
		box.appendChild(stage);
		const controls = element("div", "sprite-controls");
		controls.style.height = `var(--h-${kind})`;
		for (const layer of v.layers) {
			const row = element("div", "sprite-layer");
			const label = element("span", "sprite-layer-label", layer.label);
			const text = element("span", "sprite-info sprite-info-line");
			const select = element("select", "sprite-select");
			const animName = element("span", "sprite-anim-name");
			// Rellena el desplegable con las animaciones del modelo actual de la capa.
			const fillAnimations = () => {
				select.textContent = "";
				for (const name of layer.model.names) {
					const option = element("option", "", name);
					option.value = name;
					select.appendChild(option);
				}
				select.value = layer.current;
				select.hidden = layer.model.names.length <= 1;
				animName.textContent = layer.current || "";
				animName.hidden = layer.model.names.length > 1;
				text.textContent = animationInfo(layer);
			};
			select.addEventListener("change", () => {
				layer.current = select.value;
				v.time = 0;
				text.textContent = animationInfo(layer);
				drawView(v);
			});
			if (layer.variants && layer.variants.length > 1) {
				const variantSelect = element("select", "sprite-select");
				layer.variants.forEach((variant, index) => {
					const option = element("option", "", variant.label);
					option.value = String(index);
					variantSelect.appendChild(option);
				});
				variantSelect.addEventListener("change", () => {
					const variant = layer.variants[Number(variantSelect.value)];
					layer.model = variant.model;
					layer.current = variant.preferred.find((p) => variant.model.anims[p]) || variant.model.names[0];
					v.time = 0;
					titleEl.textContent = variant.label;
					fillAnimations();
					drawView(v);
				});
				row.appendChild(variantSelect);
			} else {
				row.appendChild(label);
			}
			row.appendChild(select);
			row.appendChild(animName);
			fillAnimations();
			row.appendChild(text);
			controls.appendChild(row);
		}
		box.appendChild(controls);
		resizeView(v);
		views.push(v);
		return box;
	}

	// Un hueco de tipo kind: la vista si la tiene, o un espacio del mismo ancho.
	function buildSlot(entry, kind) {
		if (entry.slots[kind]) {
			return buildView(entry.slots[kind], kind);
		}
		const spacer = element("div", "sprite-view");
		spacer.style.width = `var(--w-${kind})`;
		spacer.style.height = `var(--hv-${kind})`;
		return spacer;
	}

	function entryName(entry) {
		return () => Project.translate(Project.rawValue(entry.node, "name"));
	}

	// Ficha de una torreta o nave: nombre y archivo (cada uno en una línea) y sus huecos de vista.
	function buildCard(entry, kinds) {
		const card = element("div", "sprite-card");
		const head = element("div", "sprite-card-head");
		const name = element("div", "sprite-name", entryName(entry)());
		head.appendChild(name);
		const fileName = Project.fileName(entry.path);
		head.appendChild(element("div", "sprite-file", entry.tag ? `${fileName} · ${entry.tag}` : fileName));
		card.appendChild(head);
		const slots = element("div", "sprite-slots");
		for (const kind of kinds) {
			if (kindInfo[kind]) {
				slots.appendChild(buildSlot(entry, kind));
			}
		}
		card.appendChild(slots);
		cards.push({ name, nameOf: entryName(entry) });
		return card;
	}

	function render(container) {
		stopAnimation();
		panel = container;
		container.textContent = "";
		computeKinds([...enemies, ...families.flatMap((f) => Object.values(f.tiers))]);
		applyLayout();

		const toolbar = element("div", "sprite-toolbar");
		toolbar.appendChild(element("label", "", "Zoom "));
		const zoomSelect = element("select", "sprite-select");
		for (const z of ZOOMS) {
			const option = element("option", "", `×${z}`);
			option.value = String(z);
			zoomSelect.appendChild(option);
		}
		zoomSelect.value = String(zoom);
		zoomSelect.addEventListener("change", () => {
			zoom = Number(zoomSelect.value);
			applyLayout();
			views.forEach(resizeView);
		});
		toolbar.appendChild(zoomSelect);
		playButton = element("button", "", "▶ Reproducir todo");
		playButton.addEventListener("click", () => {
			const play = !views.some((v) => v.playing);
			views.forEach((v) => setPlaying(v, play));
			updateAllButton();
		});
		toolbar.appendChild(playButton);
		toolbar.appendChild(element("span", "sprite-hint", "Solo se ve: la animación va con los fps y el bucle del SpriteFrames. Cada vista tiene su ▶."));
		container.appendChild(toolbar);

		// Torretas: una fila por torreta, con una columna por fase (base, fusión, nivel 3).
		container.appendChild(element("h2", "sprite-section", "Torretas"));
		const turretGrid = element("div", "sprite-grid sprite-grid-turrets");
		turretGrid.appendChild(element("div"));
		for (const tier of TIERS) {
			turretGrid.appendChild(element("div", "sprite-col-head", tier.label));
		}
		for (const family of families) {
			const first = family.tiers.base || Object.values(family.tiers)[0];
			turretGrid.appendChild(element("div", "sprite-family-name", entryName(first)()));
			for (const tier of TIERS) {
				const entry = family.tiers[tier.id];
				turretGrid.appendChild(entry ? buildCard(entry, TURRET_KINDS) : element("div"));
			}
		}
		container.appendChild(turretGrid);

		// Naves: una ficha por nave (y una por cada sprite de desgaste), todas del mismo tamaño.
		container.appendChild(element("h2", "sprite-section", "Naves"));
		const enemyGrid = element("div", "sprite-grid sprite-grid-enemies");
		for (const entry of enemies) {
			enemyGrid.appendChild(buildCard(entry, ["enemy"]));
		}
		container.appendChild(enemyGrid);
		updateAllButton();
	}

	// Los nombres traducidos pueden cambiar al guardar el CSV desde la pestaña Diálogos.
	function refresh() {
		for (const card of cards) {
			card.name.textContent = card.nameOf();
		}
	}

	return { id: "sprites", label: "Sprites", load, render, refresh };
})();
