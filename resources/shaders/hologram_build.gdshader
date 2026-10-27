// Materialización de una torreta: una línea de escaneo cian sube de abajo arriba.
// Por encima de la línea es un holograma (rampa cian de 4 tonos con el relieve del sprite, borde
// brillante, scanlines que se desplazan y parpadeo); la línea es un núcleo blanco, una fila cian y
// una estela punteada; por debajo la torreta ya es sólida.
// Todo va en filas de píxeles del mundo (base y cañón, que gira, comparten la línea) y sin antialiasing.
// Respeta el tinte (modulate) de apagado por EMP y de calor: el holograma se oscurece con él y la parte
// sólida lo conserva.
shader_type canvas_item;

// 0 = línea bajo la torreta, 1 = línea por encima de ella (con la estela ya fuera).
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Fila de mundo de la línea con progress = 0 y con progress = 1.
uniform float line_start = 0.0;
uniform float line_end = 0.0;
uniform vec4 holo_color : source_color = vec4(0.251, 0.878, 0.941, 1.0);
uniform float holo_alpha : hint_range(0.0, 1.0) = 0.55;
// Filas de estela por debajo de la línea.
uniform float trail_length = 5.0;

varying float world_y;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	if (COLOR.a <= 0.0) {
		discard;
	}
	vec4 original = COLOR;
	float row = floor(world_y);
	float line_row = floor(mix(line_start, line_end, progress));
	// Filas por debajo de la línea (hacia abajo en pantalla); negativo = por encima.
	float k = row - line_row;
	if (k >= trail_length) {
		// Ya sólido: se deja el color original.
	} else if (k >= 0.0) {
		if (k < 1.0) {
			// Núcleo de la línea: blanco.
			COLOR.rgb = vec3(0.92, 1.0, 1.0);
		} else if (k < 2.0) {
			COLOR.rgb = holo_color.rgb * 1.25;
		} else {
			// Estela: la torreta sólida teñida de cian, en 3 pasos y punteada en los más débiles.
			float strength = floor((1.0 - (k - 2.0) / (trail_length - 2.0)) * 3.0 + 0.999) / 3.0;
			float checker = mod(floor(UV.x / TEXTURE_PIXEL_SIZE.x) + row, 2.0);
			COLOR.rgb = mix(COLOR.rgb, holo_color.rgb * 1.3, strength * 0.75);
			if (strength < 0.5 && checker < 0.5) {
				COLOR = original;
			}
		}
	} else {
		// Holograma. Borde: píxeles con algún vecino transparente.
		vec2 px = TEXTURE_PIXEL_SIZE;
		float neighbors = texture(TEXTURE, UV + vec2(px.x, 0.0)).a
				* texture(TEXTURE, UV - vec2(px.x, 0.0)).a
				* texture(TEXTURE, UV + vec2(0.0, px.y)).a
				* texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		bool edge = neighbors < 0.5;

		float lum = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
		// Se realza el relieve para que las torretas oscuras también se lean; 4 tonos de cian.
		float level = floor(clamp(pow(lum, 0.7) * 1.1 + 0.1, 0.0, 0.999) * 4.0);
		vec3 tone;
		if (level < 1.0) {
			tone = vec3(0.04, 0.26, 0.36);
		} else if (level < 2.0) {
			tone = vec3(0.12, 0.5, 0.65);
		} else if (level < 3.0) {
			tone = holo_color.rgb;
		} else {
			tone = vec3(0.78, 1.0, 1.0);
		}
		// La estela y la fila justo encima de la línea brillan más.
		float alpha = holo_alpha;
		if (edge) {
			tone = mix(tone, vec3(0.8, 1.0, 1.0), 0.65);
			alpha = 0.95;
		}
		if (k > -2.0) {
			tone = mix(tone, vec3(0.8, 1.0, 1.0), 0.5);
			alpha = max(alpha, 0.8);
		}

		// Scanlines que se desplazan, filas que se apagan y parpadeo general (todo a pasos, no suave).
		float t = floor(TIME * 14.0);
		if (mod(row + t, 3.0) < 1.0) {
			alpha *= 0.5;
			tone *= 0.85;
		}
		if (hash(vec2(row, t)) > 0.9) {
			alpha *= 0.3;
		}
		if (hash(vec2(t, 7.0)) > 0.88) {
			alpha *= 0.7;
		}
		// El holograma se enciende en los primeros instantes.
		alpha *= min(progress * 12.0, 1.0);

		COLOR = vec4(tone, COLOR.a * alpha);
	}
}
