# Code for this level goes in this file, this will set up various things for the level, such as placing collectable items in the level, and configuring sonic's starting x,y position etc

set ::levelTitle "Pinball Paradise"
set ::song biofungus

set ::sonicx 131.0
set ::sonicy 1320.0
set ::sonicl 0

set ::goalx 7432
set ::goaly 1788

makeBouncyBall 6710 1308 bb_movement_circle 176 176 0.02
makeSpring 6484 1302 left
makeBouncyBall 6694 678 bb_movement_circle 300 300 -0.1
makeBouncyBall 6694 678 bb_movement_circle 300 300 0.1

makeSpring 6700 752
makeSpring 6648 1054 right
makeSpring 6764 1044 left
makeSpring 6430 790 right
makeSpring 6962 788 left
makeSpring 7098 794 leftleft
makeSpring 6306 814 rightright
makeSpring 6278 614 right
makeSpring 7052 592 left

makeSpring 5706 1570
makeSpring 6158 1321
makeSpring 5957 1236
makeSpring 5474 1348
makeSpring 5973 1830 
makeSpring 6391 1426
makeSpring 5433 1353 right
makeSpring 5887 1198 right
makeSpring 6339 1198 right
makeSpring 6205 754 right

lineItems 3616 1599 3616 634 20 makeRing
makeSpring 3616 1638 up
makeSpring 3616 1038 up
makeSpring 3616 600 up
makeSpring 3531 610 right
makeSpring 4248 676 right
makeSpring 4470 723 right
makeSpring 4927 573 right
makeSpring 5444 291 right
makeSpring 6015 756 rightright
makeSpring 7105 1041 left
makeSpring 7097 811 leftleft
makeSpring 6073 1071 
makeSpring 6653 968 left
makeBouncyBall 6698 558 bb_movement_circle 400 400 0.06
makeBouncyBall 6698 558 bb_movement_circle 400 400 0.06 $::PI
makeBouncyBall 6275 701 bb_movement_circle 0 400 0.04 
makeBouncyBall 6700 923 bb_movement_circle 0 500 0.06


lineItems 174 1279 516 1279 10 makeRing

foreach {aa bb cc} {
2 176 579
2 825 1933
0 1034 1132
2 381 1721
2 859 557
1 894 1159
1 449 824
1 660 427
1 541 703
2 329 1913
2 548 1061
2 1180 462
0 290 511
0 158 1340
1 616 1032
1 512 260
2 272 1348
0 415 1097
2 611 1660
0 1446 1905
0 960 1089
2 1368 1911
1 428 1715
2 853 1025
2 803 1995
0 818 47
1 114 179
0 688 997
1 276 1954
0 1476 1360
0 926 1240
2 701 1625
2 211 954
0 1394 962
2 609 1364
2 656 1091
2 490 279
0 964 1126
1 350 1005
2 1432 191
1 692 1422
1 494 809
1 106 255
2 986 1851
0 1394 1141
1 1245 1260
1 713 96
2 66 1331
1 569 1978
2 897 655
1 1478 1616
} {
 makeSpring [expr {$bb+3574}] [expr {1546-$cc}] [lindex {leftleft right rightright} $aa]
}

for {set x 2749} {$x<2957} {incr x 16} {
 makeSpring $x 1954 left
}
makeSpring 2567 1707 right

for {set x 5180} {$x<6500} {incr x 16} {
 makeSpring $x 1980
}

makeBouncyBall 969 975 bb_movement_circle 70 70 0.7

makeSnail 3604 1637
makeSpring 6643 1340 right
makeSpring 6776 1334 left
makeSpring 7089 1780 leftleft

makeMonitor 245 1632 invinc
makeMonitor 967 1498 speed
makeSpring 653 1705 rightright
makeSpring 1336 1595 left
makeMonitor 1159 1786 shield
makeMonitor 2747 823 speed

makeSpring 4495 1581 leftleft
makeSpring 4326 1782 rightright

makeSpring 3152 1962 right
makeSpring 3204 1876 left
makeSpring 3165 1774 right
makeSpring 3312 1815 right
makeSpring 3374 1743 left
makeSpring 3311 1640 right

