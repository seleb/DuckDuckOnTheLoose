pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
function hex(num)
 if num>9 then
  num-=9
  num=sub("abcdef",num,num)
 end
 return num
end

cls()
print("reading")

-- read the spritesheet
-- to a string (in hex)
s=""
for y=0,127 do
for x=0,127 do
s=s..hex(sget(x,y))
end
end

printh("map:\n","map.txt",true)
printh(s,"map.txt")

-- rle
-- compress repeated characters
-- for simplicity (ie avoid delimiters)
-- max of 15 repeats per character
-- so "3fb2" is "fff22222222222"
printh("\n\nrle:\n","map.txt")
print("compressing")
rle=""
local count=0
local char=sub(s,1,1)
repeat
 c=sub(s,1,1)
 if char==c and count<15 then
  count+=1
 else
  rle=rle..hex(count)..char
  count=1
  char=c
 end
 s=sub(s,2,#s)
until #s==0
printh(rle,"map.txt")

-- print the rle version
-- with linebreaks matching
-- a .p8 file's map section
printh("\n\nrle as map:\n","map.txt")
print("converting")
while #rle > 0 do
 printh(sub(rle,1,256),"map.txt")
 rle=sub(rle,257,#rle)
end
print("done!")
__gfx__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111cccccccccccccccccc1111111111cccccccccccccccccccccccccccccccccccccc11111cccccccccccccccccccccccccccccccccc11
11111111111cccc111ccccccccccccccccccccccccccccccccccccccccccccccccc44ccccccccccccccccccccccccccccccffffffffbbbbccccbbb3333ccccc1
111111111ccccccccccccc11cc1111cccccffccccccccccccccccc444433cccc33444cccce33e333333444ccccccccccbbbfffaaafffbbfbbcbbb33bb333ccc1
11111111ccccccccccc11111cc11111ccc4ffffffffffffffffff44444433333334444333333333e3344444fffffbbbbbbfaaaaaaaaafbbbbc3333bbbb333cc1
1111111ccccccccc111111111cc1111cc4fffffffffffffffffffff44444333333344444333e3333444444fffffbbbbbbfaaaaa6aaaaafbbcc3333bbbb3333c1
111111ccccccccc11111111111ccc1cccfffffffffffffffffffffff444444333344444443333334444433333ffbbbbbffaa6666666aaaaaaaaa3333333333c1
11111ccccccccc111111111111ccccccfffffffffffffffffffffffff44444444444444444444ccccccc344433bbbbbbffaa6aa6aaaaaaaaaaa44cc3333333c1
1111cccccccc11111111111cccc1ccccccccccccccffffffffffffffff444444444444444444ccccccccccc443bbbbbfffaa66666666666666664ccc333333c1
1111cccccc1111111ccccccccccccccccccccccccccccccccccccccfffff44444444444444cccccccccccccc43bbbbbfffaaaa6aaa6aaaaaaaa44ccce33333c1
111ccccc11111111ccccccccccccccccccccccccccccccccccccccccccccff44444444ccccccccccc44ccccc43bbbbbfffaa6666666aaaaaaaaa3ccc433333c1
111ccc11111111cccccccccccfbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccc44bbcccc33bbbbbbffaaaaaa6aaaafc3343333c3333333c1
11ccc11111111ccccccccccfbbbfffffffffaaaffff4f4444cccccccccccccccccccccc4ffccccc33ebbbcccc3bbbbbbb33aaaafffaabcc33333333333333cc1
11cc11111111ccccccccbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaffbfffffffff44ffffcccc43bbbbcccccffbbbbb3f33fffffffffc33333333333e33fcc1
11cc1111111cccccbbbbbbbbaaaaaaaaaaaaa6aaaaaaaaaaaaaaaaaffbbfffffffffffffffccc4433bbcccccffffbbbbbb33fffffffffc33333333333333fcc1
1ccc111111ccccffbbbbbbbbaa66666666666666666666666666666ffb333fffffffffffffcccc433cccccccbffffbbbb3bb3ffffffffc333343333e3333fcc1
1ccc111111ccccfffbfbbbbbaa6aaaaaaaaaa6aaaa6aaaaa6aaaaaaff33333fffffff333334cccc3ccccccccbb3333bbbbfbbfffffffccf333333333333ffcc1
1cccc111111cccfffbbbbbbbaa6aaaaaaaaaa6aaaa6aaaaa6aaaaaaa3333333fffff33333344cccccccccccb333b33bbbbbbbfffffffcffbb33333333bbfccc1
1ccccccc111ccccfffbbbbbaaa6aaaaebaaaa6aaaa6aafaa6aaffbbb3333e33333ff333e33344ccccccccbb33bbb33bbbbbbbfffffffcfffb3333333bbbfccc1
11ccccccc11ccccffffbbbbaa6666aabcaa666aaaa6aafaa6aaffbb3333b333333334433333344443ffffb33bbbb333bbbbbbffffffccfffbb33333bbbbfcc11
11cccccccc11cccffffffffaaa6aaaaebaaaa6aaaa6aafafffafbb3333bb33333334444b333333333ffff33bbbbb333bbbbfbffffffcfffffbbb33bbbfffcc11
11ccccccccccccccffffbfffaa6aaaaaaaaaaaaaaa6aaffffffbb333bbbb333334444bbbbbbbfffffffff3bbbbbe333bbbbbbffffffcffffffbbbbbbbbffcc11
11cccccbccc1ccccbbffffffaa6aaaaaaaaaaaaaaa6aafffffbbbbbbbbb333333344bbbbbbbfffffffffb33bbbe3333bbbbbbfffffccffffffbbbbbbffffcc11
1cccccbbbcccccccbbbbffffaa6aaaaaa66666aaaa6aafffbbbbbbbbbb3333e33333bbfbbbffffffffbbbb33333333bbbbbbbfffffcfffffffffffffffffccc1
1ccbbb33bbccc1ccbbbbbaaaaa6aaa6aa6aaa6aaaa6aaffbbb3333bbbb3333333333bbffbfffffffffbbbbb3333333bbbbbbbbfffccffffffffffffffffffcc1
1cbbb3333bccccccbbb4ffaaaa6aaa6aa6aaa6aaaa6aafbbbbb333bbbb333333333bbbfbffffffffffffbbfbbbbbbbbbbbbbbbfffcfffffffffffffffffffcc1
1cb333333bbcccccbbbbff666666666aa6aaa6aaaa6aabbbbbbbb33bbbbb333333bbbbbffffffffffffbbbbbbbbbbbbbb333bbffccfffffffffffffbbfff3cc1
1cb33e333bbcccccbbbbffaaaa6aaa6aa6666666666aabbbbbbbb33ebbbbbb3bbbbbbbbffffffffffffbfbbbbbbbbbbb3333bbffcfffffffffffffbbbb333cc1
1cb333333bbfcccccbbbbaaaaa6aaa6aaaaaaaaaaa6aa3bbbbbbbbbbbbbbbbbbbbbbffffffffffffffbbbbbfbbbbbbb33333bbfccfffffffffffffbbb33333c1
1cbb3333bbffcccccbbbbbbfaa6aaa6aaaaaaaaaaa6aa333bbbbbbbbbbbbbbbbbbbbbfffffffffffffbbbffffbbbbb333333bbfcffffffffffffffbb333333c1
1c3bbbbbbbfffccccbbbfbbfaa6aaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbffbffffffffffffffffffffffbbbb3333333bbccfffffffffffffff3333333c1
1cbbbbbebbbfffcccbbbfbbfaa6aaaaaaaaaaaaaaaaaaaaaaaaaaaaffbbbbbbbbffffffffffffffbbbfffbbfbbbbb3333333bbcfffffffffffffff33333333c1
1cbb3bbbbbbffffcccbbbbffaa6666666666666aaaaa66666666666fffbbbbbffffffffffffffffbbbffbbbbbbbbbb33e333bcc33ffffffffffff333333333c1
1cbbbbbbbbbffffccccbbbffaaaaaa6aaaaaa6aaaaaaaaaaaa6aaaaffbbbbffffffffffffffffffbbffffffbbbbbbb3333bbbc3333fffffffffff33333333ec1
1cbb333bbffffffccccbbffffaaaaa6aaaaaa6aaaa6aaaaaaa6aaaaabbbbffffffffffffffffffffffffffffffbbbbbbbbbbcc3333ffffffffff333bb33333c1
1cb3333fffffffffccccbfffffffafffaffaa6aaaa6aafffaa6aafbbbbbffffffffffffffffffffffffffffffffffbbbbbbbc33333fffffffffb33bb3333e3c1
1cb3e333ffffffffcccccffffffffffffffafffaaa6aabffaa6aafbbbbbfffffffffffffffffffffffffffffffffffbbbbbcc33333ffffffffb333bb333333c1
1cb3e333ffffffffbcccccc4fffffffffffffff3aa6aabbbaa6aaaaaaaaaaaaffffffffffffffffffffff33333fffff3333c333e3fffffffffb333bb33333ec1
1cf3333fffffff33bbcccccc4ffffffffffb3333aa6aabbbaa6aaaaaaaaaaaffffffffffffffffffffff33333333333333cc33333ffffffff3333333333e33c1
1cff33ffffffff33bbcccccccffffffffffbb33baa6aabbbaa666666666666ffffffffffffffffffff333333333333333cc333e333ffffffb333333333333ec1
1ccffffffffff3333bbccccccccfffffbbbbbbbbaa6aabbbaa6aaaaaaaaaaafffffffffffffffffff333333333333333ccf333333ffffff3333b33333333e3c1
1ccffffffffff33333bbccccccccc44bbbbbbbbbaa6aafbfaa6aaaaaaaaaaaaffffffffffffffff333333333ff333334c4ff3333ffffff33333bb333333333c1
1cccfffffff3333333bbbcccccccccccccc4bbbfafffafbfaaaaafffffffffffffffffffffffff33333333ffffff444cc4fff33ffff33333333bbb33333e33c1
1cccffffff333e3333fbbbbccccccccccccccccccfffcccccaaaccfffffffffffffbbbffffbbb333333333fffff4cccc44fffffff3333333333beb3333333ec1
1cccfffff333333333fbbbbbcccccccccccccccccccccccccccccccccccccccccccbbbbfffb333333e3333ffff4cccc4ffffffff33333333333bbb33333333c1
1cccfff3333333333ffbbbfbbbfcccccccccccccccccccccccccccccccccccccccccccc333333333333333fffcccc4ffffffff33333333333333b333333333c1
1cccff3333333333ffbbbbbbbbffffccccccccccccccccccccccccccccccccccccccccccccc3333333333fcccccfffffffffff33333333333333333333333cc1
1ccff3333333333ffffbbbbfbbbbfbbbbb4b4444444bbfffffffccccccccccccccccccccccccccc33333ccccccccccccccccccccc33333333333333333333cc1
1ccff3333e3333fffffbbbbbbbbbffbbbbbbb44444bbbffffffffffffffccccccccccccccccccccccccccccccccccccccccccccccccccccc333333333333ccc1
1ccfff33e3333fffffbbbbbbbbbbbbbbbbbbbbbbbbbbffffffffffffffffffffffffffcccccccccccccccccccccccccfff33333333ccccccccccccccccc3cc11
1cffff333333fffffbbbbbbbbbbbbbbbfbbbbbbbbbbffffffffffffffffffffffffffffffffffbbffffffffffffffffff3333333333333333333333333cccc11
1cfffff3333ffffffbbb3333333bbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffffffbffffffffffffffffff3333333333333333333333333333cc11
1c33ffffffffffffbbb3333333333bbbbbbbbbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffff33333bb333333e3333333333333333c11
1c33fffffffffffbbb3333333e333bbbbbbbbbbbfffffffffffffffffffffffffffffffff33333333ffffffffffff333333bbbb3333333333333333333333cc1
1c333fffffffffbbb3333333333333bbbbbbbbb44ffffffbbfffffffffffffffffffff33333bb333333333fff33333333bbbbbbbb33333333333333333333cc1
1c3333fffffffbbbb33333333333333bbbbbbb44444ffffbbbfffffffffffffffffff33333bbbb333333333333333333bbbbb3333333333333333333333333c1
1c33333fffffbbbb333333333333333bbbbbbb44444bbbbbfbbffffbbbbbbffffff33333333bbb3333333333333333333bb33333333333333333333333333ec1
1c33e333fffbbbb3333333333333e333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffff333333e33333333333333333333333333333e3333333333333333333e333c1
1c3333333bbbbb33333333bbbb3333333bbbbbbbbbbbbbbbbfbbbffbbb3bbbff333333333333333333333e3333333333333333333333333333333e3e333333c1
1c33e33333333bbbb3333bbbbbb3333e33bbb3bbbbbbbbbbbbbbbbffbbbbbb33333e3333333333333e33333333333333333333333e33333333e33333333e3ec1
1c3333333333333333333bbbbbb33333333bbbbbbbbbbbbbbb3bbbbbbb333333333333333333333333333333333e333333333333e33e3333e33333e3e33333c1
1c3333333ee33e3333333bbbbbb33333333bbb3bbb3bbbbbbbbbbbbbb333333333333333333333333333333333333333e33333333333333e3333e3e333e33ec1
1c3333333333333333333bbbbbb33333333bbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333333333333333333c1
1c33333333333333333333bbbb333333333bbbbbbbbbbbbbbbbbbbbbf3333333333333333333333333333333333333e3333333333333e33333e33333333333c1
1c3333333333bbb33333333333333333e333bbbbbbbbbbfbffbbbffff333333333333333333333333333333333333333333333333e33333e33333e33e33333c1
1c33e33333bbb333333333333333333333333bfbbbbbbbbbbbbfffffff33333333e33333333333e33333333333333333333333333333333333333333333333c1
1c333333bbbbbbbb33333333333333333bb33bfffffffffffffffffffff33333333333333e3333333333333333333333333333333333e33333333333e3e333c1
1c3e333bbbbbfffbbbffff33333333bbbbbbbbbfffffffffffbfff4bffffff333333333333333333333333333333333333333333333333333333e33333333cc1
1c33333bbbbfffffffffffffffffffffffffbbbbffffffffff3ffff3bfffffff333333333333bbb33333e33333333fffff3333333333333333333333333e3cc1
1c3333bbbffffffffffffffffffffffffffffbbfffffffffbfffffffffffffffbbbbbbbb3333bbbbb33333333333fffffffff3333bbb33333333333333333cc1
1c33bbbbffffffffaaffaaffffffffffffffbbffffffffff44ffffffffffffffbbb3bbbbbb3333333333333333fffffffffffff3333bbb333333333333333cc1
1cbbbbbffffffffaaaaaaafffffffffffffbbbbfaaaffffffffb3fffff4bbffbbb33bbbbbbb33333333333ffffffffffffffffffff333333333bbb3333333cc1
1cbbbbffffffffaaa666aafffffffffa6666666666afffffffffffffffbbffbbbbbbbbbbb3bffffffffffffffffffffffffffffffffffffffbbbbbbb33333cc1
1ccbfbffffffffaa66a6aaaafaffffaa6aaaaaaaa6affffffffffffff3bffbbbbbbbbb3bbbbbffffffffffffffffffffffffffffffffffffffbbbbbbb3bb3cc1
1ccbbbffffffffaa66666666666666666a666666a6ffffffff34ffbfffffbbbb3bbbbbbb3bbbbbbfffffffff3ffffffffffbbbbbbbbbbbbbffffbbbbb33b3cc1
1ccbbfffffffffaa6aa6aaaaff33abba6a6bbbb6a6fffffffffffffffffbbbbbbbbbbbbbbbb3bbbbfffff4fffbfffffffbbbb444444444bbbffffbbbbb3b33c1
1ccbbbffffffffaa6666aaffff333bbb6a6beeb6a6bffffffffffffffffbbfbbbbbbbbbbbbbbbbbbfbfffffbffffffffbbbb444444444444bbffffbbbbbb33c1
1ccbbbfffffff444466444fff3333bbb6a6beeb6a6bfffffffff4fffffbbbbbeeeeeeeeeeeebbbbbfbffff4fffffffffbbb4443333334444bbffffbbbbbb33c1
1ccccfffffff444cc66c444f33333b3b6a6bbbb6a6bbffffffffb3ff4fbbbfbebbbbbbbbbbebbbbbfbbffffffffffffbbb443334444444444bbffffbbb3b33c1
1ccccccffcccccccc66ccccf33333bbb6666666666bb3fffffffffffffbbbbbebeeeeeeeebebbbbbfbbfffffffffffbbbb443444444444444bbbffffbb3bb3c1
11ccccccccccccccc66cccccc33333bbbbb4664bbbbb33ffffffffbfffbbbbbebebbbbbbebebbbbbffbfff3f3fffffbbbb4434444444444444bbffffff3bb3c1
11ccccccccccccccc66ccccccccc33b33b446644cccc33ffffffffffffbbbbbebebeeeebebebbb3bbfffb4ffffffffbbbb44344444474433444bbfffff33b3c1
111cccccccccccccc66ccccccccccccccccc66ccccccc3ffffffffffffbbbbbebebebbebebebbbbbbbffffffffffffbbbb44444444777443444bbfffff33b3c1
111cccccccccccccc66ccccccccccccccccc6cccccccccfffffffffffbbbbbbebebebeebebebbbb3bbbfffffffffffbbbb44444447777743444bbbffff33b3c1
1111ccccccccccccc66cccccccc111111cccc11cccccccfffffffffffbfbbbbebebebbbbebebfbbbbbbffffffffffffbbb44443444777443443bbbffff3333c1
1111ccccccccccccc66ccccccc11111111111111ccccccffffffffffbbbbbbbebebeeeeeebebbbbbfffffffffffffffbbbb4443444474434443bbbffff3333c1
1111ccccccccccccc66cccccccccc11111111111cccccfffffffffffbbbbbbbebebbbbbbbbebbbfffbffffffffffffffbbb4444344444444443bbbfffff333c1
111cccccccccccccc66cccccccccccccc1111cccccccffffffffffffbbbbbbbebeeeeeeeeeebbffbbffffffffffffffffbbb444333344444433bbbfffff33cc1
111ccccccccccc444664444fffcccccccccccccccccfffffffffffffbbb3bbbbbbbbbbbbbbbbffbbff3ffffffffffffffbbbb4444444443333bbbbffffffccc1
11ccccccccff44446666a4fffffffcccccccccccccffffffffffffffbbbbbbbbbbbbbbbbfbbbfbbffffffffffffffffffbbbbb44444333333bbbbbfffffcccc1
11cccccccffff4446446aafffffffffccccc6ccffffffffffffffbfbbbbbbbbbbbbbbbbbbbbbfbffffffbfffffffffffffbbbbb33333333bbbbbbffffcccccc1
1cccccccffffff4a6666aaffffaffffffff466fffffffffffffffbfbbbbbbbbbbbbbbbbbbbbfffffffbfffffffffffffffffbbbbbbbbbbbbbbbbffffcccccc11
1cccccffffffffaa64a6affffffffffffff4464fffffffffffffbbfbbb3bbbbbbbbfbfbbffffffffff4ff3ffffffffffffffffbbbbbbbbbbbfffffcccccccc11
1ccccfffffffffaa6666faffffffffff4ff4444fffffffffffffbbfbbbbb33bbbbffffffffffff4bfff4fffffffffffffffffffffffffffffffffcccccccc111
1ccccfffffffffff66fffffff4fffffff4f4444f4fffffffffffbbbbbb3333bbbfffffffffffffffffffbffffffffffffffffffffffffffffffffcccccccc111
1cccffffffffff4ffffafffffffffffff4f464ff4f4fffffffffbbbb3b333bbbfffffffffffffff3f4ffffffffffffffffffffff3333333333fffcccccccc111
1cccfffffffffffffffff44444fff4ffffff444f4ffffffffffffbbbbbbbbbbbbbfffffffffffffffbfffffffffffffffffff333333333333333ccccccccc111
1ccffffffffffaffffffff444444444ff4f446ff44fffffffffffbbbfbb3bfbbbffffffffffffffffffffffffffffffff33333333333333333333cccccccc111
1ccfffffffffffffffffffff444444fff44f44ffffffffffffffffbbbbbbbbbbffffffffffffffffffffffffffffff3333333333333333aaaaaaaacccccccc11
1ccfffffffffffaf4fff4fffffffffffff4444ff4f4fffffffffffbbbbffbbbfffffffffffffffffffffffffffff3333333333333333aaaa6666aacccccccc11
1ccfffffffffffaff4fff44444444444ffff44fffffffffffffffffbbffbbbfffffffffffffffffffffffffffff3333333aaaaaaaa3aaaaa6aa6aaaaaccccc11
1ccfffffffffffff44ff44f4ccc44fff44fff4fff4fffffffffffffffffffffffffffffffffffffff33333333333aaaaaaa66666aaaaa6666aa6aaaaaaccccc1
1cccfffffffffff44fff4f44c1ccc44ff4fff44ffffffffffffffffffffbfffffffffffffffffffff33aaaaaaaa3aa6666a6a6b6aaaaa6aa6aa666666accccc1
1cfcfffffffffff44ff4f44ccccccc44444fff4ffffffffffffffffffbffffffffffffffffffffff33aaa6666aaaaa6aa6a6a6b6a66666aa6aa6cccc6aacccc1
1cfccffffffffff4fff4f4cccc1c1c444f4f4f4ffffffffffffffffffffffffffffffffffffffff33ba666aa6aaaaa6aa666a6b6a63336aa6666cbbc6aacccc1
1ccccffffffffff44ff444c1c11cccc4444f4f4ffffffffffffffbfbbfffbbfffffffffffffff333bba6a6aa666a666aa6a6a666a63e36aa6aa6cccc6aacccc1
1cccccfffffff4f44fff44ccc111c1ccf44f4f4ffffffffffffffffffffbbbbbffbfffffffff33bbbba6a6666a666a6aa6a6aaa6a63336666aa666666aacccc1
1cccccffffffffff4ffff44cc1cccccc444f4f4fffff4ffffffbfbbbbbbbbbbffffffff3e3e3ebbaaaa6aaaa666a6a6666a6a666666666aaaaaaaa6aaaacccc1
1ccccccffffffffffffff444cccccc444f4f4ffffffffffffffbfb3bbbb3bbfffffffff6bbbbbbaaaaa6a33aaaaa6aaaaaa6a6aaaaaaaaaa33333a6aa77cccc1
1cccccccffffffffff4fff44444c4444f4444ffffffffffffffffbbb3bbbbffbfffffff666666666666666666666666666666666666666666666666a7777ccc1
1ccccccccffffffffffffff4444444444ff4ffffffffffffffffffbbbbbffffffffffff666666666666666666666666666666666666666666666666a7777ccc1
1cccccccccffffffff4fff4fff44ff4fff44fffff4fffffffffbfffbfffffbfffffffff6bbbbbbaaaaa6aaaaa33a6aaaaaa6a3e3e3a6aa6a3e3e3a6a7777ccc1
1cccfffccccffffffffffffffff44444ffff44fffffffffffffffffffffffffffffffff3e3e3ebbaaaa6a666aaaa6aa666a6a33333a6aa6a33333a6aa777ccc1
1cccffffccccffffffffffffffffffffff444fffffffffffffffffffffffffffffffffffffff33bbbba666a6666a6aa636a6aaaaaaa6aa6aaaaaaa6aaa77ccc1
1cccfffffccccffffffffffffff444444444fffffffffffffffffffffffffffffffffffffffff333bbaaa666aa666aa6e6666aaaa6666a666666a666aa77ccc1
1ccccfffffccccffffffffff4fffff444ffffffffffffffffffff77777777ffffffffffffffffff33baaaa6aaa6a666636aa666666aa6a6a6bb6a6a6aa77ccc1
1cccccfffffccccfffffffffffffffffffffff4fffff4fffff777777777777777777777777ffffff33aaaa66666aaaa666aa6a6aa6aa6a6a6bb66666aa7cccc1
1ccccccfffffccccfffffffffffffffffffffffffffffff777777777777777777777777777777ffff333aaaaaaaaaaaaaaaa666aa666666a6666aaaaa77cccc1
1ccccccccffffcccccfffffffffffffffffffffffffff777777777777ccccccccccccccc7777777ffff33aaaaaa3333aaa3aaaaaaaaaaaaaaaaaaaaa77ccccc1
1cccccccccffffccccccccccccccccffffffffffff777777777ccccccc7777777777777ccccccc7777f33333333333333333333333333333333333777cccccc1
1ccccccccccfffffccccccccccccccccffffff77777777cccccc7777ccccccc777777cccc7777ccc777777733333333333333333333333333777777ccccc7cc1
1cccccccccccfffffffcccccccccccccccc7777777ccccc777777777777777cccccccc777777777ccccccc777733333333333333333333777777cccc777cccc1
11cccccccccc7fffffffffff7777ccccccccccccccc777777777777777777777ccccc7777777777777777ccc777777777773333333377777777ccccccccccc11
11cccccccccc777ffffff777777777777cccccc77777777777777777777777777777ccc7777777777777777cccccc77777777733337777cccccc7777777ccc11
111cccccccccc777ffffcccc7777777777cccccccccccc7777777777777777777777cccccc7cccccccccc7777777cccc7c777777777cccccc77777777cccc111
1111ccccccccccccccccccccccc7777cccccc7cccc777cccc77777cc7777ccccccc77cccccccc77ccccc777ccc77777ccccccccccccccc77777777ccccc11111
1111111ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

