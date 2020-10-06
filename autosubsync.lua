-- default keybinding: n
-- add the following to your input.conf to change the default keybinding:
-- keyname script_binding auto_sync_subs
local utils = require('mp.utils')
local mpopt = require('mp.options')

-- Options can be changed here or in a separate config file.
-- Config path: ~/.config/mpv/script-opts/autosubsync.conf
local config = {
    subsync_path = "",  -- Replace the following line if the location of ffsubsync differs from the defaults
    subsync_tool = "ffsubsync",
}
mpopt.read_options(config, 'autosubsync')

-- Snippet borrowed from stackoverflow to get the operating system
-- originally found at: https://stackoverflow.com/a/30960054
os.name = (function()
    if os.getenv("HOME") == nil then
        return function()
            return "Windows"
        end
    else
        return function()
            return "*nix"
        end
    end
end)()

local function get_default_subsync_path()
    -- Chooses the default location of the ffsubsync executable depending on the operating system
    if os.name() == "Windows" then
        return utils.join_path(os.getenv("LocalAppData"), "Programs\\Python\\Python38\\scripts\\ffsubsync.exe")
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

local function get_extension(filename)
    return filename:match("^.+(%.%w+)$")
end

local function sync_sub_fn(timed_sub_path)
    local reference_file_path = timed_sub_path or mp.get_property("path")
    local subtitle_path = get_active_subtitle_track_path()

    if file_exists(subtitle_path) == false then
        notify(table.concat { "Subtitle synchronization failed:\nCouldn't find ", subtitle_path or "subtitle file." }, "error", 3)
        return
    end

    local retimed_subtitle_path = table.concat { remove_extension(subtitle_path), '_retimed', get_extension(subtitle_path) }

    local ret
    if config.subsync_tool ~= "ffsubsync" then
        notify("Starting alass...", nil, 2)
        ret = subprocess { config.subsync_path, reference_file_path, subtitle_path, retimed_subtitle_path }
    else
        notify("Starting ffsubsync...", nil, 2)
        ret = subprocess { config.subsync_path, reference_file_path, "-i", subtitle_path, "-o", retimed_subtitle_path }
    end

    if ret == nil then
        notify("Parsing failed or no args passed.", "fatal", 3)
        return
    end

    if ret.status == 0 then
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
local function sync_to_internal()
    local extracted_sub_filename = os.tmpname()
    os.remove(extracted_sub_filename)
    extracted_sub_filename = extracted_sub_filename .. '.srt'

    local ret = subprocess {
        config.ffmpeg_path,
        "-hide_banner",
        "-nostdin",
        "-y",
        "-loglevel", "quiet",
        "-an",
        "-vn",
        "-i", mp.get_property("path"),
        "-f", "srt",
        extracted_sub_filename
    }

    if ret == nil or ret.status ~= 0 then
        notify("Couldn't extract internal subtitle.\nMake sure the video has internal subtitles.", "error", 7)
        return
    end

    sync_sub_fn(extracted_sub_filename)
end

if config.subsync_path == "" then
    if config.subsync_tool ~= "ffsubsync" then
        -- silently guess alass path if it's not set
        config.subsync_path = file_exists('/usr/bin/alass') and '/usr/bin/alass' or '/usr/local/bin/alass'
    else
        config.subsync_path = get_default_subsync_path()
    end
end
mp.add_key_binding("n", "auto_sync_subs", sync_sub_fn)

------------------------------------------------------------
-- Menu visuals

local assdraw = require('mp.assdraw')

Menu = assdraw.ass_new()
Menu.__index = Menu

function Menu:new(o)
    o = o or {}
    o.selected = o.selected or 1
    o.canvas_width = o.canvas_width or 1280
    o.canvas_height = o.canvas_height or 720
    o.pos_x = o.pos_x or 0
    o.pos_y = o.pos_y or 0
    o.rect_width = o.rect_width or 250
    o.rect_height = o.rect_height or 40
    o.active_color = o.active_color or 'ffffff'
    o.inactive_color = o.inactive_color or 'aaaaaa'
    return setmetatable(o, self)
end

function Menu:set_position(x, y)
    self.pos_x = x
    self.pos_y = y
end

function Menu:font_size(size)
    self:append(string.format([[{\fs%s}]], size))
end

function Menu:apply_color(i)
    if i == self.selected then
        self:set_color(self.active_color)
    else
        self:set_color(self.inactive_color)
    end
end

function Menu:draw_text(i)
    local padding = 5
    local font_size = 25

    self:new_event()
    self:pos(self.pos_x + padding, self.pos_y + self.rect_height * (i - 1) + padding)
    self:font_size(font_size)
    self:apply_color(i)
    self:append(self.items[i])
end

function Menu:set_color(code)
    self:append('{\\1c&H')
    self:append(code:sub(5, 6))
    self:append(code:sub(3, 4))
    self:append(code:sub(1, 2))
    self:append('&\\1a&H10&}')
end

function Menu:draw_item(i)
    self:new_event()
    self:pos(self.pos_x, self.pos_y)
    self:apply_color(i)
    self:draw_start()
    self:rect_cw(0, 0 + (i - 1) * self.rect_height, self.rect_width, i * self.rect_height)
    self:draw_stop()
    self:draw_text(i)
end

function Menu:draw()
    self.text = ''
    for i, _ in ipairs(self.items) do
        self:draw_item(i)
    end

    mp.set_osd_ass(self.canvas_width, self.canvas_height, self.text)
end

function Menu:erase()
    mp.set_osd_ass(self.canvas_width, self.canvas_height, '')
end

function Menu:up()
    self.selected = self.selected - 1
    if self.selected == 0 then
        self.selected = #self.items
    end
    self:draw()
end

function Menu:down()
    self.selected = self.selected + 1
    if self.selected > #self.items then
        self.selected = 1
    end
    self:draw()
end

