\ Die roll from Legend of the Five Rings.
\ Add the M largest of N d10,
\ where each die adds another d10 (recursively) when 10 is rolled.

sum (largest M N#(sum accumulate x:=d10 while x=10))
