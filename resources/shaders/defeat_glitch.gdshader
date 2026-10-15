// Glitch de la derrota: corta el área de juego con bandas horizontales desplazadas y estática.
// Va en un ColorRect que tapa el área de juego, encima del oscurecido y debajo del panel.
// Todo se calcula sobre la rejilla de píxeles de juego (1 px = 1 píxel del viewport de 960x540),
// así que no hay desenfoque ni bordes suaves. El patrón lo cambia el script a saltos con `seed`.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
// Tamaño del rectángulo en píxeles de juego.
uniform vec2 rect_size = vec2(704.0, 540.0);
// 1 = corte fuerte de la entrada; 0 = sin bandas ni estática fuerte.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
// Estática tenue que queda con el panel estable.
uniform float residual : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;
// Desplazamiento máximo de una banda, en píxeles de juego.
uniform float max_shift = 40.0;
uniform vec4 tint_color : source_color = vec4(1.0, 0.235, 0.353, 1.0);
uniform vec4 static_color : source_color = vec4(1.0, 0.667, 0.745, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = floor(UV * rect_size);
	// Cuánto avanza SCREEN_UV por cada unidad de UV: sirve para pasar píxeles de juego a pantalla
	// y para no leer fuera del área de juego (las barras).
	vec2 screen_per_uv = vec2(dFdx(SCREEN_UV.x) / dFdx(UV.x), dFdy(SCREEN_UV.y) / dFdy(UV.y));
	float area_left = SCREEN_UV.x - UV.x * screen_per_uv.x;
	float area_right = area_left + screen_per_uv.x;

	// Bandas de 2, 4, 6 u 8 px; en cada paso cambian su alto y cuáles se desplazan.
	float band_height = 2.0 + floor(hash(vec2(seed, 3.1)) * 4.0) * 2.0;
	float band = floor(px.y / band_height);
	float shift = 0.0;
	if (hash(vec2(band, seed)) < intensity * 0.4) {
		shift = floor((hash(vec2(band, seed + 7.3)) - 0.5) * 2.0 * max_shift * intensity);
	}
	vec2 uv = SCREEN_UV;
	uv.x -= shift / rect_size.x * screen_per_uv.x;
	uv.x = clamp(uv.x, area_left, area_right - 0.0001);
	vec3 color = texture(screen_texture, uv).rgb;

	// Las bandas desplazadas se tiñen del rojo de la derrota.
	if (shift != 0.0) {
		color = mix(color, color * 0.5 + tint_color.rgb * 0.4, 0.3);
	}

	// Estática de la entrada: píxeles sueltos en el claro del acento.
	float grain = hash(px + vec2(seed * 13.7, seed * 5.3));
	if (grain > 1.0 - intensity * 0.08) {
		color = mix(color, static_color.rgb, 0.4 + 0.5 * hash(px.yx + seed));
	}

	// Estática residual: algunas filas sueltas con píxeles tenues que cambian en cada paso.
	if (residual > 0.0 && hash(vec2(px.y, seed + 1.7)) > 0.97 && grain > 0.5) {
		color = mix(color, static_color.rgb, residual);
	}

	// Líneas de barrido: una fila de cada dos algo más oscura.
	float scanline = mod(px.y, 2.0);
	color *= 1.0 - scanline * (0.12 * intensity + 0.5 * residual);

	COLOR = vec4(color, 1.0);
}
