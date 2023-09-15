part of iratus_game;

abstract class Board {
  /// All the undone moves.
  final List<MainMove> _backMovesHistory = [];

  /// Used by calculators. True when calculating the valid moves.
  /// False when duplicating the original's moves.
  ///
  /// This field prevents changes to _backMovesHistory during calculs.
  /// Without it, _backMovesHistory would be mest up by the calculs.
  bool _duringCalcul = false;

  /// The game managing the board
  final Game _game;

  /// All the possible moves in the position
  Map<String, Move> allLegalMoves = {};
  // TODO : allLegalMoves (distinction between legal and valid move)
  // TODO : replace piece.validMoves by piece.reachableSquares ? squaresWithinReach ? accessibleSquares ?
  // TODO : look at an official chess library

  /// The board used to simulate moves, to check if the king is in check
  late CalculatorInterface? calculator;

  /// The move currently being calculated
  late Move currentMove;

  /// The kings, sorted by color
  Map<String, Piece?> king = {'w': null, 'b': null};

  /// The last MainMove played
  MainMove? get lastMove => movesHistory.lastOrNull;

  /// The currentMove or the move who created the currentMove
  late MainMove mainCurrentMove;

  /// All the moves played during the game.
  final List<MainMove> movesHistory = [];

  /// The number of rows in this board
  final int nbrows;

  /// The number of columns in this board
  final int nbcols;

  /// All the pieces, sorted by time of creation
  List<Piece> pieces = [];

  /// All the pieces, the index correspond to piece.pos.index
  List<Piece?> piecesByPos;

  /// All the pieces, sorted by color
  Map<String, List<Piece>> piecesColored = {'w': [], 'b': []};

  /// The FEN of the starting position
  late IratusFEN startFEN;

  /// The color of the player who has to make the next move.
  ///
  /// Can be 'w' or 'b'.
  String get turn => lastMove?.nextTurn ?? startFEN.turn;

  Iterable<String> get validNotations => waitingForInput ? promotionValidNotations : allLegalMoves.keys;

  /// Return true if the last move played needs an input.
  ///
  /// Exemple : when a pawn reaches the end of the board,
  /// the pawn is waiting for a promotion id.
  bool get waitingForInput => lastMove?.waitingForInput ?? false;

  Board(String fen, Game game, this.nbrows, this.nbcols)
      : _game = game,
        piecesByPos = List.filled(nbcols * nbrows, null) {
    createPieces(fen);

    // piece.isWidgeted needs to be set after all the pieces creation, because
    // when a piece is phantomized, if it is widgeted, it will try to phantomize
    // the simulated piece, whereas the calculator has not been initialized yet.
    // The simulated piece will transform itself at calculator initialization.
    if (this is! CalculatorInterface) {
      for (Piece piece in pieces) {
        piece.forCalcul = false;
      }
      updateAllLegalMoves();
    }
  }

  void addPiece(Piece piece) {
    pieces.add(piece);
    piecesByPos[piece.pos.index] = piece;
    piecesColored[piece.color]!.add(piece);

    if (piece.id == 'k') {
      if (king[piece.color] != null) {
        throw AssertionError('An army can only have one king');
      }
      king[piece.color] = piece;
    }
  }

  /// Called once, at board creation
  ///
  /// In the implementation, initialize the pieces and calculator fields
  void createPieces(String fen);

  /// Get a piece from a position
  Piece? get(Position pos) {
    return piecesByPos[pos.index];
  }

  /// return a fen of the current board
  FEN getFEN();

  /// Move a piece from start to end
  /// if the movement is the result of another move, main is false
  void _moveFromTo(Position start, Position end) {
    MainMove move = MainMove(this, start, end);

    movesHistory.add(move);

    if (this is! CalculatorInterface) {
      (calculator! as Board)._moveFromTo(start, end);
    }

    if (!move.waitingForInput) {
      move.lock();
      if (!_duringCalcul) {
        _backMovesHistory.clear();
      }
      updateAllLegalMoves();
    }
  }

