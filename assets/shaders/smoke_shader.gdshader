shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float speed : hint_range(0.0, 1.0) = 0.1;
uniform float scale : hint_range(0.5, 5.0) = 2.0;
uniform vec3 smoke_color : source_color = vec3(0.05, 0.05, 0.06);

float noise(vec2 p) {
    return sin(p.x * 12.0 + TIME * speed * 3.0) * sin(p.y * 8.0 + TIME * speed * 2.0) * 0.5 + 0.5;
}

void fragment() {
    vec2 uv = UV;
    float n = noise(uv * scale + vec2(TIME * speed, 0.0));
    float alpha = smoothstep(0.4, 0.7, n) * 0.4;
    COLOR = vec4(smoke_color, alpha);
}