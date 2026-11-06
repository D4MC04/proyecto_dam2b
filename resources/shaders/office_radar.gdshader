shader_type canvas_item;

// Pantalla del radar de la mesa de Sectores, en la consola inclinada del menú: un trapecio (más
// estrecho arriba) con cuadrícula, tres anillos, cruz y un barrido con estela tramada. Va en un
// ColorRect del tamaño de la caja del trapecio y pinta en píxeles enteros; fuera del trapecio,
// transparente. Lo anima RadarConsole (sweep) y lo coloca con los datos de OfficeLayout.

uniform vec2 rect_size;
// Extremos del trapecio, en píxeles del ColorRect: arriba (izquierda, derecha) y abajo.
uniform vec2 top_span;
uniform vec2 bottom_span;
// Ángulo del barrido, en radianes.
uniform float sweep = 0.0;
uniform float radius = 0.78;

const vec3 SCREEN_DARK = vec3(6.0, 13.0, 24.0) / 255.0;
const vec3 SCREEN = vec3(8.0, 17.0, 31.0) / 255.0;
const vec3 GRID = vec3(13.0, 30.0, 46.0) / 255.0;
const vec3 CYAN_DEEP = vec3(20.0, 48.0, 74.0) / 255.0;
const vec3 CYAN_DARK = vec3(28.0, 116.0, 150.0) / 255.0;
const vec3 CYAN_LIGHT = vec3(190.0, 250.0, 255.0) / 255.0;
const int BAYER[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

void fragment() {
	vec2 p = floor(UV * rect_size);
	float v = p.y / max(rect_size.y - 1.0, 1.0);
	float xl = mix(top_span.x, bottom_span.x, v);
	float xr = mix(top_span.y, bottom_span.y, v);
	if (p.x < xl || p.x >= xr) {
		COLOR = vec4(0.0);
	} else {
		float u = (p.x - xl) / (xr - xl);
		// El radar se ve chafado en vertical: la mesa está inclinada.
		vec2 q = vec2((u - 0.5) * 3.0, (v - 0.5) * 2.0);
		float r = length(q);
		float a = atan(q.y, q.x);
		vec3 c = mod(p.y, 2.0) > 0.5 ? SCREEN_DARK : SCREEN;
		vec2 g = abs(q * 5.0 - round(q * 5.0));
		if (g.x < 0.05 || g.y < 0.07) {
			c = GRID;
		}
		if (r <= radius + 0.01) {
			for (int i = 1; i <= 3; i++) {
				float ring = radius * float(i) / 3.0;
				if (abs(r - ring) < 0.022) {
					c = i == 3 ? CYAN_DARK : CYAN_DEEP;
				}
			}
			if (abs(q.x) < 0.016 || abs(q.y) < 0.02) {
				c = CYAN_DEEP;
			}
			float d = mod(sweep - a, TAU);
			if (r < radius - 0.01) {
				if (d < 0.06) {
					c = CYAN_LIGHT;
				} else if (d < 1.0) {
					// Estela del barrido en tramado de Bayer, más densa cerca de la línea.
					float level = (1.0 - d) * 11.0;
					float b = float(BAYER[int(mod(p.y, 4.0)) * 4 + int(mod(p.x, 4.0))]);
					if (b < level) {
						c = level > 6.0 && b < level - 5.0 ? CYAN_DARK : CYAN_DEEP;
					}
				}
			}
		}
		float edge = min(min(p.x - xl, xr - 1.0 - p.x), min(p.y, rect_size.y - 1.0 - p.y));
		if (edge < 2.0) {
			c = CYAN_DEEP;
		}
		COLOR = vec4(c, 1.0);
	}
}
