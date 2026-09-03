-- Replace Omarchy's immediate workspace cycling with the visual switcher.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")

local workspace_switcher_active = false
local workspace_switcher_submap = "reomarchy-workspace-switcher"
local release_watchdog
local hold_timer
local super_is_down = false
local other_key_pressed = false
local hold_ticks = 0

local function finish_workspace_switcher(commit)
  if not workspace_switcher_active then return end

  workspace_switcher_active = false
  release_watchdog:set_enabled(false)
  if hl.get_current_submap() == workspace_switcher_submap then
    hl.dispatch(hl.dsp.submap("reset"))
  end

  if commit then
    hl.exec_cmd("omarchy-shell shell summon reomarchy.workspace-switcher '{\"commit\":true}'")
  else
    hl.exec_cmd("omarchy-shell shell hide reomarchy.workspace-switcher")
  end
end

release_watchdog = hl.timer(function()
  if workspace_switcher_active
      and not hl.is_key_down(133)
      and not hl.is_key_down(134) then
    finish_workspace_switcher(true)
  end
end, { timeout = 100, type = "repeat" })
release_watchdog:set_enabled(false)

local function summon_workspace_switcher(direction, immediate)
  if not workspace_switcher_active then
    workspace_switcher_active = true
    hl.dispatch(hl.dsp.submap(workspace_switcher_submap))
  end
  release_watchdog:set_enabled(true)
  local payload
  if immediate then
    payload = '{\"direction\":0,\"immediate\":true}'
  else
    payload = '{\"direction\":' .. direction .. '}'
  end
  hl.exec_cmd("omarchy-shell shell summon reomarchy.workspace-switcher '" .. payload .. "'")
end

-- Hold timer: polls every 50ms while Super is held.
-- After 4 ticks (~200ms) of holding Super with no other keys pressed,
-- it brings up the workspace switcher visual overlay.
hold_timer = hl.timer(function()
  if not super_is_down or other_key_pressed or (not hl.is_key_down(133) and not hl.is_key_down(134)) then
    hold_timer:set_enabled(false)
    return
  end

  hold_ticks = hold_ticks + 1
  if hold_ticks >= 4 then
    hold_timer:set_enabled(false)
    if not workspace_switcher_active then
      summon_workspace_switcher(0, true)
    end
  end
end, { timeout = 50, type = "repeat" })
hold_timer:set_enabled(false)

hl.define_submap(workspace_switcher_submap, function()
  hl.bind("SUPER + TAB", function() summon_workspace_switcher(1, false) end)
  hl.bind("SUPER + SHIFT + TAB", function() summon_workspace_switcher(-1, false) end)
  hl.bind("escape", function() finish_workspace_switcher(false) end, { ignore_mods = true })

  -- Allow direct workspace selection by digit (1-9, 0 for 10) while the switcher is open
  for workspace = 1, 10 do
    local key = "code:" .. tostring(workspace + 9)
    local select_ws = function()
      hl.exec_cmd("omarchy-shell shell summon reomarchy.workspace-switcher '{\"selectWorkspace\":" .. workspace .. "}'")
    end
    hl.bind(key, select_ws, { ignore_mods = true })
    hl.bind("SUPER + " .. key, select_ws)
  end
end)

hl.bind("SUPER + TAB", function() summon_workspace_switcher(1, false) end, { description = "Visual workspace switcher" })
hl.bind("SUPER + SHIFT + TAB", function() summon_workspace_switcher(-1, false) end, { description = "Visual workspace switcher (reverse)" })

-- XKB keycodes 133/134 are left/right Command/Super; state 1 is press, 0 is release.
hl.on("input.keyboard.key", function(keycode, _, state)
  if keycode == 133 or keycode == 134 then
    if state == 1 then
      if not workspace_switcher_active then
        super_is_down = true
        other_key_pressed = false
        hold_ticks = 0
        hold_timer:set_enabled(false)
        hold_timer:set_enabled(true)
      end
    elseif state == 0 then
      super_is_down = false
      hold_timer:set_enabled(false)
      if workspace_switcher_active then
        finish_workspace_switcher(true)
      end
    end
  else
    if state == 1 then
      if not workspace_switcher_active then
        other_key_pressed = true
        hold_timer:set_enabled(false)
      end
    end
  end
end)

-- A config reload destroys the old watchdog and event subscription. Never
-- leave Hyprland in the switcher submap if a reload happened mid-switch.
if hl.get_current_submap() == workspace_switcher_submap then
  hl.dispatch(hl.dsp.submap("reset"))
end
