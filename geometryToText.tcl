# Legend
#	f	Floor
#	p	Platform (green floor)
#	w	Wall
#	g	angle Guide (provides hints for the floor angle procedure)
#	s	Switcher (for loops etc)
#	0	Switch sonic to layer 0 when he's in the air
#	1	Switch sonic to layer 1 when he's in the air
#	o	flyOff when sonic is at a high enough speed
#	>       \	
#	v	 |  angle overrides
#	<	 |
#	^	/

array set geometryPixelLookup {
 {128 64 0}	f	{128 0 0}	f
 {0 128 0}	p
 {255 128 128}	w
 {0 128 128}	g
 {128 128 255}	s
 {128 255 128}	0
 {255 255 128}	1
 {255 128 0}	o
 {0 0 255}	>
 {255 0 255}	v
 {0 255 0}	^
 {255 0 0}	<
}

proc geomToText {img} {
 set w [image width $img]
 set h [image height $img]
 set out ""
 for {set y 0} {$y < $h} {incr y} {
  for {set x 0} {$x < $w} {incr x} {
   set pixel [$img get $x $y]
   if { [info exists ::geometryPixelLookup($pixel)] } {
    append out $::geometryPixelLookup($pixel)
   } else {
    append out .
   }
  }
 }
 return $out
}

proc buildGeometry {levelPath} {
 if { [file exists $levelPath/geometry.txt]
       &&
      [file mtime $levelPath/layer0.png] < [file mtime $levelPath/geometry.txt]
       &&
      [file mtime $levelPath/layer1.png] < [file mtime $levelPath/geometry.txt]
 } {
  return
 }
 global level levW levH
 set level {};  set levW {};  set levH {};
 for {set i 0} {$i<2} {incr i} {
  set img [image create photo -file $levelPath/layer$i.png]
  lappend level [geomToText $img]
  lappend levW [image width $img]
  lappend levH [image height $img]
  image delete $img
 }
 set f [open $levelPath/geometry.txt w]
 puts $f "set ::levW {$levW}; set ::levH {$levH}; set ::level {$level}"
 close $f
}

proc levelGet {l x y} {
 set i [expr { [lindex $::levW $l] * int($y) + int($x) }]
 return [string range [lindex $::level $l] $i $i]
}
# return [lindex $::level $l [expr { [lindex $::levW $l] * int($y) + int($x) }]]

proc loadGeometry {path} {
 if {$::DONT_CONVERT_GEOMETRY} {
  catch {
   foreach i $::levelImages {image delete $i}
  }
  set ::levelImages [list [image create photo -file $path/layer0.png] [image create photo -file $path/layer1.png]]
  set ::levW [lmap i $::levelImages {image width $i}]
  set ::levH [lmap i $::levelImages {image height $i}]
 } else {
  buildGeometry $path
  source $path/geometry.txt
  image delete gfx0
  image delete gfx1
 }
}

if {$DONT_CONVERT_GEOMETRY} {
 proc levelGet {l x y} {
  set img [lindex $::levelImages $l]
  if {$x<0 || $x>=[set w [expr {int([image width  $img])}]]} {return}
  if {$y<0 || $y>=[set h [expr {int([image height $img])}]]} {return}
  set pixel [$img get [expr {int($x)}] [expr {int($y)}]]
  if { [info exists ::geometryPixelLookup($pixel)] } {
   return $::geometryPixelLookup($pixel)
  } else {
   return
  }
 }
}

if 0 {
package require Tk
buildGeometry /home/patrick/sonictcl/levels/3_deepdennace
exit
}