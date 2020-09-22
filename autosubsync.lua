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
    if not filepath then
        return false
    end
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

local function subprocess(args)
    return mp.command_native {
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        args = args
    }
end

local function get_active_subtitle_track_path()
    local sub_track_path
    local tracks_count = mp.get_property_number("track-list/count")

    for i = 1, tracks_count do
        local track_type = mp.get_property(string.format("track-list/%d/type", i))
        local track_index = mp.get_property_number(string.format("track-list/%d/ff-index", i))
        local track_selected = mp.get_property(string.format("track-list/%d/selected", i))

        if track_type == "sub" and track_selected == "yes" then
            sub_track_path = mp.get_property(string.format("track-list/%d/external-filename", i))
            break
        end
    end
    return sub_track_path
end

local function remove_extension(filename)
    return filename:gsub('%.%w+$', '')
end

local function sync_sub_fn()
    local video_path = mp.get_property("path")
    local subtitle_path = get_active_subtitle_track_path()

    if file_exists(subtitle_path) == false then
        notify(table.concat { "Subtitle synchronization failed:\nCouldn't find ", subtitle_path or "subtitle file." }, "error", 3)
        return
    end

    notify("Starting ffsubsync...", nil, 2)

    local retimed_subtitle_path = remove_extension(subtitle_path) .. '_retimed.srt'
    local ret = subprocess { config.subsync_path, video_path, "-i", subtitle_path, "-o", retimed_subtitle_path }

    if ret.error == nil then
        if mp.commandv("sub_add", retimed_subtitle_path) then
            notify("Subtitle synchronized.")
        else
            notify("Error: couldn't add synchronized subtitle.", "error", 3)
        end
    else
        notify("Subtitle synchronization failed.", "error", 3)
    end
end

-- Entry point
if config.subsync_path == "" then
    config.subsync_path = get_default_subsync_path()
end
mp.add_key_binding("n", "auto_sync_subs", sync_sub_fn)
