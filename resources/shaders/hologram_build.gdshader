// Materialización de una torreta: una línea de escaneo cian sube de abajo arriba.
// Por debajo de la línea la torreta es sólida; por encima es un holograma cian translúcido que parpadea.
// Trabaja en coordenadas de mundo, así base y cañón (que gira) comparten la misma línea.
shader_type canvas_item;

// 0 = línea en la base, 1 = línea en lo alto.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Centro de la torreta en y (mundo) y mitad de su altura.
uniform float center_y = 0.0;
uniform float half_height = 9.0;
uniform vec4 holo_color : source_color = vec4(0.251, 0.878, 0.941, 1.0);
uniform float holo_alpha : hint_range(0.0, 1.0) = 0.45;
uniform float line_width = 1.5;

varying float world_y;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	float line_y = mix(center_y + half_height, center_y - half_height, progress);
	float dist = world_y - line_y;
	if (dist < -line_width) {
		// Ya sólido: se deja el color original.
	} else if (dist < 0.0) {
		COLOR.rgb = holo_color.rgb * 2.0;
	} else {
		// Holograma: parpadeo por filas y en el tiempo.
		float flicker = 0.75 + 0.25 * hash(floor(world_y) + floor(TIME * 30.0));
		float lum = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
		COLOR.rgb = holo_color.rgb * (0.6 + 0.8 * lum);
		COLOR.a *= holo_alpha * flicker;
	}
}
