shader_type canvas_item;

// Pantalla de la mesa de Sectores, en la consola inclinada del menú: un trapecio (más estrecho
// arriba) con fondo de cuadrícula y, encima, la pantalla de Sectores de verdad (screen_texture, la
// textura de RadarViewport, recortada a su contenido con `crop`) estirada a todo el trapecio. Va en
// un ColorRect del tamaño de la caja del trapecio y pinta el fondo en píxeles enteros; fuera del
// trapecio, transparente. La coloca RadarConsole con los datos de OfficeLayout (y la endereza con el
// zoom de Sectores). Al verse encogida, cada píxel se queda con lo más brillante de los texeles que
// cubre, para que las letras finas no se apaguen; a tamaño real es un solo texel.

uniform vec2 rect_size;
// Extremos del trapecio, en píxeles del ColorRect: arriba (izquierda, derecha) y abajo.
uniform vec2 top_span;
uniform vec2 bottom_span;
uniform sampler2D screen_texture : filter_nearest, repeat_disable, hint_default_transparent;
// Parte de la textura que se enseña (x, y, ancho, alto en UV).
uniform vec4 crop = vec4(0.0, 0.0, 1.0, 1.0);

const vec3 SCREEN_DARK = vec3(6.0, 13.0, 24.0) / 255.0;
const vec3 SCREEN = vec3(8.0, 17.0, 31.0) / 255.0;
const vec3 GRID = vec3(13.0, 30.0, 46.0) / 255.0;
const vec3 CYAN_DEEP = vec3(20.0, 48.0, 74.0) / 255.0;

void fragment() {
	// Pantalla de Sectores, con coordenadas continuas: al final del zoom cae píxel a píxel.
	vec2 pc = UV * rect_size;
	float vc = pc.y / rect_size.y;
	float xlc = mix(top_span.x, bottom_span.x, vc);
	float xrc = mix(top_span.y, bottom_span.y, vc);
	vec2 tuv = crop.xy + vec2((pc.x - xlc) / (xrc - xlc), vc) * crop.zw;
	vec2 tex_size = vec2(textureSize(screen_texture, 0));
	vec2 texels = max(fwidth(tuv) * tex_size, vec2(1.0));
	vec2 p = floor(UV * rect_size);
	float v = p.y / max(rect_size.y - 1.0, 1.0);
	float xl = mix(top_span.x, bottom_span.x, v);
	float xr = mix(top_span.y, bottom_span.y, v);
	if (p.x < xl || p.x >= xr) {
		COLOR = vec4(0.0);
	} else {
		float u = (p.x - xl) / (xr - xl);
		vec2 q = vec2((u - 0.5) * 3.0, (v - 0.5) * 2.0);
		vec3 c = mod(p.y, 2.0) > 0.5 ? SCREEN_DARK : SCREEN;
		vec2 g = abs(q * 5.0 - round(q * 5.0));
		if (g.x < 0.05 || g.y < 0.07) {
			c = GRID;
		}
		float edge = min(min(p.x - xl, xr - 1.0 - p.x), min(p.y, rect_size.y - 1.0 - p.y));
		if (edge < 2.0) {
			c = CYAN_DEEP;
		}
		vec4 t = vec4(0.0);
		for (int i = 0; i < 3; i++) {
			for (int j = 0; j < 3; j++) {
				vec2 o = (vec2(float(i), float(j)) - 1.0) / 3.0 * (texels - 1.0) / tex_size;
				t = max(t, texture(screen_texture, tuv + o));
			}
		}
		COLOR = vec4(mix(c, t.rgb, t.a), 1.0);
	}
}
