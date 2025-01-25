#Breakable Crystal 

proc makeSmashCrystal {x y} {
 set sprite $::SSmashCrystal
 set objData [list $x $y]
 set cItem [.c create image $x $y -anchor s -tag object -image $sprite]
 lappend ::levelObjects [list SCRYSTAL scrystalAction $cItem $objData]
}
proc scrystalAction { cItem data } {
 lassign $data x y
 if {abs($x-$::sonicx)>640.0} return
 #collision detection
 if {abs($x-$::sonicx)>50.0 || abs($y-$::sonicy)>100.0} return
 if {$::sonicOnFloor } {
  # sonic on floor -------------------------------------------------------------------------
  set collision [expr { abs($::sonicy-$y)<16 && abs($::sonicx-$x)<48 }]
  if {!$collision} return
  if {$::sonicWasOnObjectPlatform && $::sonicy==$y-30 && $::sonicx>$x-31 && $::sonicx<$x+31} {
   set ::sonicOnObjectPlatform 1
   return
  }
  if {$::sonicState == {ROLL}} {
   upvar objectIndex objectIndex
   #sCrystalSmash $objectIndex
   makeBurst $x $y
   set y 14000
   .c delete $cItem;
   upvar objectIndex objectIndex
   lset ::levelObjects $objectIndex {}
   return
  } else {
   #if sonic has landed inside the monitor bounds, we will stand him on top of the monitor
   if { $::sonicox>$x-36 && $::sonicox<$x+36 } {
    putSonicOnObjectPlatform $::sonicx [expr {$y-40}]
   } elseif {!$::sonicWasOnObjectPlatform && $::sonicx>$x-32 && $::sonicx<$x+32 } {
    # if sonic is running into the monitor, we'll push him out of it and kill his momentum
    set xx [expr { $::sonicox<$x ? $x-46 : $x+46 }]
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
   if { sqrt( pow($x-$::sonicx,2)+pow($y-$::sonicy,2) ) < 42.0 } {
    upvar objectIndex objectIndex
    #sCrystalSmash $cItem
    sonicObjectReboundAction
	makeBurst  $x $y
	set $y 14000
	.c delete $cItem; 
	upvar objectIndex objectIndex
	lset ::levelObjects $objectIndex {}
    return
   }
  } elseif { $::sonicx>$x-36 && $::sonicx<$x+36 && $::sonicym>=0.0 && $::sonicy<=$y && $::sonicy>=$y-40 } {
   putSonicOnObjectPlatform $::sonicx [expr {$y-40}]
  }
 }
}
#proc sCrystalSmash {cItem data} {
# .c delete $cItem;
#}
# Amy 
proc makeAmy {x y {type {}}} {
lappend objData [list $x $y]
set sprite $::SAmyStand
set cItem [.c create image $x $y -anchor s -tag obj_Amy -image $sprite]
lappend ::levelObjects [list AMY amyAction $cItem $objData]
}
proc amyAction {cItem data} {
}



# ---------- rose springs ....


proc rose_makeSpring {x y {type up}} {
 set objData [list $x $y]
 switch -- $type {
  up {
   lappend objData springUp
   set sprite $::SUpSpring
   set cItem [.c create image $x $y -anchor s -tag object -image $sprite]
   lappend ::levelObjects [list SPRING rose_springUpAction $cItem $objData]
  }
  sup {
   lappend objData springSUp
   set sprite $::SUpSpring
   set cItem [.c create image $x $y -anchor s -tag obj_spring -image $sprite]
   lappend ::levelObjects [list SPRING rose_springSUpAction $cItem $objData]
  } 
  left {
   lappend objData springULeft
   set sprite $::SULeftSpring
   set cItem [.c create image $x $y -anchor s -tag object -image $sprite]
   lappend ::levelObjects [list SPRING rose_springULeftAction $cItem $objData]
  }
  right {
  lappend objectData springURight
   set sprite $::SURightSpring 
   set cItem [.c create image $x $y -anchor s -tag object -image $sprite]
   lappend ::levelObjects [list SPRING rose_springURightAction $cItem $objData]
  }
  leftleft {
   lappend objData springLeft
   set sprite $::SLeftSpring
   set cItem [.c create image $x $y -anchor e -tag object -image $sprite]
   lappend ::levelObjects [list SPRING rose_springLeftAction $cItem $objData]
  }
  rightright {
  lappend objectData springRight
   set sprite $::SRightSpring 
   set cItem [.c create image $x $y -anchor w -tag object -image $sprite]
   lappend ::levelObjects [list SPRING rose_springRightAction $cItem $objData]
  }
  default {
   error "bad spring type"
  }
 }

}

proc rose_springLeftAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicm [expr { -30 * ($::sonica>$::PI ? -1.0 : 1.0) }]
  } else {
   set ::sonicm -20.0
  }
  playSound spring

 }
}
proc rose_springRightAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicm [expr { 40 * ($::sonica>$::PI ? -1.0 : 1.0) }]
  } else {
   set ::sonicm 20.0
  }
  playSound spring

 }
}
proc rose_springUpAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicOnFloor 0
  }
  set ::sonicym -25.0
   playSound spring
 }
}
proc rose_springSUpAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicOnFloor 0
  }
  set ::sonicym -45.0
   playSound spring
 }
}
proc rose_springULeftAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicOnFloor 0
  }
  set ::sonicym -20.0
  set ::sonicm -20.0
  playSound spring

 }
}
proc rose_springURightAction {cItem data} {
 if {abs($::sonicx-[lindex $data 0])>128.0} return
 lassign $data x y
 if { [thisPointIsTouchingSonic $x $y] } {
  if {$::sonicOnFloor} {
   set ::sonicOnFloor 0
  }
  set ::sonicym -20.0
  set ::sonicm 20.0
  playSound spring
 }
}