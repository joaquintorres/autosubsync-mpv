-- default keybinding: n
-- add the following to your input.conf to change the default keybinding:
-- keyname script_binding auto_sync_subs
local utils = require 'mp.utils'

-- Snippet borrowed from stackoverflow to get the operating system
-- originally found at: https://stackoverflow.com/a/30960054
if os.getenv('HOME') == nil then
  function os.name()
    return "Windows"
  end
else
  function os.capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
  end
  function os.name()
    return os.capture('uname')
  end
end

-- Chooses the default location of the ffsubsync executable depending on the operating system
if os.name() == "Linux" or os.name() == "macOS" then
    default_subsync_location = utils.join_path(os.getenv("HOME"), ".local/bin/ffsubsync") 
elseif os.name() == "Windows" then 
    default_subsync_location = utils.join_path(os.getenv("LocalAppData"), "Programs\\Python\\Python38\\scripts\\ffsubsync.exe")
end

function display_error()
  mp.msg.warn("Subtitle synchronization failed: ")
  mp.osd_message("Subtitle synchronization failed")
end

-- Courtesy of https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua
function file_exists(filepath)
   local f=io.open(filepath,"r")
   if f~=nil then io.close(f) return true else return false end
end

function sync_sub_fn()
  path = mp.get_property("path")
  srt_path = string.gsub(path, "%.%w+$", ".srt")
  if file_exists(srt_path)==false then
    mp.msg.warn("Couldn't find",srt_path)
    display_error()
    do return end
  end 

  -- Replace the following line if the location of ffsubsync differs from the defaults
  -- You may use 'which ffsubsync' to find the path
  subsync = default_subsync_location
  t = {}
  t.args = {subsync, path, "-i",srt_path,"-o",srt_path}

  mp.osd_message("Sync subtitle...")
  mp.msg.info("Starting ffsubsync...")
  res = utils.subprocess(t)
  if res.error == nil then
    if mp.commandv("sub_add", srt_path) then
      mp.msg.info("Subtitle updated")
      mp.osd_message("Subtitle at'" .. srt_path .. "' synchronized")
    else
      display_error()
    end
  else
    display_error()
  end
end

mp.add_key_binding("n", "auto_sync_subs", sync_sub_fn)

