#!/usr/bin/env tclsh

proc cmdAlias {nickname realname} {
 set ::argv [lmap i $::argv {if {$i eq $nickname} {set realname} else {set i}}]
}
cmdAlias -recordgame -recorddemo

package require Tk
tk appname "Sonac the Hedgehog v2"
pack [label .notice -text "Loading, please wait" -font {sans 20}] -fill both -expand 1
update
update

set fullGameRecording {}
set timeAverage 0.0
set song {}

proc debugMsg {args} {
 foreach i $args {
  puts -nonewline stderr "$i	"
 }
 puts stderr {}
}

proc cmdArgument {argument {default {}} } {
 set index [lsearch -exact $::argv $argument]
 set result $default
 if {$index != -1} {
  set result [lindex $::argv $index+1]
 }
 return $result
}

proc cmdArgumentIsDefined {argument} {
 expr { [lsearch -exact $::argv $argument] != -1 }
}
proc cmdArgumentsAreDefined {args} {
 foreach i $args {
  if { [cmdArgumentIsDefined $i] } {return 1}
 }
 return 0
}

set DONT_CONVERT_GEOMETRY [::tcl::mathop::! [cmdArgumentIsDefined -convert]]
source geometryToText.tcl

set DEBUG [cmdArgumentIsDefined -debug]
set DEBUG_MESSAGES [cmdArgumentIsDefined -debugmsg]
set DISABLE_GFX_LAYERS [cmdArgumentIsDefined -nogfx]
set PLAY_MUSIC [cmdArgument -music 1]
set ENABLE_SOUND [cmdArgument -sound 1]
set SHOW_TITLECARD [cmdArgument -titlecard 1]
set SHOW_TITLESCREEN [cmdArgument -titlescreen 1]
if { [cmdArgumentIsDefined -quick] } {
 set SHOW_TITLECARD 0
 set SHOW_TITLESCREEN 0
}
set currentLevelIndex [cmdArgument -level 1]

set recordGame [expr { [cmdArgumentIsDefined -recorddemo] && ! [cmdArgumentIsDefined -playdemo] }]
if {$recordGame} {
 set demoFile [cmdArgument -demofile recorded_demo.txt]
}
set playRecording [cmdArgumentsAreDefined -playdemo -replay]
if {$playRecording} {
 if {[cmdArgumentIsDefined -replay]} {
  set path [cmdArgument -replay]
  if { ! [cmdArgumentIsDefined -level] && [lindex [file split $::path] end-2] eq {replays} } {
   set currentLevelIndex [lindex [file split $::path] end-1]
  }
  set fullGameRecording [lrepeat 32 {0 0}]
  lset fullGameRecording [expr {$currentLevelIndex-1}] [read [open [cmdArgument -replay ]]]
 } else {
  set fullGameRecording [read [open [cmdArgument -demofile recorded_demo.txt]]]
 }
}
set recordingPos 0
set watchPos [cmdArgument -watchpos 0]
if { [cmdArgumentIsDefined -frame] } {
 set watchPos [cmdArgument -frame]
}

if { [cmdArgumentIsDefined -test] } {
 set DEBUG 1
 set DEBUG_MESSAGES 1
 set DISABLE_GFX_LAYERS 1
 set PLAY_MUSIC 0
 set ENABLE_SOUND 0
 set SHOW_TITLECARD 0
 set SHOW_TITLESCREEN 0
 set DONT_CONVERT_GEOMETRY 1
 set currentLevelIndex [cmdArgument -level 0]
}

if {! $DEBUG_MESSAGES } {
 proc debugMsg {args} {}
}

set timeDivisor [cmdArgument -timedivisor 1000.0]
set wtime [cmdArgument -wtime]
if { $tcl_platform(platform) eq {windows} && ![cmdArgumentIsDefined -wtime] } {
 # Unfortunately, on windows the 'after (miliseconds)' command doesn't work properly,
 # and the amount of time it sleeps for is unpredictable and not accurate to the miliseconds argument specified.
 # So on windows, the game has to hog a cpu core in order to run at a smooth consistent framerate.
 # this is not a problem on Linux
 set wtime 0
}
set frameMs [cmdArgument -framems 16666]
set frameTimeLength [expr { int((16666.66666666)/double($timeDivisor)) }]
#puts "Time to wait between frames: $frameTimeLength ms\n"
set WTIME 17
if {$::tcl_platform(platform) eq {windows}} {
 set WTIME 7
}
proc testbeep { {freq 100} {message {}} } {
 debugMsg "\nTESTBEEP FREQ $freq	$message\n"
 #exec beep -f $freq -l 2 &
}

