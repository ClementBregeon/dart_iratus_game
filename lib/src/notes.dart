/* 
Iratus Notation Documentation

All standart chess notation still apply.


  PHANTOM

When a phantom moves, we note the symbol '~' after the id of the phantomized
piece.

Ex : Q~xe4       <- a phantomized queen captured a piece on e4
Ex : Sc~xe4      <- a phantomized soldier, from c file, captured a piece on e4


  SOLDIER

A dog state is never shown from a soldier notation.

When a soldier moves, the movement of the dog is inferred.
When the soldier is captured, the dog's rage isn't noted either.

When a soldier promotes to an elite soldier, the characters '=E' are added at
the end of the notation.

Ex : Sg9=E       <- a soldier promoted to elite soldier on g9


  DYNAMITE

When a piece equips dynamite, we note which piece, the symbol '+', and then the
coordinates of the dyanmite.

Ex : N+e0        <- a knight went to e0 and equipped dynamite

When a dynamite attaches itself to a piece, we note which dynamite, the symbol
'+', and then the coordinates of the piece.

Ex : Ye+d7       <- a dynamite from e file attached itself to a piece on d7

When a dynamite explodes, the notation is ended by an asterisk.

Ex : dxe3*       <- a pawn captured a dynamited piece on e3
Ex : Rxc7*#      <- a rook captured a dynamited piece on c7 and it was checkmate


  GRAPPLE

When the grapple is used, we note 'G:', the id of the pulled piece, the original
coordinates of the pulled piece, the symbol '->', and then the new coordinates
of the pulled piece.

Ex : G:Kg2->h1     <- a grapple pulled a king from g2 to h1
Ex : G:Pf2->f9=Q   <- a grapple pulled a pawn from f2 to f9 and it promoted to a queen

If the grappled chose a dynamited piece, they both explode.

Ex : G:Dg2->*     <- a grapple pulled a dog from g2 and they exploded


  PIECE MOVING TWICE

A piece moving twice has its two moved noted, separated by a hyphen.

Ex : Ce4-Cxf4    <- an enraged dog when to e4, then captured a piece on f4

*/

/* 
Insufficient material studies :

  difficulty is from 1 (mate with a queen) to 5 (mate with knight & bishop)
  can be ~ (the enemy has to be very stupid -> mate knight vs bishop)

  ┍━━━━━━━━━┯━━━━━━━━━┯━━━━━━━━━┯━━━━━━━━━━━━━┑
  │  white  │  black  │ enough? │ difficulty? │
  ┕━━━━━━━━━┷━━━━━━━━━┷━━━━━━━━━┷━━━━━━━━━━━━━┙
  ┍━━━━━━━━━┯━━━━━━━━━┯━━━━━━━━━┯━━━━━━━━━━━━━┑
  │ c       │         │   yes   │      3      │
  ┝━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━━━━━┥
  │ e       │         │    X    │             │
  ┝━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━━━━━┥
  │ f       │         │    X    │             │
  ┝━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━━━━━┥
  │ g       │         │    X    │             │
  ┝━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━━━━━┥
  │ y       │         │    X    │             │
  ┕━━━━━━━━━┷━━━━━━━━━┷━━━━━━━━━┷━━━━━━━━━━━━━┙
  ┍━━━━━━━━━┯━━━━━━━━━┯━━━━━━━━━┯━━━━━━━━━━━━━┑
  │ ds      │         │   yes   │     TODO    │
  ┝━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━━━━━┥
  │ e       │ n       │   yes   │      ~      │
  ┝━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━┿━━━━━━━━━━━━━┥
  │ e       │ b       │   yes   │      ~      │
  ┕━━━━━━━━━┷━━━━━━━━━┷━━━━━━━━━┷━━━━━━━━━━━━━┙

*/

/*
Some games

[Event "Casual game"]
[Site "iratus.fr"]
[Date "2023.9.14"]
[Time "16.45.18"]
[White "Syméon RB"]
[Black "Yannick Noël"]
[Result "*"]
[Variant "Iratus"]

1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Bc5 5. c3 Qf6 6. Be3 Nge7 7. Be2 0-0 8. 0-0 d5 9. Nxc6 Qxc6 10. exd5 Nxd5
11. Bf3 Nxe3 12. Bxc6 Nxd1 13. Rxd1 bxc6 14. Yd+b1 Sd7 15. Nd2 Yd+c8 16. Ne4 Bb6 17. Ng5 h6 18. Nxf7 Rxf7* 19. b4 c4
20. N~b2 Sb5 21. N~xc4 Bxf2+ 22. Kxf2 Sxc4 23. Rd8+ Kg9 24. Re1 Bd7 25. Rxd7* Sxa2 26. Sb1 Rf8+ 27. Kg1 c6 28. Re7 Y+c9 29. Rxg7+ Kh8
30. Rxa7 P~a8 31. Ra3 Se7 32. Rxb3 Sg5 33. Sd2 Sf4 34. h4 Sh2 35. Sf4 Kh7 36. Y+b0

*/