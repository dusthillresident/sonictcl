proc titleScreen {} {
 if {! $::SHOW_TITLESCREEN } return
 image create photo titlescreen -file sprites/title.png
 .c create image [cx 0] [cy 0] -anchor nw -image titlescreen -tag titlescreen
 playSong title
 while { $::input & $::I_JUMP } { after 7; update }
 while { ! ($::input & $::I_JUMP) } { after 7; update }
 titlescreen read sprites/title2.png
 while { $::input & $::I_JUMP } { after 7; update }
 while { ! ($::input & $::I_JUMP) } { after 7; update }
 .c delete titlescreen
 .c create text 100 100 -anchor nw -font {Sans 20} -fill red  -tag object -text "LOADING, PLEASE WAIT"
 image delete titlescreen
 update
}