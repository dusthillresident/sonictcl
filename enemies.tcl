proc cItemBboxToXY {item rx ry} {
 lassign [.c bbox $item] x1 y1 x2 y2
 upvar $rx xx $ry yy
 set xx [expr {($x1+$x2)*0.5}]
 set yy [expr {($y1+$y2)*0.5}]
}

proc distanceBetweenTwoItems {item1 item2} {
 if {$item1 eq {sonic}} {upvar ::sbbcx sx ::sbbcy sy} else {cItemBboxToXY $item1 sx sy}
 cItemBboxToXY $item2 xx yy
 return [expr { sqrt( pow($sx-$xx,2)+pow($sy-$yy,2) ) }]
}

#	o--------o
#	| rocket |
#	o--------o

proc makeRocket {x y {m 4.0}} {
 makeBurst $x $y
 #cItemBboxToXY sonic sx sy
 upvar ::sbbcx sx ::sbbcy sy
 set a [expr { atan2( -($sy-$y), ($sx-$x) )+$::PID2 + ($::PI2/128*(rand()*2-1.0))  }]
 set xm [expr { $m*sin($a) }]
 set ym [expr { $m*cos($a) }]
 set objData [list $x $y $xm $ym]
 lappend ::levelObjects [list ROCKET rocketAction [.c create image $x $y -image [lindex $::Srocket [expr {$::sonicx>$x}]] -tag object] $objData]
 playSound shoot
}

proc rocketAction { cItem data } {
 lassign $data x y xm ym
 set x [expr {$x+$xm}]
 set y [expr {$y+$ym}]
 .c coords $cItem $x $y
 upvar objectIndex i; lset ::levelObjects $i 3 [list $x $y $xm $ym]
 if {$x<0 || $y<0 || $x>$::bx || $y>$::by || (abs($x-$::sbbx1)+abs($y-$::sbby1))>1066 } {
  lset ::levelObjects $i {}; .c delete $cItem; return
 }
 if {$x>=$::sbbx1 && $x<=$::sbbx2 && $y>=$::sbby1 && $y<=$::sbby2} {
  if {!$::sonicHasShield} {hurtSonic; if {$::restarted} return}
  lset ::levelObjects $i {}; .c delete $cItem
  playSound explode
  makeBurst $x $y
 }
}

#	o------o
#	| Bird |
#	o------o

image create photo blankImage -width 1 -height 1

proc makeBird {x y} {
 set objData [list $x $y [list [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}]]]
 set cItem [.c create image $x $y -image blankImage -tag object]
 lappend ::levelObjects [list BIRD birdAction $cItem $objData] 
}

proc birdAction {cItem data} {
 lassign [.c bbox $cItem] x y 
 if {abs($::sonicx-$x)>700 || abs($::sonicy-$y)>500} return
 lassign $data cx cy nutlist
 lassign $nutlist aaa bbb ccc ddd eee fff
 #puts "xy... $x $y	$cItem	[.c bbox $cItem]"
 set x [expr {$cx+sin( ($::framecounter+$aaa)*0.04006346 )*60
                 +sin( ($::framecounter+$bbb)*0.03005674 )*60
                 +sin( ($::framecounter+$ccc)*0.06067567 )*60}]
 set y [expr {$cy+sin( ($::framecounter+$ddd)*0.030056346 )*60
                 +sin( ($::framecounter+$eee)*0.050045674 )*60
                 +sin( ($::framecounter+$fff)*0.070067567 )*60}]
 .c coords $cItem $x $y
 .c itemconfigure $cItem -image [lindex $::Sbird [expr {$::sonicx>$x}] [expr {($::framecounter>>2)&1}]]
 #collision
 cItemBboxToXY sonic sx sy
 cItemBboxToXY $cItem xx yy
 set collision [expr { sqrt( pow($sx-$xx,2)+pow($sy-$yy,2) )<31.0 }]
 if {$collision} {
  if {$::sonicStar || $::sonicState == {SPIN} || $::sonicState == {ROLL}} {
   makeBurst $xx $yy
   upvar objectIndex i
   lset ::levelObjects $i {}
   .c delete $cItem
   sonicObjectReboundAction
   playSound pop
   return
  } else {
   hurtSonic; if {$::restarted} return
  }
 }
 if {rand()>0.99} {
  makeRocket $x $y
 }
}

