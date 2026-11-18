-- Example: Webhook (MIT)
--
-- Posts a small JSON message when a track starts or ends. The permission
-- "network:local" lets the plugin reach addresses in the home network only
-- (192.168.x.x, *.local, …). To reach a server on the internet, name its
-- host instead: "network:example.com".

local function send(event, t)
  local url = velouna.settings.get("url")
  if not url or url == "" then
    return false, "no address set"
  end
  -- velouna.http.post(url, body, options): a table as body is sent as JSON.
  local res, err = velouna.http.post(url, {
    event = event,
    title = t.title,
    artist = t.artist,
    kind = t.kind,
    source = t.source,
  })
  if not res then
    return false, err                 -- network error: nil plus a message
  end
  if not res.ok then
    return false, "HTTP " .. res.status
  end
  return true
end

local function wanted(t)
  return not velouna.settings.get("music_only") or t.kind == "audio"
end

velouna.events.on("track-started", function(t)
  if wanted(t) then
    local ok, err = send("track-started", t)
    if not ok then velouna.warn("webhook: " .. err) end
  end
end)

velouna.events.on("track-ended", function(t, info)
  if wanted(t) and info.reason == "eof" then
    send("track-ended", t)
  end
end)

-- The "Send a test" button on the settings page (type "action", run = "test").
velouna.settings.on_action("test", function()
  local ok, err = send("test", { title = "Test", kind = "audio", source = "file" })
  velouna.ui.toast(ok and "Webhook: sent" or ("Webhook: " .. err))
end)
