\ Match highest attack die against highest defending dice and so on
\ (like in Risk) counting 1 to the victor of each match (ties = 0).
\ Result is shown as attacker score minus defender score.

attack := M d6;
defense := N d6;
size := min {M,N};
sum
  foreach i in 1..size do (
    aval := min largest i attack;
    dval := min largest i defense;
    if aval>dval then 1 else if dval>aval then -1 else 0
  )
