// Example visualizer, preset "Pulse": a disc that breathes with the bass
// and jumps with the kick, rings sent out by score.lua, a slowly drifting
// background. Meant to be copied and changed.
//
// Velouna puts its prelude in front of this file, so these are ready to
// use (see docs/shaders.md, "Inputs"):
//   px()            pixel position, origin top left, y down
//   F_res, F_time   size, time, seed, shorter side (F_time.w)
//   F_au0..F_au2    smoothed music curves, 0..1
//   F_pulse         decaying hit pulses: kick, snare, hat, keys
//   F_phase         beat and bar phase 0..1
//   F_shape0/1      this preset's params, in the order of plugin.json
//   F_react0/1      how strongly to react to kick, snare, ... (see docs)
//   C(i)            palette colour i (0 background ... 6 text)
//   F_cam.w, F_rip(i), rip_center(i)   rings returned by score.lua
//   gnoise(), fbm(), hash21(), rot(), seed_off()   helpers

void main() {
    // Centred coordinates: 1.0 is the shorter side of the picture.
    vec2 p = (px() - F_res.xy * 0.5) / F_time.w;

    // Params from plugin.json, in their order (size, rings, glow).
    float size = F_shape0.x;
    float rings = F_shape0.y;
    float glow = F_shape0.z;

    // Music. Curves are smooth (0..1); pulses jump on a hit and decay.
    // Multiplying by F_react0 applies Velouna's reaction values.
    float bass = F_au0.y * F_react0.w;
    float kick = F_pulse.x * F_react0.x;
    float intensity = F_au2.x;

    // Background: palette colours 0 and 1, mixed by drifting noise. The
    // seed offset makes every seed look a little different.
    float n = fbm(p * 1.4 + seed_off() + vec2(0.0, F_time.x * 0.03), 3);
    vec3 col = mix(C(0), C(1), clamp(0.5 + 0.8 * n, 0.0, 1.0));

    // The disc. Its colour turns once per bar (F_phase.y is the bar phase).
    float r = 0.16 * size * (1.0 + 0.25 * bass + 0.2 * kick);
    float d = length(p);
    float disc = smoothstep(r, r - 3.0 / F_time.w, d);
    vec3 disc_col = mix(C(2), C(3), 0.5 + 0.5 * sin(F_phase.y * 6.2831853));
    col = mix(col, disc_col, disc);

    // A glow around it in the accent colour, brighter on kicks.
    float halo = exp(-max(d - r, 0.0) * 8.0 / max(glow, 0.05));
    col += C(5) * halo * (0.2 + 0.6 * kick + 0.3 * intensity) * glow * (1.0 - disc);

    // Rings from score.lua: x, y (shorter-side units), age in seconds,
    // strength. rip_center() turns x, y into the centred units used here.
    int count = int(F_cam.w);
    for (int i = 0; i < count; i++) {
        vec4 rp = F_rip(i);
        vec2 c = rip_center(i);
        float front = r + rp.z * 0.5;
        float ring = exp(-pow((length(p - c) - front) / 0.01, 2.0)) * exp(-rp.z * 1.6) * rp.w;
        col += C(4) * ring * rings;
    }

    // The final pass writes o_color; Velouna adds vignette, grain and the
    // fade in and out afterwards.
    o_color = vec4(col, 1.0);
}
