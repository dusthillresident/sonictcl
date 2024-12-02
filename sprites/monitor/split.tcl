package require Tk

image create photo monitors -file sprites/monitor/noise.png
set w [expr [image width p]/8]
for {set i 0} {$i<8} {incr i} {
 set m [image create photo]
 $m copy monitors -from [expr {$w*$i}] [expr {$w*$i+$w}]
 lappend SnoiseMonitors
}
image delete monitors