#	o-------o
#	| snail |
#	o-------o


proc makeSnail {x y {layer 0} {facing 1}} {
 floorCollision $layer $x $y $x [expr {$y+50}] x y
 set cItem [.c create image $x $y -tag object -image [lindex $::Ssnail $facing] -anchor s]
 set objData [list $x $y $layer $facing FALLING 0]
 lappend ::levelObjects [list SNAIL snailAction $cItem $objData]
}

proc snailAction {cItem data} {
 if { abs($::sonicx-[lindex $data 0])>700 || abs($::sonicy-[lindex $data 1])>500 } return
 lassign $data x y layer facing state jumpym
 switch -- $state {

  FALLING {
   set jumpym [expr {$jumpym + 0.2}]
   set oy $y
   set y [expr {$y+$jumpym}]
   if {[floorCollision $layer $x $oy $x $y x y]} {
    set jumpym 0
    set state WALKING
   }
  }

  WALKING {

   set endangered [expr {  ( $::sonicState == {SPIN} && abs($::sonicx-$x)<240 && abs($::sonicy-$y)<240 ) }]
   if {$endangered && rand()>0.996} {makeRocket $x $y 4.44}
   
   if {1 & $::framecounter || $endangered  } {

    for {set n 0} {$n<=$endangered} {incr n} {
     set xof [expr { $facing ? 3 : -3 }]
     if { ![floorCollision $layer $x [expr {$y-6}] [expr {$x+$xof}] [expr {$y+9}] px py] || [colTest_floorswalls $layer [expr {$x+$xof}] [expr {$y-10}]] } {
      set facing [expr {!$facing}]
      set xof [expr { $facing ? 3 : -3 }]
     } else {
      set x $px
      set y $py
     }
    }

   }
   if {$::sonicOnFloor && $::sonicState=={ROLL} && abs($::sonicx-$x)<240 && abs($::sonicy-$y)<66 } {
    set state JUMPING
    set jumpym -15.0
   }

  }

  JUMPING {
   set oy $y
   set y [expr {$y+$jumpym}]
   set collision [floorCollision $layer $x $oy $x $y px py]
   if {$collision} {
    if {$jumpym<0.0} {
     set y $py
     set jumpym 0.0
    } else {
     set y $py
     set state WALKING
    }
   }
   if { ! (0b111 & $::framecounter) } {
    makeRocket $x $y 6.6
   }
   set jumpym [expr {$jumpym + 0.5}]
  }

 }
 .c coords $cItem $x $y
 .c itemconfigure $cItem -image [lindex $::Ssnail $facing]

 upvar objectIndex i; lset ::levelObjects $i 3 [list $x $y $layer $facing $state $jumpym] 
 
 if {[distanceBetweenTwoItems sonic $cItem] < 31} {
  if {$::sonicState == {SPIN} || $::sonicState == {ROLL} || $::sonicStar} {
   makeBurst $x $y
   .c delete $cItem
   lset ::levelObjects $i {}
   sonicObjectReboundAction
   playSound pop
   return
  } else {
   hurtSonic
   return
  }
 }

}




#	o-----------o
#	| frogstomp |
#	o-----------o

#    o-----------o
#    | frogstomp |
#    o-----------o
image create photo blankImage3 -width 1 -height 1

proc makeFrog {x y {layer 0} {facing 1}} {
 floorCollision $layer $x $y $x [expr {$y+100}] x y
 set cItem [.c create image $x $y -image blankImage3 -tag object -anchor s]
 set objData [list $x $y $layer $facing WALKING 0]
 lappend ::levelObjects [list frog frogAction $cItem $objData]
}

