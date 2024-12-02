#puts "here"
#	o------------------o
#	| Load the sprites |
#	o------------------o


#	o-------o
#	| Sonic |
#	o-------o


set SsonicWalkingR [lmap i [lsort [glob sprites/sonic/?_?.png]] {image create photo -file $i}]

set SsonicWalkingL \
 [lmap i $SsonicWalkingR {
  set p [image create photo]
  $p copy $i -subsamp -1 1
  set p}]

set SsonicWalking [list $SsonicWalkingL $SsonicWalkingR]


set SsonicRunningR [lmap i [lsort [glob sprites/sonic/runfast?_?.png]] {image create photo -file $i}]
set SsonicRunningL \
 [lmap i $SsonicRunningR {
  set p [image create photo]
  $p copy $i -subsamp -1 1
  set p}]
set SsonicRunning [list $SsonicRunningL $SsonicRunningR]

set SsonicRunning2R [lmap i [lsort [glob sprites/sonic/runfaster_??.png]] {image create photo -file $i}]
set SsonicRunning2L \
 [lmap i $SsonicRunning2R {
  set p [image create photo]
  $p copy $i -subsamp -1 1
  set p}]
set SsonicRunning2 [list $SsonicRunning2L $SsonicRunning2R]


proc createFlippedImg {img} {
 set p [image create photo]
 $p copy $img -subsample -1 1
 return $p
}
set SsonicHurtR [image create photo -file sprites/sonic/hurt.png]
set SsonicHurtL [createFlippedImg $SsonicHurtR]
set SsonicHurt [list $SsonicHurtL $SsonicHurtR]
set SsonicBall  [image create photo -file sprites/sonic/spinball.png]

set SsonicSkidR [lmap i [lsort [glob sprites/sonic/skid/one/skid?.png]] {image create photo -file $i}]
set SsonicSkidL \
 [lmap i $SsonicSkidR {
  set p [image create photo]
  $p copy $i -subsamp -1 1
  set p}]
set SsonicSkid [list $SsonicSkidL $SsonicSkidR]



set SsonicDuckR [image create photo -file sprites/sonic/duck.png]
set SsonicDuckL [createFlippedImg $SsonicDuckR]
set SsonicDuck [list $SsonicDuckL $SsonicDuckR]


set SsonicDashR [lmap i [lsort [glob sprites/sonic/dash?.png]] {image create photo -file $i}]
set SsonicDashL \
 [lmap i $SsonicDashR {
  set p [image create photo]
  $p copy $i -subsamp -1 1
  set p}]
set SsonicDash [list $SsonicDashL $SsonicDashR]


set SdashDustR [lmap i [lsort [glob sprites/spindashdust/dust?.png]] {image create photo -file $i}]
set SdashDustL \
 [lmap i $SdashDustR {
  set p [image create photo]
  $p copy $i -subsamp -1 1
  set p}]
set SdashDust [list $SdashDustL $SdashDustR]


set Sshield [lmap i [lsort [glob sprites/shield/?.png]] {image create photo -file $i}]
#Fooken Amy
set SAmyStand [image create photo -file sprites/amy/stand.png]
#	o----------o
#	| Monitors |
#	o----------o

# blank monitors which just display noise
image create photo monitors -file sprites/monitor/noise.png
set w [expr [image width monitors]/8]
for {set i 0} {$i<8} {incr i} {
 set m [image create photo]
 $m copy monitors -to 0 0 $w [image height monitors] -from [expr {$w*$i}] 0 [expr {$w*$i+$w}] [image height monitors]
 lappend SNoiseMonitors $m
}
image delete monitors

image create photo brokenmonitor -file sprites/monitor/brokenmonitor.png

foreach i [list invincmonitor.png speedmonitor.png shieldmonitor.png ringmonitor.png] j {SMonInvinc SMonSpeed SMonShield SMonRing} {
 set $j [image create photo -file sprites/monitor/$i]
}

#	o-------o
#	| Burst |
#	o-------o

