# autosubsync-mpv
Automatic subtitle synchronization script for mpv media player,
using [ffsubsync](https://github.com/smacke/ffsubsync).
This is a fork of [autosub](https://github.com/vayan/autosub-mpv),
and it's meant to work nicely alongside `autosub`,
[trueautosub](https://github.com/fullmetalsheep/mpv-iina-scripts)
or similar scripts.

This branch tests experimental support for 
[alass](https://github.com/kaegi/alass) (and tools with similar 
syntax). This hasn't been fully tested yet but appears to work in 
GNU/Linux. The basic idea is to first get it to work properly 
with one alternative subsync tool, and then incorporate support
for most.

### Usage
1. Install [ffsubsync](https://github.com/smacke/ffsubsync).
You can simply use `pip install ffsubsync`,
assuming you already have `ffmpeg` installed.
Alternatively, install [alass](https://github.com/kaegi/alass).
2. Download `autosubsync.lua` or clone the repo.
3. If your `ffsubsync` path isn't the default,
create a config file at `~/.config/mpv/script-opts/autosubsync.conf`
and add the correct path. For example:
```
subsync_path=/usr/local/bin/ffsubsync
```
* In Windows you need to use forward slashes 
or double backslashes for your path,
like `"C:\\Users\\YourPath\\Scripts\\ffsubsync"`
or `"C:/Users/YourPath/Scripts/ffsubsync"`,
or else it won't work. 

* In GNU/Linux you can use `which ffsubsync` to find out where it is.

* If you'd like to use `alass`, add this line to your 
`autosubsync.conf` file:
```
subsync_path=/usr/local/bin/alass
subsync_tool=alass
```
where `subsync_path` now contains your `alass` path.
 
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
version of the video might not sync properly. `alass` is supposed
to handle some edge cases better, but I haven't fully tested it yet,
obtaining similar results with both.

Note that the script will create a new subtitle file, in the same folder as the original, with the `_retimed` suffix at the end.

### Possible improvements
* ~~Actually check if the srt file exists before feeding it to ffsubsync.
Pressing n without the proper file will cause ffsubsync to extract the
whole raw audio before actually raising the corresponding error flag,
and that's just incredibly slow for such basic error handling.~~
Fixed, added some messages too.
* Test if it works properly in ~~Windows~~ or MacOS, or in mpv-based
players like [mpv.net](https://github.com/stax76/mpv.net) 
or [celluloid](https://celluloid-player.github.io/).
* ~~Modify it to support multiple filenames/languages. 
Since `autosub` and `trueautosub` only use one language at a time and 
the same subtitle name as the video file, this hasn't been too much of a bother yet.~~
* Add compatibility with 
[autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) 
to sync all the files in a playlist.
