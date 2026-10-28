// Onda de un Amplificador al pasar por una torreta amplificada: versión ligera y en ámbar de la
// línea de escaneo de construir (hologram_build.gdshader). La torreta sigue sólida (sin holograma):
// una línea ámbar sube de abajo arriba con una estela corta punteada, y el contorno del sprite brilla
// en ámbar y se apaga a pasos mientras dura.
// Todo va en filas de píxeles del mundo (base y cañón, que gira, comparten la línea) y sin antialiasing.
// Respeta el tinte (modulate) de apagado por EMP y de calor.
shader_type canvas_item;

// 0 = línea bajo la torreta, 1 = línea por encima de ella (con la estela ya fuera).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Fila de mundo de la línea con progress = 0 y con progress = 1.
uniform float line_start = 0.0;
uniform float line_end = 0.0;
// Filas de estela por debajo de la línea.
uniform float trail_length = 3.0;
uniform vec4 core_color : source_color = vec4(1.0, 0.973, 0.902, 1.0);
uniform vec4 amber_color : source_color = vec4(0.925, 0.698, 0.235, 1.0);
// Fuerza del brillo del contorno al empezar (baja hasta 0 al acabar).
uniform float edge_glow : hint_range(0.0, 1.0) = 0.6;

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	if (COLOR.a <= 0.0) {
		discard;
	}
	float row = floor(world_y);
	float line_row = floor(mix(line_start, line_end, progress));
	// Filas por debajo de la línea (hacia abajo en pantalla); negativo = por encima.
	float k = row - line_row;
	// Contorno: píxeles con algún vecino transparente. Brilla en 3 pasos que se apagan.
	vec2 px = TEXTURE_PIXEL_SIZE;
	float neighbors = texture(TEXTURE, UV + vec2(px.x, 0.0)).a
			* texture(TEXTURE, UV - vec2(px.x, 0.0)).a
			* texture(TEXTURE, UV + vec2(0.0, px.y)).a
			* texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	if (neighbors < 0.5) {
		float fade = floor((1.0 - progress) * 3.0 + 0.999) / 3.0;
		COLOR.rgb = mix(COLOR.rgb, amber_color.rgb * 1.2, edge_glow * fade);
	}
	if (k >= 0.0 && k < trail_length) {
		if (k < 1.0) {
			// Núcleo de la línea: ámbar casi blanco, mezclado para que no tape la torreta del todo.
			COLOR.rgb = mix(COLOR.rgb, core_color.rgb, 0.85);
		} else {
			// Estela teñida de ámbar en 2 pasos; la más débil, punteada.
			float strength = k < 2.0 ? 0.6 : 0.3;
			float checker = mod(floor(UV.x / TEXTURE_PIXEL_SIZE.x) + row, 2.0);
			if (strength > 0.5 || checker > 0.5) {
				COLOR.rgb = mix(COLOR.rgb, amber_color.rgb * 1.25, strength);
			}
		}
	}
}
