\ Dice roll from the 2005 version of World of Darkness.
\ Does not consider botches.
\ Explanation: count how many are above 7 of N d10s
\              where each 10 adds another d10 to the pool.

count 7< N#(accumulate x:=d10 while x=10)
