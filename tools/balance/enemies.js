// Pestaña Enemigos: una fila por resources/enemy_data/*.tres.
"use strict";

const EnemiesTab = (() => {
	const ENEMY_DIR = "resources/enemy_data";
	// Velocidad de referencia (Corsair): enemigos.md da la velocidad como múltiplo de 60 px/s.
	const BASE_SPEED = 60;

	let rows = [];
	let table = null;

	async function load() {
		rows = [];
		const paths = await Project.loadDir(ENEMY_DIR);
		paths.forEach((path, index) => {
			const n = Project.node(path, null);
			if (n) {
				rows.push({ path, node: n, rowClass: `group-${index % 2}` });
			}
		});
	}

	function rowName(row) {
		return Project.translate(Project.rawValue(row.node, "name"));
	}

	function enemyValue(row, key) {
		return Project.value(Project.ref(row.node, key));
	}

	function enemyColumn(key, label, title) {
		return { id: key, label, title: title || key, ref: (row) => Project.ref(row.node, key) };
	}

	function columns() {
		const f = BalanceTable.formatNumber;
		return [
			{ id: "name", label: "Nave", sticky: true, get: rowName, format: (v) => v, cellTitle: (row) => row.path },
			{ id: "file", label: "Archivo", get: (row) => Project.fileName(row.path), format: (v) => v, cls: "file" },
			enemyColumn("hp", "Vida", "hp"),
			enemyColumn("speed", "Velocidad", "speed (px/s)"),
			{
				id: "spacing",
				label: "Separación (s)",
				title: "Segundos entre dos naves seguidas de un grupo: spawn_spacing.tres, una entrada por velocidad. Cambiarla cambia todas las naves con esa velocidad",
				ref: (row) => Project.spacingRef(() => enemyValue(row, "speed")),
				warn: (row) => !Project.hasSpacing(enemyValue(row, "speed")),
				cellTitle: (row) => {
					const speed = enemyValue(row, "speed");
					if (!Project.hasSpacing(speed)) {
						const seconds = BalanceTable.formatNumber(Project.DEFAULT_SPACING);
						return `${speed} px/s no está en spawn_spacing.tres: el juego usa ${seconds} s. Pon una separación para añadir la entrada.`;
					}
					return `Compartida por todas las naves de ${speed} px/s`;
				},
			},
			enemyColumn("reward", "Botín", "reward (€)"),
			enemyColumn("base_damage", "Daño est.", "base_damage: vida que quita a la estación al llegar"),
			enemyColumn("heal_rate", "Curación", "heal_rate (Mender)"),
			enemyColumn("reveal_time", "Camuflaje", "reveal_time (s); 0 = no se camufla"),
			enemyColumn("emp_radius", "EMP radio", "emp_radius (px); 0 = no explota al morir"),
			enemyColumn("death_damage", "Daño muerte", "death_damage: daño de la explosión al morir"),
			{
				id: "split_into",
				label: "Se parte en",
				title: "split_into (solo se ve)",
				get: (row) => Project.linkedList(row.node, "split_into").map((n) => Project.translate(Project.rawValue(n, "name")) + " (" + Project.fileName(n.path) + ")").join(", "),
				format: (v) => v,
				cls: "text",
			},
			{
				id: "hp_per_reward",
				label: "Vida/€",
				group: "Calculado",
				title: "hp ÷ reward",
				get: (row) => enemyValue(row, "hp") / enemyValue(row, "reward"),
				format: (v) => f(v, 1),
			},
			{
				id: "speed_factor",
				label: "Vel. ×60",
				group: "Calculado",
				title: `speed ÷ ${BASE_SPEED}: la velocidad como múltiplo de ${BASE_SPEED} px/s, como en la tabla de enemigos.md`,
				get: (row) => enemyValue(row, "speed") / BASE_SPEED,
				format: (v) => f(v, 2),
			},
		];
	}

	function render(container) {
		table = BalanceTable.create(container, columns(), rows);
	}

	function refresh() {
		if (table) {
			table.refresh();
		}
	}

	return { id: "enemies", label: "Enemigos", load, render, refresh };
})();
