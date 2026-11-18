// Example "Trails", pass 1 of 2: a feedback pass. It reads its own last
// picture (u_prev), lets it fade and drift, and paints the dots on top.
// It runs at half size ("scale": 0.5) and stores floats ("rgba16f"), so a
// slow fade doesn't get stuck on the last steps of 8-bit colour.
//
// The four channels are not colours yet but amounts of palette colours
// a, b, c and the accent. The second pass turns them into colours.

uniform sampler2D u_prev;

void main() {
    vec2 uv = px() / u_size;                    // 0..1 in this pass
    float m = min(u_size.x, u_size.y);
    vec2 p = (px() - u_size * 0.5) / m;         // centred, 1.0 = shorter side
    float len = F_shape0.x;
    float drift = F_shape0.y;

    // Last picture, read a little closer to the centre: the trails flow
    // outwards. Then fade it, and take off a tiny bit so it reaches zero.
    vec2 back = 0.5 + (uv - 0.5) * (1.0 - 0.006 * drift);
    vec4 col = tex_tl(u_prev, back);
    col = max(col * mix(0.90, 0.985, len) - 0.002, 0.0);

    // Three dots circling. F_phase.z ("flow") is a time that runs faster
    // with the bass, so the dots speed up without jumping.
    float t = F_time.x;
    float size = 0.012 + 0.03 * F_au0.y * F_react0.w + 0.03 * F_pulse.x * F_react0.x;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float a = F_phase.z * (1.2 + 0.4 * fi) + fi * 2.094;
        float r = 0.22 + 0.08 * sin(t * 0.7 + fi * 1.7);
        vec2 c = r * vec2(cos(a), sin(a));
        float dot_ = smoothstep(size, size * 0.4, length(p - c));
        vec4 amount = i == 0 ? vec4(1.0, 0.0, 0.0, 0.0) : (i == 1 ? vec4(0.0, 1.0, 0.0, 0.0) : vec4(0.0, 0.0, 1.0, 0.0));
        col = max(col, amount * dot_);
    }

    // Snares: a ring that grows from the middle while the snare pulse
    // decays, painted in the accent channel. Its trail stays behind.
    float snare = F_pulse.y * F_react0.y;
    float radius = 0.05 + (1.0 - F_pulse.y) * 0.45;
    float ring = exp(-pow((length(p) - radius) / 0.008, 2.0)) * snare;
    col.a = max(col.a, ring);

    o_color = col;
}
