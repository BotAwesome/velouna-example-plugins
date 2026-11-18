-- score.lua of "Splash": a simulation driven by step().
--
-- build() works out once per song where each splash goes. step() is then
-- called 60 times per second of song time and hands the shader the
-- operations of that step: 12 numbers each, read in sim.glsl with
-- op_tex(i, 0..2) as three vec4: head, a, b.
--
--   head: kind, colour, 0, 0
--   a:    x, y, radius, strength    (shorter-side units, origin top left)
--   b:    unused here
--
-- The second value step() returns is the decay of this step: the shader
-- multiplies the last picture by it (u_step.y).

local SPLASH, CLEAR = 0, 1
local hits = {}
local decay = 0.99

function build(song, ctx)
  local P, R = ctx.params, ctx.react
  -- same seed, same splashes: use velouna.rng, never math.random
  local rng = velouna.rng(ctx.seed)
  hits = {}
  -- linger 0..1 -> how much is left after one step
  decay = 1 - 0.02 * (1.05 - P.fade)

  local function add(name, colour, size, react)
    for _, h in ipairs(song:hits(name)) do
      local s = math.min(1, h.s * react)
      if s >= 0.15 then
        hits[#hits + 1] = {
          t = h.t, c = colour, s = s,
          x = rng:range(0.1, 0.9) * ctx.aw,
          y = rng:range(0.1, 0.9) * ctx.ah,
          r = size * P.size * (0.6 + 0.6 * h.s),
        }
      end
    end
  end
  add("kick", 0, 0.09, R.kick)
  add("snare", 1, 0.06, R.snare)
  add("hat", 2, 0.025, R.hats)
  table.sort(hits, function(a, b) return a.t < b.t end)
end

-- Index of the first hit at or after t (binary search, hits are sorted).
local function first_at(t)
  local lo, hi = 1, #hits + 1
  while lo < hi do
    local mid = (lo + hi) // 2
    if hits[mid].t < t then lo = mid + 1 else hi = mid end
  end
  return lo
end

-- t0: song time of this step, dt: its length (1/60 s), first: the first
-- step after the start or a jump, when the picture should start empty.
function step(t0, dt, first)
  local ops = {}
  local function op(kind, colour, x, y, r, s)
    local v = { kind, colour or 0, 0, 0, x or 0, y or 0, r or 0, s or 0, 0, 0, 0, 0 }
    for i = 1, 12 do ops[#ops + 1] = v[i] end
  end
  if first then
    op(CLEAR)
  end
  for k = first_at(t0), #hits do
    local h = hits[k]
    if h.t >= t0 + dt then break end
    op(SPLASH, h.c, h.x, h.y, h.r, h.s)
  end
  return ops, decay
end
