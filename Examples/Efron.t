\ Efron's non-transitive dice
\ A beats B with p = 2/3
\ B beats C with p = 2/3
\ C beats E with p = 2/3
\ E beats A with p = 2/3

A := choose{4,4,4,4,0,0};
B := choose{3,3,3,3,3,3};
C := choose{6,6,2,2,2,2};
E := choose{5,5,5,1,1,1};

count A>B

\ modify above which pair you want to test.