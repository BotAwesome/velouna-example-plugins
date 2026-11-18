-- Example: Track log (MIT)
--
-- Listens to player events and writes them to the plugin console
-- (Settings → Extensions → ⋯ → Console). Needs no permissions.
--
-- Every event handler gets the item that plays as its first argument:
--   t.title, t.artist, t.album, t.duration, t.kind ("audio"/"video"),
--   t.source ("file", "stream", "radio", "tv", "plex", "jellyfin", "emby", "plugin"),
--   t.path (empty for media servers), t.youtube_id (when there is one)

local function describe(t)
  local who = t.artist and (t.artist .. " – ") or ""
  return who .. (t.title or "?") .. " [" .. (t.source or "?") .. "]"
end

velouna.events.on("app-idle", function()
  -- velouna.storage keeps values across restarts (plugin-data/<id>/storage.json).
  print("Velouna is ready. Plays counted so far: " .. (velouna.storage.get("plays") or 0))
end)

velouna.events.on("track-started", function(t)
  print("started: " .. describe(t))
end)

velouna.events.on("paused", function(t, pos)
  print(string.format("paused at %.1f s", pos))
end)

velouna.events.on("resumed", function(t, pos)
  print(string.format("playing again from %.1f s", pos))
end)

velouna.events.on("seeked", function(t, pos)
  print(string.format("jumped to %.1f s", pos))
end)

velouna.events.on("track-ended", function(t, info)
  -- info.reason: "eof" (played to the end), "stop", "error" or "other"
  print(string.format("ended (%s) after %.0f s of playing", info.reason, info.played))
  local n = (velouna.storage.get("plays") or 0) + 1
  velouna.storage.set("plays", n)
end)
