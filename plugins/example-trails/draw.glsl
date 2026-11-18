// Example "Trails", pass 2 of 2: reads the "trail" pass (listed under
// "inputs" in plugin.json, so it is available as u_trail) and turns its
// amounts into palette colours. This last pass is what the user sees.

uniform sampler2D u_trail;

void main() {
    vec2 uv = px() / u_size;
    vec4 w = tex_tl(u_trail, uv);   // tex_tl: same top-left origin as px()

    vec3 col = mix(C(0), C(1), uv.y * 0.6);
    col += C(2) * w.r + C(3) * w.g + C(4) * w.b + C(5) * w.a;

    o_color = vec4(col, 1.0);
}
