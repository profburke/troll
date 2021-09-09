\ Result of battle between 3 attackers and 2 defenders in Risk.
\ The value is the number of killed defenders.
\ The number of killed attackers is 2 minus that.

attack := 3d6;
defense := 2d6;
  (count (max attack)>(max defense))
+ (count (min largest 2 attack)>(min defense))
