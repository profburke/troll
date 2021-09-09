\ Rolling a Yatzhee in three rolls.
\ Assume you keep the largest number of equal dice after each roll.
\ Result is number of identical dice after three rolls.

rollOne := 5d6;
maxEqualOne := max (foreach i in 1..6 do count i=rollOne);
rollTwo := (5 - maxEqualOne)d6;
maxEqualTwo := max {(maxEqualOne + (count 6= rollTwo)),
                    max (foreach i in 1..6 do count i=rollTwo)};
rollThree := (5 - maxEqualTwo)d6;
max {(maxEqualTwo + (count 6= rollThree)),
     max (foreach i in 1..6 do count i=rollThree)}


