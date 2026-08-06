shader_type canvas_item;

// Água animada e barata: duas camadas de ruído deslizando em velocidades e
// direções diferentes criam um efeito de ondulação sem precisar simular
// física de água nenhuma. `noise_tex` é gerada em código (WorldBuilder) e
// só entra aqui como padrão de variação.

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 color_shallow : source_color = vec4(0.16, 0.38, 0.58, 1.0);
uniform vec4 color_deep : source_color = vec4(0.05, 0.16, 0.32, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform float speed = 0.045;
uniform float tile = 7.0;

void fragment() {
	vec2 uv1 = UV * tile + vec2(TIME * speed, TIME * speed * 0.6);
	vec2 uv2 = UV * (tile * 1.7) - vec2(TIME * speed * 0.8, TIME * speed * 0.5);

	float n1 = texture(noise_tex, uv1).r;
	float n2 = texture(noise_tex, uv2).r;
	float wave = (n1 * 0.6 + n2 * 0.4);

	vec4 col = mix(color_deep, color_shallow, wave);

	// Crista de espuma: só onde o ruído combinado passa de um limiar bem
	// alto, então fica esparsa em vez de cobrir tudo.
	float foam = smoothstep(0.78, 0.92, wave);
	col = mix(col, foam_color, foam * 0.5);

	COLOR = col;
}
