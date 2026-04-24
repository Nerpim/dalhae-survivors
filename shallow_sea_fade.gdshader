shader_type canvas_item;

// 페이드 시작 거리 (0.0 = 중앙, 1.0 = 가장자리)
uniform float fade_start : hint_range(0.0, 1.0) = 0.6;
// 페이드 끝 거리
uniform float fade_end : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// 중앙에서부터의 거리 계산 (0~1 범위)
	vec2 uv_centered = UV - vec2(0.5);
	float dist = length(uv_centered) * 2.0;
	
	// 거리에 따라 투명도 계산
	float alpha = 1.0 - smoothstep(fade_start, fade_end, dist);
	
	// 원본 색상 가져오기
	vec4 tex_color = texture(TEXTURE, UV);
	
	// 투명도 적용
	COLOR = vec4(tex_color.rgb, tex_color.a * alpha);
}