  /// Move a piece or complete an input request (like promotion)
  void _move(String notation) {
    if (lastMove?.waitingForInput ?? false) {
      if (!validNotations.contains(notation)) {
        throw ArgumentError.value(notation, 'Unknown move');
      } // TODO : remove ?

      lastMove!.input(notation);

      _backMovesHistory.clear();
      if (calculator != null) {
        (calculator as IratusBoard)._move(notation);
      }

      updateAllLegalMoves();
      return;
    }

    if (this is CalculatorInterface) throw Exception('A calculator can\'t call the _move() method');

    Move? calcMove = allLegalMoves[notation];
    if (calcMove == null) {
      throw ArgumentError.value(notation, 'Unknown move');
    }

    _moveFromTo(calcMove.start, calcMove.end);
  }

  /// Redo the last move undone
  void redo() {
    if (_backMovesHistory.isEmpty) {
      return;
    }

    MainMove lastUndoneMove = _backMovesHistory.removeLast();

    lastUndoneMove.redoCommands();

    movesHistory.add(lastUndoneMove);

    if (this is! CalculatorInterface) {
      (calculator! as Board).redo();
    }

    updateAllLegalMoves();
  }

  /// Undo the last move played
  void undo() {
    if (movesHistory.isEmpty) {
      return;
    }

    MainMove undoneMove = movesHistory.removeLast();

    if (!_duringCalcul) {
      // _backMovesHistory only stores real moves, not calcul moves
      _backMovesHistory.add(undoneMove);
    }

    undoneMove.undoCommands();

    if (this is! CalculatorInterface) {
      (calculator! as Board).undo();
    }

    updateAllLegalMoves();
  }

  /// Updates board.allLegalMoves
  void updateAllLegalMoves() {
    // A calculator doesn't ask for calculs.
    if (this is CalculatorInterface) return;

    // This is the field to update
    allLegalMoves.clear();

    // First, we update the valid moves, regardless of checks.

    // The antiking squares need to be cleared because ?
    // TODO : remove ?
    for (Piece piece in pieces) {
      piece.antiking.clear();
    }
    for (Piece piece in pieces) {
      piece.identity.updateValidMoves();
    }
    // We need to update again the king's valid moves, because of the castling moves.
    // Castling depends on the enemies antiking, so they are updated last.
    for (Piece? king in king.values) {
      if (king == null) return;
      king.identity.updateValidMoves();
    }

    // Then, we set up the calculator.

    CalculatorInterface calc = calculator!;
    Board calc2 = calc as Board;
    // Prevent changes to calculator._backMovesHistory
    calc2._duringCalcul = true;

    // Next, we remove the moves that leave their king in check.

    for (Piece piece in piecesColored[turn]!) {
      // Captured pieces can't move.
      if (piece.isCaptured) continue;

      // The list of the piece's moves that don't leave their king in check.
      List<Position> legalMoves = [];

      // The equivalent of this piece, but on the calculator board.
      Piece clonedPiece = calc.getSimulatedPiece(piece);

      for (Position validMove in piece.validMoves) {
        // We simulate the move on the calculator board.
        calc2._moveFromTo(clonedPiece.pos, validMove);
        MainMove move = calc2.lastMove!;
        if (move.isLegal()) {
          // We validate the move.
          legalMoves.add(validMove);
          allLegalMoves[move.notation] = move;
        }
        calc2.undo();
      }

      // We update this piece's valid moves so that they are all legal.
      piece.validMoves = legalMoves;
    }

    // Enables changes to calculator._backMovesHistory.
    calc2._duringCalcul = true;
  }
}

class IratusBoard extends Board {
  Map<String, List<Piece>> phantoms = {'w': [], 'b': []};

  IratusBoard(String fen, Game game) : super(fen, game, 10, 8);

  @override
  void addPiece(Piece piece) {
    super.addPiece(piece);
    if (piece.phantomized) {
      phantoms[piece.color]!.add(piece);
    }
  }

  @override
  void createPieces(String fen) {
    startFEN = IratusFEN.fromString(fen, this);

    if (this is! CalculatorInterface) {
      calculator = CalculatorIratusBoard(original: this);
    }
  }

  @override
  FEN getFEN() {
    return IratusFEN.fromBoard(this);
  }

