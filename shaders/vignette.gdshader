shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.6;
uniform vec4 vignette_color : source_color = vec4(0.02, 0.01, 0.03, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv * vec2(1.0, 0.85)); // Widescreen oval curvature
	float vig = smoothstep(0.35, 0.75, dist) * vignette_intensity;
	COLOR = vec4(vignette_color.rgb, vig * vignette_opacity);
}
