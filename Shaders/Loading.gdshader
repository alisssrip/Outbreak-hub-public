shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform sampler2D mask_a : hint_default_white;

uniform vec4 color_b : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform sampler2D mask_b : hint_default_white;

uniform float rotation_deg : hint_range(0.0, 360.0) = 0.0;

// glow (A y B)
uniform float glow_blur : hint_range(0.0, 10.0) = 3.0;
uniform float glow_strength : hint_range(0.0, 5.0) = 1.5;
uniform float glow_flicker_speed : hint_range(0.0, 30.0) = 2.0;
uniform float glow_flicker_amount : hint_range(0.0, 3.0) = 0.2;

// fog
uniform sampler2D fog_noise : hint_default_white;
uniform sampler2D mask_fog : hint_default_white;
uniform float fog_speed : hint_range(0.0, 2.0) = 0.1;
uniform float fog_scale : hint_range(0.0, 5.0) = 1.0;
uniform vec4 fog_color : source_color = vec4(1.0, 1.0, 1.0, 0.25);

vec4 over(vec4 dst, vec4 src) {
    float a = src.a + dst.a * (1.0 - src.a);
    vec3 rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / max(a, 0.0001);
    return vec4(rgb, a);
}

vec2 rotate_uv(vec2 uv, float angle_rad) {
    vec2 centered = uv - 0.5;
    float s = sin(angle_rad);
    float c = cos(angle_rad);
    centered = vec2(c * centered.x - s * centered.y,
                    s * centered.x + c * centered.y);
    return centered + 0.5;
}

vec4 calc_color_a(vec2 uv) {
    float val = texture(mask_a, uv).a;
    return vec4(color_a.rgb, color_a.a * val);
}

vec4 calc_color_b(vec2 uv) {
    float val = texture(mask_b, uv).a;
    return vec4(color_b.rgb, color_b.a * val);
}

void fragment() {
    float angle = -rotation_deg * (PI / 180.0);
    vec2 uv_rot = rotate_uv(UV, angle);

    // noise del fog (sin rotar)
    vec2 uv_up    = fract(UV * fog_scale + vec2( 0.1, -TIME * fog_speed));
    vec2 uv_down  = fract(UV * fog_scale + vec2( 0.0,  TIME * fog_speed));
    vec2 uv_left  = fract(UV * fog_scale + vec2(-TIME * fog_speed,  0.1));
    vec2 uv_right = fract(UV * fog_scale + vec2( TIME * fog_speed, -0.1));

    float n = (texture(fog_noise, uv_up).r +
               texture(fog_noise, uv_down).r +
               texture(fog_noise, uv_left).r +
               texture(fog_noise, uv_right).r) * 0.25;

    // base transparente
    vec4 result = vec4(0.0);

    // glow A + B
    float flicker = sin(TIME * glow_flicker_speed) * 0.6
                  + sin(TIME * glow_flicker_speed * 2.3) * 0.4;
    flicker = flicker * 0.5 + 0.5;
    float current_glow = glow_strength + flicker * glow_flicker_amount;

    vec2 pixel_size_a = 1.0 / vec2(textureSize(mask_a, 0));
    vec2 pixel_size_b = 1.0 / vec2(textureSize(mask_b, 0));
    vec4 glow_a = vec4(0.0);
    vec4 glow_b = vec4(0.0);
    float blur_total = 0.0;

    for (int x = -3; x <= 3; x++) {
        for (int y = -3; y <= 3; y++) {
            float weight = exp(-float(x*x + y*y) / 8.0);
            vec2 offset_a = vec2(float(x), float(y)) * pixel_size_a * glow_blur;
            vec2 offset_b = vec2(float(x), float(y)) * pixel_size_b * glow_blur;
            glow_a += calc_color_a(uv_rot + offset_a) * weight;
            glow_b += calc_color_b(uv_rot + offset_b) * weight;
            blur_total += weight;
        }
    }
    glow_a /= blur_total;
    glow_b /= blur_total;
    glow_a.rgb *= current_glow;
    glow_b.rgb *= current_glow;

    result = over(result, glow_a);
    result = over(result, glow_b);
    result = over(result, calc_color_a(uv_rot));
    result = over(result, calc_color_b(uv_rot));

    // fog ENCIMA de todo
    float fog_mask = texture(mask_fog, uv_rot).a;
    vec4 fog_layer = vec4(fog_color.rgb, fog_color.a * n * fog_mask);
    result = over(result, fog_layer);

    COLOR = result;
}