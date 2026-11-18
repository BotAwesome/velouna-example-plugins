-- Example: Module (MIT)
--
-- A module has no extension point of its own. Other plugins name it in
-- "requires" and load it with require("dev.botawesome.example-module").
-- It runs inside the plugin that loads it, with that plugin's permissions.

local M = {}

-- 3725 → "1:02:05", 65 → "1:05"
function M.duration(sec)
  sec = math.floor(tonumber(sec) or 0)
  local h, m, s = sec // 3600, (sec // 60) % 60, sec % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
  return string.format("%d:%02d", m, s)
end

-- First child element with this name.
function M.child(node, name)
  for _, c in ipairs(node.children or {}) do
    if c.name == name then return c end
  end
end

-- An RSS 2.0 feed as { title, image, episodes = { {id, title, date, url, duration, description} } }.
function M.read_rss(xml_text)
  local root, err = velouna.text.xml(xml_text)
  if not root then return nil, err end
  local channel = M.child(root, "channel")
  if not channel then return nil, "not an RSS feed" end
  local feed = { title = (M.child(channel, "title") or {}).text or "?", episodes = {} }
  local img = M.child(channel, "itunes:image")
  feed.image = img and img.attrs.href or ((M.child(M.child(channel, "image") or {}, "url") or {}).text)
  for _, item in ipairs(channel.children) do
    if item.name == "item" then
      local enc = M.child(item, "enclosure")
      if enc and enc.attrs.url then
        local dur = M.child(item, "itunes:duration")
        feed.episodes[#feed.episodes + 1] = {
          id = (M.child(item, "guid") or {}).text or enc.attrs.url,
          title = (M.child(item, "title") or {}).text or "?",
          date = (M.child(item, "pubDate") or {}).text,
          url = enc.attrs.url,
          duration = dur and velouna.text.time(dur.text) or nil,
          description = velouna.text.strip_tags((M.child(item, "description") or {}).text or ""),
        }
      end
    end
  end
  return feed
end

return M
