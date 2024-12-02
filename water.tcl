
set waterTargetLevel 400
set waterLevel 400
set airTimer 0

image create photo waterImage -file sprites/water.png

foreach i [lsort [glob sprites/splash/*.png]] {
 lappend Ssplash [image create photo -file $i]
}

proc makeSplash {x y} {
 set objData -1
 set cItem [.c create image $x $y -anchor s -image [lindex $::Ssplash 0] -tag object]
 lappend ::levelObjects [list SPLASH splashAction $cItem $objData] 
}

proc splashAction {cItem counter} {
 incr counter
 set img  [lindex $::Ssplash [expr { $counter >> 1}]]
 upvar objectIndex objectIndex
 if {$img eq {}} {
  .c delete $cItem
  lset ::levelObjects $objectIndex {}
  return
 }
 .c itemconfigure $cItem -image $img
 lset ::levelObjects $objectIndex 3 $counter
}

proc makeWater {level} {
 set ::waterTargetLevel $level
 set ::waterLevel $level
 set cItem [.c create image 0 0 -anchor nw -tag [list water object] -image waterImage]
 set objData {}
 lappend ::levelObjects [list WATER waterAction $cItem $objData]
}

proc waterAction {cItem data} {

 .c raise $cItem
 .c coords $cItem [cx -50] [expr { max( $::waterLevel, [cy -50] ) + sin( $::framecounter * 0.06) * 4 }]

 if {$::sonicy-16.0 > $::waterLevel} {

  if {$::sonicoy-16.0 < $::waterLevel} {
   set ::oldSonicXM 0
   set ::oldSonicYM 0
   set ::sonicm  [expr {$::sonicm * 0.8}]
   set ::sonicym [expr {$::sonicym * 0.8}]
   makeSplash [expr { ($::sonicox+$::sonicx)*0.5 }] $::waterLevel
   set airTimer 0
  }

  set ::oldSonicXM [expr { ($::sonicm *0.5 + $::oldSonicXM*0.5)*0.97 }]
  set ::oldSonicYM [expr { ($::sonicym*0.5 + $::oldSonicYM*0.5)*0.97 }]
  set ::sonicm  [expr {$::sonicm  * 0.5 + $::oldSonicXM * 0.5}]
  set ::sonicym [expr {$::sonicym * 0.5 + $::oldSonicYM * 0.5}]

  if { ! $::sonicOnFloor } { set ::sonicym [expr {$::sonicym - 0.30}] }

  incr airTimer
 } elseif {$::sonicoy-16.0 > $::waterLevel} {
  makeSplash [expr { ($::sonicox+$::sonicx)*0.5 }] $::waterLevel
 }
 
 if {$::waterLevel != $::waterTargetLevel} {
  set ::waterLevel [expr {$::waterLevel + sgn( $::waterTargetLevel - $::waterLevel )}]
 }

}

