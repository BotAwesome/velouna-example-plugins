-- Example: Effects (MIT)
--
-- velouna.player.video_shader(file) puts one GLSL file of the plugin on the
-- picture (nil takes it off). velouna.player.audio_filter(chain) adds a
-- chain of FFmpeg filters from an allowed list (nil removes it). Both stay
-- until the plugin changes them or is switched off.

local gray, night = false, false

local function toggle_gray()
  gray = not gray
  velouna.player.video_shader(gray and "grayscale.glsl" or nil)
  velouna.ui.toast(gray and "Grayscale on" or "Grayscale off")
end

local function toggle_night()
  night = not night
  -- Loud parts quieter, quiet parts louder: easier on the neighbours.
  velouna.player.audio_filter(night and "acompressor=threshold=0.05:ratio=8:attack=10:release=200:makeup=4,dynaudnorm=f=200" or nil)
  velouna.ui.toast(night and "Night mode on" or "Night mode off")
end

velouna.menu.add({ id = "gray", label = { en = "Grayscale", de = "Graustufen" }, icon = "palette", where = { "player" }, kinds = { "video" }, run = toggle_gray })
velouna.menu.add({ id = "night", label = { en = "Night mode", de = "Nachtmodus" }, icon = "moon", where = { "player" }, run = toggle_night })

-- A sleep timer: velouna.timer.after(seconds, fn) runs fn once,
-- velouna.timer.every(seconds, fn) again and again; both return an id for
-- velouna.timer.cancel(id).
local sleep = nil
velouna.menu.add({
  id = "sleep",
  label = { en = "Pause in 10 minutes", de = "In 10 Minuten anhalten" },
  icon = "timer",
  where = { "player", "main" },
  run = function()
    if sleep then velouna.timer.cancel(sleep) end
    sleep = velouna.timer.after(600, function()
      velouna.player.pause()
      velouna.ui.toast("Good night")
      sleep = nil
    end)
    velouna.ui.toast("Pausing in 10 minutes")
  end,
})
