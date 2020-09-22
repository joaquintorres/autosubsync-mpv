-- default keybinding: n
-- add the following to your input.conf to change the default keybinding:
-- keyname script_binding auto_sync_subs
local utils = require 'mp.utils'
local mpopt = require('mp.options')

-- Options can be changed here or in a separate config file.
-- Config path: ~/.config/mpv/script-opts/autosubsync.conf
local config = {
    subsync_path = ""  -- Replace the following line if the location of ffsubsync differs from the defaults
}
mpopt.read_options(config, 'autosubsync')

-- Snippet borrowed from stackoverflow to get the operating system
-- originally found at: https://stackoverflow.com/a/30960054
os.name = (function()
    local binary_format = package.cpath:match("%p[\\|/]?%p(%a+)")
    if binary_format == "dll" then
        return function()
            return "Windows"
        end
    elseif binary_format == "so" then
        return function()
            return "Linux"
        end
    elseif binary_format == "dylib" then
        return function()
            return "macOS"
        end
    end
end)()

local function get_default_subsync_path()
    -- Chooses the default location of the ffsubsync executable depending on the operating system
    if os.name() == "Windows" then
        return "%APPDATA%/Python/Scripts/ffsubsync"
    else
        return utils.join_path(os.getenv("HOME"), ".local/bin/ffsubsync")
    end
end

-- Courtesy of https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua
local function file_exists(filepath)
    local f = io.open(filepath, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function notify(message, level, duration)
    level = level or 'info'
    duration = duration or 1
    mp.msg[level](message)
    mp.osd_message(message, duration)
end

local function sync_sub_fn()
    local video_path = mp.get_property("path")
    local subtitle_path = string.gsub(video_path, "%.%w+$", ".srt")

    if file_exists(subtitle_path) == false then
        notify(table.concat { "Subtitle synchronization failed:\nCouldn't find ", subtitle_path }, "error", 3)
        return
    end

    local t = {}
    t.args = { config.subsync_path, video_path, "-i", subtitle_path, "-o", subtitle_path }

    notify("Starting ffsubsync...", nil, 9999)

    local ret = utils.subprocess(t)
    if ret.error == nil then
        if mp.commandv("sub_add", subtitle_path) then
            notify("Subtitle synchronized.")
        else
            notify("Error: couldn't add synchronized subtitle.", "error", 2)
        end
    else
        notify("Subtitle synchronization failed.", "error", 2)
    end
end

-- Entry point

config.subsync_path = config.subsync_path == "" or get_default_subsync_path()
mp.add_key_binding("n", "auto_sync_subs", sync_sub_fn)
