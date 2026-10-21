// Camuflaje del Espectro: el sprite se disuelve píxel a píxel de la punta a la cola, en franjas
// de interferencia (las filas pares van un poco por detrás), con un borde morado brillante.
// Todo va sobre la rejilla de píxeles de la textura, sin antialiasing.
// `progress` 0 = visible, 1 = camuflado; para reaparecer se anima de 1 a 0.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Opacidad de los píxeles ya disueltos.
uniform float cloaked_alpha : hint_range(0.0, 1.0) = 0.2;
// Ancho del borde brillante, en la escala del umbral (0-1).
uniform float edge_width = 0.12;
uniform vec4 edge_color : source_color = vec4(0.667, 0.471, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
	// Umbral de cada píxel: barrido de arriba abajo, ruido y franjas alternas.
	float threshold = 0.55 * UV.y + 0.3 * hash(px) + 0.15 * mod(px.y, 2.0);
	float sweep = progress * (1.0 + edge_width);
	if (threshold < sweep - edge_width) {
		COLOR.a *= cloaked_alpha;
	} else if (threshold < sweep) {
		COLOR.rgb = edge_color.rgb;
	}
}
