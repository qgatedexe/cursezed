shader_type canvas_item;

uniform vec3 fog_color : source_color = vec3(0.05, 0.08, 0.06);
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float time_speed : hint_range(0.0, 2.0) = 0.2;
uniform float noise_scale : hint_range(0.1, 5.0) = 1.5;

float noise(vec2 p) {
    return sin(p.x * 10.0 + TIME * time_speed) * sin(p.y * 8.0 + TIME * time_speed * 0.7) * 0.5 + 0.5;
}

void fragment() {
    vec2 uv = UV;
    float n = noise(uv * noise_scale);
    float fog = smoothstep(0.25, 0.75, n) * density;
    COLOR = vec4(fog_color, fog);
}