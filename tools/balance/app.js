// Arranque del panel: pestañas, abrir proyecto, guardar y descartar.
"use strict";

const BalanceApp = (() => {
	// Las pestañas sin load/render salen como "Pendiente" (las hacen otros tickets).
	const TABS = [
		TurretsTab,
		EnemiesTab,
		LevelsTab,
		DialogsTab,
		SpritesTab,
	];

	let handle = null;
	let activeTab = TABS[0].id;
	const el = {};

	function init() {
		for (const id of ["open-button", "reload-button", "save-button", "discard-button", "project-name", "status", "tab-bar", "tab-content", "unsupported"]) {
			el[id] = document.getElementById(id);
		}
		buildTabs();
		if (!("showDirectoryPicker" in window)) {
			el.unsupported.hidden = false;
			el["open-button"].disabled = true;
		}
		el["open-button"].addEventListener("click", openProject);
		el["reload-button"].addEventListener("click", reload);
		el["save-button"].addEventListener("click", save);
		el["discard-button"].addEventListener("click", discard);
		Project.onChange(onProjectChange);
		Project.onSaved(async (paths) => {
			for (const tab of TABS) {
				if (tab.onSaved) {
					await tab.onSaved(paths);
				}
			}
		});
		window.addEventListener("beforeunload", (e) => {
			if (Project.pendingCount > 0) {
				e.preventDefault();
				e.returnValue = "";
			}
		});
		updateButtons();
	}

	function buildTabs() {
		for (const tab of TABS) {
			const button = document.createElement("button");
			button.className = "tab";
			button.textContent = tab.label;
			button.dataset.tab = tab.id;
			button.addEventListener("click", () => selectTab(tab.id));
			el["tab-bar"].appendChild(button);

			const panel = document.createElement("section");
			panel.className = "tab-panel";
			panel.id = `tab-${tab.id}`;
			panel.innerHTML = tab.render ? '<p class="placeholder">Pulsa «Abrir proyecto» y elige la carpeta del juego.</p>' : '<p class="placeholder">Pendiente.</p>';
			el["tab-content"].appendChild(panel);
		}
		selectTab(activeTab);
	}

	function selectTab(id) {
		activeTab = id;
		for (const button of el["tab-bar"].children) {
			button.classList.toggle("active", button.dataset.tab === id);
		}
		for (const panel of el["tab-content"].children) {
			panel.hidden = panel.id !== `tab-${id}`;
		}
	}

	function setStatus(text, kind) {
		el.status.textContent = text;
		el.status.className = kind || "";
	}

	function confirmDiscard() {
		return Project.pendingCount === 0 || window.confirm(`Hay ${Project.pendingCount} cambios sin guardar. ¿Descartarlos?`);
	}

	async function openProject() {
		if (!confirmDiscard()) {
			return;
		}
		let picked;
		try {
			picked = await window.showDirectoryPicker({ id: "astro-artillery", mode: "readwrite" });
		} catch (e) {
			// El usuario ha cerrado el selector.
			return;
		}
		await loadProject(picked);
	}

	async function reload() {
		if (handle && confirmDiscard()) {
			await loadProject(handle);
		}
	}

	async function loadProject(picked) {
		setStatus("Cargando…");
		try {
			await Project.openWithHandle(picked);
			handle = picked;
			for (const tab of TABS) {
				if (tab.load) {
					await tab.load();
				}
			}
			for (const tab of TABS) {
				if (tab.render) {
					tab.render(document.getElementById(`tab-${tab.id}`));
				}
			}
			el["project-name"].textContent = picked.name;
			setStatus(`Proyecto cargado: ${picked.name}`, "ok");
		} catch (e) {
			console.error(e);
			setStatus(e.message || String(e), "error");
		}
		updateButtons();
	}

	// Devuelve true si se ha guardado todo.
	async function save() {
		const paths = Project.pendingPaths;
		setStatus("Guardando…");
		try {
			const saved = await Project.save();
			setStatus(`Guardado en ${saved.length} archivo(s): ${saved.join(", ")}`, "ok");
			return true;
		} catch (e) {
			console.error(e);
			setStatus(`Error al guardar (${paths.join(", ")}): ${e.message || e}`, "error");
			return false;
		}
	}

	function discard() {
		if (Project.pendingCount > 0 && window.confirm(`¿Descartar ${Project.pendingCount} cambios?`)) {
			Project.discard();
			setStatus("Cambios descartados.");
		}
	}

	function onProjectChange() {
		for (const tab of TABS) {
			if (tab.refresh) {
				tab.refresh();
			}
		}
		updateButtons();
	}

	function updateButtons() {
		const pending = Project.pendingCount;
		el["save-button"].disabled = pending === 0;
		el["discard-button"].disabled = pending === 0;
		el["reload-button"].disabled = !Project.isOpen;
		el["save-button"].textContent = pending > 0 ? `Guardar (${pending})` : "Guardar";
	}

	return { init, save, setStatus };
})();

document.addEventListener("DOMContentLoaded", BalanceApp.init);
