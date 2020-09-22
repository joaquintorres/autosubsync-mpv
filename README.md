# autosubsync-mpv
Automatic subtitle synchronization script for mpv media player,
using [ffsubsync](https://github.com/smacke/ffsubsync).
This is a fork of [autosub](https://github.com/vayan/autosub-mpv),
and it's meant to work nicely alongside `autosub`,
[trueautosub](https://github.com/fullmetalsheep/mpv-iina-scripts)
or similar scripts.

### Usage
1. Install [ffsubsync](https://github.com/smacke/ffsubsync).
You can simply use `pip install ffsubsync`,
assuming you already have `ffmpeg` installed.
2. Download `autosubsync.lua` or clone the repo.

3. If your `ffsubsync` path isn't the default,
create a config file at `~/.config/mpv/script-opts/autosubsync.conf`
and add the correct path. For example:
```
subsync_path=/usr/local/bin/ffsubsync
```
In GNU/Linux you can use `which ffsubsync` to find out where it is.

4. Move `autosubsync.lua` to your scripts folder.
This is typically in `~/.config/mpv/scripts` (GNU/Linux)
or `%AppData%\mpv\scripts\` (Windows).

5. When you have an out of sync sub, press `n` to synchronize it.

`ffsubsync` can typically take up to about 20-30 seconds
to synchronize (I've seen it take as much as 2 minutes
with a very large file on a lower end computer), so it
would probably be faster to find another, properly
synchronized subtitle with `autosub` or `trueautosub`.
Many times this is just not possible, as all available
subs for your specific language are out of sync.
Take into account that using this script has the
same limitations as `ffsubsync`, so subtitles that have
a lot of extra text or are meant for an entirely different 
version of the video might not sync properly

Note that **the subtitle file will be overwritten**, so beware.

### Possible improvements
* Test if it works properly in Windows or MacOS,
or in mpv-based players like [mpv.net](https://github.com/stax76/mpv.net)
or [celluloid](https://celluloid-player.github.io/).
* Modify it to support multiple filenames/languages.
Since `autosub` and `trueautosub` only use one language
at a time and the same subtitle name as the video file,
this hasn't been too much of a bother yet.
