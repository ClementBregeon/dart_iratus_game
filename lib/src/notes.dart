/* 
Iratus Notation Documentation

All standart chess notation still apply.


  PHANTOM

When a phantom moves, we note the symbol '~' after the id of the phantomized
piece.

Ex : Q~xe4       <- a phantomized queen captured a piece on e4
Ex : Sc~xe4       <- a phantomized soldier, from c file, captured a piece on e4


  SOLDIER

A dog state is never shown from a soldier notation.

When a soldier moves, the movement of the dog is inferred.
When the soldier is captured, the dog's rage isn't noted either.


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