  @override
  void updateAllLegalMoves() {
    // A calculator doesn't ask for calculs
    if (this is CalculatorInterface) return;

    for (Piece piece in pieces) {
      piece.antiking.clear();
    }
    for (Piece piece in pieces) {
      piece.identity.updateValidMoves();
    }
    for (Piece? king in king.values) {
      if (king == null) return;
      king.identity.updateValidMoves();
    }

    CalculatorInterface calc = calculator!;
    Board calc2 = calc as Board;
    calc2._duringCalcul = true; // prevent changes to _backMovesHistory

    allLegalMoves.clear();

    if (lastMove != null ? lastMove!.movingAgain : startFEN.coordPMA != null) {
      Piece movingAgain;
      if (lastMove == null) {
        movingAgain = get(Position.fromCoords(this, startFEN.coordPMA!))!;
      } else {
        movingAgain = lastMove!.piece;
      }

      if (movingAgain.identity is! PieceMovingTwice) {
        throw Exception('Wrong piece movingAgain');
      }

      Piece clonedPiece = calc.getSimulatedPiece(movingAgain);
      List<Position> validMoves = [];
      for (Position validMove in movingAgain.validMoves) {
        calc2._moveFromTo(clonedPiece.pos, validMove);
        Move moveObject = calc2.lastMove!;
        for (Piece enemyClonedPiece in calc2.piecesColored[clonedPiece.enemyColor]!) {
          enemyClonedPiece.identity.updateValidMoves();
        }
        if (!inCheck(calc2.king[movingAgain.color]!, dontCareAboutPhantoms: false)) {
          validMoves.add(validMove);
          allLegalMoves[moveObject.notation] = moveObject;
        }
        calc2.undo();
      }
      movingAgain.validMoves = validMoves;
      if (movingAgain.validMoves.isEmpty) {
        throw Exception('A piece has to move again, but has to legal move');
      }
    } else {
      for (Piece piece in piecesColored[turn]!) {
        if (piece.isCaptured) continue;
        Piece clonedPiece = calc.getSimulatedPiece(piece);
        List<Position> validMoves = [];

        if (piece.identity is PieceMovingTwice) {
          for (Position validMove in piece.validMoves) {
            calc2._moveFromTo(clonedPiece.pos, validMove);
            Move moveObject = calc2.lastMove!;
            bool valid;
            if (moveObject.movingAgain) {
              // If there is 1 second move who doesn't leave the king in check, the first move is legal
              valid = false;
              clonedPiece.identity.updateValidMoves();
              for (Position validMove2 in clonedPiece.validMoves) {
                calc2._moveFromTo(clonedPiece.pos, validMove2);
                for (Piece enemyClonedPiece2 in calc2.piecesColored[clonedPiece.enemyColor]!) {
                  enemyClonedPiece2.identity.updateValidMoves();
                }

                if (!inCheck(calc2.king[piece.color]!, dontCareAboutPhantoms: false)) {
                  valid = true;
                }
                calc2.undo();
                if (valid) {
                  break;
                }
              }
            } else {
              // happens when clonedPiece was blown up by dynamite on first move
              for (Piece enemyClonedPiece in calc2.piecesColored[clonedPiece.enemyColor]!) {
                enemyClonedPiece.identity.updateValidMoves();
              }
              valid = !inCheck(calc2.king[piece.color]!, dontCareAboutPhantoms: false);
            }
            calc2.undo();
            if (valid) {
              validMoves.add(validMove);
              allLegalMoves[moveObject.notation] = moveObject;
            }
          }
        } else {
          for (Position validMove in piece.validMoves) {
            calc2._moveFromTo(clonedPiece.pos, validMove);
            MainMove moveObject = calc2.lastMove!;
            for (Piece enemyClonedPiece in calc2.piecesColored[clonedPiece.enemyColor]!) {
              enemyClonedPiece.identity.updateValidMoves();
            }
            if (!inCheck(calc2.king[piece.color]!, dontCareAboutPhantoms: false)) {
              validMoves.add(validMove);
              allLegalMoves[moveObject.notation] = moveObject;
            }
            calc2.undo();
          }
        }
        piece.validMoves = validMoves;
      }
    }

    calc2._duringCalcul = false;
  }
}

abstract class CalculatorInterface {
  abstract IratusBoard original;
  // abstract List<Piece> piecesCorrespondence;

  Piece getSimulatedPiece(Piece originalPiece);
}

class CalculatorIratusBoard extends IratusBoard implements CalculatorInterface {
  @override
  IratusBoard original;

  CalculatorIratusBoard({required this.original}) : super(original.startFEN.fen, original._game) {
    calculator = null;
  }

  @override
  Piece getSimulatedPiece(Piece originalPiece) {
    int i = original.pieces.indexOf(originalPiece);
    return pieces[i];
  }
}
