// Example "Bars": eight bars, one per music curve. There is no score.lua:
// everything comes from the values Velouna passes to every shader.
//
//   F_au0  sub, bass, drums, mix      smooth curves, 0..1
//   F_au1  voice (always 0 for now), keys, pads, high
//   F_au2.x  intensity
//   F_pulse.x  kick pulse (jumps on a kick, then decays)
//   F_phase.x  beat phase: 0 on the beat, rising to 1 until the next one

// Curve i of the eight, left to right. Velouna doesn't separate the voice
// yet (F_au1.x is 0), so bar 5 shows the intensity instead.
float band(int i) {
    if (i == 4) return F_au2.x;
    return i < 4 ? F_au0[i] : F_au1[i - 4];
}

// The reaction value that fits curve i. Multiplying by it lets this
// visualizer follow Velouna's reaction settings.
float react(int i) {
    if (i < 2) return F_react0.w;   // sub, bass: bass
    if (i == 2) return F_react0.x;  // drums: kick
    if (i == 4) return F_react1.z;  // intensity: dynamics
    if (i == 5) return F_react1.y;  // keys
    if (i == 7) return F_react0.z;  // high: hats
    return 1.0;
}

void main() {
    vec2 q = px() / F_res.xy;       // 0..1 across the picture, y down
    float height = F_shape0.x;      // params, in the order of plugin.json
    float gap = F_shape0.y;
    float glow = F_shape0.z;

    // Background: palette colour 0 at the top, 1 at the bottom.
    vec3 col = mix(C(0), C(1), q.y);

    // Which bar this pixel is in, and where across it (0..1).
    float x = q.x * 8.0;
    int i = int(clamp(floor(x), 0.0, 7.0));
    float fx = fract(x);
    float column = step(gap * 0.5, fx) * step(fx, 1.0 - gap * 0.5);

    // Bars grow up from the bottom.
    float v = clamp(band(i) * react(i), 0.0, 1.0);
    float top = 1.0 - 0.85 * height * v;
    float inside = column * step(top, q.y);

    // Bar colour: palette colours 2, 3, 4 from left to right.
    float u = float(i) / 7.0;
    vec3 bar = u < 0.5 ? mix(C(2), C(3), u * 2.0) : mix(C(3), C(4), u * 2.0 - 1.0);
    col = mix(col, bar, inside);

    // A soft light above each bar, brightest right on the beat.
    float beat = 1.0 - F_phase.x;
    float above = column * (1.0 - inside) * exp(-max(top - q.y, 0.0) * 18.0 / max(glow, 0.05));
    col += bar * above * glow * (0.25 + 0.35 * beat * beat);

    // The accent colour washes up from the bottom on kicks.
    col += C(5) * F_pulse.x * F_react0.x * 0.15 * q.y;

    o_color = vec4(col, 1.0);
}
