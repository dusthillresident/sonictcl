# sonictcl
Sonic the hedgehog game in Tcl/Tk

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