makeSpring 1966 1505 rightright
makeSpring 3051 1816 left
makeSpring 2565 1818 right
makeSpring 1778 1927 left
makeSpring 1761 1822 right
makeBouncyBall 3186 1995
makeBouncyBall 3345 1999
makeSpring 3376 1923
makeSpring 3201 1918
makeSpring 4254 1188 left
makeSpring 3639 1311 right
makeSpring 4491 1773 left
makeSpring 5121 786 leftleft
makeSpring 4683 804 rightright
foreach {aa bb cc dd} {2 1632 174 0.0735479642637074
1 660 246 0.0267523007234558
2 8 1440 0.0936185555066913
1 1624 1097 0.0153208484407514
0 1909 1717 0.0222037214087322
2 334 1905 0.0752506759949029
2 985 1587 0.0213823002763093
2 1774 1444 0.0591494825901464
0 1661 92 0.0951304338639602
0 1514 107 0.0591859980253503
0 164 1647 0.0425303876865655
1 1976 1085 0.0344338596798480
1 1816 1451 0.0446071646641940
0 455 1645 0.0248925101710483
1 423 1576 0.0550100546795875
0 1926 853 0.0632297522854060
2 1854 1420 0.0696256972383708
0 702 1694 0.0384443651419133
1 1928 1849 0.0956132663181052
0 48 349 0.0779808173421770
1 373 1619 0.0149993398692459
1 1962 1550 0.0193650408647954
2 184 1222 0.0259940911317244
0 850 1270 0.0703278104076162
1 1227 676 0.0710754276486114
0 291 1119 0.0167423589620739
2 1055 5 0.0753617406124249
2 527 397 0.0026172812329605
1 1912 195 0.0144113528076559
0 636 1240 0.0564470580313355
1 394 1740 0.0918605835409835
0 1669 1834 0.0709991739597172
1 343 104 0.0190884120762348
2 104 894 0.0757035213056952
0 668 947 0.0776087793055922
2 1143 446 0.0627103539416567
0 457 1906 0.0756140216020867
0 319 541 0.0776937156217173
2 738 1062 0.0708331955829635
0 1983 1848 0.0739358936436474
2 1903 1283 0.0884133611107245
0 1774 234 0.0586109228897840

} {
 set xx [expr {5190+$cc}] 
 set yy [expr {2004-$dd}]
 makeBouncyBall $xx $yy bb_movement_circle 200 200 $dd 
 makeSpring $xx $yy [lindex {up left right} $aa]
}
foreach {aa bb cc} {
2 122 207
0 72 240
0 77 142
1 39 116
1 39 100
2 48 78
1 11 97
1 141 94
1 0 201
2 140 172
1 220 18
1 244 249
1 184 4
2 11 134
1 236 209
0 157 224
2 132 90
1 114 102
1 95 91
1 115 252
0 167 19
} {
 makeSpring [expr {$bb*10+5366}] [expr {1720-$cc*10}] [lindex {left up right} $aa]
}


makeSpring 1631 2023 
makeSpring 1769 2026
makeSpring 1897 2022
makeSpring 614 1039 left
makeSpring 60 757 rightright
makeSpring 60 796 rightright
makeSpring 60 822 rightright
makeSpring 1600 1989
makeSpring 1661 1982
makeSpring 1589 1904 right
makeSpring 1917 1978
makeSpring 1880 1954
makeBouncyBall 2970 1869 bb_movement_circle 60 60 0.05

makeSpring 2028 610 right
makeSpring 926 331 right
makeSpring 706 288 right
makeSpring 1106 202 leftleft
makeSpring 186 341 right
makeSpring 548 661 leftleft
makeSpring 1310 1164 rightright
makeSpring 1238 1186 rightright
makeBouncyBall 1524 715 bb_movement_circle 0 200 0.1
makeSpring 841 1207 rightright
makeSpring 1148 643 left
makeSpring 782 636 right
makeBouncyBall 970 393 bb_movement_circle 0 300 0.09
makeSpring 794 316 right
makeSpring 1118 317 right

for {set y 801} {$y>21} {incr y -32} {
 makeSpring 2544 $y left
}

makeSpring 1435 647 right
makeSpring 1623 471 left
makeSpring 1299 333 right
makeSpring 1308 524 right
makeBouncyBall 1381 718 bb_movement_circle 0 500 0.04
makeBouncyBall 1444 718 bb_movement_circle 0 500 0.04
makeSpring 1551 1011 left
makeSpring 1610 856 left
makeBouncyBall 730 630 bb_movement_circle 100 100 0.08
makeBouncyBall 1164 637 bb_movement_circle 100 100 0.08
makeSpring 1320 586 left
makeSpring 1191 483 leftleft
makeSpring 796 489 rightright
makeSpring 55 1306 
makeSpring 248 1108
makeSpring 480 1313 rightright
makeBouncyBall 4026 1604 bb_movement_circle 200 200 0.04
makeBouncyBall 4337 1382 bb_movement_circle 200 200 0.05
makeBouncyBall 3993 1185 bb_movement_circle 200 200 0.02
makeBouncyBall 4332 942 bb_movement_circle 222 222 0.01
makeBouncyBall 3813 855 bb_movement_circle 300 300 0.07
makeSpring 3650 1260 right
makeSpring 4493 1232 left
makeSpring 3602 1325
makeSpring 3550 454 rightright
makeSpring 3551 157 rightright
makeSpring 222 696 rightright
makeSpring 222 376 rightright