proc frogAction {cItem data} {
 if { abs($::sonicx-[lindex $data 0])>700 || abs($::sonicy-[lindex $data 1])>500 } return
 lassign $data x y layer facing state jumpym
 .c itemconfigure $cItem -image [lindex $::Sfrog $facing [expr { ($::framecounter >> 2 ) % 4 }]]
 switch -- $state {

  WALKING {

   set endangered [expr {  ( $::sonicState == {SPIN} && abs($::sonicx-$x)<240 && abs($::sonicy-$y)<240 ) }]
   if {$endangered && rand()>0.996} {makeRocket $x $y 4.44}
   
   if {1 & $::framecounter || $endangered  } {
    for {set n 0} {$n < 1+$endangered} {incr n} {
     set xof [expr { ($facing ? 1 : -1)*$::speedo }]
     if { [floorCollision $layer $x $y $x [expr {$y-10}] px py] } {
      set facing [expr {!$facing}]
      set xof [expr { $facing ? 1 : -1 }]
     }
     set xx [expr {$x + $xof * ($endangered ? 1.0 : 1.0)}]
     if { ! [floorCollision $layer $xx [expr {$y-16.0}] $xx [expr {$y+16.0}] px py] || abs($y-$py)>40  } {
      set facing [expr {! $facing}]
     } else {
      set x $px
      set y $py
     }
    }
   }
   if {$::sonicOnFloor && $::sonicState=={ROLL} && abs($::sonicx-$x)<240 && abs($::sonicy-$y)<66 } {
    set state JUMPING
    set jumpym -14.0
   }

  }

  JUMPING {
   set oy $y
   set y [expr {$y+$jumpym}]
   set collision [floorCollision $layer $x $oy $x $y px py]
   if {$collision} {
    if {$jumpym<0.0} {
     set y $py
     set jumpym 0.0
    } else {
     set y $py
     set state WALKING
    }
   }
   if { ! (0b111 & $::framecounter) } {
    makeRocket $x $y 6.6
   }
   set jumpym [expr {$jumpym + 0.4}]
  }

 }
 .c coords $cItem $x $y
 .c itemconfigure $cItem -image [lindex $::Sfrog $facing [expr { ($::framecounter >> 2 ) % 4 }]]

 upvar objectIndex i; lset ::levelObjects $i 3 [list $x $y $layer $facing $state $jumpym] 
 
 if {[distanceBetweenTwoItems sonic $cItem] < 31} {
  if {$::sonicState == {SPIN} || $::sonicState == {ROLL} || $::sonicStar} {
   makeBurst $x $y
   .c delete $cItem
   lset ::levelObjects $i {}
   sonicObjectReboundAction
   playSound pop
   return
  } else {
   hurtSonic
   return
  }
 }

}


#	o------o
#	|FlyBug|
#	o------o

image create photo blankImage2 -width 1 -height 1

proc makeBug {x y} {
 set objData [list $x $y [list [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}] [expr {int(rand()*1000*$::speedo)}]]]
 set cItem [.c create image $x $y -image blankImage2 -tag object]
 lappend ::levelObjects [list FLYBUG bugAction $cItem $objData] 
}

proc bugAction {cItem data} {
 lassign [.c bbox $cItem] x y 
 if {abs($::sonicx-$x)>700 || abs($::sonicy-$y)>500} return
 lassign $data cx cy nutlist
 lassign $nutlist aaa bbb ccc ddd eee fff
 #puts "xy... $x $y	$cItem	[.c bbox $cItem]"
 set x [expr {$cx+sin( ($::framecounter+$aaa)*0.04456346 )*70
                 +sin( ($::framecounter+$bbb)*0.03145674 )*70
                 +sin( ($::framecounter+$ccc)*0.06267567 )*70}]
 set y [expr {$cy+sin( ($::framecounter+$ddd)*0.031456346 )*20
                 +sin( ($::framecounter+$eee)*0.053145674 )*20
                 +sin( ($::framecounter+$fff)*0.076267567 )*20}]
 .c coords $cItem $x $y
 .c itemconfigure $cItem -image [lindex $::Sbug [expr {$::sonicx>$x}] [expr {($::framecounter>>2)&1}]]
 #collision
 cItemBboxToXY sonic sx sy
 cItemBboxToXY $cItem xx yy
 set collision [expr { sqrt( pow($sx-$xx,2)+pow($sy-$yy,2) )<31.0 }]
 if {$collision} {
  if {$::sonicStar || $::sonicState == {SPIN} || $::sonicState == {ROLL}} {
   makeBurst $xx $yy
   upvar objectIndex i
   lset ::levelObjects $i {}
   .c delete $cItem
   sonicObjectReboundAction
   playSound pop
   return
  } else {
   hurtSonic; if {$::restarted} return
  }
 }
 if {rand()>0.99} {
  makeRocket $x $y
 }
}