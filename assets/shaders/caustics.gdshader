shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float speed : hint_range(0.0, 2.0) = 0.6;
uniform float scale : hint_range(0.5, 5.0) = 2.5;
uniform vec3 caustic_color : source_color = vec3(0.2, 0.35, 0.45);

float noise(vec2 p) {
    return sin(p.x * 8.0 + TIME * speed) * sin(p.y * 6.0 + TIME * speed * 0.7) * 0.5 + 0.5;
}

void fragment() {
    vec2 uv = UV;
    float n1 = noise(uv * scale + vec2(TIME * speed, TIME * speed * 0.5));
    float n2 = noise(uv * scale * 1.3 + vec2(TIME * speed * -0.7, TIME * speed * 0.3));
    float combined = (n1 + n2) * 0.5;
    float intensity = smoothstep(0.45, 0.65, combined);
    COLOR = vec4(caustic_color * intensity, intensity * 0.6);
}