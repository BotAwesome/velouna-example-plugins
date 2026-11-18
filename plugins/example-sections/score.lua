-- score.lua of "Sections" (used by both presets).
--
-- song:sections() lists the parts of the song, each as
-- { kind = "calm" | "groove" | "build" | "drop", start = s, stop = s }.
-- Every section start sends a ring out of the sun. Build-up and drop
-- themselves need no Lua: the shader reads them from F_au2.

local starts = {}
local sx, sy = 0.5, 0.5
local strength = { calm = 0.4, groove = 0.6, build = 0.8, drop = 1.0 }

function build(song, ctx)
  -- The sun's centre, the same as in horizon.glsl, but in the units rings
  -- use: shorter-side units with the origin top left.
  sx = ctx.aw / 2
  sy = ctx.ah / 2 + 0.12 * ctx.params.horizon - 0.02
  starts = {}
  for _, s in ipairs(song:sections()) do
    if s.start > 0.5 then
      starts[#starts + 1] = { t = s.start, s = strength[s.kind] or 0.6 }
    end
  end
end

function frame(t)
  -- Rings of the last four seconds, newest first.
  local rip = {}
  for k = #starts, 1, -1 do
    local age = t - starts[k].t
    if age >= 0 then
      if age > 4.0 or #rip >= 16 then break end
      rip[#rip + 1] = { sx, sy, age, starts[k].s }
    end
  end
  return { rip = rip }
end
