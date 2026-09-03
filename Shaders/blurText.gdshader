shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float glow_strength : hint_range(0.0, 5.0) = 2.0;
uniform float glow_flicker_speed : hint_range(0.0, 30.0) = 2.0;
uniform float glow_flicker_amount : hint_range(0.0, 3.0) = 0.2;
uniform float glow_flicker_blink_speed : hint_range(0.0, 50.0) = 20.0;

void fragment() {
    vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
    
    vec4 blur = vec4(0.0);
    float total = 0.0;
    
    for (int x = -4; x <= 4; x++) {
        for (int y = -4; y <= 4; y++) {
            float weight = exp(-float(x*x + y*y) / 8.0);
            vec2 offset = vec2(float(x), float(y)) * pixel_size * blur_amount;
            blur += texture(TEXTURE, UV + offset) * weight;
            total += weight;
        }
    }
    
    blur /= total;

    float random_time = fract(sin(floor(TIME * glow_flicker_speed)) * 43758.5453);
    float next_random = fract(sin(floor(TIME * glow_flicker_speed) + 1.0) * 43758.5453);
    float t = fract(TIME * glow_flicker_speed);
    float pulse = mix(random_time, next_random, smoothstep(0.0, 1.0, t));
    
    float flicker = pulse;
    float current_glow = glow_strength + flicker * glow_flicker_amount;

    COLOR = blur * glow_color * current_glow;
}