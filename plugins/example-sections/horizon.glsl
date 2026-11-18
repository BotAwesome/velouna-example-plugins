// Example "Sections": one shader for two presets. Both name this file in
// plugin.json and differ only in their params and palettes.
//
//   F_au2.y  section gain: how lively the current part of the song is
//   F_au2.z  build-up: rises 0..1 while a build-up runs
//   F_au2.w  drop: jumps to 1 when a drop starts, then fades

void main() {
    vec2 p = (px() - F_res.xy * 0.5) / F_time.w;   // centred, y down
    float horizon = 0.12 * F_shape0.y;
    float gain = F_au2.y;
    float build = F_au2.z;
    float drop = F_au2.w;
    float dyn = F_react1.z;                         // reaction value "dynamics"

    // Sky: colour 1 at the horizon to colour 0 at the top, livelier
    // sections a little brighter.
    float up = clamp((horizon - p.y) * 1.4, 0.0, 1.0);
    vec3 col = mix(C(1), C(0), up) * (0.75 + 0.4 * gain * dyn);

    // The sun grows during a build-up and flares on the drop.
    vec2 sc = vec2(0.0, horizon - 0.02);
    float r = 0.12 * F_shape0.x * (1.0 + 0.6 * build + 0.4 * drop);
    float d = length(p - sc);
    float sky = step(p.y, horizon);
    float sun = smoothstep(r, r - 2.0 / F_time.w, d) * sky;
    col = mix(col, mix(C(2), C(3), build), sun);
    col += C(5) * exp(-max(d - r, 0.0) * 6.0) * (0.15 + 0.8 * drop) * sky * (1.0 - sun);

    // Rings from score.lua, one per section start.
    int count = int(F_cam.w);
    for (int i = 0; i < count; i++) {
        vec4 rp = F_rip(i);
        float front = r + rp.z * 0.35;
        float ring = exp(-pow((length(p - rip_center(i)) - front) / 0.006, 2.0)) * exp(-rp.z * 1.2) * rp.w;
        col += C(6) * ring * 0.8 * sky;
    }

    // Ground: stripes running towards you, faster with the bass ("flow").
    if (p.y > horizon) {
        float below = p.y - horizon;
        float z = 1.0 / max(below, 0.004);
        float stripe = step(0.5, fract(z * 0.25 - F_phase.z * 1.5));
        float fadein = clamp(below * 4.0, 0.0, 1.0);
        col = mix(C(1) * 0.35, C(4) * (0.35 + 0.5 * gain), stripe * fadein);
    }

    o_color = vec4(col, 1.0);
}
