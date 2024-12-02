

set joyDev "/dev/input/js0"

set JOYPAD 1
if [catch {set js0 [open $joyDev {RDONLY BINARY}]}] {
 set JOYPAD 0
}


if $JOYPAD {

proc translateJoypadEvent {data} {
 binary scan $data {i s c c} joy_time joy_value joy_type joy_number
 set joy_time [expr {$joy_time & 0xffffffff}]
 set joy_type [expr {$joy_type & 0xff}]
 set joy_number [expr {$joy_number & 0xff}]
 switch $joy_type {
  1 {
   return [list [lindex {buttonRelease buttonPress} $joy_value] \
                $joy_number \
                $joy_time]
  }
  2 {
   return [list axisMoved \
                $joy_number \
                $joy_value \
                $joy_time]
  }
  129 {
   return "buttonInit $joy_number $joy_time"
  }
  130 {
   return "axisInit $joy_number $joy_time"
  }
  default {
   return "unknown $joy_time $joy_value $joy_type $joy_number"
  }
 }
}

set oldLastEventTime 0
set lastEventTime 0

array set joyBinds "
 a0m    $I_LEFT
 a0p    $I_RIGHT
 a1m    $I_UP
 a1p    $I_DOWN
 a6m	$I_LEFT
 a6p	$I_RIGHT
 a7p	$I_DOWN
 a7m	$I_UP
 b0	$I_JUMP
 b1	$I_JUMP
 b2	$I_JUMP
 b3	$I_JUMP
"

fileevent $js0 readable {
 set event [translateJoypadEvent [read $js0 8]]
 set eventType [lindex $event 0]
 set eventData [lrange $event 1 end]
 set oldLastEventTime $lastEventTime
 switch $eventType {
  buttonInit {
   lassign $eventData buttonNumber lastEventTime
   set oldLastEventTime $lastEventTime
   #pack [button .f.buttons.b$buttonNumber -text "Button $buttonNumber" -background black -disabledforeground white -state disabled]
  }
  axisInit {
   lassign $eventData axisNumber axisValue lastEventTime
   set oldLastEventTime $lastEventTime
   #pack [scale .f.axes.a$axisNumber -label "Axis $axisNumber" -orient h -from -32768 -to 32767 -resolution 1 -state disabled -length 150]
  }
  buttonPress {
   lassign $eventData buttonNumber lastEventTime
   #.f.buttons.b$buttonNumber configure -disabledforeground black -background white
   set code [string cat "b" $buttonNumber]
   if {[info exists joyBinds($code)]} {
    set ::input [expr {$::input | $joyBinds($code)}]
   }
  }
  buttonRelease {
   lassign $eventData buttonNumber lastEventTime
   #.f.buttons.b$buttonNumber configure -disabledforeground white -background black
   set code [string cat "b" $buttonNumber]
   if {[info exists joyBinds($code)]} {
    set ::input [expr {$::input & ~$joyBinds($code)}]
   }
  }
  axisMoved {
   lassign $eventData axisNumber axisValue lastEventTime
   #.f.axes.a$axisNumber configure -state normal
   #.f.axes.a$axisNumber set $axisValue
   #.f.axes.a$axisNumber configure -state disabled
   set code1 [string cat "a" $axisNumber "m"]
   set code2 [string cat "a" $axisNumber "c"]
   set code3 [string cat "a" $axisNumber "p"]
   #puts "fuck.... '$code1' '$code2' '$code3'"
   set thisCode [expr { $axisValue <= 0 ? ( $axisValue==0 ? $code2 : $code1 ) : $code3 }]
   foreach i [list $code1 $code2 $code3] {
    if { [info exists joyBinds($i)] } {
     #puts "here $i $joyBinds($i)"
     set ::input [expr {$::input & ~$joyBinds($i)}]
    }
   }

   if { [info exists joyBinds($thisCode)] } {
    #puts "yes $thisCode $joyBinds($thisCode)"
    set ::input [expr {$::input | $joyBinds($thisCode)}]
   }   

   #puts "thisCode $thisCode"

  }
 }
}

}