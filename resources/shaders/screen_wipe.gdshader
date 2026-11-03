// Transición de pantalla en tramado de píxeles (ScreenWipe): la pantalla se tapa (o se destapa) por
// celdas cuadradas que avanzan desde un punto hacia fuera, mezclando la distancia con una matriz de
// Bayer 4x4 para que el frente salga tramado. El frente brilla en cian y su borde en el tono claro.
// Celdas enteras de píxeles lógicos y colores planos, sin antialiasing.
shader_type canvas_item;

// 0 = nada tapado, 1 = todo tapado.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Tamaño del rectángulo en píxeles lógicos y punto de partida, en los mismos píxeles.
uniform vec2 rect_size = vec2(960.0, 540.0);
uniform vec2 origin = vec2(480.0, 270.0);
uniform float cell_size = 4.0;
// Con true se tapa primero lo lejano: al destapar, lo cercano al punto se ve antes.
uniform bool reverse_order = false;
// Ancho del frente brillante, en la misma escala que progress.
uniform float edge_width = 0.08;
uniform vec4 fill_color : source_color = vec4(0.024, 0.043, 0.078, 1.0);
uniform vec4 edge_color : source_color = vec4(0.251, 0.878, 0.941, 1.0);
uniform vec4 core_color : source_color = vec4(0.745, 0.98, 1.0, 1.0);

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
// Peso del tramado frente a la distancia.
const float DITHER_WEIGHT = 0.2;

void fragment() {
	vec2 cell = floor(UV * rect_size / cell_size);
	vec2 center = (cell + 0.5) * cell_size;
	// Distancia al punto de partida, 0..1 respecto a la esquina más lejana.
	vec2 far_corner = max(origin, rect_size - origin);
	float dist = length(center - origin) / length(far_corner);
	int index = int(mod(cell.y, 4.0)) * 4 + int(mod(cell.x, 4.0));
	float value = dist * (1.0 - DITHER_WEIGHT) + BAYER[index] / 16.0 * DITHER_WEIGHT;
	if (reverse_order) {
		value = 1.0 - value;
	}
	float t = progress * (1.0 + edge_width);
	if (value >= t) {
		COLOR = vec4(0.0);
	} else if (value >= t - edge_width * 0.3) {
		COLOR = core_color;
	} else if (value >= t - edge_width) {
		COLOR = edge_color;
	} else {
		COLOR = fill_color;
	}
}
