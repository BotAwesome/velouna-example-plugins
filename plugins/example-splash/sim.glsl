// Example "Splash", pass 1 of 2: the simulation. "rate": "step" runs it
// 60 times per second of song time, in step with score.lua's step(), and
// "feedback" gives it its own last result as u_prev.
//
// u_step: x = number of operations in this step, y = decay of this step.
// op_tex(i, 0..2): operation i as head, a, b (see score.lua).
// Channels hold amounts of palette colours a, b and c.

uniform sampler2D u_prev;

void main() {
    float m = min(u_size.x, u_size.y);
    vec2 p = px() / m;              // shorter-side units, like score.lua
    ivec2 ip = ivec2(px());

    // Last state, blurred a little so the colour runs, then decayed.
    vec4 here = fetch_tl(u_prev, ip);
    vec4 around = fetch_tl(u_prev, ip + ivec2(1, 0)) + fetch_tl(u_prev, ip - ivec2(1, 0))
                + fetch_tl(u_prev, ip + ivec2(0, 1)) + fetch_tl(u_prev, ip - ivec2(0, 1));
    vec4 col = mix(here, around * 0.25, 0.04) * u_step.y;

    // This step's operations, in order.
    int n = int(u_step.x);
    for (int i = 0; i < n; i++) {
        vec4 head = op_tex(i, 0);
        vec4 a = op_tex(i, 1);
        if (head.x > 0.5) {
            col = vec4(0.0);        // CLEAR
            continue;
        }
        float s = smoothstep(a.z, a.z * 0.5, length(p - a.xy)) * a.w;
        vec4 amount = head.y < 0.5 ? vec4(1.0, 0.0, 0.0, 0.0) : (head.y < 1.5 ? vec4(0.0, 1.0, 0.0, 0.0) : vec4(0.0, 0.0, 1.0, 0.0));
        col = col * (1.0 - s) + amount * s;   // paint over what was there
    }

    o_color = col;
}
