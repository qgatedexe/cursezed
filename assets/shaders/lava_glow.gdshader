shader_type canvas_item;

uniform float glow_speed : hint_range(0.0, 5.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.25;
uniform vec3 glow_color : source_color = vec3(1.0, 0.4, 0.0);

void fragment() {
    vec2 uv = UV;
    float glow = sin(uv.x * 10.0 + TIME * glow_speed) * sin(uv.y * 8.0 + TIME * glow_speed * 0.7) * 0.5 + 0.5;
    vec4 base = texture(TEXTURE, uv);
    vec3 glow_effect = glow_color * glow * glow_intensity;
    COLOR = base + vec4(glow_effect, 0.0);
}