foreach i [lsort [glob sprites/pop/*.png]] {
 lappend Sburst [image create photo -file $i]
}

#	o-------o
#	| Rings |
#	o-------o

foreach i [lsort [glob sprites/ring/ring?.png]] {
 lappend Sring [image create photo -file $i]
}
lappend Sring [lindex $Sring 2] [lindex $Sring 1]

image create photo ringImg -width 21 -height 21
ringImg copy [lindex $Sring 0] -compositingrule set

set Ssparkle [list [image create photo -file sprites/ring/sparkle.png] [image create photo -file sprites/ring/sparkle2.png]]

#	o---------------o
#	| Spring object |
#	o---------------o
 
set SUpSpring [image create photo -file sprites/spring/springup.png]
set SULeftSpring [image create photo -file sprites/spring/springuleft.png]
set SURightSpring [image create photo -file sprites/spring/springuright.png]
set SRightSpring [image create photo -file sprites/spring/springright.png]
set SLeftSpring  [createFlippedImg $SRightSpring]

#	o------------o
#	| BouncyBall |
#	o------------o

set SbouncyBall [image create photo -file sprites/item/bouncy.png]


#	o-------o
#	| garbo |
#	o-------o

#	o------o
#	| Bird |
#	o------o

set SbirdL [list [image create photo -file sprites/baddie/bird.png] [image create photo -file sprites/baddie/bird2.png]]
set SbirdR [lmap i $SbirdL {createFlippedImg $i}]
set Sbird [list $SbirdL $SbirdR]

#	o--------o
#	| rocket |
#	o--------o

set SrocketL [image create photo -file sprites/baddie/rocket.png]
set SrocketR [createFlippedImg $SrocketL]
set Srocket [list $SrocketL $SrocketR]

#	o-------o
#	| snail |
#	o-------o

set SsnailL [image create photo -file sprites/baddie/snail.png]
set SsnailR [createFlippedImg $SsnailL]
set Ssnail [list $SsnailL $SsnailR]

set Sgoal [image create photo -file sprites/goal.png]

if 0 {
 toplevel .t
 set n 0
 foreach i $SsonicWalkingR {
  grid [label .t.l$n -image $i] -column [expr $n%4] -row [expr $n/4]
  incr n
 }
 toplevel .t2
 set n 0
 foreach i $SsonicWalkingL {
  grid [label .t2.l$n -image $i] -column [expr $n%4] -row [expr $n/4]
  incr n
 }
 toplevel .t3
 set n 0
 foreach i $SNoiseMonitors {
  pack [label .t3.l$n -image $i]
  incr n
 }
}
#puts "there"



# ------------------------




#	o-----------o
#	| frogstomp |
#	o-----------o

set SfrogL [list [image create photo -file sprites/baddie/frogstomp1.png] [image create photo -file sprites/baddie/frogstomp2.png]  [image create photo -file sprites/baddie/frogstomp3.png]  [image create photo -file sprites/baddie/frogstomp4.png]]
set SfrogR [lmap i $SfrogL {createFlippedImg $i}]
set Sfrog [list $SfrogL $SfrogR]

set Sgoal [image create photo -file sprites/goal.png]

if 0 {
 toplevel .t
 set n 0
 foreach i $SsonicWalkingR {
  grid [label .t.l$n -image $i] -column [expr $n%4] -row [expr $n/4]
  incr n
 }
 toplevel .t2
 set n 0
 foreach i $SsonicWalkingL {
  grid [label .t2.l$n -image $i] -column [expr $n%4] -row [expr $n/4]
  incr n
 }
 toplevel .t3
 set n 0
 foreach i $SNoiseMonitors {
  pack [label .t3.l$n -image $i]
  incr n
 }
}

#	o-------o
#	| Flybug |
#	o-------o

set SbugL [list [image create photo -file sprites/baddie/flybug.png] [image create photo -file sprites/baddie/flybug2.png]]
set SbugR [lmap i $SbugL {createFlippedImg $i}]
set Sbug [list $SbugL $SbugR]

#Fooken Amy
set SAmyStand [image create photo -file sprites/amy/stand.png]
set SSmashCrystal [image create photo -file sprites/item/smashcrystal.png]
set SSmashedCrystal [image create photo -file sprites/item/smashedcrystal.png]
