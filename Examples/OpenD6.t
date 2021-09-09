\ d6 where a 6 counts as 5 + reroll
\ Explanation: Roll a d6 until it is different from 6,
\ then count 5 for each 6 rolled and add the value that was less than 6.
\ Since rerolls are limited, there may be no value less than 6,
\ so the "sum" is needed to avoid an error when adding an empty collection.

x := accumulate y:=d6 while y=6;
5*(count 6= x) + sum (6>x)