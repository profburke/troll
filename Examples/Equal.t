\ The size of the largest set of identical results on N d6s
\ Explanation:  Roll N d6 and for each possible number on a die
\               count how many there are of that,
\               finally taking the maximum of these.

x := N d6; max (foreach i in 1..6 do count i=x)