makeBouncyBall 966 657 bb_movement_circle 300 300 0.02
makeBouncyBall 966 657 bb_movement_circle 300 300 0.02 $::PI
makeBouncyBall 969 891 bb_movement_circle 0 300 0.03
makeBouncyBall 267 972 bb_movement_circle 0 160 0.025
makeBouncyBall 444 972 bb_movement_circle 0 160 0.025 $::PI
makeBouncyBall 1820 762 bb_movement_circle 0 644 0.04 
makeBouncyBall 1820 762 bb_movement_circle 0 644 0.04 $::PI
makeBouncyBall 1785 1989 bb_movement_circle 500 0.02 
makeBouncyBall 1822 1527 bb_movement_circle 300 300 0.01
makeBird 1822 1527 
makeSnail 1476 1520

lineItems 2025 1118 2513 1118 10 makeSpring
makeSpring 2032 940 right
makeSpring 2509 940 left
makeBouncyBall 2261 930 bb_movement_circle 200 200 0.022 $::PI
makeBouncyBall 2261 930 bb_movement_circle 200 200 0.022 
makeBouncyBall 2502 1476 bb_movement_circle 400 0 0.05
makeBouncyBall 2826 1606 bb_movement_circle 160 160 0.06
makeBouncyBall 2826 1606 bb_movement_circle 160 160 0.06 $::PI
makeBouncyBall 2820 1918 bb_movement_circle 100 100 0.07 $::PI
makeSpring 2956 1996 left
makeBouncyBall 3262 1548 bb_movement_circle 120 120 0.03 $::PI
makeSpring 3819 1638 right
makeSpring 4495 1776 left
makeSpring 5136 1693 leftleft
makeSpring 51 1176 right
makeSpring 51 1076 right
makeSpring 51 976 right
makeSpring 895 1039 right
makeSpring 1044 1024 left
makeSpring 905 973 right
makeSpring 1037 957 left
makeSpring 932 878 right
makeSpring 1004 875 left
makeSpring 861 1216 rightright


makeRing 334 1845
makeRing 354 1845
makeRing 374 1845
makeRing 334 2133
makeRing 354 2133
makeRing 374 2133
makeRing 1728 962 
makeRing 1795 1012
makeRing 1825 1080
makeRing 1897 1046
makeRing 1727 1122
makeRing 1800 1162
makeRing 1894 1203
makeRing 1836 1253
makeRing 1729 1279
makeRing 1805 1330
makeRing 1903 1368
makeRing 1837 1417
makeRing 1726 1437
makeRing 1809 1495
makeRing 1904 1518
makeRing 1826 1575
makeRing 1728 1598
makeRing 1807 1657
makeRing 2010 2045
makeRing 2040 2061
makeRing 2070 2075
makeRing 2100 2087
makeRing 2130 2100
makeRing 2160 2110
makeRing 2190 2117
makeRing 2220 2128
makeRing 2250 2128
makeRing 2280 2130
makeRing 2310 2126
makeRing 2340 2119
makeRing 2370 2106
makeRing 2400 2090
makeRing 2430 2071
makeRing 2460 2044
makeRing 2540 2046
makeRing 2570 2055
makeRing 2600 2073
makeRing 2630 2087
makeRing 2660 2099
makeRing 2690 2111
makeRing 2720 2120
makeRing 2750 2128
makeRing 2780 2133
makeRing 2900 2136
makeRing 2930 2127
makeRing 2960 2111
makeRing 2990 2098
makeRing 2920 2129
makeRing 2950 2116
makeRing 2980 2100
makeRing 3010 2084
makeRing 3040 2065
makeRing 3070 2044
makeRing 4708 2236
makeRing 4728 2236
makeRing 4748 2236
makeRing 4768 2236
makeRing 4788 2236
makeRing 4808 2236
makeRing 4828 2236
makeRing 4848 2236
makeRing 4868 2236
makeRing 4888 2236
makeRing 4908 2236
makeRing 4928 2236
makeRing 4948 2236
makeRing 4968 2236
makeRing 4988 2236
makeRing 4508 2236

