-- Example: Segments from a file (MIT)
--
-- For "Movie.mkv", put a "Movie.segments.json" next to it:
--
--   [
--     { "from": 0,   "to": 42,  "action": "skip", "label": "Intro" },
--     { "from": 600, "to": 660, "action": "ask",  "label": "Recap" },
--     { "from": 900, "to": 905, "action": "mute" },
--     { "from": 1200, "to": 1260, "action": "mark", "label": "Best part", "color": "#ff8800" },
--     { "from": 1500, "to": 1500, "action": "chapter", "label": "Credits" }
--   ]
--
-- Actions: skip (jump over it, with an Undo button), ask (a "Skip" button
-- while inside), mute (sound off while inside), mark (only coloured on the
-- seek bar), chapter (a chapter mark). Times in seconds.
--
-- The segments hook runs in the background when a file starts; it may take
-- its time and use the network (a SponsorBlock plugin would ask its server
-- here). velouna.media.sidecar reads small text files next to the file that
-- plays: no permission needed, nothing else on the disk is reachable.

velouna.hooks.on("segments", function(item)
  local text = velouna.media.sidecar("segments.json")
  if not text then
    return nil                        -- nothing for this file
  end
  local list, err = velouna.json.decode(text)
  if not list then
    velouna.warn("segments.json: " .. err)
    return nil
  end
  print(#list .. " segments for " .. item.title)
  return list
end)
