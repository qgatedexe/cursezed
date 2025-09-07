shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float speed : hint_range(0.0, 2.0) = 0.4;
uniform float strength : hint_range(0.0, 0.1) = 0.03;
uniform float swirl_center_x : hint_range(0.0, 1.0) = 0.5;
uniform float swirl_center_y : hint_range(0.0, 1.0) = 0.5;

float noise(vec2 p) {
    return sin(p.x * 6.0 + TIME * speed) * sin(p.y * 4.0 + TIME * speed * 0.7) * 0.5 + 0.5;
}

void fragment() {
    vec2 uv = UV - vec2(swirl_center_x, swirl_center_y);
    float r = length(uv);
    float angle = TIME * speed + noise(uv * 3.0 + TIME * 0.1) * 6.2831;
    vec2 offset = vec2(cos(angle), sin(angle)) * (strength * (1.0 - r));
    vec2 coord = UV + offset;
    COLOR = texture(SCREEN_TEXTURE, coord);
}