shader_type canvas_item;

// Pantalla de la mesa de Sectores, en la consola inclinada del menú: un trapecio (más estrecho
// arriba) con fondo de cuadrícula y, encima, la pantalla de Sectores de verdad (screen_texture, la
// textura de RadarViewport, recortada a su contenido con `crop`) estirada a todo el trapecio. Va en
// un ColorRect del tamaño de la caja del trapecio y pinta el fondo en píxeles enteros; fuera del
// trapecio, transparente. La coloca RadarConsole con los datos de OfficeLayout (y la endereza con el
// zoom de Sectores). Con el zoom aparece (frame_alpha) un marco de metal en el borde del recorte,
// para que al final se vea la pantalla con su marco y no solo lo de dentro.

uniform vec2 rect_size;
// Extremos del trapecio, en píxeles del ColorRect: arriba (izquierda, derecha) y abajo.
uniform vec2 top_span;
uniform vec2 bottom_span;
uniform sampler2D screen_texture : filter_linear, repeat_disable, hint_default_transparent;
// Parte de la textura que se enseña (x, y, ancho, alto en UV) y su tamaño en píxeles del menú.
uniform vec4 crop = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 screen_px = vec2(960.0, 540.0);
// Grosor del marco en píxeles del menú y cuánto se ve (0 en la mesa, 1 al final del zoom).
uniform float frame_px = 24.0;
uniform float frame_alpha = 0.0;

const vec3 SCREEN_DARK = vec3(6.0, 13.0, 24.0) / 255.0;
const vec3 SCREEN = vec3(8.0, 17.0, 31.0) / 255.0;
const vec3 GRID = vec3(13.0, 30.0, 46.0) / 255.0;
const vec3 CYAN_DEEP = vec3(20.0, 48.0, 74.0) / 255.0;
const vec3 CYAN_DARK = vec3(28.0, 116.0, 150.0) / 255.0;
const vec3 CYAN = vec3(64.0, 224.0, 240.0) / 255.0;
const vec3 OUTLINE = vec3(12.0, 14.0, 22.0) / 255.0;
const vec3 METAL_DARK = vec3(52.0, 58.0, 74.0) / 255.0;
const vec3 METAL = vec3(96.0, 106.0, 124.0) / 255.0;
const vec3 METAL_LIGHT = vec3(150.0, 162.0, 182.0) / 255.0;
const vec3 AMBER = vec3(236.0, 178.0, 60.0) / 255.0;

// Marco de metal: contorno, bisel claro arriba e izquierda y oscuro abajo y derecha, línea cian por
// dentro, pilotos cian arriba y luces ámbar en las esquinas. `s` = posición en píxeles del menú.
vec3 frame_color(vec2 s) {
	float left = s.x;
	float right = screen_px.x - 1.0 - s.x;
	float top = s.y;
	float bottom = screen_px.y - 1.0 - s.y;
	float d = min(min(left, right), min(top, bottom));
	if (d < 2.0 || d >= frame_px - 2.0) {
		return OUTLINE;
	}
	if (d >= frame_px - 4.0) {
		return CYAN_DARK;
	}
	if (min(left, right) < 14.0 && min(top, bottom) < 14.0 && min(left, right) >= 6.0 && min(top, bottom) >= 6.0) {
		return AMBER;
	}
	if (top == d && abs(top - frame_px * 0.5) < 1.5 && mod(s.x, 28.0) < 12.0 && left > 28.0 && right > 28.0) {
		return mod(floor(s.x / 28.0), 4.0) == 1.0 ? CYAN_DEEP : CYAN;
	}
	if (top == d || left == d) {
		return d < 5.0 ? METAL_LIGHT : METAL;
	}
	return d < 5.0 ? METAL_DARK : METAL;
}

void fragment() {
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
		// Pantalla de Sectores, con coordenadas continuas: al final del zoom cae píxel a píxel.
		vec2 pc = UV * rect_size;
		float vc = pc.y / rect_size.y;
		float xlc = mix(top_span.x, bottom_span.x, vc);
		float xrc = mix(top_span.y, bottom_span.y, vc);
		vec2 uvc = vec2((pc.x - xlc) / (xrc - xlc), vc);
		vec4 t = texture(screen_texture, crop.xy + uvc * crop.zw);
		c = mix(c, t.rgb, t.a);
		vec2 s = floor(uvc * screen_px);
		float d = min(min(s.x, screen_px.x - 1.0 - s.x), min(s.y, screen_px.y - 1.0 - s.y));
		if (frame_alpha > 0.0 && d < frame_px) {
			c = mix(c, frame_color(s), frame_alpha);
		}
		COLOR = vec4(c, 1.0);
	}
}
