shader_type canvas_item;

uniform float strength : hint_range(0.0, 0.1) = 0.02;
uniform float frequency : hint_range(1.0, 20.0) = 8.0;
uniform float speed : hint_range(0.0, 3.0) = 0.8;

float noise(vec2 p) {
    return sin(p.x * frequency + TIME * speed) * sin(p.y * frequency * 0.7 + TIME * speed * 1.3);
}

void fragment() {
    vec2 uv = UV;
    float n = noise(uv * 2.0) * strength;
    vec2 coord = uv + vec2(n, n * 0.5);
    COLOR = texture(SCREEN_TEXTURE, coord);
}