set gameLevels [lsort [glob levels/*]]
#puts "gamelevels $gameLevels"; exit


#rename lindex linux
#proc lindex {args} {
# if { [llength $args]==1 || [string is space [linux $args 1]] } {error "here it is"}
# return [linux {*}$args]
#}

proc print {args} {
 foreach i $args {
  puts -nonewline "$i	"
 }
 puts {}
}
proc ::tcl::mathfunc::sgn n {expr {$n<0 ? -1 : ($n>0 ? 1 : 0)}}

# A level will have these things:
# * Two 'layers', a layer is an image representing the level geometry
# * graphics layer 1 (background)
#  Graphical representation of the level geometry. Sonic is drawn above this layer
# * graphics layer 2 (foreground)
#  Graphical representation of the level geometry. Sonic is drawn below this layer

catch {
 console show
 update
 if { ! [cmdArgumentIsDefined -console] } {console hide}
 wm deiconify .
}

source "loadsprites.tcl"
source "sound.tcl"

image create photo graphics0 
image create photo graphics1

set level {}

toplevel .debug
pack [label .debug.x -textvariable sonicx -anchor w] -fill x
pack [label .debug.y -textvariable sonicy -anchor w] -fill x
pack [entry .debug.e -textvariable wtime] -fill x
pack [listbox .debug.lb -listvariable levelObjects] -fill x -expand 1
pack [frame .f -relief raised -borderwidth 1] -fill x
pack [label .f.l -textvariable sonica -font {monospace 9} -width 16 -anchor w ] -side left -padx 4
pack [label .f.l2 -textvariable sonicm -font {monospace 9} -width 16 -anchor w ] -side left -padx 4
pack [label .f.l3 -font {monospace 9} -width 16 -anchor w] -side left -padx 4
pack [label .f.l4 -font {monospace 9} -width 16 -anchor w] -side left -padx 4
pack [label .f.spacer] -fill x -side right -expand 1
pack [canvas .c -width 640 -height 480 -background black -cursor [expr { $DEBUG ? "" : "none" }]] -expand [cmdArgument -expand 1] -fill [cmdArgument -fill none]
pack [checkbutton .debug.shield -variable sonicHasShield -text shield] 
. configure -background black

set bx 0; # set this to level width -1
set by 0; # set this to level height -1
incr bx -1
incr by -1

#	o-------------o
#	| Init canvas |
#	o-------------o

.c create text 0 0 -anchor nw -text "Rings: " -tag rings -font {Sans 20}  -fill yellow
#if {$DISABLE_GFX_LAYERS} {.c create image 0 0 -anchor nw -tag gfx-1}
.c create image 0 0 -anchor nw -tag gfx0
.c create image 0 0 -anchor nw -tag gfx1

image create photo gfx0 
image create photo gfx1
.c itemconfigure gfx0 -image gfx0
.c itemconfigure gfx1 -image gfx1


.c create image 0 0 -tag sonic
.c create image 0 0 -tag spindash
.c create image -640 -480 -tag shield

.c create image 0 0 -tag goal -anchor s -image $Sgoal

proc debugCanvasOrder {} {
 foreach i [.c find all] {
  debugMsg "$i	[.c type $i]		[.c gettags $i]"
 }
}

#	o---------------------------------o
#	| Debug infographics canvas items |
#	o---------------------------------o



image create photo marker -file sprites/debug/marker.png
image create photo marker2 -file sprites/debug/marker2.png
if {$DEBUG} {

 .c create line 0 0 0 0 -tag fadebug -width 2 -fill yellow

 .c create image 0 0 -tag marker -image marker
 .c create image 0 0 -tag marker2 -image marker2

 set angleTestIndicatorSize 24

 .c create oval 0 0 10 10 -outline pink -tag angler
 .c create line 0 0 10 10 -fill pink -tag anglel 
 .c create oval 0 0 10 10 -outline pink -tag anglerx
 .c create line 0 0 10 10 -fill pink -tag anglelx 
 .c create oval 0 0 [expr $angleTestIndicatorSize*2] [expr $angleTestIndicatorSize*2] -width 1 -outline cyan -tag angleoval
 .c create arc 0 0 [expr $angleTestIndicatorSize*2] [expr $angleTestIndicatorSize*2] -width 1 -outline white -tag angle -start 0 -extent 359

 .c create arc 0 0 [expr $angleTestIndicatorSize*2] [expr $angleTestIndicatorSize*2] -width 1 -outline cyan -tag angley -start 0 -extent 359
 .c create arc 0 0 [expr $angleTestIndicatorSize*2] [expr $angleTestIndicatorSize*2] -width 1 -outline white -tag angle -start 0 -extent 359
 .c create line 0 0 10 10 -fill pink -tag anglel 

 set angel 0.0
 proc angleTest2 {x y} {
  catch {
   set x [.c canvasx $x] 
   set y [.c canvasy $y]
   set a $::angel
   .c moveto angleoval [expr {$x-$::angleTestIndicatorSize}] [expr {$y-$::angleTestIndicatorSize}]
   .c coords anglel $x $y [expr {$x+$::angleTestIndicatorSize*sin($a)}] [expr {$y+$::angleTestIndicatorSize*cos($a)}]

   set a1 [floorAngle [expr {$x+$::angleTestIndicatorSize*sin($a)}] [expr {$y+$::angleTestIndicatorSize*cos($a)}]]
   set a2 $::angel

   debugMsg specialfunction [specialfunction $a1 $a2]
  }
 }
 bind .c <Motion> {
  angleTest %x %y
 }
 bind .c <ButtonPress-4> {
  set angel [expr {fnwrap($angel + 0.2)}]
  angleTest2 %x %y
 }
 bind .c <ButtonPress-5> {
  set angel [expr {fnwrap($angel - 0.2)}]
  angleTest2 %x %y
 }
}

#	o------------o
#	| Title card |
#	o------------o

proc cx {x} {
 return [.c canvasx [expr $x]]
}
proc cy {y} {
 return [.c canvasy [expr $y]]
}
proc wait {miliseconds} {
 #set miliseconds [expr {int( $miliseconds / (1000.0/$::timeDivisor) )}]
 set wval 17
 if {$::tcl_platform(platform) eq {windows}} {
  set wval 7
 }
 debugMsg wat [time {
  for {set i 0} {$i<$miliseconds} {incr i 17} {
   after $wval
   update
  }
 }]
}
proc titleCard {} {
 .c raise rings
 if {!$::SHOW_TITLECARD} return
 .c delete titlecard
 set black [.c create rectangle 0 0 645 485 -tag [list titlecard tblack] -outline {} -fill black]
 set green [.c create polygon [list 0 0  160 0  640 480  0 480] -tag [list titlecard tgreen] -outline {} -fill green]
 set blue  [.c create polygon [list 0 0  480 0  480 480] -tag [list titlecard tblue] -outline {} -fill blue]
 set red   [.c create polygon [list 0 0  362 0  0   362] -tag [list titlecard tred] -outline {} -fill red]
 set text  [.c create text 0 0 -text "Sonac the hedgehog" -font {Sans 20} -tag [list titlecard ttext] -fill white -anchor nw]
 set text  [.c create text 0 0 -text $::levelTitle -font {Sans 35} -tag [list titlecard ttitle] -fill white -anchor sw]
 .c moveto ttext [cx 0] [cy -640]
 .c moveto ttitle [cx 0] [cy 640*1.66]
 .c moveto tblack [cx 0] [cy 0]
 .c moveto tgreen [cx -640] [cy 0]
 .c moveto tblue [cx 640+160] [cy 0]
 .c moveto tred [cx 0] [cy -640]
 set step 16
 set mstep [expr {-$step}]
 for {set i 0} {$i<640} {incr i $step} {
  .c move tgreen $step 0
  .c move tblue $mstep 0
  .c move tred 0 $step
  .c move ttext 0 $step
  .c move ttitle 0 $mstep
  update
  after $::WTIME
 }
 set ::tcx [cx 0]
 set ::tcy [cy 0]
 .c delete tblack
 #lassign [.c coords tgreen] ::greenx ::greeny
 #lassign [.c coords tblue] ::bluex ::bluey
 #lassign [.c coords tred] ::redx ::redy
 #lassign [.c coords ttext] ::ttextx ::ttexty
 #lassign [.c coords ttitle] ::ttitlex ::ttitley
 #foreach {x y} { ::greenx ::greeny ::bluex ::bluey ::redx ::redy ::ttextx ::ttexty ::ttitlex ::ttitley } {
 # set $x [expr {int([set $x] - [cx 0])}]
 # set $y [expr {int([set $y] - [cy 0])}]
 #}
 makeTitleCard
 wait 1000
 #tk_messageBox -title {} -message {}
 #.c delete titlecard
}

proc makeTitleCard {} {
 lappend ::levelObjects [list TITLECARD titleCardAction {} {}]
 set ::titleCardCounter 640
}

proc titleCardAction {cItem data} {
 set step 16.0
 set ::titleCardCounter [expr {$::titleCardCounter-$step}]
 if {$::titleCardCounter<=0} {
  .c delete titlecard
  upvar objectIndex i
  lset ::levelObjects $i {}
  return
 }
 
 set otcx $::tcx
 set otcy $::tcy
 set ::tcx [cx 0]
 set ::tcy [cy 0]
#debugMsg tc $otcx $otcy $::tcx $::tcy
#return
 set cx [expr {($::tcx-$otcx)}]
 set cy [expr {($::tcy-$otcy)}]
 
 .c move tgreen [expr {$cx+-$step}] [expr {$cy}]
 .c move tblue [expr {$cx+$step}] [expr {$cy}]
 .c move tred [expr {$cx}] [expr {$cy+-$step}]
 .c move ttext [expr {$cx}] [expr {$cy+-$step}]
 .c move ttitle [expr {$cx}] [expr {$cy+$step}]
# foreach i {tgreen tblue tred ttext ttitle} {
#  puts "$i	[.c coords $i]"
# }
}

#	o--------------o
#	| Load a level |
#	o--------------o

set currentLevelPath {}
set ::restarted 1
proc loadLevel {path} {
 debugMsg "loadLevel start"
 set ::restarted 1
 set oldLevelPath $::currentLevelPath
 #if {$oldLevelPath ne $path} {
 # set ::holdGameRecording $::gameRecording
 #} else {
 # set ::gameRecording $::holdGameRecording
 #}
 set ::currentLevelPath $path
 foreach i [.c find withtag object] {
  .c delete $i
 }
 # --- init state ---
 initGameVariables
 if { $::playRecording } {
  set ::gameRecording [lindex $::fullGameRecording [expr {$::currentLevelIndex-1}]]
  #puts "here $::gameRecording"
 }
 # -- load level geometry and data ---
 if {$oldLevelPath ne $path} {
  loadGeometry $path
  if {!$::DISABLE_GFX_LAYERS} {
   image create photo gfx0 -file "$path/graphics0.png"
   image create photo gfx1 -file "$path/graphics1.png"
  } else {
   image create photo gfx0 -file "$path/layer0.png"
   image create photo gfx1 -file "$path/layer1.png"
  }
 }
 set ::bx [::tcl::mathfunc::max {*}$::levW]
 set ::by [::tcl::mathfunc::max {*}$::levH]
 .c configure -scrollregion [list 0 0 $::bx $::by]
 .c coords gfx0 0 0
 .c coords gfx1 0 0
 source "$path/level.tcl"
 if {$::DISABLE_GFX_LAYERS} {
  # some levels change the position of the graphics layer image objects, if gfx is disabled we must undo that
  .c coords gfx0 0 0
  .c coords gfx1 0 0
 }
 .c create rectangle [cx 0] [cy 0] [cx 640] [cy 480] -fill black -outline black -tag snacksucks
 playSong $::song
 .c delete snacksucks
 .c coords goal $::goalx $::goaly
 lassign [.c bbox goal] ::goalx1 ::goaly1 ::goalx2 ::goaly2
 .c raise gfx1
 foreach i {goal sonic spindash shield} {
  .c lower $i gfx1
 }
 if {$::DISABLE_GFX_LAYERS} {
  .c itemconfigure gfx1 -image {}
  .c itemconfigure gfx0 -image [lindex {gfx0 gfx1} $::sonicl]
 }
 .c moveto shield -600 -600
 .c moveto spindash -600 -600
 debugCanvasOrder
 centreViewSonic
 titleCard
 debugMsg "loadLevel end"
 error "LEVEL_LOADED"
}

proc demoPlaybackMode? {} {cmdArgumentsAreDefined -playdemo -replay}

proc saveReplay {} {
 if { [demoPlaybackMode?] } return
 catch {
  if { ! [file isdirectory replays/$::currentLevelIndex] } {
   file mkdir replays/$::currentLevelIndex
  }
  set path replays/$::currentLevelIndex/[clock seconds].txt
  set f [open $path w]
  puts $f $::gameRecording
  close $f
 }
}

# time trial records
proc loadRecords {} {
 set ::records [lrepeat 32 {}]
 catch {
  set f [open records.txt]
  set ::records [read $f]
  close $f
 }
 if { [llength $::records] != 32 } {
  set ::records [lrepeat 32 {}]
 }
}
proc saveRecords {} {
 catch {
  set f [open records.txt w]
  puts $f $::records
  close $f
 }
}
proc getCurrentBestRecord {} {
 loadRecords
 return [lindex $::records $::currentLevelIndex] 
}
proc saveRecord {} {
 set thisRecord [getCurrentBestRecord]
 set ::lastBestRecord $thisRecord
 if { $thisRecord eq {} || $thisRecord > $::framecounter } {
  lset ::records $::currentLevelIndex $::framecounter
  saveRecords
  return 1
 } else {
  return 0
 }
}
proc recordToString {record} {
 if {$record eq {}} {return "\[no record\]"}
 set l [list [expr {$record / 60 / 60}]  [expr {$record / 60 % 60}]  [expr { int($record % 60 / 60.0 * 100.0) }]]
 set l [lmap i $l {format %02d $i}]
 join $l :
}

set gameComplete 0
proc putText {x y msg {col white}} {
 .c create text [cx [expr {$x+1}]] [cy [expr {$y+1}]] -font {Sans 20} -text $msg -tag object -anchor w -fill black
 .c create text [cx $x] [cy $y] -font {Sans 20} -text $msg -tag object -anchor w -fill $col
}
proc sonicHasPassed {} {
 puts "framecounter: $::framecounter"
 puts "Time average:	[expr { [::tcl::mathop::+ {*}$::timeAverage] / $::framecounter / 1000.0 }]"
 puts "Slowest frame:	[expr { [::tcl::mathfunc::max {*}$::timeAverage] / 1000.0}]"
 puts "Fastest frame:	[expr { [::tcl::mathfunc::min {*}$::timeAverage] / 1000.0}]"
 puts "Lag frames:	[ 
  set lagFrames 0
  set t [expr {  $::frameTimeLength * 1000  }]
  foreach i $::timeAverage { if {$i >= $t} {incr lagFrames} }
  set lagFrames
 ] out of [llength $::timeAverage] ([expr { int( $lagFrames / double([llength $::timeAverage]) * 100.0 ) }]%)"
 puts ""
 if { $::recordGame } {
  lappend ::fullGameRecording $::gameRecording
  #puts "here.. $::gameRecording"
 }
 saveReplay
 lassign {-999 -999 -999 -999} ::goalx1 ::goaly1 ::goalx2 ::goaly2
 playSong levelclear
 putText 100 70 "Sonac has passed '$::levelTitle'" 
 putText 100 300 "Press JUMP to continue"
 set yy 77; set ystp 26;
 putText 120 [incr yy $ystp] "Current record:" yellow
 putText 120 [incr yy $ystp] "  [recordToString [getCurrentBestRecord]]" orange
 putText 120 [incr yy $ystp] "This record:" yellow
 putText 120 [incr yy $ystp] "  [recordToString $::framecounter]" orange
 foreach blah {1 2} {incr yy $ystp}
 # time trial record
 if { ! [demoPlaybackMode?] && [saveRecord] && $::lastBestRecord ne {}} {
  putText 120 [incr yy $ystp] "Wow!! It's a new record!!" pink
  playSound nice
 }
 # wait for input
 while { $::input & $::I_JUMP } { after 17; update }
 while { ! ($::input & $::I_JUMP) } { after 17; update }
 vignetteEffect
 incr ::currentLevelIndex
 if {[lindex $::gameLevels $::currentLevelIndex] eq {}} {
  set ::gameComplete 1
  pack forget .c
  pack [message .complete -text "game over"] -fill both -expand 1
  playSong ending
 } else {
  loadLevel [lindex $::gameLevels $::currentLevelIndex]
 }
}

proc int x {
 expr {int($x)}
}

#	o--------------------------------------------o
#	| Test for a collision in the level geometry |
#	o--------------------------------------------o

# This returns 1 if the pixel at x,y is a floor
proc colTest_floors {layer x y} {
 set got [levelGet $layer $x $y]
 return [expr {$got eq {f} || $got eq {p}}]
}

proc colTest_forFloorAngle {layer x y} {
 set got [levelGet $layer $x $y]
 return [expr {$got eq {f} || $got eq {p} || $got eq {g}}]
}

# This returns 1 if the pixel at x,y is a 'wall'
proc colTest_walls {layer x y} {
 set got [levelGet $layer $x $y]
 return [expr {$got eq {f} || $got eq {w}}]
}

# This returns 1 if either a floor or a wall
proc colTest_floorswalls {layer x y} {
 set got [levelGet $layer $x $y]
 return [expr {$got eq {f} || $got eq {p} || $got eq {w}}]
}

# This is hacked for the lost rings
proc colTest_lostRingCustom {layer x y} {
 set got [levelGet $layer $x $y]
 if {$got eq {p}} {
  upvar y1 y1 y2 y2
  return [expr {$y1<$y2}]
 }
 return [expr {$got eq {f} || $got eq {w}}]
}

# This returns 1 if either a brown floor or a pink wall, NOT green floors
proc colTest_brownFloorsAndPinkWalls {layer x y} {
 set got [levelGet $layer $x $y]
 return [expr {$got eq {f} || $got eq {w}}]
}

proc colTest_onlyBrownFloors {layer x y} {
 set got [levelGet $layer $x $y]
 return [expr {$got eq {f}}]
}

proc colTest_onlyGreenFloors {layer x y} {
 set got [levelGet $layer $x $y]
 return [expr {$got eq {p}}]
}


array set floorCollisionResultCodes [list {f} 1 {f} 1 {p} 2 {w} 4]

set FCS 3
proc _floorCollision {layer x1 y1 x2 y2 xReturn yReturn colTest} {
 #.c coords fadebug $x1 $y1 $x2 $y2
 if { [$colTest $layer $x1 $y1] } {return 0}
 upvar $xReturn rx $yReturn ry
 #if {$x2<0} {set x2 0}
 #if {$x2>$::bx} {set x2 $::bx}
 #if {$y2<0} {set y2 0}
 #if {$y2>$::by} {set y2 $::by}

 if { ! [$colTest $layer $x2 $y2] } {
  set xd [expr {$x2-$x1}]
  set yd [expr {$y2-$y1}]
  set d [expr { sqrt( $xd*$xd+$yd*$yd )}]
  if {$d<$::FCS} {return 0}
  set success 0
  for {set i $::FCS} {$i<$d-4} {incr i 4} {
   set xx [expr {$x1+$xd*(double($i)/$d)}]
   set yy [expr {$y1+$yd*(double($i)/$d)}]
   #.c raise fadebug; .c raise marker; .c coords marker $xx $yy; update; after 16

   if {[$colTest $layer $xx $yy]} {
    set x2 $xx
    set y2 $yy
    set success 1
    break
   }
  }
  if {!$success} {return 0}
 }

 while { abs($x1-$x2)+abs($y1-$y2)>1.0 } {
  set x [expr {double($x1+$x2)*0.5}]
  set y [expr {double($y1+$y2)*0.5}]
  if {[$colTest $layer $x $y]} {
   set x2 $x
   set y2 $y
  } else { 
   set x1 $x
   set y1 $y
  }
 }
 #.c create image $x1 $y1 -image marker -tag [list object FUCK]; if {[llength [.c find withtag FUCK]] > 10} {.c delete [lindex [.c find withtag FUCK] 0]}
 set rx [list $x1 $x2]
 set ry [list $y1 $y2]
 return 1
}
set fcrrxy {}; # colTest_floors
proc floorCollision {layer x1 y1 x2 y2 xReturn yReturn {index 0}} {
 upvar $xReturn rx $yReturn ry
 set result [_floorCollision $layer $x1 $y1 $x2 $y2 rrx rry colTest_floorswalls]
 if {$result} {

  # return 1 for brown floors, 2 for green floors
  set floorType $::floorCollisionResultCodes([levelGet $layer [expr {int([lindex $rrx 1])}] [expr {int([lindex $rry 1])}]])
  # -- put here: special check for absolute right angles, to prevent inappropriate attaching when doing floor collision, which must be disable-able via option parameter
  # ---
  # -- possibly also put here: special check for green floors, make them invisible from underneath
  if {$floorType==2 && $y2<$y1} {return 0}
  # ---
  set rx [lindex $rrx $index]
  set ry [lindex $rry $index]
  lassign $rrx ::fcrrx1 ::fcrrx2
  lassign $rry ::fcrry1 ::fcrry2
  set result $floorType
 }
 return $result
}

proc wallCollision {layer x1 y1 x2 y2 xReturn yReturn {index 0}} {
 upvar $xReturn rx $yReturn ry
 set result [_floorCollision $layer $x1 $y1 $x2 $y2 rx ry colTest_walls]
 if {$result} {
  set result $::floorCollisionResultCodes([levelGet $layer [expr {int([lindex $rx 1])}] [expr {int([lindex $ry 1])}]])
  set rx [lindex $rx $index]
  set ry [lindex $ry $index]
 }
 return $result
}

proc collision {colTest layer x1 y1 x2 y2 xReturn yReturn {index 0}} {
 upvar $xReturn rx $yReturn ry
 set result [_floorCollision $layer $x1 $y1 $x2 $y2 rx ry $colTest]
 if {$result} {
  set result $::floorCollisionResultCodes([levelGet $layer [expr {int([lindex $rx 1])}] [expr {int([lindex $ry 1])}]])
  set rx [lindex $rx $index]
  set ry [lindex $ry $index]
 }
 return $result
}

#	o-------------o
#	| Floor Angle |
#	o-------------o

set faDist 16
set PI 3.1415926535897931
set PI 3.141592653589793238462643383279502884197
set PI2 [expr 2.0*$PI]
set PID2 [expr $PI/2.0]
set PID4 [expr $PI/4.0]
set PID8 [expr $PI/8.0]
set faCount 6
set _floorAngle_failure_result [expr {$PID2+$PI2}]
#puts "failresult $_floorAngle_failure_result"


proc _floorAngle {layer x y} {
 #puts "floorAngle called at $layer, $x, $y"
 global PI PI2 PID2 faDist
 set a1 0
 set a2 0
 set last -1
 set result $::_floorAngle_failure_result
 set a 0
 #puts "start"
 set v 0.4
 for {set i 0} {$i<=$::faCount+1} {incr i} {
  set oa $a
  set a [expr {$PI2/$::faCount*$i}]
  set xx [expr {$x-cos($a)*$faDist}]
  set yy [expr {$y+sin($a)*$faDist}]

  set this [expr { [colTest_forFloorAngle $layer [expr {$x-cos($a)*$faDist}] [expr {$y+sin($a)*$faDist}]] || [colTest_forFloorAngle $layer [expr {$x-cos($a)*$faDist*$v}] [expr {$y+sin($a)*$faDist*$v}]]   }]
  if {$last>-1&&$this!=$last} {

   #narrow down
   set a1 $oa
   set a2 $a
   #set penismagic 0
   while {abs($a1-$a2)>0.044} {
    set _a [expr {($a1+$a2)*0.5}]
    if {$this==( [colTest_forFloorAngle $layer [expr {$x-cos($_a)*$faDist}] [expr {$y+sin($_a)*$faDist}]] || [colTest_forFloorAngle $layer [expr {$x-cos($_a)*$faDist*$v}] [expr {$y+sin($_a)*$faDist*$v}]] )} {
     set a2 $_a
    } else {
     set a1 $_a
    }
    #incr penismagic
   }
   #puts "penismagic $penismagic"

   lappend aa [expr {($a1+$a2)*0.5}]
   if {[llength $aa] == 2} {
    lassign $aa a1 a2
    if {$this} { 
     set a1 [expr {$a1+$PI2}]
    }
    set result [expr {($a1+$a2)*0.5}]
    return [expr {$result - $PI2*($result>=$PI2)}]
   }
  }
  set last $this

 } ;#endfor
 debugMsg "_floorAngle failure at layer $layer, $x,$y"
 return $result
} ;#endproc

array set angleoverrides "
 {128 128 128} $PI
 {^}   [expr $PI]
 {>}   [expr $PID2]
 {v} [expr 0]
 {<}   [expr $PID2*3]
"
set lastAngleResult $PI
proc floorAngle {layer x y} {
 #set x [expr {int($x)}]
 #set y [expr {int($y)}]
 # put here: look up this position in the 'angle override' image
 # and if found, return the looked up angle
 set lookup [levelGet $layer $x $y]
 # perhaps put here: if $lookup eq {128 128 128} then return some default value
 #if {$lookup eq {128 128 128}} {
 # debugMsg "floorAngle: warning: returning 'lastAngleResult'	$::lastAngleResult"
 # return $::lastAngleResult
 #}
 if {[info exists ::angleoverrides($lookup)]} { 
  return $::angleoverrides($lookup)
 }
 # else, continue to call _floorAngle
 return [_floorAngle $layer $x $y]
 #set ::lastAngleResult [_floorAngle $x $y]
 #return $::lastAngleResult
}

proc angleTest {x y} {
 #puts "help: [floorAngle 0 303.373674503527 181.94319493673237]"
 return

 if {[catch {
  .c raise angley
  .c raise angle
  .c raise anglel
  set x [.c canvasx $x]
  set y [.c canvasy $y]
  set a [floorAngle $::sonicl $x $y]
  .c itemconfigure angley -start [expr {$a / $::PI2 * 360 }]
  .c itemconfigure angle -start [expr {$a / $::PI2 * 360 - 90 }]
  .c moveto angley [expr {$x-$::angleTestIndicatorSize}] [expr {$y-$::angleTestIndicatorSize}]
  .c moveto angle [expr {$x-$::angleTestIndicatorSize}] [expr {$y-$::angleTestIndicatorSize}]
  .c coords anglel $x $y [expr {$x+$::angleTestIndicatorSize*sin($a)}] [expr {$y+$::angleTestIndicatorSize*cos($a)}]
 } eror]} {
  debugMsg "angleTest caught error: $eror"
 }
}

proc sonicFlyOff {} {
 if { abs($::sonicm)>5.44*$::speedo } {
  set m $::sonicm
  debugMsg "Detaching sonic because 'fly off'"
  detachSonicFromFloor
  if { [colTest_floorswalls $::sonicl $::sonicx $::sonicy] } {
   testbeep 1000 "sonicFlyOff: oh no, sonic is now inside the floor"
   return
  }
  set ox $::sonicx; set oy $::sonicy
  set newx [expr { $::sonicx + $m*0.5*sin($::sonica)}]
  set newy [expr { $::sonicy + $m*0.5*cos($::sonica)}]
  if {![colTest_floorswalls $::sonicl $newx $newy]} {
   set ::sonicx $newx
   set ::sonicy $newy
   updateCameraOffset $ox $oy
  }
 }
 #set ::sonicOnFloor 0
 #set m $::sonicm
 #set ::sonicm [expr {$m*sin($::sonica)}]
 #set ::sonicym [expr {$m*cos($::sonica)}]
}

#	o--------------------------------o
#	| Move on floor, floor traversal |
#	o--------------------------------o

set moveOnFloorStep 7
# return 1 if we hit an obstacle or a wall or something
set MOF_OBSTRUCTED 1
set MOF_FELLOFF 2
set moveOnFloor_distRemaining 0
set MOF_inLayerSwitcher 0
proc moveSonicOnFloor {dist} {
 #puts "dist $dist"
 if {$dist == 0} {return 0}
 global PID2
 upvar ::sonicx x ::sonicy y ::sonica a ::sonicl layer ::MOF_inLayerSwitcher inLayerSwitcher
 set step [expr { $::moveOnFloorStep * ($dist < 0 ? -1.0 : 1.0 ) }]
 while {$dist} {
  # get the size for this step and decrease total distance
  if {abs($dist)>abs($step)} {
   set dist [expr {double($dist)-$step}]
   set thisDist $step
  } else {
   set thisDist $dist
   set dist 0
  }
  # calculate the next point from this spot
  set ox $x
  set oy $y
  set x [expr {  $x + sin($a)*$thisDist  }]
  set y [expr {  $y + cos($a)*$thisDist  }]
  set xof [expr { sin($a-$PID2)*4.0 }]
  set yof [expr { cos($a-$PID2)*4.0 }]
  set x1 [expr { $x - $xof }]
  set y1 [expr { $y - $yof }]
  set x2 [expr { $x + $xof }]
  set y2 [expr { $y + $yof }]
  # put here:
  #  if neither point is in a floor, store the remaining distance to travel in 'moveOnFloor_distRemaining' and return MOF_FELLOFF
  set aIsIn [colTest_floors $layer $x1 $y1]
  set bIsIn [colTest_floors $layer $x2 $y2]
  if {!$aIsIn && !$bIsIn} {
   set ::moveOnFloor_distRemaining $dist
   return $::MOF_FELLOFF
  }
  set aIsIn [colTest_floorswalls $layer $x1 $y1]
  set bIsIn [colTest_floorswalls $layer $x2 $y2]
  #  if both points are in a floor (or a wall!), get the intersection between last xy and current xy and set x,y to that, and return MOF_OBSTRUCTED 
  if {$aIsIn && $bIsIn} {
   collision colTest_floorswalls $layer $ox $oy $x $y x y
   return $::MOF_OBSTRUCTED
  }
  # narrow down
  #set counter 0
  while { abs($x1-$x2)+abs($y1-$y2)>2.0 } {
   set x [expr {($x1+$x2)*0.5}]
   set y [expr {($y1+$y2)*0.5}]
   if {[colTest_floorswalls $layer $x $y]} {
    set x2 $x
    set y2 $y
   } else {
    set x1 $x
    set y1 $y
   }
   #incr counter
  }
  #puts "counter $counter"
  set x $x1
  set y $y1
  set a [floorAngle $layer $x $y]
  # if we entered a flyoff point, we must flyoff
  set colourAtCurrentPosition [levelGet $layer $x $y]
  if {$colourAtCurrentPosition eq {o}} {
   sonicFlyOff
   set ::sonicx [expr {$::sonicx+$dist*sin($a)}]
   set ::sonicy [expr {$::sonicy+$dist*cos($a)}]
   return
  }
  # if we entered a layer switcher, we must switch layers
  set wasInLayerSwitcher $inLayerSwitcher
  set inLayerSwitcher [expr {$colourAtCurrentPosition eq {s}}]
  #debugMsg wasIn $wasInLayerSwitcher in $inLayerSwitcher x $x y $y
  if { $inLayerSwitcher && !$wasInLayerSwitcher } {
   set layer [expr {! $layer }]
  }
 }
 #puts "s"
 return 0
}



#	o-------------------------------o
#	| Sonic variables and constants |
#	o-------------------------------o

proc initGameVariables {} {
uplevel "#0" {
expr { srand(-123456) }
set restarted 1
set gameRecording {}
set recordingPos 0
set playRecording [cmdArgumentsAreDefined -playdemo -replay]
set timeAverage {}
set sonicSpeed 0
set sonicx 500.0
set sonicy 500.0
# sonic bounding box
foreach i {::sbbx1 ::sbby1 ::sbbx2 ::sbby2 ::sbbcx ::sbbcy} {set $i 0}
set sonicl 0; # the layer which sonic is on right now
set sonicox $sonicx
set sonicoy $sonicy
#floorCollision 0 100 0 100 9999 sonicx sonicy
set sonica $PID2
set sonicm 0.0
set sonicym 0.0
set sonicOnFloor 0
set sonicOnObjectPlatform 0
set sonicWasOnObjectPlatform 0
set sonicState NORMAL
set sonicFacing 1; #0 left, 1 right
lassign {0 1 2 3 4 5 6 7 8} NORMAL ROLL SPIN HURT DUCK
set sonicStateNames {NORMAL ROLL SPIN HURT DUCK}
array set sonicHalfHeight "
 NORMAL 28.5
 ROLL 15.5
 SPIN 15.5
 HURT 15.5
 DUCK 15.5
"
set sonicInvinc 0
set sonicStar 0




set sonicJumpStartYM 9
set sonicJumpContinueM 1.20
set sonicJumpContinueDecline 0.875
set sonicLastJumpAngle 0.0
set sonicLastJumpXmul 0.0
set sonicLastJumpYmul 0.0
set sonic_jump_x 0
set sonic_jump_y 0
set sonicJumping 0

set sonicGravity 0.70

set sonicDashing 0

set sonicRollDrag 0.9964
set sonicWalkDrag 0.98
set sonicAirDrag 0.9882
set sonicSlopePush 0.32
set sonicDetachM 7.5

set sonicRunAccel 0.24
set sonicSkidAccel 0.32000000000000006
set sonicRollBrake 0.08000000000000002


set speedo [cmdArgument -speedo 0.78]

set sonicJumpStartYM [expr $speedo * 9]
set sonicJumpContinueM [expr $speedo * 1.20]
set sonicJumpContinueDecline [expr 1 - (1 - $speedo) * 0.875]
set sonicGravity [expr $speedo * 0.7 * (9.0 / 0.7)]

# Drag multipliers (scaled closer to 1)
set dragAdjust 1.044
set sonicRollDrag [expr 1 - (1 - 0.9964) * ($speedo * $dragAdjust) ]
set sonicWalkDrag [expr 1 - (1 - 0.98) * ($speedo * $dragAdjust) ]
set sonicAirDrag [expr 1 - (1 - 0.9882) * ($speedo * $dragAdjust) ]

set sonicSlopePush [expr $speedo * 0.32]
set sonicDetachM [expr $speedo * 7.5]

set sonicRunAccel [expr $speedo * 0.24]
set sonicSkidAccel [expr $speedo * 0.32000000000000006]
set sonicRollBrake [expr $speedo * 0.08000000000000002]

set sonicSpeedBoost [expr 4.0 * (1.0-((1.0-($speedo**1.6))**2)) ]
puts $sonicSpeedBoost
puts [expr 4.0 * $speedo]

# Original values
set original_sonicJumpStartYM 9.0
set original_sonicGravity 0.70

# Scale gravity
set sonicGravity [expr $speedo * $original_sonicGravity]

# Recalculate jump start velocity to maintain height
set sonicJumpStartYM [expr sqrt(($original_sonicJumpStartYM ** 2) / $original_sonicGravity * $sonicGravity)]



# Original values
set original_sonicJumpContinueM 1.20
set original_sonicJumpContinueDecline 0.875

# Adjust continued jump strength (scale by game speed)
set sonicJumpContinueM [expr $original_sonicJumpContinueM * $speedo]

# Adjust continued jump decay rate (closer to original)
set sonicJumpContinueDecline [expr 1 - (1 - $original_sonicJumpContinueDecline) * 0.9]

#set sonicJumpContinueM 0
#set sonicJumpContinueDecline 0



set framecounter 0
set framecount 0.0
set framecountx 0.0
set framecountstep 0.0
set spindashframecount 0

set sonicRings 0
set sonicHasShield 0

set levelTitle {}

set levelObjects {}
set scheduledCommands {}

set goalx1 0
set goaly1 0
set goalx2 0
set goaly2 0
set goalx 0
set goaly 0
set cxo 0
set cyo 0
}}
initGameVariables
#.c moveto sonic [expr {$::sonicx-3}] [expr {$::sonicy-3}]
#debugMsg $sonicx $sonicy $sonica

# Tue Jan 21: slowed the game down to roughly 80% the speed it ran at before, now momentum constants need to be converted and updated
# Procedure to adjust x momentum 
proc newxm {oldXMomentum} {
 return [expr {$oldXMomentum * $::speedo}]
}
# Procedure to adjust y momentum
proc newym {oldYMomentum} {
 return [expr {$oldYMomentum * sqrt($::sonicGravity / $::original_sonicGravity)}]
}


lassign {0 1 2 4 8 16 32 64} I_UP I_DOWN I_LEFT I_RIGHT I_JUMP I_START
set I_DIRECTIONAL [expr {$I_UP | $I_DOWN | $I_LEFT | $I_RIGHT}]
set I_LR [expr {$I_RIGHT | $I_LEFT}]
set oinput 0
set input 0

set SM_lastskid 0

#	o--------o
#	| Camera |
#	o--------o

set cxo 0
set cyo 0

proc updateCameraOffset {oldx oldy} {
 #debugMsg "updateCameraOffset:\n$oldx	$oldy\n$::sonicx	$::sonicy\n"
 #return
 set ::cxo [expr {$::cxo-($::sonicx-$oldx)}]
 set ::cyo [expr {$::cyo-($::sonicy-$oldy)}]
 if {abs($::cxo)>320} {set ::cxo [expr {$::cxo * 0.77}]}
 if {abs($::cyo)>240} {set ::cyo [expr {$::cyo * 0.77}]}
}
proc centreViewSonic {} {
 set ::cxo [expr {abs($::cxo)<1.0 ? 0.0 : $::cxo-sgn($::cxo)}]
 set ::cyo [expr {abs($::cyo)<1.0 ? 0.0 : $::cyo-sgn($::cyo)}]
 set xp [expr { ($::sonicx+$::cxo-320)/double($::bx) }]
 set yp [expr { ($::sonicy+$::cyo-240)/double($::by) }]
 .c xview moveto $xp
 .c yview moveto $yp
}


# ============================================================================================================================================================
# ============================================================================================================================================================

proc distance {x1 y1 x2 y2} {
 expr { sqrt( ($x1-$x2)**2 + ($y1-$y2)**2 ) }
}

#	o------------------------------------------------------o
#	| Sonic's movement, behaviour, and collision detection |
#	o------------------------------------------------------o

proc helpImStuck {} {
}

proc unhurtSonic {} {
 if {$::sonicState == {HURT}} {
  set ::sonicInvinc [expr {3*60}]
  set ::sonicState NORMAL
 }
 if {! $::sonicOnFloor && $::sonicState == {ROLL} } {
  set ::sonicState SPIN
 }
}

#	o-------------------------o
#	| Detach sonic from floor |
#	o-------------------------o

set sonicWasFacing 0
proc detachSonicFromFloor {} {
 if {$::DEBUG} {
  debugMsg "detachSonicFromFloor: x=$::sonicx y=$::sonicy l=$::sonicl a=$::sonica"
  .c coords marker2 $::sonicx $::sonicy
 }
 set xm  [expr {$::sonicm * sin($::sonica)}]
 set ::sonicym [expr {$::sonicm * cos($::sonica)}]
 set ::sonicm $xm
 set ::sonicOnFloor 0
 set ::sonicWasFacing $::sonicFacing
 # correct x,y position
 set halfHeight $::sonicHalfHeight($::sonicState)
 set oldx $::sonicx; set oldy $::sonicy;
 set PA [expr {$::sonica+$::PID2}]
 if { ! ($::sonica >= 1.07  &&  $::sonica <= 2.14  &&  abs($::sonicm) < 4.44) } {
  set ::sonicx [expr {$::sonicx+$halfHeight*sin($PA)}]
  set ::sonicy [expr {$::sonicy+$halfHeight*cos($PA)+$halfHeight}]
  # Thu Aug 01 2024 - fix for "sonic falls through the floor" bug -----
  while { [colTest_floorswalls $::sonicl $::sonicx $::sonicy] } {
   set ::sonicy [expr {$::sonicy - 1.0}]
  }
  # -------------------------------------------------------------------
  updateCameraOffset $oldx $oldy
 }
 set ::sonicox $::sonicx
 set ::sonicoy $::sonicy
 if {$::sonicState == {ROLL}} {
  set ::sonicState SPIN
 }
}

#	o-----------------------o
#	| Attach sonic to floor |
#	o-----------------------o

# function used for determining sonic's x momentum after landing, depending on the angle of the floor and the angle of his movement
proc specialfunction {a1 a2} {
 set a [expr {  fnwrap($a1)  }]
 set b [expr {  fnwrap($a2)  }]
 set c [expr { fnwrap($a - $b)-$::PI  }]

 # hardness!! I got it!
 #set hardness [expr { 1.0 - abs(abs( $c / $::PI ) - 0.5)*2.0 }]
  
 # more usefully, this should be the multiplier for sonic's total momentum, to convert it to the normal $::sonicm for movement on the floors
 #set multiplier [expr { abs(abs( $c / $::PI ) - 0.5)*2.0 }]
 # now we need: the sign to multiply with

 #try this!
 set this [expr { (( $c / $::PI ) - ($c<0 ? -0.5 : 0.5) )*-2.0 }]
 if { $c>0   } {
  return [expr {-$this}]
 }
 return $this
}


proc ::tcl::mathfunc::fnwrap {a} {set a [expr {fmod($a,$::PI2)}]
return [expr { $a<0.0 ? $::PI2+$a : $a }]
}
proc sonicMovementAngle {} {
 return [expr { atan2( -$::sonicym, $::sonicm ) - $::PID2 + $::PI }]
}
proc attachSonicToFloor {px py} {

    if {$::DEBUG} {.c coords marker $px $py}

    set oldx $::sonicx; set oldy $::sonicy;

    # if this is a 'green floor' and we landed 'inside' it, let's push up to the top so that sonic is comfortably placed, and the wall collision detection won't kill sonic's momentum
    if { [levelGet $::sonicl [expr {int($px)}] [expr {int($py)}]] eq {p} || [levelGet $::sonicl [expr {int($px)}] [expr {int($py-1)}]] eq {p} } {
     set ipx [expr {int($px)}]; set ipy [expr {int($py)}]; while {[levelGet $::sonicl $ipx $ipy] eq {p}} {incr ipy -1}; set py [expr {double($ipy)}]
     debugMsg "green floor y correction mechanism activated"
    }

    set ::sonicx $px
    set ::sonicy $py
 
    set ::sonica [floorAngle $::sonicl $::sonicx $::sonicy]
    if {$::sonica == $::_floorAngle_failure_result} {
     set ::sonicx $oldx
     set ::sonicy $oldy
     return
    }
    updateCameraOffset $oldx $oldy
    #debugMsg "attachSonicToFloor	$px	$py	$::sonica"

    set pa [expr { $::sonica-$::PID2 }]
    if {$::sonica<$::PI} {
     set ::sonicm [expr { ($::sonicym > 0.0) ? $::sonicm-$::sonicym*sin($pa) : $::sonicm }]
    } else {
     #debugMsg "hapening. $::sonicm $::sonicym"

     set movementAngle [sonicMovementAngle]
     
     set momentum [expr { sqrt( $::sonicm*$::sonicm + $::sonicym*$::sonicym ) }]
     set mult [expr { [specialfunction [expr {$::sonica}] $movementAngle] }]
     set ::sonicm [expr { $momentum * $mult }]
     debugMsg mmr	$momentum	$mult	$::sonicm

    }
     

    #set ::sonicm 0
    set ::sonicym 0
    set ::sonicOnFloor 1
    unhurtSonic
    set ::sonicState NORMAL
    if {$::sonicm && ($::input & $::I_DOWN)} {
     set ::sonicState ROLL
     playSound roll
    }
    set ::sonicWasOnObjectPlatform 0
    set ::sonicOnObjectPlatform 0
}

#	o-----------------------------------------------------------------o
#	| Sonic's movement, collision detection, control, sprite updating |
#	o-----------------------------------------------------------------o

proc sonicMovement {} {
 if {$::DEBUG_MESSAGES} {puts -nonewline stderr ";"}
 # stuck fixing
 if { [colTest_onlyBrownFloors $::sonicl $::sonicx $::sonicy] } {
  testbeep 2000 "oh no sonic is STUCK"
  #sonicStuckDetection
 }

 # invincibility timer 
 if {$::sonicInvinc} {
  incr ::sonicInvinc -1
 }
 set skid 0
 set oxm $::sonicm
 set olayer $::sonicl
 # keep track of whether or not sonic is on an object platform
 if {!$::sonicOnObjectPlatform && $::sonicWasOnObjectPlatform} {
  debugMsg "Sonic falls off object platform"
  set ::sonicOnFloor 0
 }
 set ::sonicWasOnObjectPlatform $::sonicOnObjectPlatform

 # Input response
 # left n right
 if {$::sonicState != {HURT} && $::sonicState != {DUCK}} {
  if { $::sonicState != {ROLL} } {
   if {$::input & $::I_LEFT} {
    set ::sonicm [expr {$::sonicm - $::sonicRunAccel*( $::sonicSpeed ? $::sonicSpeedBoost : 1.0) }]
    set ::sonicFacing 0
    if {$::sonicm > 0} {
     set ::sonicm [expr {$::sonicm - $::sonicSkidAccel*( $::sonicSpeed ? $::sonicSpeedBoost : 1.0) }]
     set skid 1
    }
   } elseif {$::input & $::I_RIGHT} {
    set ::sonicm [expr {$::sonicm + $::sonicRunAccel*( $::sonicSpeed ? $::sonicSpeedBoost : 1.0) }]
    set ::sonicFacing 1
    if {$::sonicm < 0} {
     set ::sonicm [expr {$::sonicm + $::sonicSkidAccel*( $::sonicSpeed ? $::sonicSpeedBoost : 1.0) }]
     set skid 1
    }
   }
  }
 }
 # jumping
 #  continuing an ongoing jump
 if {!$::sonicOnFloor && !($::input & $::I_JUMP)} {set ::sonicJumping 0}
 if {!$::sonicOnFloor && $::sonicJumping} {
  set ::sonicm  [expr {$::sonicm  + ($::sonicJumpContinueM * $::sonic_jump_x) }]
  set ::sonicym [expr {$::sonicym + ($::sonicJumpContinueM * $::sonic_jump_y) }]
  set ::sonic_jump_x [expr {$::sonic_jump_x*$::sonicJumpContinueDecline}]
  set ::sonic_jump_y [expr {$::sonic_jump_y*$::sonicJumpContinueDecline}]
 }
 #  starting a new jump
 #debugMsg "jump info" $::sonicOnFloor $::input $::oinput
 if {$::sonicOnFloor && $::sonicState!={DUCK} && ($::input & $::I_JUMP) && !($::oinput & $::I_JUMP)} {
  #debugMsg "starting jump"
  debugMsg "Sonic starts a jump"
  set ::sonicOnFloor 0
  set platformAngle [expr {$::sonica+$::PID2}]
  set ::sonicLastJumpXmul [expr {sin($platformAngle)}]
  #if {abs($::sonicLastJumpXmul)<0.0001} {set ::sonicLastJumpXmul 0}
  set ::sonicLastJumpYmul [expr {cos($platformAngle)}]
  set ::sonic_jump_x $::sonicLastJumpXmul
  set ::sonic_jump_y $::sonicLastJumpYmul
  # debugMsg xymul $::sonicLastJumpXmul $::sonicLastJumpYmul
  # apply jump momentum
  set xm [expr {$::sonicm * sin($::sonica) + $::sonicJumpStartYM * $::sonicLastJumpXmul }]
  set ym [expr {$::sonicm * cos($::sonica) + $::sonicJumpStartYM * $::sonicLastJumpYmul }]
  set ::sonicm $xm
  set ::sonicym $ym
  # correct x,y position
  set oldx $::sonicx; set oldy $::sonicy;
  set ::sonicx [expr {$::sonicx+17.0*$::sonicLastJumpXmul}]
  set ::sonicy [expr {$::sonicy+17.0*$::sonicLastJumpYmul+15.5}]
  updateCameraOffset $oldx $oldy
  set ::sonicox $::sonicx
  set ::sonicoy $::sonicy
  # some misc stuff
  if {$::sonicState!={ROLL}} {set ::sonicState SPIN}
  set ::sonicJumping 1
  playSound jump
 }
 # rolling
 if {$::sonicState=={NORMAL} && $::sonicOnFloor && abs($::sonicm)>1.0 && ($::input & $::I_DOWN)} {
  set ::sonicState ROLL
  playSound roll
 }
 if {$::sonicState=={ROLL}} {
  if {($::input & $::I_LEFT) && $::sonicm>0.0} {
   set ::sonicm [expr {$::sonicm - $::sonicRollBrake}]
  } elseif {($::input & $::I_RIGHT) && $::sonicm<0.0} {
   set ::sonicm [expr {$::sonicm + $::sonicRollBrake}]
  }
 }
 # ducking
 if {$::sonicOnFloor && abs($::sonicm)<0.001 && ($::input & $::I_DOWN) && ($::sonica>1.0102867940993896 && $::sonica<2.057905842) } {
  set ::sonicState DUCK
  # charge spindash
  if { (($::input ^ $::oinput) & $::input & $::I_JUMP) && $::sonicDashing<4 } {
   incr ::sonicDashing
   playSound spindash
  }
 } elseif { $::sonicState == {DUCK}} {
  set ::sonicState NORMAL
  # release spindash
  if {$::sonicDashing} {
   set ::sonicState ROLL
   set ::sonicm [expr { ($::sonicFacing ? 1.0 : -1.0) * (11.6+2*$::sonicDashing) }]
   set oxm $::sonicm
   set ::sonicDashing 0
   .c itemconfigure spindash -image {}
   playSound release
  }
 }

 # Momentum calculation
 if { $::sonicOnFloor && ($::sonica<=0.0 || $::sonica>=$::PI) && abs($::sonicm)<$::sonicDetachM } {
  debugMsg "Detaching sonic because he is on a very steep slope with low momentum ( angle $::sonica )"
  detachSonicFromFloor
 }
 if {$::sonicOnFloor} {
  # normal slope push
  if {$::sonica>=0.0 && $::sonica<=$::PI} {
   set ::sonicm [expr {$::sonicm + $::sonicSlopePush * cos($::sonica)}]
  }
  # drag calculations
  if {$::sonicState=={ROLL}} {
   set ::sonicm [expr {$::sonicm*$::sonicRollDrag }]
   if { $::sonica<1.6142472221867377 && $::sonica>1.52808727102979 && abs($::sonicm)<0.6 } {
    #debugMsg "set to zero1"
    set ::sonicm 0
    set ::sonicState DUCK
   } else {
    # extra slope push that only increases speed
    set xm [expr { $::sonicm + $::sonicSlopePush*cos($::sonica) }]
    if {abs($xm)>abs($::sonicm)} {set ::sonicm $xm}
   }
  } else {
   set ::sonicm [expr {$::sonicm*$::sonicWalkDrag}]
   if { $::sonica<1.6969878665682314 && $::sonica>1.4428442254604885 &&  !( $::input & $::I_LR ) && abs($::sonicm)<0.9 } {
    #debugMsg "set to zero2"
    set ::sonicm 0
   }
  }
 } else {
  set ::sonicm  [expr {$::sonicm*$::sonicAirDrag}]
  set ::sonicym [expr {$::sonicym+$::sonicGravity}]
 }
 # deactivate roll
 if {$::sonicOnFloor && $::sonicState=={ROLL} && sgn($oxm)!=sgn($::sonicm)} {
  set ::sonicState NORMAL
 }

 # Movement
 set ::sonicox $::sonicx
 set ::sonicoy $::sonicy
 # First, check for flyoff point
 if { $::sonicOnFloor && [levelGet $::sonicl $::sonicx $::sonicy] eq {o}  } {
  sonicFlyOff
 }
 # also first, check if sonic has become stuck in a green floor
 if {$::sonicOnFloor && [levelGet $::sonicl $::sonicx $::sonicy] eq {p}} {
  while {[levelGet $::sonicl $::sonicx $::sonicy] eq {p}} {
   set ::sonicy [expr {$::sonicy-1.0}]
  }
  set ::sonica [floorAngle $::sonicl $::sonicx $::sonicy]
  debugMsg "sonicMovement: stuck-in-green-floor fix activated"
 }
 if {$::sonicOnFloor} {
  # ----------------------------------------- movement: sonic on floor -------------------------------------------
  if {$::sonicOnObjectPlatform} {
   set ::sonicx [expr {$::sonicx + $::sonicm}]
  } else {
   set retval [moveSonicOnFloor $::sonicm]
   switch -- $retval { 
    1 { # obstructed
     #debugMsg "obstructed"
     set ::sonicm 0
     set ::sonicState NORMAL
    }
    2 { # fell off
     debugMsg "Detaching sonic because he 'fell off'"
     detachSonicFromFloor
     #tailcall sonicMovement
    }
   }
  }
  # wall detection
  if {$::sonicOnFloor} {
   set pa [expr {$::sonica+$::PID2}]
   set sonicTummyX [expr {$::sonicx+sin($pa)*15.5}]
   set sonicTummyY [expr {$::sonicy+cos($pa)*15.5}]
   set sonicSideX [expr {15.5*sin($::sonica)}]
   set sonicSideY [expr {15.5*cos($::sonica)}]
   set sonicRightSideX [expr {$sonicTummyX+$sonicSideX}]
   set sonicRightSideY [expr {$sonicTummyY+$sonicSideY}]
   set sonicLeftSideX [expr {$sonicTummyX-$sonicSideX}]
   set sonicLeftSideY [expr {$sonicTummyY-$sonicSideY}]
   set px 0; set py 0
   # && [colTest_walls $::sonicl $sonicRightSideX $sonicRightSideY]
   if { $::sonicm >= 0.0 && [wallCollision $::sonicl $sonicTummyX $sonicTummyY $sonicRightSideX $sonicRightSideY px py] } {
    debugMsg "on floor, wall detect right	$::sonica, $px, $py	$::sonicx $::sonicy"
    # wall detect right
    set ::sonicx [expr {$::sonicx+($px-$sonicRightSideX)}]
    set ::sonicy [expr {$::sonicy+($py-$sonicRightSideY)}]
    set ::sonicm 0
    set ::sonicState NORMAL
    # && [colTest_walls $::sonicl $sonicLeftSideX $sonicLeftSideY]
   } elseif { $::sonicm <= 0.0 && [wallCollision $::sonicl $sonicTummyX $sonicTummyY $sonicLeftSideX $sonicLeftSideY px py] } {
    debugMsg "on floor, wall detect left	$::sonica, $px, $py	$::sonicx $::sonicy"
    debugMsg "sonic was at $::sonicx, $::sonicy, angle $::sonica"
    # wall detect left
    set ::sonicx [expr {$::sonicx+($px-$sonicLeftSideX)}]
    set ::sonicy [expr {$::sonicy+($py-$sonicLeftSideY)}]
    set ::sonicm 0
    set ::sonicState NORMAL
   }
   set tries 4
   while {[sonicIsTouching colTest_brownFloorsAndPinkWalls] && [incr tries -1] } {
    debugMsg "floor wall detection stuck fix happening	$::sonicx, $::sonicy,	$::sonicox, $::sonicoy"
 
    if { [sonicLeftSideIsTouching colTest_brownFloorsAndPinkWalls] } {
     moveSonicOnFloor 6
    } elseif { [sonicRightSideIsTouching colTest_brownFloorsAndPinkWalls] } {
     moveSonicOnFloor -6
    }
    
   }
   #if {[sonicIsTouching colTest_brownFloorsAndPinkWalls]} {debugMsg "watch out: floor wall stuck fix failure"}
   #debugMsg pxpy $px $py
  }

 } else {
  # ----------------------------------------- movement: sonic in the air -------------------------------------------
  # Green floor fix, Sat Jul 27 2024
  if { $::sonicym > 0.0 && [colTest_onlyGreenFloors $::sonicl $::sonicx $::sonicy] } {
   attachSonicToFloor $::sonicx $::sonicy
   tailcall sonicMovement
  }
  # Move sonic
  set ::sonicx [expr {$::sonicx+$::sonicm}]
  set ::sonicy [expr {$::sonicy+$::sonicym}]
  # Check for layer switchers
  switch -- [levelGet $::sonicl $::sonicx $::sonicy] {
   0 {set ::sonicl 0}
   1 {set ::sonicl 1}
  }
  

  # Sonic's sides
  if {! $::sonicOnFloor } { # must check that sonic is still not on a floor before doing these collision checks
   foreach side {left right} testCondition {{$::sonicm<=0.0} {$::sonicm>=0.0}} wallAdjust {-15.5 15.5} \
    attachCondition {
    {(($ang>$::PID8 && $ang<$::PI-$::PID8) || ($ang>$::PI && !($ang>3.926990816987552 && $ang<5.501560710776383)))}
    {($ang>$::PID8 && $ang<$::PI-$::PID8) || ($ang>$::PI+$::PID8 && !($ang>3.926990816987552 && $ang<5.501560710776383))}
   } {
    if $testCondition {
     set collision [wallCollision $::sonicl [expr {$::sonicox}] [expr {$::sonicoy-15.5}] [expr {$::sonicx+$wallAdjust}] [expr {$::sonicy-15.5}] px py ]
     if {$collision} {
      set ang [floorAngle $::sonicl $px $py]
      if {$collision==1 && $ang<=$::PI2 && [expr $attachCondition]} {
       debugMsg "attachSonicToFloor: $side side at $px,$py	ang=$ang"
       attachSonicToFloor $px $py
       break
      } else {
       debugMsg "in-air wall collision (collision==$collision): $side side at $px,$py"
       # needs fixing: add stuck fix mechanism to stop sonic getting stuck in floors
       set ox $::sonicx
       set ::sonicx [expr {$px-$wallAdjust}]
       #updateCameraOffset $ox $::sonicy
       if {$ang<=$::PI || $collision == 4} {set ::sonicm 0.0}
       #if {[colTest $::sonicx $::sonicy]} helpImStuck
      }
     }
    }
   }
  }

  # Sonic's head
  if {! $::sonicOnFloor } { # must check that sonic is still not on a floor before doing these collision checks
   set sonicHeadOX $::sonicox
   set sonicHeadOY [expr {$::sonicoy-32.0}]
   set sonicHeadX $::sonicx
   set sonicHeadY [expr {$::sonicy-32.0}]
   set collision [wallCollision $::sonicl $sonicHeadOX $sonicHeadOY $sonicHeadX $sonicHeadY px py]
   if {$collision==1 || $collision==4} {
    debugMsg "sonics head c==1"
    if {$collision!=4} {set ang [floorAngle $::sonicl $px $py]}
    if {$collision==4 || $ang>$::PI} {
     if {$collision==4 || $ang>3.926990816987552 && $ang<5.501560710776383} {
      debugMsg "sonic bumps his head on the ceiling"
      set ox $::sonicx; set oy $::sonicy
      set ::sonicy [expr {$py+32.0}]
      if { [colTest_floorswalls $::sonicl $::sonicx $::sonicy] } {
       testbeep 500 "sonic head collision: had to set sonic's x position as well"
       set ::sonicx $px
      }
      updateCameraOffset $ox $oy
      set ::sonicym 0
      set ::sonic_jump_x 0
      set ::sonic_jump_y 0
     } elseif { $ang>=$::PI+$::PID8 &&  $ang<=$::PI2-$::PID8 } {
      debugMsg "attachSonicToFloor: sonic's head at $px,$py	ang=$ang"
      attachSonicToFloor $px $py
     }
    }
   }
  }

  # Sonic's feet
  if {! $::sonicOnFloor && $::sonicym>=0.0 } { # must check that sonic is still not on a floor before doing this collision check
   set collision [floorCollision $::sonicl $::sonicox $::sonicoy $::sonicx $::sonicy px py]
   # special check for green floors
   if {$collision && $collision!=4} {set ang [floorAngle $::sonicl $px $py]}
   if {$collision == 2 && $ang==$::PID2 && [levelGet $::sonicl $::sonicx $::sonicy] eq {p} && [levelGet $::sonicl $px [expr {$py+1}]] eq {>} } {
    set ::sonicy [int $::sonicy]; while {[levelGet $::sonicl $::sonicx $::sonicy] eq {p}} {incr ::sonicy -1}
    debugMsg "attachSonicToFloor: sonic's feet on a horizontal green platform"
    attachSonicToFloor $::sonicx $::sonicy
   } elseif {$collision && $collision!=4 && $ang>0.0 && $ang<$::PI } {
    # put here: check the angle and decide what to do and calculate momentum accordingly
    #set ::sonica [floorAngle $::sonicl $px $py]
    debugMsg "attachSonicToFloor: sonic's feet at $px,$py	ang=[floorAngle $::sonicl $px $py]"
    attachSonicToFloor $px $py
   } elseif {$collision==1 || $collision==4} {
    debugMsg "foot wall collision: watch out! this is probably not meant to happen! at $::sonicx, $::sonicy"
    set ::sonicm 0
    set ::sonicx $px
   }
  }

  # Sonic's nuts. This is a failsafe to prevent sonic from moving through solid walls
  if {! $::sonicOnFloor } {
   set oy [expr {$::sonicoy-16.0}]
   set y [expr {$::sonicy-16.0}]
   set collision [collision colTest_brownFloorsAndPinkWalls $::sonicl $::sonicox $oy $::sonicx $y px py]
   if {$collision} {
    debugMsg "wall collision: sonic's nuts."
    if { $collision == 1 && $::sonicym>0 && [colTest_onlyBrownFloors $::sonicl $px [expr {$py+1}]] } {
     # Mon, Dec 23, 2024 - fix for sonic's nuts getting stuck on things - Sonic's nuts could get him stuck in walls or in floors
     #tk_messageBox -title "test" -detail "nuts test"
     set oldx $::sonicx; set oldy $::sonicy
     set ::sonicx $px;   set ::sonicy $py
     updateCameraOffset $oldx $oldy
    } else {
     set ::sonicx $px
     set ::sonicy [expr {$py+16.0}]
     set ::sonicym 0.0
     while {[colTest_brownFloorsAndPinkWalls $::sonicl $::sonicx $::sonicy]} { 
      set ::sonicy [expr { $::sonicy - 1.0 }]
     }
    }
   }
  }

 }
  # ------------------------------------------------------------------------------------------------------------------


 #debugMsg $::sonicx $::sonicy $::sonica

 # Update sprite

 if { $::sonicState == {NORMAL} } {
  set a [expr {7-(int(($::sonica+$::PI2/16.0)/($::PI2/8.0))-3&7)}]
  set spr $a
  if {!$::sonicFacing} {
   set spr [expr {7-(($spr-1)&7)}]
  }
  set anchor [lindex {s sw w nw n ne e se} $a]
  if {$::sonicOnFloor} {
   set ::framecountstep [expr { max( abs($::sonicm), 1.0 ) }]
  }
  set ::framecountx [expr { ($::sonicm || !$::sonicOnFloor) ? fmod($::framecountx + abs($::framecountstep*0.04), 8.0) : 1.0 }]
  set ::framecount [expr { fmod( $::framecountx, 4.0 ) }]
  if {$skid && $::sonicOnFloor} {
   set sprite [lindex $::SsonicSkid $::sonicFacing $spr]
  } elseif {abs($::sonicm)<9*$::speedo} {
   set sprite [lindex $::SsonicWalking $::sonicFacing [expr {$spr*4+int($::framecount)}]]
  } elseif {abs($::sonicm)<23*$::speedo} {
   set sprite [lindex $::SsonicRunning $::sonicFacing [expr {$spr*4+int($::framecount)}]]
  } else {
   set sprite [lindex $::SsonicRunning2 $::sonicFacing [expr {$spr*8+int($::framecountx)}]]
  }
  if {$::sonicOnFloor} {
  .c itemconfigure sonic -image $sprite -anchor center
  .c coords sonic [expr {int($::sonicx+cos($::sonica)*27.0)}] [expr {int($::sonicy-sin($::sonica)*27.0)}]
  } else {
   if {$::sonica!=$::PID2} {
    set oa $::sonica
    set ::sonica [expr { ($::sonica + ($::sonicWasFacing ? -0.1 : 0.1))/$::PI2 }]
    set ::sonica [expr { ($::sonica <0.0 ? 1.0+$::sonica : $::sonica-int($::sonica))*$::PI2 }]
    if { abs($::sonica-$oa)<1.0 && ($::sonica>$::PID2 ^ $oa>$::PID2) } {
     set ::sonica $::PID2
    }
   }
   .c itemconfigure sonic -image $sprite -anchor center
   .c coords sonic [expr {int($::sonicx)}] [expr {int($::sonicy-28.5)}]
  }
 } elseif { $::sonicState == {SPIN} } {
  .c itemconfigure sonic -image $::SsonicBall -anchor s
  .c coords sonic [expr {int($::sonicx)}] [expr {int($::sonicy)}]
 } elseif { $::sonicState == {ROLL} } {
  if {$::sonicOnFloor} {
  .c itemconfigure sonic -image $::SsonicBall -anchor center
  .c coords sonic [expr {int($::sonicx+sin($::sonica+$::PID2)*15.5)}] [expr {int($::sonicy+cos($::sonica+$::PID2)*15.5)}]
  } else {
   .c itemconfigure sonic -image $::SsonicBall -anchor s
   .c coords sonic [expr {int($::sonicx)}] [expr {int($::sonicy)}]
  }
 } elseif { $::sonicState == {DUCK} } {
  if {$::sonicDashing} {
   set ::framecount [expr { int($::framecount+1)&3 }]
   .c itemconfigure sonic -image [lindex $::SsonicDash $::sonicFacing $::framecount] -anchor s
   set ::spindashframecount [expr { ($::spindashframecount + 1) % 5 }]
   .c itemconfigure spindash -image [lindex $::SdashDust $::sonicFacing $::spindashframecount] -anchor [lindex {sw se} $::sonicFacing]
   set x [expr {int($::sonicx)}]
   set y [expr {int($::sonicy)}]
   .c coords sonic $x $y
   .c coords spindash [expr {$::sonicx + ($::sonicFacing ? -10.0 : 10.0) }] $::sonicy
  } else {
   .c itemconfigure sonic -image [lindex $::SsonicDuck $::sonicFacing] -anchor s
   .c coords sonic [expr {int($::sonicx)}] [expr {int($::sonicy)}]
  }
 } elseif { $::sonicState == {HURT} } {
  .c itemconfigure sonic -image [lindex $::SsonicHurt $::sonicFacing] -anchor s
  .c coords sonic [expr {int($::sonicx)}] [expr {int($::sonicy)}]
 }
 # update sonic bounding box
 lassign [.c bbox sonic] ::sbbx1 ::sbby1 ::sbbx2 ::sbby2
 set ::sbbcx [expr {int(($::sbbx1+$::sbbx2)*0.5)}]
 set ::sbbcy [expr {int(($::sbby1+$::sbby2)*0.5)}]
 # display sonic's shield if he has it
 if {$::sonicHasShield} {
  .c coords shield $::sbbcx $::sbbcy
  .c itemconfigure shield -image [lindex $::Sshield [expr {$::framecounter&1}]]
 }
 # debug info displays
 if {$::DEBUG} {
  # angle debug display
  set aaa $::sonica
  .c coords anglerx [expr {$::sonicx-$::angleTestIndicatorSize}] [expr {$::sonicy-$::angleTestIndicatorSize}] [expr {$::sonicx+$::angleTestIndicatorSize}] [expr {$::sonicy+$::angleTestIndicatorSize}]
  .c coords anglelx $::sonicx $::sonicy [expr {$::sonicx+sin($aaa)*$::angleTestIndicatorSize}] [expr {$::sonicy+cos($aaa)*$::angleTestIndicatorSize}]
 }
 # debug level geometry display
 if {$::DISABLE_GFX_LAYERS && $olayer!=$::sonicl} {
  #.c itemconfigure gfx-1 -image [lindex {gfx1 gfx0} $::sonicl]
  .c itemconfigure gfx0 -image [lindex {gfx0 gfx1} $::sonicl]
 }
 # clear 'sonicOnObjectPlatform' every frame. one or more objects must continually set sonicOnObjectPlatform every frame to keep him from falling. once all the objects concerned stop considering sonic to be on their platform(s), he will fall
 set ::sonicOnObjectPlatform 0
 if {$::sonicy > $::by } { set ::sonicy $::by; killSonic }
 if {$::sonicInvinc && $::sonicState!={HURT} && ($::framecounter&1) } {
  .c coords sonic -640 -480 
 }
}
#  N
# W E
#  S

# ============================================================================================================================================================
# ============================================================================================================================================================

proc putSonicOnObjectPlatform {x y} {
 debugMsg "Put sonic on object platform at $x, $y"
 #set ox $::sonicx; set oy $::sonicy
 set ::sonicx $x; set ::sonicy $y
 #updateCameraOffset $ox $oy
 set ::sonicOnFloor 1
 set ::sonicOnObjectPlatform 1
 set ::sonica $::PID2
 set ::sonicym 0
}

# used for bouncing off monitors or baddies after jumping on them
proc sonicObjectReboundAction {} {
 if {$::sonicym<0} return
 if {$::input & $::I_JUMP} { 
  set ::sonicym [expr {-$::sonicym}]
 } else {
  set ::sonicym [newym -9.403781916995237]
 }
}

#	o---------o
#	| Objects |
#	o---------o

proc lineItems {x1 y1 x2 y2 n makeProc} {
 for {set i 0} {$i<$n} {incr i} {
  $makeProc [expr {$x1+($x2-$x1)*($i/double($n))}] [expr {$y1+($y2-$y1)*($i/double($n))}] 
 }
}

set levelObjects {}
# each object is a list containing these things: name, action proc, corresponding canvas item ({} if none), and then an extra value that can be whatever the object needs
# the action proc is a procedure that takes these arguments: canvas item, data
# objects can be destroyed by setting the object item in the list to {}

proc processObjects {} {
 set objectIndex -1
 set deleted 0
 foreach i $::levelObjects {
  if {$::restarted} {return}
  incr objectIndex
  if {$i eq {}} {set deleted 1; continue}
  set actionProc [lindex $i 1]
  if {$actionProc ne {}} {
   $actionProc [lindex $i 2] [lindex $i 3]
  }
 }
 if {$deleted} {set ::levelObjects [lmap i $::levelObjects {if {$i eq {}} continue; set i}]}
}

#	o-----------------o
#	| Hurtzone object |
#	o-----------------o

proc makeHurtzone {x1 y1 x2 y2 {mode FLOOR} } {
 set area [expr {abs($x1-$x2)*abs($y1-$y2)}]
 if {$area > 160*120} {
  debugMsg "this one: $x1 $y1 $x2 $y2"
 }
 set outline {}
 set fill {}
 if {$::DEBUG} {
  set outline white
  set fill red
 }
 set cItem [.c create rectangle $x1 $y1 $x2 $y2 -outline $outline -fill $fill -stipple @sprites/stipple -tag object]
 lappend ::levelObjects [list HURTZONE hurtzoneAction $cItem [list $x1 $y1 $x2 $y2 $mode]]
}

proc hurtzoneAction {cItem data} {
 if {!($::sonicx>[lindex $data 0] && $::sonicx<[lindex $data 2])} {return}
 lassign $data x1 y1 x2 y2 mode
 if {$::sonicy>$y1 && $::sonicy<$y2} {
  switch -- $mode {
   AIR { if {!$::sonicOnFloor} hurtSonic }
   FLOOR { if {$::sonicOnFloor} hurtSonic }
   BOTH {hurtSonic}
  }
 }
}

#	o--------------o
#	| Burst object |
#	o--------------o
# burst objects data: { x y counter1 counter2 }
proc makeBurst {x y} {
 set objData [list $x $y 1 0]
 set cItem [ .c create image $x $y -image [lindex $::Sburst 0] -tag [list obj_burst object]]
 lappend ::levelObjects [list BURST burstAction $cItem $objData]
}

proc burstAction { cItem data } {
 lassign $data x y counter1 counter2
 upvar objectIndex objectIndex
 incr counter1 -1
 if {$counter1 <= 0 } {
  incr counter2
  if {$counter2 > 5} {
   lset ::levelObjects $objectIndex {}
   .c delete $cItem
   return
  }
  set counter1 $counter2
  .c itemconfigure $cItem -image [lindex $::Sburst $counter2]
 }
 lset ::levelObjects $objectIndex 3 [list $x $y $counter1 $counter2]
}

#	o----------------o
#	| Monitor object |
#	o----------------o

proc schedule {timer command} {
 lappend ::scheduledCommands [list $timer $command]
}
proc processScheduledCommands {} {
 if { $::scheduledCommands eq {} } return
 set updatedScheduledCommands {}
 foreach item $::scheduledCommands {
  lassign $item timer command
  incr timer -1
  if { $timer <= 0 } { 
   uplevel "#0" $command
   continue
  }
  lappend updatedScheduledCommands [list $timer $command]
 }
 set ::scheduledCommands $updatedScheduledCommands
}


proc ringMon {} {
 debugMsg "ringMon"
}
proc shieldMon {} {
 debugMsg "shieldMon"
 set ::sonicHasShield 1
 playSound shield
}
proc speedMon {} {
 debugMsg "speedMon"
 set ::sonicSpeed [expr {60*22}]
 if { $::lastSong ne "speed" && $::lastSong ne "invinc" } {
  set ::holdLastSong $::lastSong
 }
 playSong speed
}
proc invincMon {} {
 debugMsg "invincMon"
 set ::sonicStar [expr {60*22}]
 if { $::lastSong ne "speed" && $::lastSong ne "invinc" } {
  set ::holdLastSong $::lastSong
 }
 playSong invinc
}

proc makeMonitor {x y {type {}}} {
 set objData [list $x $y]
 switch -- $type {
  ring {
   lappend objData ringMon $::SMonRing
  }
  shield {
   lappend objData shieldMon $::SMonShield
  }
  speed {
   lappend objData speedMon $::SMonSpeed
  }
  invinc {
   lappend objData invincMon $::SMonInvinc
  }
 }
 set cItem [.c create image $x $y -anchor s -tag [list obj_monitor object]]
 lappend ::levelObjects [list MONITOR monitorAction $cItem $objData]
}

proc popMonitor {objectIndex} {
 lassign [lindex $::levelObjects $objectIndex 3] x y popProc monitorImg 
 set cItem [lindex $::levelObjects $objectIndex 2]
 lset ::levelObjects $objectIndex {}
 .c itemconfigure $cItem -image brokenmonitor 
 .c addtag brokenmonitor withtag $cItem
 if {$popProc ne {}} {schedule 30 $popProc}
 makeBurst $x [expr {$y-15}]
 playSound pop
 return
}

proc sonicIsTouching { colTest } {
 if { ! $::sonicOnFloor } {
  set sonicTummyY [expr {$::sonicy - 16}]
  return [expr { [$colTest $::sonicl $::sonicx $::sonicy] || [$colTest $::sonicl [expr {$::sonicx-16}] $sonicTummyY] || [$colTest $::sonicl [expr {$::sonicx+16}] $sonicTummyY] }]
 } else {
  set pa [expr {$::sonica+$::PID2}]
  set sonicTummyX [expr {$::sonicx+sin($pa)*15.5}]
  set sonicTummyY [expr {$::sonicy+cos($pa)*15.5}]
  set sonicSideX [expr {15.5*sin($::sonica)}]
  set sonicSideY [expr {15.5*cos($::sonica)}]
  set sonicRightSideX [expr {$sonicTummyX+$sonicSideX}]
  set sonicRightSideY [expr {$sonicTummyY+$sonicSideY}]
  set sonicLeftSideX [expr {$sonicTummyX-$sonicSideX}]
  set sonicLeftSideY [expr {$sonicTummyY-$sonicSideY}]
  return [expr { [$colTest $::sonicl $::sonicx $::sonicy] || [$colTest $::sonicl $sonicLeftSideX $sonicLeftSideY] || [$colTest $::sonicl $sonicRightSideX $sonicRightSideY] }]
 }
}
proc sonicLeftSideIsTouching { colTest } {
 set pa [expr {$::sonica+$::PID2}]
 set sonicTummyX [expr {$::sonicx+sin($pa)*15.5}]
 set sonicTummyY [expr {$::sonicy+cos($pa)*15.5}]
 set sonicSideX [expr {15.5*sin($::sonica)}]
 set sonicSideY [expr {15.5*cos($::sonica)}]
 set sonicLeftSideX [expr {$sonicTummyX-$sonicSideX}]
 set sonicLeftSideY [expr {$sonicTummyY-$sonicSideY}]
 $colTest $::sonicl $sonicLeftSideX $sonicLeftSideY
}
proc sonicRightSideIsTouching { colTest } {
 set pa [expr {$::sonica+$::PID2}]
 set sonicTummyX [expr {$::sonicx+sin($pa)*15.5}]
 set sonicTummyY [expr {$::sonicy+cos($pa)*15.5}]
 set sonicSideX [expr {15.5*sin($::sonica)}]
 set sonicSideY [expr {15.5*cos($::sonica)}]
 set sonicRightSideX [expr {$sonicTummyX+$sonicSideX}]
 set sonicRightSideY [expr {$sonicTummyY+$sonicSideY}]
 $colTest $::sonicl $sonicRightSideX $sonicRightSideY
}

proc monitorAction { cItem data } {
 if {abs([lindex $data 0]-$::sonicx)>640.0 || abs([lindex $data 1]-$::sonicy)>500.0} return
 lassign $data x y popProc monitorImg 
 #update sprite
 if {$::framecounter & 2} {
  if {$::framecounter & 4 || $monitorImg eq {} } {
   .c itemconfigure $cItem -image [lindex $::SNoiseMonitors [expr {7&($::framecounter>>3)}]]
  } else {
   .c itemconfigure $cItem -image $monitorImg
  }
 }
 #collision detection
 if {abs($x-$::sonicx)>40.0 || abs($y-$::sonicy)>100.0} return
 if {$::sonicWasOnObjectPlatform &&      $::sonicx>$x-16 && $::sonicx<$x+16      && $::sonicy>=($y-30) && abs($::sonicy-($y-30))<4 } {
  set ::sonicOnObjectPlatform 1
  set ::sonicy [expr {$y-30}]
  return
 }
 if {$::sonicOnFloor } {
  # sonic on floor -------------------------------------------------------------------------
  set collision [expr { abs($::sonicy-$y)<8 && abs($::sonicx-$x)<32 }]
  if {!$collision} return
  #if {$::sonicWasOnObjectPlatform && abs($::sonicy-($y-30))<4 && $::sonicx>$x-16 && $::sonicx<$x+16} {
  # set ::sonicOnObjectPlatform 1
  # set ::sonicy [expr {$y-30}]
  # return
  #}
  if {$::sonicState == {ROLL}} {
   upvar objectIndex objectIndex
   popMonitor $objectIndex
   return
  } else {
   #if sonic has landed inside the monitor bounds, we will stand him on top of the monitor
   if { $::sonicox>$x-16 && $::sonicox<$x+16 } {
    putSonicOnObjectPlatform $::sonicx [expr {$y-30}]
   } elseif {!$::sonicWasOnObjectPlatform && $::sonicx>$x-32 && $::sonicx<$x+32 } {
    # if sonic is running into the monitor, we'll push him out of it and kill his momentum
    set xx [expr { $::sonicox<$x ? $x-32 : $x+32 }]
    set ::sonicm 0 
    set px $xx
    set py $y
    set sonicOnFloor [expr { !! [floorCollision $::sonicl $xx [expr {$y-8}] $xx [expr {$y+8}] px py] }]
    set ox $::sonicx; set oy $::sonicy
    set ::sonicx $px; set ::sonicy $py
    updateCameraOffset $ox $oy
   }

  }
 } else { 
  # sonic in the air -----------------------------------------------------------------------
  if {$::sonicState == {SPIN} || $::sonicState == {ROLL}} {
   set yy [expr {$y+15.0}]
   set sy [expr {$::sonicy+15.5}]
   if { sqrt( pow($x-$::sonicx,2)+pow($y-$::sonicy,2) ) < 32.0 } {
    upvar objectIndex objectIndex
    popMonitor $objectIndex
    sonicObjectReboundAction
    return
   }
  } elseif { $::sonicx>$x-16 && $::sonicx<$x+16 && $::sonicym>=0.0 && $::sonicy<=$y && $::sonicy>=$y-30 } {
   putSonicOnObjectPlatform $::sonicx [expr {$y-30}]
   # Tue Aug 06 - fix 
   while { [sonicIsTouching colTest_brownFloorsAndPinkWalls] && abs( $::sonicx - $x )>1 } {
    set ::sonicx [expr { $::sonicx + sgn( $x - $::sonicx ) }]
   }
  }
 }
}

#	o--------------o
#	| Ring objects |
#	o--------------o

proc makeSparkle {x y} {
 lappend ::levelObjects [list SPARKLE sparkleAction [.c create image $x $y -tag object] 0]
}
proc sparkleAction {cItem counter} {
 incr counter
 upvar objectIndex objectIndex
 if {$counter>35} {
  lset ::levelObjects $objectIndex {}
  .c delete $cItem
  return
 }
 lset ::levelObjects $objectIndex 3 $counter
 .c itemconfigure $cItem -image [lindex $::Ssparkle [expr {1&($counter>>3)}]]
}

proc makeRing {x y} {
 lappend ::levelObjects [list RING ringAction [.c create image $x $y -image ringImg -tag object] [list $x $y]]
}

proc ringAction {cItem data} {
 # check for collision
 if {abs($::sonicx-[lindex $data 0])>128.0} return
 lassign $data x y
 if {$::sonicState!={HURT} && $x>=$::sbbx1 && $x<=$::sbbx2 && $y>=$::sbby1 && $y<=$::sbby2} {
  incr ::sonicRings; playSound ring; .c delete $cItem; makeSparkle $x $y; upvar objectIndex objectIndex; lset ::levelObjects $objectIndex {}; return
 }
}

proc makeLostRing {x y xm ym l} {
 lappend ::levelObjects [list LOSTRING lostRingAction [.c create image $x $y -image ringImg -anchor s -tag object] [list $x $y $xm $ym $::sonicl 0]]
}

proc lostRingAction {cItem data} {
 upvar objectIndex objectIndex
 lassign $data ox oy xm ym l counter
 incr counter
 set x [expr {$ox+$xm}]
 set y [expr {$oy+$ym}]
 if {$y >= $::by+21} {.c delete $cItem; lset ::levelObjects $objectIndex {}; return}
 set ym [expr {$ym+0.25*$::speedo}]
 set collided [collision colTest_lostRingCustom $l $ox $oy $x $y x y]
 if { $collided } {
  set xx [expr {int($x+rand()*3-1)}]
  set yy [expr {int($y+rand()*3-1)}]
  set y1 $oy; set y2 $y
  if {![colTest_lostRingCustom $l $xx $yy]} {
   set x $xx
   set y $yy
  }
  set y2 $y
  if { [colTest_lostRingCustom $l [expr {$x-1}] $y] || [colTest_lostRingCustom $l [expr {$x+1}] $y] } {
   set xm [expr {-$xm}]
  }
  if { [colTest_lostRingCustom $l $x [expr {$y-1}]] || [colTest_lostRingCustom $l $x [expr {$y+1}]] } {
   set ym [expr {-$ym}]
  }
 }
 if {$y>=$::by+21 || ($counter>10*60 && rand()>0.99)} {
  .c delete $cItem; lset ::levelObjects $objectIndex {}
 } elseif {abs($::sonicx-$x)<=160.0 && $::sonicState!={HURT} && $x>=$::sbbx1 && $x<=$::sbbx2 && $y>=$::sbby1 && $y<=$::sbby2} {
  incr ::sonicRings; playSound ring; .c delete $cItem; makeSparkle $x $y; lset ::levelObjects $objectIndex {}
 } else {
  .c coords $cItem $x $y; lset ::levelObjects $objectIndex 3 [list $x $y $xm $ym $l $counter]
 }
}

#	o-------------------o
#	| BouncyBall object |
#	o-------------------o

# try to handle the scenario where some bouncy object (eg. bouncy ball or springs) have put sonic inside the floor/wall/etc
proc sonicStuckDetection {} {

 if { ! [colTest_floorswalls $::sonicl $::sonicx $::sonicy] } return

 set steps [expr {int([distance $::sonicox $::sonicoy $::sonicx $::sonicy])>>1}]
 
 for {set i 0} {$i < $steps} {incr i} {
  set m [expr { $i / double($steps) }]
  set x [expr { $::sonicox + ($::sonicx - $::sonicox) * $m }]
  set y [expr { $::sonicoy + ($::sonicy - $::sonicoy) * $m }]
  if { ! [colTest_floorswalls $::sonicl $x $y] } break
 }

 if {$steps > 0} {
  set ::sonicx $x
  set ::sonicy $y
 } else {set ::sonicx $::sonicox; set ::sonicy $::sonicoy}

}

proc makeBouncyBall {x y {movementFunction {}} {xRange 100} {yRange 100} {speed 0.05} {angleOffset 0.0} } {
 set objData [list $x $y $xRange $yRange $speed $angleOffset $movementFunction 0]
 lappend ::levelObjects [list BOUNCY bouncyBallAction [.c create image $x $y -tag [list obj_bouncy object] -image $::SbouncyBall] $objData]
}

proc bb_movement_circle {} {
 upvar x x y y xr xr yr yr speed speed angleOffset angleOffset
 set a [expr {$::framecounter * $speed * $::speedo + $angleOffset}]
 set x [expr {$x+sin($a)*$xr}]
 set y [expr {$y+cos($a)*$yr}]
}

proc bouncyBallAction {cItem data} {
 lassign $data x y xr yr speed angleOffset movementFunction collidedLastFrame
 if {$movementFunction ne {}} {
  $movementFunction 
  .c coords $cItem $x $y
 }
 if {abs($::sonicx - $x)>124 || abs($::sonicy - $y)>124} {return}
 #.c coords marker [expr {$x+56.0*sin($a)}] [expr {$y+56.0*cos($a)}]

 set d [expr {sqrt( pow( $::sbbcx-$x, 2 ) + pow( $::sbbcy-$y, 2 ) )}]
 #set a [expr { atan2( -(($::sonicoy-15.5)-$y), ($::sonicox-$x) )+$::PID2 }]

 if {$::sonicOnFloor && $d < 55.0} {
  if {$collidedLastFrame} return
  set condition [expr { (($::sbbcx < $x) ^ 0 ^ ($::sonica>$::PI)) }]
  set d [expr { 55 - $d }]
  moveSonicOnFloor [expr { $condition ? -$d : $d}]
  set ::sonicm [expr { ($condition ? -1.0 : 1.0) * ( abs($::sonicm)+8.0 ) }]
  unhurtSonic
  playSound ping
  set collidedLastFrame 1
 } elseif { ! $::sonicOnFloor && $d <= 55.0 } {
  if {$collidedLastFrame} return
  set d [expr { 55.0 - $d }]
  set sm [expr { sqrt($::sonicm*$::sonicm+$::sonicym*$::sonicym)+1.0 }]
  set a [expr { atan2( -(($::sonicoy-15.5)-$y), ($::sonicox-$x) )+$::PID2 }]
  set ::sonicx [expr {$x+sin($a)*56.0}]
  set ::sonicy [expr {$y+cos($a)*56.0}]
  set ::sonicm  [expr {$sm*sin($a)}]
  set ::sonicym [expr {$sm*cos($a)}]
  unhurtSonic
  playSound ping
  sonicStuckDetection
  set collidedLastFrame 1
 } else {
  set collidedLastFrame 0
 }
 upvar objectIndex objectIndex
 lset ::levelObjects $objectIndex end end $collidedLastFrame
}


#	o---------------o
#	| Spring object |
#	o---------------o

proc thisPointIsTouchingSonic {x y} {
 return [expr { $x>$::sbbx1 && $x<$::sbbx2 && $y>$::sbby1 && $y<$::sbby2 }]
}

proc makeSpring {x y {type up}} {
 set objData [list $x $y]
 switch -- $type {
  up {
   lappend objData springUp
   set sprite $::SUpSpring
   set cItem [.c create image $x $y -anchor s -tag object -image $sprite]
   lappend ::levelObjects [list SPRING springUpAction $cItem $objData]
  }
  left {
   lappend objData springULeft
   set sprite $::SULeftSpring
   set cItem [.c create image $x $y -anchor s -tag object -image $sprite]
   lappend ::levelObjects [list SPRING springULeftAction $cItem $objData]
  }
  right {
  lappend objectData springURight
   set sprite $::SURightSpring 
   set cItem [.c create image $x $y -anchor s -tag object -image $sprite]
   lappend ::levelObjects [list SPRING springURightAction $cItem $objData]
  }
  leftleft {
   lappend objData springLeft
   set sprite $::SLeftSpring
   set cItem [.c create image $x $y -anchor e -tag object -image $sprite]
   lappend ::levelObjects [list SPRING springLeftAction $cItem $objData]
  }
  rightright {
  lappend objectData springRight
   set sprite $::SRightSpring 
   set cItem [.c create image $x $y -anchor w -tag object -image $sprite]
   lappend ::levelObjects [list SPRING springRightAction $cItem $objData]
  }
  default {
   error "bad spring type"
  }
 }

}

proc springLeftAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0 || abs($::sonicy-[lindex $data 1])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicm [expr { -30*$::speedo * ($::sonica>$::PI ? -1.0 : 1.0) }]
  } else {
   unhurtSonic
   set ::sonicm [expr {-20.0*$::speedo}]
  }
  playSound spring
 }
}
proc springRightAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0 || abs($::sonicy-[lindex $data 1])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicm [expr { 30*$::speedo  * ($::sonica>$::PI ? -1.0 : 1.0) }]
  } else {
   unhurtSonic
   set ::sonicm [expr {20.0*$::speedo}]
  }
  playSound spring

 }
}
	
proc springUpAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0 || abs($::sonicy-[lindex $data 1])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicOnFloor 0
  } else {
   unhurtSonic
  }
  set ::sonicym [newym -25.0]
   playSound spring
 }
}
proc springULeftAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0 || abs($::sonicy-[lindex $data 1])>128.0} return
 lassign $data x y; if {$::sonicox == $x} return
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicOnFloor 0
  } else {
   unhurtSonic
  }
  set ::sonicx $x
  set ::sonicy $y
  set ::sonicym [newym -20.0]
  set ::sonicm [newxm -21.0]
  playSound spring

 }
}
proc springURightAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0 || abs($::sonicy-[lindex $data 1])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicOnFloor 0
  } else {
   unhurtSonic
  }
  set ::sonicx $x
  set ::sonicy $y
  set ::sonicym [newym -20.0]
  set ::sonicm [newxm 21.0]
  playSound spring
 }
}

#	o-------o
#	| Water |
#	o-------o

source "water.tcl"

# ============================================================================================================================================================
# ============================================================================================================================================================

#	o--------------------------------------o
#	| Sonic's pain and hurt, his suffering |
#	o--------------------------------------o

proc hurtSonic {} {
 if { $::sonicInvinc || $::sonicStar || $::sonicDead } {
  #debugMsg "hurt sonic: invinc $::sonicInvinc"
  return
 }
 .c moveto spindash -600 -600
 if { !$::sonicRings && !$::sonicHasShield } {
  killSonic
  return
 }
 # set sonic's state
 set ::sonicState HURT
 set ::sonicInvinc [expr {4*60}]
 set ::sonicOnFloor 0 
 set ::sonicym [newym -12.457]
 set ::sonicm [expr {($::sonicFacing ? -7.692307692 : 7.692307692 )*$::speedo}]
 if {$::sonicHasShield} {
  .c coords shield -640 -480
  set ::sonicHasShield 0
  playSound hit
  return
 }
 # make the lost rings
 set n [expr {min(32,$::sonicRings)}]
 # for testing, set n to some stupid number
 #set n 16
 set y [expr {$::sonicy-16.0}]
 set randomOffset [expr { rand()*6.283 }]
 for {set i 0} {$i<$n} {incr i} {
  set a [expr {double($i)/double($n)*$::PI2 + $randomOffset}]
  makeLostRing $::sonicx $y [expr {sin($a)*8.0*$::speedo}] [expr {cos($a)*8.0*$::speedo}] $::sonicl
 }
 playSound rings
 # remove rings from sonic
 set ::sonicRings 0
}

.c create oval -640 -480 -640 -480 -outline black -fill {} -width 0 -tag vignette
set ::sonicDead 0
proc killSonic {} {
 set ::sonicDead 1
 .c itemconfigure sonic -image $::SsonicHurtL -anchor center
 .c coords sonic $::sonicx $::sonicy
 playSound hit
 .c moveto shield -600 -600;  .c moveto spindash -600 -600
 set v -15
 if { $::recordingPos >= $::watchPos } {
  if {$::sonicy > $::by} {set ::sonicy $::by}
  while { [lindex [.c coords sonic] 1] <  [cy 510] } {
   set v [expr {$v+1.0}]
   .c move sonic 0 $v
   update
   after $::WTIME
  }
  if { ! $::recordGame } vignetteEffect
 }
 set ::sonicDead 0
 saveReplay
 loadLevel $::currentLevelPath
}

proc vignetteEffect {} {
 .c raise vignette
 set radius [expr { 0.5 * sqrt( 640*640+480*480 ) }]
 set x1 [expr {[.c canvasx 0] + (320 - $radius) }]
 set y1 [expr {[.c canvasy 0] + (240 - $radius) }]
 set x2 [expr {$x1+$radius*2}]
 set y2 [expr {$y1+$radius*2}]
 .c itemconfigure vignette -width 0.0
 .c coords vignette $x1 $y1 $x2 $y2
 for {set i 0} {$i<=50} {incr i} {
  .c itemconfigure vignette -width [expr {$radius*2*($i/50.0)}]
  update
  after $::WTIME
 }
 .c itemconfigure vignette -width 0.0
 .c coords vignette -640 -480 -640 -480
}

source "enemies.tcl"

#	o--------------------o
#	| Input key bindings |
#	o--------------------o

if { [cmdArgument "-joy" 1] } {
 source "joy.tcl"
}

array set keyBinds "
 z	$I_LEFT
 x	$I_RIGHT
 s	$I_DOWN
 space	$I_JUMP
 Left	$I_LEFT
 Right	$I_RIGHT
 Down	$I_DOWN
"

bind . <KeyPress> {
 if {[info exists keyBinds(%K)]} {
 #puts %K
  set input [expr { $input | $keyBinds(%K) }]
 }
}
bind . <KeyRelease> {
 if {[info exists keyBinds(%K)]} {
  set input [expr { $input & ~$keyBinds(%K) }]
 }
}

bind . <Key-h> {
 schedule 0 {
  set ::sonicInvinc 0
  set ::sonicStar 0
  unhurtSonic
  hurtSonic
 }
}
bind . <Key-k> { schedule 0 killSonic }
bind . <Key-i> {
 invincMon; set ::sonicStar 99999999
}

.c create rectangle 0 0 1 1 -width 2 -tag jumpxy -outline purple

#	o--------------o
#	| Main program |
#	o--------------o

catch {destroy .notice}

if {!$DEBUG} {
 wm withdraw .debug
 pack forget .f
}

if { [cmdArgumentIsDefined -edit] } {
 loadLevel [lindex $gameLevels $::currentLevelIndex]
 .c delete object
 source "objecteditor.tcl"
 return
}

if 0 {
 set fileout [open fileout.txt w]
 bind . <Key-r> {
  puts $fileout "$::sonicx $::sonicy"
 }
 label .destroynotifier
 bind .destroynotifier <Destroy> {
  close $fileout
 }
}
label .snackreallyreallyreallyreallysucks
bind .snackreallyreallyreallyreallysucks <Destroy> {
 if {$::recordGame} {
  set f [open $demoFile w]
  puts $f $::fullGameRecording
  close $f
 }
 exit
}

if {[cmdArgumentIsDefined -screencapturemode]} {
 while { ! ($::input & $::I_JUMP) } { after 7; update }
}
source titlescreen.tcl
titleScreen

#gets stdin
#loadLevel levels/greenhill
#loadLevel amelia_level
#loadLevel robynlevel
#loadLevel finale


if {$::DEBUG} {
 bind .c <ButtonPress-1> {
  set ::sonicOnFloor 0
  set ::sonicm 0
  set ::sonicym 0
  set ::sonicx [.c canvasx %x]
  set ::sonicy [.c canvasy %y]
  set ::sonicState NORMAL
 }
 bind . <Key-u> {
  detachSonicFromFloor
  set ::sonicym -30.0
 }
 bind . <Key-p> {
  set ::sonicm [expr { $::sonicFacing ? 30.0 : -30.0 }]
 }
}

if 0 {
foreach {i j} { 
sonicox	3157.401965359388
sonicoy	1357.776249574417
sonicx	3157.401965359388
sonicy	1357.776249574417
sonica	1.6907877128695066
sonicl	1
sonicm	0
sonicym	0
sonicState	0
sonicOnFloor	1
sonicFacing 1

} {
 set $i $j
}
}


update
wm geometry . [winfo reqwidth .]x[winfo reqheight .]

proc gameMainLoop {} {
 if {$::restarted} {loadLevel [lindex $::gameLevels $::currentLevelIndex]}
 uplevel "#0" {
  set sonicStarType 0
  set ringframe 0
  set input 0

  while 1 {

   
   set cms [clock microseconds]; incr cms $frameMs
   set timeTaken [lindex [time {
    set framecounter [expr {($framecounter + 1)&0xffffff}]
    if {($framecounter&0b11)==0} {
     set ringframe [expr {($ringframe+1)%6}]
     ringImg copy [lindex $Sring $ringframe] -compositingrule set
    }
    sonicMovement
    centreViewSonic
    .c coords rings [expr { [.c canvasx 0]+10 }] [expr { [.c canvasy 0]+10 }]
    .c itemconfigure rings -text "Rings: $::sonicRings"
    processObjects
    processScheduledCommands
    if {$::sonicx >= $::goalx1  &&  $::sonicy >= $::goaly1  &&  $::sonicx <= $::goalx2  &&  $::sonicy <= $::goaly2} sonicHasPassed
    if {$::restarted} {set ::restarted 0; return}

    if {$::gameComplete} return
    if {$::sonicStar} {
     if { ! ($::framecounter % 4) } {
      set bbox [.c bbox sonic]
      lassign $bbox sxx1 syy1 sxx2 syy2

      set sww [expr {$sxx2-$sxx1}]; set shh [expr {$syy2-$syy1}]

      set sonicStarType [expr {!$sonicStarType}]
      [lindex {makeSparkle makeBurst} $sonicStarType]  [expr {$sxx1+rand()*$sww}] [expr {$syy1+rand()*$shh}]
     }
     incr ::sonicStar -1
     if {!$::sonicStar} {
      playSong $::holdLastSong
     }
    }
    if {$::sonicSpeed} {
     incr ::sonicSpeed -1
     if {!$::sonicSpeed} {
      playSong $::holdLastSong
     }
    }

    set oinput $input
    .f.l3 conf -text "$sonicOnFloor $sonicState"
    #if {rand()>0.96} {set input [expr { $input ^ int( rand()*256) }]}
    if { ! $::playRecording || $recordingPos >= $watchPos } {update
#puts "\n$::sonicx $::sonicy $::sonicm $::sonicym $::sonicState $::sonica"
#exit
}
    if {$::playRecording} {
     set input [lindex $::gameRecording $recordingPos]
     .f.l4 configure -text "frame: $recordingPos"
     incr recordingPos
     if {$input eq {}} {set ::playRecording 0; set input 0}
    } else {
     lappend ::gameRecording $input
    }
    #puts "$::framecounter	$input"
    

   }] 0];
   #set realtt [expr { [clock microseconds] - $cms }]
   #puts "$timeTaken	$realtt"
   #puts "timetaken [format %.2g [expr {$timeTaken/1000.0}]]"
   lappend ::timeAverage $timeTaken
 
   # controller debug
   if 0 {
    for {set i 0} {$i<16} {incr i} {
     puts -nonewline [expr {!!($oinput & (0b1000000000000000>>$i))}]
    }; puts ""
    for {set i 0} {$i<16} {incr i} {
     puts -nonewline [expr {!!($input & (0b1000000000000000>>$i))}]
    }; puts ""
   }

   #after 4


   if { $recordingPos >= $watchPos } {
    if {[string is integer -strict $wtime]} {
    after $wtime
    } else {
     after [expr { int((16666.66666666-$timeTaken)/$timeDivisor )-2 }]
    }
    if { [clock microseconds] >= $cms } {puts lag\ fc$framecounter\	[clock microseconds]\	$cms}
    while {[clock microseconds] < $cms} {}
   }

  }

 }
}



button .retryAfterBug -text "sorry, there was an error, click here to restart level" -command {
 playSound bugcheckstop
 pack forget .m
 pack forget .retryAfterBug
 pack .c -expand [cmdArgument -expand 1] -fill [cmdArgument -fill none]
 #loadLevel $::currentLevelPath
 set ::restarted 1
 set ::smashmyballs {}
}
message .m

while { ! $gameComplete } {

 if {[catch {
  gameMainLoop
 } errorInfo]} {
  if { ! [string first {LEVEL_LOADED} $errorInfo] } {
   set ::restarted 0
   continue
  }
  if {! $::gameComplete } {
   saveReplay
   puts $errorInfo
   set msgtext "The level needs to be restarted.\nI am truly sorry for this inconvenience.\n\n"
   foreach i {sonicox sonicoy sonicx sonicy sonica sonicl sonicm sonicym sonicState sonicOnFloor levelTitle} {
    puts "$i	[set $i]"
    append msgtext "$i	[set $i]\n"
   }
   set shorter [join [lrange [split $errorInfo \n] 0 5]]
   append msgtext "\n$shorter"
   playSound bugcheck
   pack .retryAfterBug -fill x
   pack forget .c
   .m configure -background darkblue -foreground white -text $msgtext
   pack .m -fill both -expand 1
   tkwait variable ::smashmyballs
  }
 }

}

