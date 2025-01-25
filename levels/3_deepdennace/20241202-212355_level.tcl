# Code for this level goes in this file, this will set up various things for the level, such as placing collectable items in the level, and configuring sonic's starting x,y position etc


if { ! [info exists ::ROSE_OBJECTS_LOADED] } {
 source "$::currentLevelPath/roseobjects.tcl"
}

set ::ROSE_OBJECTS_LOADED 1


set ::levelTitle "Deep Dennace"
set ::song ice

set ::sonicx 52
set ::sonicy 2000
set ::sonicl 0

if 0 {
 set ::sonicx 4783
 set ::sonicy 1476
}

set ::goalx 15200
set ::goaly 2560

lineItems 10905 4971 11580 4971 16 makeSpring

makeSpring 11582 4593
makeSpring 11396 4257 right
makeSpring 11571 4173 right
makeSpring 11630 4791 left

lineItems 9032 4946 10066 4946 7 makeSpring
makeSpring 5177 4582 right
makeSpring 5170 4577 right
makeSpring 5470 4357 left
makeSpring 5460 4347 left
makeSpring 5537 4419 left
makeSpring 5537 4429 left
makeSpring 5604 4469 left
makeSpring 5604 4479 left

makeSpring 10091 4433
makeSpring 10937 4427
makeSpring 11499 4514
makeSpring 8915 4620

rose_makeSpring 1280 2042 up
rose_makeSpring 6953 4549 right
rose_makeSpring 3074 2620 right

rose_makeSpring 1662 3817 right
rose_makeSpring 1917 3471 up
rose_makeSpring 2110 4031 right
rose_makeSpring 4438 2010 sup 
rose_makeSpring 4541 2548 up
rose_makeSpring 7741 877 right
rose_makeSpring 8439 3316 right
rose_makeSpring 13309 567 left
rose_makeSpring 14651 4652 up
rose_makeSpring 14890 4142 left
rose_makeSpring 14508 3884 right
rose_makeSpring 14716 3640 up
rose_makeSpring 14701 3168 up
rose_makeSpring 14701 2880 up
rose_makeSpring 9885 3942 right
rose_makeSpring 8060 4146 up
rose_makeSpring 8560 4128 right
rose_makeSpring 6944 4569 up
rose_makeSpring 6844 3188 up
rose_makeSpring 6844 3000 up
rose_makeSpring 7894 692 right

rose_makeSpring 6847 2683 up

rose_makeSpring 6847 2400 up

rose_makeSpring 12820 695 up

rose_makeSpring 8704 1779 right

rose_makeSpring 9663 1631 up

rose_makeSpring 11397 1028 right 

rose_makeSpring 6405 4854 rightright

rose_makeSpring 3089 3569 rightright

rose_makeSpring 2425 3917 rightright



makeRing 318 2032 
makeRing 358 2032 
makeRing 398 2032 
makeRing 438 2032 
makeRing 3709 3838
makeRing 3749 3858
makeRing 3982 4080 
makeRing 3242 4030 
makeRing 4271 3828

makeRing 1090 2483 
makeRing 1144 2643 
makeRing 1133 2727 
makeRing 1096 2822 
makeRing 1081 2864 
makeRing 1040 2900 
makeRing 998 2930 
makeRing 1845 3836
makeRing 1890 3862
makeRing 1943 3891

makeRing 3582 2602 
makeRing 3664 2602
makeRing 3746 2602
makeRing 3828 2602
makeRing 3910 2602
makeRing 3992 2602 
makeRing 4074 2602
makeRing 4156 2602
makeRing 4159 2602

makeRing 1888 3851 
makeRing 1948 3891 
makeRing 2000 3926
makeRing 2045 3961
makeRing 2084 3998
makeRing 2120 4052


makeRing 5894 4528
makeRing 5937 4585
makeRing 5983 4623
makeRing 6024 4654
makeRing 6085 4689
makeRing 6128 4727
makeRing 6176 4751
makeRing 6210 4777
makeRing 6252 4796
makeRing 6286 4823
makeRing 6328 4842
makeRing 6368 4859



makeMonitor 760 3801 ring
makeMonitor 797 3809 shield

makeMonitor 13886 4671 ring
makeMonitor 13930 4671 shield
makeMonitor 13980 4671 ring
makeMonitor 12927 288 shield

makeMonitor 12926 284 invinc

makeMonitor 5396 3133 speed
makeMonitor 5456 3133 ring
makeMonitor 5496 3133 ring

makeAmy 14969 2547

makeSmashCrystal 1057 2038

makeSnail 3434 4987

makeSnail 3544 4987

makeBug 3929 4868 
makeBug 4330 4868 

makeBug 3928 2483

makeSnail 844 2038

makeSnail 1029 3829

makeSnail 1229 3829

makeSnail 1229 3829

makeSnail 10792 2788

makeBug 1738 3595

lineItems 8206 1911 8715 1911 13 makeSmashCrystal
lineItems 8226 1866 8689 1866 12 makeSmashCrystal

lineItems 6573 3176 6973 3176 10 makeRing

makeMonitor 13858 4848 ring
makeMonitor 13888 4848 ring
makeMonitor 13928 4848 ring 

makeBug 13868 2464
makeBug 15868 2464

lineItems 8600 237 8830 578 10 makeRing 

makeBug 8951 1797

makeBug 9551 1727

makeFrog 444 2038

makeFrog 122091 3951

makeFrog 7602 4270
   
#lineItems 3574 2624 4274 2624 20 makeAmy

lineItems 3491 1291 4074 1291 6  makeRing

lineItems 4530 4987 4830 4987 6 makeRing

lineItems 9290 3886 9590 3886 6 makeRing

