-- score.lua of the example visualizer: turns the song analysis into rings.
--
-- Velouna calls
--   build(song, ctx)  once per song, seed, setting or window shape
--   frame(t)          once per drawn frame (optional)
--   step(t0, dt, first)  60 times per second, for simulations (optional,
--                     not used here; see velounizer/ink/score.lua)
--
-- The sandbox has math, string, table and utf8. There are no files, no
-- network, no os or io. A call that runs too long (50 ms, build 3 s) is
-- stopped and the preset shows an error.

local kicks = {}
local cx, cy = 0.5, 0.5

function build(song, ctx)
  -- ctx.aw, ctx.ah: picture width and height, in units of its shorter side.
  -- ctx.params: this preset's params by id; ctx.react: the reaction values.
  -- ctx.seed: the seed the user picked (same seed, same picture).
  cx, cy = ctx.aw / 2, ctx.ah / 2
  kicks = {}
  -- song:hits("kick" | "snare" | "hat" | "keys") lists { t = seconds,
  -- s = strength 0..1 }, sorted by time.
  for _, h in ipairs(song:hits("kick")) do
    if h.s >= 0.2 then
      kicks[#kicks + 1] = h
    end
  end
end

-- Number of kicks at or before t (binary search, the list is sorted).
local function upto(t)
  local lo, hi = 1, #kicks + 1
  while lo < hi do
    local mid = (lo + hi) // 2
    if kicks[mid].t <= t then lo = mid + 1 else hi = mid end
  end
  return lo - 1
end

function frame(t)
  -- Rings of the last two seconds, newest first, at most 16 (Velouna's
  -- limit). Each ring: { x, y, age, strength }, x and y in shorter-side
  -- units with the origin top left.
  local rip = {}
  for k = upto(t), 1, -1 do
    local age = t - kicks[k].t
    if age > 2.0 or #rip >= 16 then break end
    rip[#rip + 1] = { cx, cy, age, kicks[k].s }
  end
  return { rip = rip }
end
