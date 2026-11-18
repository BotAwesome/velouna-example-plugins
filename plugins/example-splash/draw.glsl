// Example "Splash", pass 2 of 2: paper from noise, and the colour amounts
// of the simulation (u_sim) mixed on top.

uniform sampler2D u_sim;

void main() {
    vec2 uv = px() / u_size;
    vec4 w = tex_tl(u_sim, uv);

    // Paper: two palette colours mixed by noise. seed_off() differs per seed.
    float paper = fbm(px() / F_time.w * 3.0 + seed_off(), 3);
    vec3 col = mix(C(0), C(1), clamp(0.5 + paper, 0.0, 1.0));

    // Colour: the average of a, b, c weighted by their amounts.
    float total = w.r + w.g + w.b;
    vec3 ink = (C(2) * w.r + C(3) * w.g + C(4) * w.b) / max(total, 1e-4);
    col = mix(col, ink, min(total, 1.0));

    o_color = vec4(col, 1.0);
}
