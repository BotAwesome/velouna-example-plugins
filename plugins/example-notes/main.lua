-- Example: Notes (MIT)
--
-- A menu entry in the player's menu opens a dialog; the note is stored with
-- the position. A button in the player bar lists the notes of this file and
-- jumps to one.

local function fmt(sec)
  sec = math.floor(sec or 0)
  return string.format("%d:%02d", sec // 60, sec % 60)
end

local function notes_for(path)
  local all = velouna.storage.get("notes") or {}
  return all[path] or {}, all
end

-- Labels can be one string or one per language.
velouna.menu.add({
  id = "add-note",
  label = { en = "Note at this point…", de = "Notiz zu dieser Stelle…" },
  icon = "bookmark",
  where = { "player" },              -- also: "main", "item" (plugin sources)
  run = function(item)
    if not item or not item.path or item.path == "" then
      velouna.ui.toast("Notes work for files and streams, not for media servers")
      return
    end
    local pos = velouna.player.state().time
    velouna.ui.dialog({
      title = "Note at " .. fmt(pos),
      text = item.title,
      fields = {
        { id = "text", type = "text", label = "Note" },
      },
      buttons = {
        { id = "cancel", label = "Cancel" },
        { id = "save", label = "Save", primary = true },
      },
    }, function(button, values)
      -- Called with the button's id ("close" when the dialog was closed).
      if button ~= "save" or values.text == "" then return end
      local list, all = notes_for(item.path)
      list[#list + 1] = { at = pos, text = values.text }
      all[item.path] = list
      velouna.storage.set("notes", all)
      velouna.ui.toast("Note saved at " .. fmt(pos))
    end)
  end,
})

velouna.player.add_button({
  id = "notes",
  icon = "list",                     -- see the docs for the icon names
  label = { en = "Notes", de = "Notizen" },
  run = function(item)
    local list = notes_for(item and item.path or "")
    if #list == 0 then
      velouna.ui.toast("No notes for this file yet")
      return
    end
    local options = {}
    for i, n in ipairs(list) do
      options[#options + 1] = { value = tostring(i), label = fmt(n.at) .. "  " .. n.text }
    end
    velouna.ui.dialog({
      title = "Notes",
      fields = { { id = "pick", type = "choice", options = options, default = "1" } },
      buttons = { { id = "close", label = "Close" }, { id = "go", label = "Jump there", primary = true } },
    }, function(button, values)
      if button == "go" then
        velouna.player.seek(list[tonumber(values.pick)].at)
      end
    end)
  end,
})
