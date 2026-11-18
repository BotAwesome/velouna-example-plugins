-- Example: Podcasts (RSS) (MIT)
--
-- A source shows up in the library's sidebar. browse(path) returns the
-- items of a page: path "" is the start page, every other path is the id
-- of a folder item the user opened. Items with a url (or playable = true and
-- a resolve function) play when clicked.
--
-- "network:*" lets it read feeds from any server, because the feeds are
-- whatever the user enters. A plugin for one service names its host instead.

local util = require("dev.botawesome.example-module")

local cache = {}                       -- url → feed, for this session

local function feeds()
  local list = {}
  for url in (velouna.settings.get("feeds") or ""):gmatch("%S+") do
    list[#list + 1] = url
  end
  return list
end

local function load(url)
  if cache[url] then return cache[url] end
  local res, err = velouna.http.get(url)
  if not res then error("can't load " .. url .. ": " .. err) end
  if not res.ok then error(url .. " answered " .. res.status) end
  local feed, perr = util.read_rss(res.body)
  if not feed then error(url .. ": " .. perr) end
  cache[url] = feed
  return feed
end

local function episode_item(feed, e)
  return {
    id = e.id,
    kind = "episode",
    title = e.title,
    -- Velouna shows the duration itself, at the right of the row.
    subtitle = e.date or "",
    description = e.description,
    duration = e.duration,
    art = { thumb = feed.image },
    url = e.url,                       -- plays right away, no resolve needed
  }
end

velouna.sources.add({
  id = "podcasts",
  label = { en = "Podcasts", de = "Podcasts" },
  icon = "microphone",
  browse = function(path)
    if path == "" then
      local items = {}
      for _, url in ipairs(feeds()) do
        local ok, feed = pcall(load, url)
        items[#items + 1] = {
          id = url,
          kind = "folder",
          title = ok and feed.title or url,
          subtitle = ok and (#feed.episodes .. " episodes") or tostring(feed),
          art = ok and { thumb = feed.image } or nil,
        }
      end
      if #items == 0 then
        items[1] = { id = "", kind = "folder", title = "Add feeds in the plugin's settings", playable = false }
      end
      return velouna.ui.list({ items = items, view = "grid" })
    end
    local feed = load(path)
    local items = {}
    for _, e in ipairs(feed.episodes) do
      items[#items + 1] = episode_item(feed, e)
    end
    return velouna.ui.list({ items = items, view = "list" })
  end,
  search = function(text)
    local q, items = text:lower(), {}
    for _, url in ipairs(feeds()) do
      local ok, feed = pcall(load, url)
      if ok then
        for _, e in ipairs(feed.episodes) do
          if e.title:lower():find(q, 1, true) then
            items[#items + 1] = episode_item(feed, e)
          end
        end
      end
    end
    return items
  end,
})

-- A row on the start page: the newest episode of every feed.
velouna.home.add({
  id = "new",
  label = { en = "New podcast episodes", de = "Neue Podcast-Folgen" },
  items = function()
    local items = {}
    for _, url in ipairs(feeds()) do
      local ok, feed = pcall(load, url)
      if ok and feed.episodes[1] then
        items[#items + 1] = episode_item(feed, feed.episodes[1])
      end
    end
    return items
  end,
})
