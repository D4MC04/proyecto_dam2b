// Pestaña Torretas: una fila por resources/turret_data/*.tres, con base, fusión y nivel 3 juntas.
"use strict";

const TurretsTab = (() => {
	const TURRET_DIR = "resources/turret_data";

	// Campo de TurretData que decide el tipo de ataque y cómo se llama en el panel.
	const ATTACKS = [
		{ key: "bullet_data", label: "Bala" },
		{ key: "pulse", label: "Onda" },
		{ key: "chain", label: "Cadena" },
		{ key: "beam", label: "Haz" },
		{ key: "focus_beam", label: "Haz continuo" },
		{ key: "orbit", label: "Órbita" },
	];

	const DPS_TITLE = [
		"DPS aproximado a un objetivo:",
		"Bala: daño × salva ÷ cooldown (con la cadencia base, sin sobrecalentamiento).",
		"Onda, Cadena y Haz: daño ÷ cooldown a cada enemigo que alcanza.",
		"Órbita: daño ÷ cooldown (una carga por cooldown).",
		"Haz continuo: damage_per_second del nivel 1.",
		"El área, los saltos y la perforación pegan a más enemigos: no cuentan aquí.",
	].join("\n");

	let rows = [];
	let table = null;

	async function load() {
		rows = [];
		const paths = await Project.loadDir(TURRET_DIR);
		const byPath = {};
		for (const path of paths) {
			const n = Project.node(path, null);
			if (!n) {
				continue;
			}
			const row = { path, node: n, attackKey: null, attack: null, shape: null, prev: null, next: null, level: 1 };
			row.shape = await Project.loadLinked(n, "attack_range");
			for (const attack of ATTACKS) {
				const target = await Project.loadLinked(n, attack.key);
				if (target) {
					row.attackKey = attack.key;
					row.attack = target;
					break;
				}
			}
			byPath[path] = row;
		}
		// Cadena de mejoras: fusion apunta al nivel siguiente.
		for (const row of Object.values(byPath)) {
			const next = Project.linked(row.node, "fusion");
			if (next && byPath[next.path]) {
				row.next = byPath[next.path];
				byPath[next.path].prev = row;
			}
		}
		const bases = Object.values(byPath).filter((r) => !r.prev);
		bases.sort((a, b) => (Project.rawValue(a.node, "cost") || 0) - (Project.rawValue(b.node, "cost") || 0) || a.path.localeCompare(b.path));
		const seen = new Set();
		bases.forEach((base, groupIndex) => {
			let level = 1;
			for (let row = base; row && !seen.has(row); row = row.next) {
				seen.add(row);
				row.level = level++;
				row.rowClass = `group-${groupIndex % 2} level-${row.level}`;
				rows.push(row);
			}
		});
		// Lo que no esté en ninguna cadena (no debería pasar) va al final.
		for (const row of Object.values(byPath)) {
			if (!seen.has(row)) {
				row.rowClass = "orphan";
				rows.push(row);
			}
		}
		markShared();
	}

	// Aviso de archivos compartidos (alcance o ataque) entre varias torretas.
	function markShared() {
		const users = {};
		for (const row of rows) {
			for (const linked of [row.shape, row.attack]) {
				if (linked) {
					(users[linked.path] = users[linked.path] || []).push(row);
				}
			}
		}
		const warning = (linked) => {
			if (!linked || users[linked.path].length < 2) {
				return null;
			}
			const names = users[linked.path].map(rowName).join(", ");
			return `⚠ ${Project.fileName(linked.path)}.tres lo comparten: ${names}. Cambiarlo cambia todas.`;
		};
		for (const row of rows) {
			row.shapeShared = warning(row.shape);
			row.attackShared = warning(row.attack);
		}
	}

	function rowName(row) {
		return Project.translate(Project.rawValue(row.node, "name"));
	}

	function turretValue(row, key) {
		return Project.value(Project.ref(row.node, key));
	}

	function attackValue(row, key) {
		return row.attack ? Project.value(Project.ref(row.attack, key)) : undefined;
	}

	// Coste total para tenerla en este nivel: el suyo más el de los niveles anteriores.
	function totalCost(row) {
		let total = 0;
		for (let r = row; r; r = r.prev) {
			total += turretValue(r, "cost") || 0;
		}
		return total;
	}

	// DPS aproximado a un objetivo y la cuenta que lo explica.
	function dps(row) {
		const f = BalanceTable.formatNumber;
		const cooldown = turretValue(row, "attack_cooldown");
		const damage = attackValue(row, "damage");
		switch (row.attackKey) {
			case "bullet_data": {
				const salvo = turretValue(row, "salvo_count") || 1;
				const value = (damage * salvo) / cooldown;
				let text = `Bala: ${f(damage)} × ${salvo} ÷ ${f(cooldown)} = ${f(value)}`;
				const minCooldown = turretValue(row, "overheat_min_cooldown");
				if (turretValue(row, "overheat_shots") > 0 && minCooldown > 0) {
					text += `\nPico con sobrecalentamiento: ${f(damage)} × ${salvo} ÷ ${f(minCooldown)} = ${f((damage * salvo) / minCooldown)}`;
				}
				return { value, text };
			}
			case "pulse":
			case "chain":
			case "beam":
			case "orbit": {
				const value = damage / cooldown;
				const label = ATTACKS.find((a) => a.key === row.attackKey).label;
				return { value, text: `${label}: ${f(damage)} ÷ ${f(cooldown)} = ${f(value)}` };
			}
			case "focus_beam": {
				const levels = attackValue(row, "damage_per_second") || [];
				return {
					value: levels[0],
					text: `Haz continuo: DPS del nivel 1 = ${f(levels[0])} (niveles ${levels.map((v) => f(v)).join(" / ")}, sube cada ${f(attackValue(row, "level_time"))} s sobre el mismo enemigo)`,
				};
			}
			default:
				return { value: undefined, text: "No ataca." };
		}
	}

	function turretColumn(key, label, group, title) {
		return { id: key, label, group, title: title || key, ref: (row) => Project.ref(row.node, key) };
	}

	function attackColumn(attackKey, key, label, group, title, index) {
		return {
			id: `${attackKey}.${key}${index === undefined ? "" : index}`,
			label,
			group,
			title: title || key,
			ref: (row) => (row.attackKey === attackKey ? Project.ref(row.attack, key, index) : null),
			shared: (row) => (row.attackKey === attackKey ? row.attackShared : null),
		};
	}

	function columns() {
		const f = BalanceTable.formatNumber;
		return [
			{
				id: "name",
				label: "Torreta",
				sticky: true,
				get: rowName,
				format: (v) => v,
				cellTitle: (row) => row.path,
			},
			{ id: "level", label: "Nv", title: "Nivel: 1 base, 2 fusión, 3 nivel 3", get: (row) => row.level },
			{
				id: "attack",
				label: "Ataque",
				get: (row) => {
					if (row.attackKey) {
						return ATTACKS.find((a) => a.key === row.attackKey).label;
					}
					return turretValue(row, "money_amount") > 0 ? "Minero" : turretValue(row, "amplifier_level") > 0 ? "Amplificador" : "—";
				},
				format: (v) => v,
			},
			turretColumn("cost", "Coste", "Torreta", "cost (€)"),
			turretColumn("attack_cooldown", "Cooldown", "Torreta", "attack_cooldown (s)"),
			turretColumn("salvo_count", "Salva", "Torreta", "salvo_count: balas por disparo"),
			{
				id: "range",
				label: "Alcance",
				group: "Torreta",
				title: "radius del Shape2D de attack_range (px), en resources/collision_shapes/",
				ref: (row) => (row.shape ? Project.ref(row.shape, "radius") : null),
				shared: (row) => row.shapeShared,
				cellTitle: (row) => (row.shape ? row.shape.path : ""),
			},
			turretColumn("min_range", "Mín.", "Torreta", "min_range (px): con más de 0, el alcance es un anillo"),
			turretColumn("turn_speed", "Giro", "Torreta", "turn_speed (°/s); 0 = no gira"),
			{
				id: "damage",
				label: "Daño",
				group: "Ataque",
				title: "damage del recurso de ataque",
				ref: (row) => (row.attack && row.attackKey !== "focus_beam" ? Project.ref(row.attack, "damage") : null),
				shared: (row) => row.attackShared,
				cellTitle: (row) => (row.attack ? row.attack.path : ""),
			},
			attackColumn("bullet_data", "speed", "Vel.", "Bala", "speed (px/s)"),
			attackColumn("bullet_data", "pierce", "Perfora", "Bala", "pierce: enemigos que atraviesa"),
			attackColumn("bullet_data", "splash_radius", "Área", "Bala", "splash_radius (px)"),
			attackColumn("bullet_data", "slow_factor", "Frenado", "Bala", "slow_factor: velocidad que conserva el enemigo (0,1 = va al 10 %)"),
			attackColumn("bullet_data", "slow_duration", "Dur.", "Bala", "slow_duration (s)"),
			attackColumn("chain", "max_targets", "Objetivos", "Cadena", "max_targets"),
			attackColumn("chain", "jump_range", "Salto", "Cadena", "jump_range (px)"),
			attackColumn("beam", "half_width", "½ ancho", "Haz", "half_width (px)"),
			attackColumn("beam", "length", "Largo", "Haz", "length (px)"),
			attackColumn("pulse", "slow_factor", "Frenado", "Onda", "slow_factor: velocidad que conserva el enemigo (0,55 = va al 55 %)"),
			attackColumn("pulse", "slow_time", "Dur.", "Onda", "slow_time (s)"),
			attackColumn("pulse", "start_radius", "Radio ini.", "Onda", "start_radius (px): radio de la onda en su primer frame"),
			attackColumn("pulse", "growth", "Crece", "Onda", "growth (px por frame): radio = start_radius + growth × frame"),
			attackColumn("focus_beam", "damage_per_second", "DPS N1", "Haz continuo", "damage_per_second[0]", 0),
			attackColumn("focus_beam", "damage_per_second", "DPS N2", "Haz continuo", "damage_per_second[1]", 1),
			attackColumn("focus_beam", "damage_per_second", "DPS N3", "Haz continuo", "damage_per_second[2]", 2),
			attackColumn("focus_beam", "level_time", "T. nivel", "Haz continuo", "level_time (s) sobre el mismo enemigo para subir de nivel"),
			attackColumn("orbit", "splash_radius", "Área", "Órbita", "splash_radius (px)"),
			attackColumn("orbit", "max_orbs", "Cargas", "Órbita", "max_orbs"),
			turretColumn("overheat_shots", "Disparos", "Sobrecalentamiento", "overheat_shots: disparos hasta pararse (0 = no se calienta)"),
			turretColumn("overheat_min_cooldown", "Cad. mín.", "Sobrecalentamiento", "overheat_min_cooldown (s): cooldown a tope"),
			turretColumn("overheat_time", "Rampa", "Sobrecalentamiento", "overheat_time (s)"),
			turretColumn("overheat_cool_time", "Parada", "Sobrecalentamiento", "overheat_cool_time (s)"),
			turretColumn("money_amount", "Dinero", "Apoyo", "money_amount (€ cada attack_cooldown s): Minero"),
			turretColumn("amplifier_level", "Nv. amp.", "Apoyo", "amplifier_level: Amplificador"),
			{
				id: "total_cost",
				label: "Coste acum.",
				group: "Calculado",
				title: "Coste acumulado: el suyo más el de los niveles anteriores (lo invertido para tenerla en este nivel)",
				get: totalCost,
				format: (v) => f(v, 0),
			},
			{
				id: "dps",
				label: "DPS",
				group: "Calculado",
				title: DPS_TITLE,
				get: (row) => dps(row).value,
				format: (v) => f(v, 1),
				cellTitle: (row) => dps(row).text,
			},
			{
				id: "dps_per_cost",
				label: "DPS/€",
				group: "Calculado",
				title: "DPS ÷ coste acumulado",
				get: (row) => {
					const value = dps(row).value;
					return value === undefined ? undefined : value / totalCost(row);
				},
				format: (v) => f(v, 3),
				cellTitle: (row) => {
					const value = dps(row).value;
					return value === undefined ? "" : `${f(value, 1)} ÷ ${f(totalCost(row), 0)} = ${f(value / totalCost(row), 3)}`;
				},
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

	return { id: "turrets", label: "Torretas", load, render, refresh };
})();
