-- Example: Clean titles (MIT)
--
-- track-info runs before track-started, so scrobblers and the player see the
-- cleaned title. It has 50 ms and no network: just string work. Return only
-- the fields to change (title, artist, album) or nil for no change.

local junk = {
  "%s*[%(%[][Oo]fficial [^%)%]]*[%)%]]",
  "%s*[%(%[][Ll]yrics?[^%)%]]*[%)%]]",
  "%s*[%(%[][Hh][Dd][%)%]]",
  "%s*[%(%[]4[Kk][^%)%]]*[%)%]]",
  "%s*[%(%[][Vv]isuali[sz]er[%)%]]",
}

velouna.hooks.on("track-info", function(t)
  local title = t.title or ""
  -- Files without a title tag show their file name: drop the ending.
  if t.source == "file" then
    title = title:gsub("%.%w%w%w?%w?$", "")
  end
  for _, p in ipairs(junk) do
    title = title:gsub(p, "")
  end
  local out = {}
  -- "Artist - Title" when the file has no artist tag.
  if not t.artist then
    local a, rest = title:match("^(.-)%s+[%-–—]%s+(.+)$")
    if a then
      out.artist, title = a, rest
    end
  end
  if title ~= t.title then out.title = title end
  if next(out) == nil then return nil end
  return out
end)
