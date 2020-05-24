-- default keybinding: n
-- add the following to your input.conf to change the default keybinding:
-- keyname script_binding auto_sync_subs
local utils = require 'mp.utils'

function display_error()
  mp.msg.warn("Subtitle synchronization failed: ")
  mp.osd_message("Subtitle synchronization failed")
end

function sync_sub_fn()
  path = mp.get_property("path")
  srt_path = string.gsub(path, "%.%w+$", ".srt")
  subsync = "/home/user/.local/bin/ffsubsync" -- use 'which ffsubsync' to find the path
  t = {}
  t.args = {subsync, path, "-i",srt_path,"-o",srt_path}

  mp.osd_message("Sync subtitle...")
  res = utils.subprocess(t)
  if res.error == nil then
    if mp.commandv("sub_add", srt_path) then
      mp.msg.warn("Subtitle updated")
      mp.osd_message("Subtitle at'" .. srt_path .. "' synchronized")
    else
      display_error()
    end
  else
    display_error()
  end
end

mp.add_key_binding("n", "auto_sync_subs", sync_sub_fn)
