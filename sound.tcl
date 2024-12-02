set lastSong {}

 proc playSound {dummy} {}
 proc stopMusic {dummy} {}
 proc playSong {dummy {dummy2 {}}} {}


if {!$ENABLE_SOUND} {
 return
}

set SOUND_DEBUG 0
if {$SOUND_DEBUG} {
 package require Tk
}

if {[catch {


set snackSucksFormat "ogg"
set snackSucksExt "ogg"

if {[tk windowingsystem] ne "x11"} {
 set folder snack2.2.11/
 lappend auto_path $folder
 set snackSucksFormat "wav"
 set snackSucksExt "wav"
 package require snack
} else {
 package require snack
 package require snackogg
}

if {[tk windowingsystem] ne "x11"} {
 snack::audio playLatency 166
} else {
 snack::audio playLatency 166
}

#	o-------o
#	| Sound |
#	o-------o

snack::sound snacksucks -file sounds/snackreallysucks.wav
set fucksnack {}
proc snackreallysucks {} { 
 snacksucks play
 set ::fucksnack [after 4344 snackreallysucks]
}
snackreallysucks
update
snack::sound snd_rings -file sounds/rings.wav
snack::sound snd_ring -file sounds/ring.wav
snack::sound snd_jump -file sounds/jump.wav
snack::sound snd_roll -file sounds/roll.wav
snack::sound snd_spindash -file sounds/spindash.wav
snack::sound snd_release -file sounds/release.wav
snack::sound snd_hit -file sounds/hit.wav
snack::sound snd_bugcheck -file sounds/bugcheck.wav
snack::sound snd_pop -file sounds/pop.wav
snack::sound snd_shield -file sounds/shield.wav
snack::sound snd_ping -file sounds/ping.wav
snack::sound snd_shoot -file sounds/shoot.wav
snack::sound snd_explode -file sounds/explode.wav
snack::sound snd_spring -file sounds/spring.wav

snack::sound snd_bgm -file sounds/jump.wav
set queuedMusicReplay {}

proc playSong {song {loop 1}} {
 if {$song eq {}} return
 if {!$::PLAY_MUSIC} return
 debugMsg "playSong $song"
 after cancel $::queuedMusicReplay
 catch {
  snd_bgm stop; snd_bgm destroy
 }
 if { $::tcl_platform(platform) ne {windows} } {after cancel $::fucksnack; snacksucks stop}
 update
 # Whoever made 'snack' did a ridiculously bad job
 set songFile sounds/music/$song.$::snackSucksExt
 if { $::snackSucksFormat eq "wav" } {
  if { ! [file exists $songFile] } {
   set errorinfo ""
   set currentDir [pwd]
   cd sounds/music
   catch {
    exec ./oggdec.exe $song.ogg -w $song.wav
   } errorinfo
   puts "error info: $errorinfo"
   cd $currentDir
   puts "sorry for delay. we've just had to decode an ogg file because 'snack' is rubbish"
  }
  if { ! [file exists $songFile] } {
   puts "sorry there's no music: snack is rubbish"
   return
  }
 }
 snack::sound snd_bgm -fileformat $::snackSucksFormat -file sounds/music/$song.$::snackSucksExt
 update
 set timeSeconds [snd_bgm length -unit SECONDS] ;# note that 'SECONDS' is in all caps, inconsistent with tcl style, snack is rubbish
 debugMsg "seconds $timeSeconds"
 snd_bgm play
 if {$loop} {
  set ::queuedMusicReplay [after [expr {int((1000.0*$timeSeconds))}] [list playSong $song]]
 } else {
  set ::queuedMusicReplay {}
 }
 if { $::tcl_platform(platform) ne {windows} } { snackreallysucks }
 set ::lastSong $song
}

proc stopMusic {} {
 after cancel $::queuedMusicReplay
 catch {
  snd_bgm stop; snd_bgm destroy
 }
}

proc playSound {sound} {
 switch -- $sound {
  rings {snd_rings stop; snd_rings play}
  ring {snd_ring stop; snd_ring play}
  jump {snd_jump stop; snd_jump play}
  roll {snd_roll stop; snd_roll play}
  spindash {snd_spindash stop; snd_spindash play}
  release {snd_spindash stop; snd_release stop; snd_release play}
  pop {snd_pop play}
  shield {snd_shield play}
  ping {snd_ping stop; snd_ping play}
  hit {snd_hit play}
  bugcheck {stopMusic; snd_bugcheck play}
  bugcheckstop {stopMusic; snd_bugcheck stop}
  shoot {snd_shoot stop; snd_shoot play}
  explode {snd_explode stop; snd_explode play}
  spring {snd_spring stop; snd_spring play}
 }
}



if {$SOUND_DEBUG} {
set n 0
pack [button .b[incr n] -command {playSound jump}]
pack [button .b[incr n] -command {playSound roll}]
pack [button .b[incr n] -command {playSong levelclear}]
pack [button .b[incr n] -command {playSong greenhill}]
}






if { $tcl_platform(platform) ne "windows" } {
 after 500 snackreallysucks
}


} errorinfo ]} {
 tk_messageBox -title "Can't do sound: $errorinfo" -message "$errorinfo\nYou might need to install Snack, Debian calls it 'tcl-snack'"
}

update
#playSong greenhill
