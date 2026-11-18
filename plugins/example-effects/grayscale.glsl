//!HOOK MAIN
//!BIND HOOKED
//!DESC Example: grayscale

// An mpv user shader (https://mpv.io/manual/master/#options-glsl-shaders).
// MAIN is the picture in RGB before scaling.
vec4 hook() {
    vec4 c = HOOKED_texOff(0);
    float y = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    return vec4(vec3(y), c.a);
}
