# sonictcl
Sonic the hedgehog game in Tcl/Tk

To play on windows, download the zip and extract it somewhere, and then double click the "windows_run.bat" file.

To play on Debian or Ubuntu or similar linux distros, you should install these packages:

`tcl tk tcl-snack`

You can do that with this terminal command:

`sudo apt-get install tcl tk tcl-snack`

Then you can run the game by navigating to the folder and doing this:

`tclsh sonic.tcl`

You can use these command line options: 

Disable sound: `-sound 0`

Disable joypad (you might need to do this if you have a laptop that exposes the tilt sensors as a joypad) `-joy 0`

Start on level '[number]': `-level [number]`

Windows randomly thinks this is a virus, I don't know why it does that. There is of course no virus in this. If this happens to you, look up online with duckduckgo or bing "how to temporarily disable Windows Defender"

The game runs at a fixed resolution of 640x480. If this is too small for you, you can use magnifying to zoom in. On windows, press Ctrl + Windows + M to get the magnifier settings menu, from there you can set the magnifier as you need.

on Linux with XFCE you can zoom in by using the zoom in feature, try holding left Alt and using the scrollwheel on your mouse. (if it doesn't work, look in 'Window Manager Tweaks' -> 'Compositor' tab -> tick 'enable display compositing' and 'zoom desktop with mouse wheel'
