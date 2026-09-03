shader_type canvas_item;

// shader general
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D background_texture : hint_default_white;
uniform sampler2D pulse_mask : hint_default_white;
uniform sampler2D lines_mask : hint_default_white;
uniform float lines_mask_tile_y : hint_range(0.1, 10.0) = 1.0;
uniform vec4 lines_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_a : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform sampler2D visibility_mask_a : hint_default_white;
uniform vec4 color_b : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 color_b_multiplier : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D visibility_mask_b : hint_default_white;
uniform sampler2D two_lines_text : hint_default_white;
uniform sampler2D two_lines_mask : hint_default_white;
uniform vec4 two_lines_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float scroll_global : hint_range(-0.2, 2.2) = 0.0;

// glow
uniform float glow_blur : hint_range(0.0, 10.0) = 3.0;
uniform float glow_strength : hint_range(0.0, 5.0) = 1.5;
uniform float glow_flicker_speed : hint_range(0.0, 30.0) = 2.0;
uniform float glow_flicker_amount : hint_range(0.0, 3.0) = 0.2;

// fog
uniform sampler2D fog_noise_a : hint_default_white;
uniform float fog_speed : hint_range(0.0, 2.0) = 0.1;
uniform float fog_scale : hint_range(0.0, 5.0) = 1.0;
uniform vec4 fog_color : source_color = vec4(1.0, 1.0, 1.0, 0.25);

// shader itself :p
vec4 calc_layers(vec2 uv) {
    float lines_value = texture(lines_mask, vec2(uv.x, fract(uv.y * lines_mask_tile_y))).r;
    float pulse_value = texture(pulse_mask, uv).r;
    vec2 uv_scroll = vec2(fract(uv.x * 0.5 + (2.0 - scroll_global) * 0.5), uv.y);

    vec4 layer  = mix(vec4(0.0), color_a, lines_value);
    vec4 layer2 = mix(vec4(0.0), color_a, pulse_value);
    vec4 layer_a = layer2 + (layer2 * layer * 2.0);
    layer_a.a *= texture(visibility_mask_a, uv_scroll).r * pulse_value;

    vec4 layer_b_base = mix(vec4(0.0), color_b, pulse_value);
    vec4 layer_b = layer_b_base + (layer_b_base * layer * 2.0);
    layer_b *= color_b_multiplier;
    float vis_b = texture(visibility_mask_b, uv_scroll).r;
    layer_b.a *= vis_b * pulse_value;

    vec4 layers = mix(layer_a, layer_b, vis_b);

    vec4 two_lines_colored = mix(vec4(0.0), two_lines_color, texture(two_lines_text, uv).r);
    two_lines_colored.a *= texture(two_lines_mask, uv_scroll).r;
    layers += two_lines_colored;

    return layers;
}

void fragment() {
    // fondo
	float modulate_alpha = COLOR.a;
    vec4 bg_tex = texture(background_texture, UV);
    float lines_value = texture(lines_mask, vec2(UV.x, fract(UV.y * lines_mask_tile_y))).r;
    vec4 result = bg_tex * background_color + mix(vec4(0.0), lines_color, lines_value);

    // niebla
    vec2 uv_up    = fract(UV * fog_scale + vec2(0.1,  -TIME * fog_speed));
    vec2 uv_down  = fract(UV * fog_scale + vec2(-0.0,   TIME * fog_speed));
    vec2 uv_left  = fract(UV * fog_scale + vec2(-TIME * fog_speed, 0.1));
    vec2 uv_right = fract(UV * fog_scale + vec2( TIME * fog_speed, -0.1));

    float n_up    = texture(fog_noise_a, uv_up).r;
    float n_down  = texture(fog_noise_a, uv_down).r;
    float n_left  = texture(fog_noise_a, uv_left).r;
    float n_right = texture(fog_noise_a, uv_right).r;

    float n = (n_up + n_down + n_left + n_right) * 0.25;

    result.rgb = mix(result.rgb, fog_color.rgb, fog_color.a * n);

    // glow
    float flicker = sin(TIME * glow_flicker_speed) * 0.6
                  + sin(TIME * glow_flicker_speed * 2.3) * 0.4;
    flicker = flicker * 0.5 + 0.5;
    float current_glow = glow_strength + flicker * glow_flicker_amount;

    // abataglow 2
    vec2 pixel_size = 1.0 / vec2(textureSize(pulse_mask, 0));
    vec4 glow_result = vec4(0.0);
    float blur_total = 0.0;
    for (int x = -3; x <= 3; x++) {
        for (int y = -3; y <= 3; y++) {
            float weight = exp(-float(x*x + y*y) / 8.0);
            vec2 offset = vec2(float(x), float(y)) * pixel_size * glow_blur;
            glow_result += calc_layers(UV + offset) * weight;
            blur_total += weight;
        }
    }
    glow_result /= blur_total;
    glow_result *= current_glow;

    vec4 sharp = calc_layers(UV);

	//result
    result = mix(result, glow_result, clamp(glow_result.a, 0.0, 1.0));
    result = mix(result, sharp, clamp(sharp.a, 0.0, 1.0));
    COLOR = result;
    COLOR.a *= modulate_alpha;
}