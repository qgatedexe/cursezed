shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 20.0) = 6.0;
uniform float speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec2 uv = UV;
    float sway = sin((uv.y * 10.0) + TIME * speed) * amplitude / 1000.0;
    vec2 coord = uv + vec2(sway, 0.0);
    COLOR = texture(TEXTURE, coord);
}