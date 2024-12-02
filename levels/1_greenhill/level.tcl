# Code for this level goes in this file, this will set up various things for the level, such as placing collectable items in the level, and configuring sonic's starting x,y position etc

set ::levelTitle "Green Valley"
set ::song greenhill

set ::sonicx 85.0;#5952.0;#2790.0
set ::sonicy 748.0;#790.0;#1187.0

if 0 {
 # testing end of level action
 set ::sonicx 5794.0;
 set ::sonicy 748.0;
}

makeSpring 19 487 right

set ::sonicl 0

.c coords gfx1 744 0

makeMonitor 2720 399 shield
makeMonitor 1683 1172 invinc
makeMonitor 4616 1069 shield
set ::goalx 6019
set ::goaly 798

makeSpring 4476 1400
makeSpring 4476 1410
makeSpring 4476 1420

lineItems 2682 1142 2841 1180 4 makeRing
lineItems 3482 1101 3614 1107 5 makeRing
lineItems 3754 1289 4036 1270 6 makeRing
lineItems 4688 1235 4693 684 16 makeRing

lineItems 1194 1404 2000 1404 28 makeSpring
lineItems 1194 1420 2000 1420 28 makeSpring

makeSpring 2336 1400
makeSpring 2615 1400
makeBouncyBall 1907 1374

makeSpring 2660 1146 rightright
makeSpring 16 31 rightright
makeSpring 16 64 rightright
makeSpring 16 96 rightright
makeSpring 4688 1244
makeSpring 40 744 rightright
makeSpring 4501 1417
makeSpring 4455 1036 right
makeSpring 4449 1025 right
makeSpring 4488 1011 right
makeSpring 3311 1121 right
makeSpring 4047 367 right
lineItems 4066 353 4165 254 10 makeRing
makeSpring 4116 89 rightright

makeBouncyBall 1625 1355
makeBouncyBall 1798 1321
makeBouncyBall 1461 1414

makeBird 1455 1416
makeSnail 1380 1241 1
makeSnail 898 164
makeSnail 1507 516
makeSnail 2556 761
makeBird 2492 1246
lineItems 3101 643 3923 634 4 makeBird
makeSnail 4007 1074

makeRing 338 664
makeRing 161 579
makeRing 269 429
makeRing 89 290
makeRing 162 132

lineItems 212 139 381 184 5 makeRing
lineItems 381 184 502 272 5 makeRing
lineItems 502 272 595 397 5 makeRing
lineItems 595 397 731 454 5 makeRing
lineItems 1193 194 1426 498 10 makeRing

lineItems 732 946 837 949 6 makeRing
lineItems 1128 1166 1577 1236 10 makeRing


makeMonitor 3198 1125 shield

makeBouncyBall 1197 1348
makeBouncyBall 800 1000
#makeBouncyBall 6014 766   ;#bb_movement_circle

makeBouncyBall 2480 1166 bb_movement_circle  160 160 0.05
makeBouncyBall 2480 1166 bb_movement_circle  160 160 0.05 $::PI

makeBouncyBall 2454 304 bb_movement_circle 140 140 0.077

#makeBouncyBall 1192 1371

makeBouncyBall 4770 1100 bb_movement_circle  160 160 0.07
makeBouncyBall 4770 1100 bb_movement_circle  160 160 0.07 $::PID2
makeBouncyBall 4770 1100 bb_movement_circle  160 160 0.07 $::PI
makeBouncyBall 4770 1100 bb_movement_circle  160 160 0.07 [expr {$::PI+$::PID2}]