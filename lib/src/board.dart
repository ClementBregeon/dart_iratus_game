part of iratus_game;

abstract class Board {
  /// All the undone moves.
  final List<Move> _backMovesHistory = [];

  /// All the board's position sinc the game started.
  ///
  /// This field is used for checking 3 times repetition.
  final List<FEN> _fenHistory = [];

  /// The game managing the board
  final Game _game;

  /// All the possible moves in the position
  Map<String, Move> allValidMoves = {};

  /// The board used to simulate moves, to check if the king is in check
  late CalculatorInterface? calculator;

  /// The move currently being calculated
  late Move currentMove;

  /// The kings, sorted by color
  Map<String, Piece?> king = {'w': null, 'b': null};

  /// The last mainMove played
  Move? lastMove;

  /// The currentMove or the move who created the currentMove
  late Move mainCurrentMove;

  /// All the moves played during the game.
  final List<Move> movesHistory = [];

  /// The number of rows in this board
  final int nbrows;

  /// The number of columns in this board
  final int nbcols;

  /// The pawn to promote, waiting for an input
  Piece? pawnToPromote;

  /// All the pieces, sorted by time of creation
  List<Piece> pieces = [];

  /// All the pieces, the index correspond to piece.pos.index
  List<Piece?> piecesByPos;

  /// All the pieces, sorted by color
  Map<String, List<Piece>> piecesColored = {'w': [], 'b': []};

  /// The FEN of the starting position
  late IratusFEN startFEN;

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
  void createPieces(String fen);

  /// Get a piece from a position
  Piece? get(Position pos) {
    return piecesByPos[pos.index];
  }

  /// return a fen of the current board
  FEN getFEN();

  /// Move a piece from start to end
  /// if the movement is the result of another move, main is false
  Move _move(Position start, Position end, {bool main = true}) {
    // if (this is CalculatorInterface) {
    //   print('Calculator');
    // } else {
    //   print('Original');
    // }
    // print('start:${start.coord}  end:${end.coord}');

    Move moveToReturn = Move(this, start, end);
    currentMove = moveToReturn;

    if (main) {
      mainCurrentMove = moveToReturn;
    }

    moveToReturn.executeCommand(MainMove()); // This may change the value of this.currentMove

    if (main) {
      lastMove = moveToReturn;
    }

    return moveToReturn;
  }

  void redo(Move move, {main = true}) {
    currentMove = move;
    if (main) {
      mainCurrentMove = currentMove;
    }
    move.redoCommands();

    lastMove = move;
  }

  void undo(Move move) {
    lastMove = movesHistory.isEmpty ? null : movesHistory.last;

    for (final Command command in move.commands.reversed) {
      move.undoCommand(command);
    }
  }

  void updateAllValidMoves();
}

abstract class CalculatorInterface {
  abstract IratusBoard original;
  // abstract List<Piece> piecesCorrespondence;

  void clone();

  Piece getSimulatedPiece(Piece originalPiece);
}

class IratusBoard extends Board {
  Map<String, List<Piece>> phantoms = {'w': [], 'b': []};

  IratusBoard(String fen, Game game) : super(fen, game, 10, 8) {
    if (this is! CalculatorInterface) calculator = CalculatorIratusBoard(original: this);
  }

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
  }

  @override
  FEN getFEN() {
    return IratusFEN.fromBoard(this, turn: _game.turn);
  }

  @override
  void updateAllValidMoves() {
    // TODO : Improve !
    if (this is CalculatorInterface) throw Exception('A calculator can\'t call the updateAllValidMoves() method');

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
    calc.clone();

    allValidMoves.clear();

    bool secondMove = false;
    if (lastMove != null || startFEN.pieceMovingAgain != null) {
      Piece lastMovedPiece = lastMove == null ? startFEN.pieceMovingAgain! : lastMove!.piece;
      if (lastMovedPiece.identity is PieceMovingTwice && (lastMovedPiece.identity as PieceMovingTwice).stillHasToMove) {
        secondMove = true;
        Piece clonedPiece = calc.getSimulatedPiece(lastMovedPiece);
        Board calc2 = calc as Board;
        List<Position> validMoves = [];
        for (Position validMove in lastMovedPiece.validMoves) {
          Move moveObject = calc2._move(clonedPiece.pos, validMove, main: true);
          for (Piece enemyClonedPiece in calc2.piecesColored[clonedPiece.enemyColor]!) {
            enemyClonedPiece.identity.updateValidMoves();
          }
          if (!inCheck(calc2.king[lastMovedPiece.color]!, dontCareAboutPhantoms: false)) {
            validMoves.add(validMove);
            allValidMoves[moveObject.notation] = moveObject;
          }
          calc2.undo(moveObject);
        }
        lastMovedPiece.validMoves = validMoves;
        if (lastMovedPiece.validMoves.isEmpty) {
          throw Exception('A piece moving twice started moving, but can\'t make its second move');
        }
        for (Piece otherPiece in piecesColored[lastMovedPiece.color]!) {
          if (otherPiece == lastMovedPiece) {
            continue;
          }
          otherPiece.validMoves.clear(); // TODO : remove ? since now, we only look at board.allValidMoves...
        }
      }
    }
    if (secondMove == false) {
      for (Piece piece in piecesColored[_game.turn]!) {
        if (piece.isCaptured) continue;
        Piece clonedPiece = calc.getSimulatedPiece(piece);
        List<Position> validMoves = [];
        Board calc2 = calc as Board;
        if (piece.identity is PieceMovingTwice && !(piece.identity as PieceMovingTwice).stillHasToMove) {
          for (Position validMove in piece.validMoves) {
            Move moveObject = calc2._move(clonedPiece.pos, validMove, main: true);
            for (Piece enemyClonedPiece in calc2.piecesColored[clonedPiece.enemyColor]!) {
              enemyClonedPiece.identity.updateValidMoves();
            }
            bool valid;
            if (moveObject.nextTurn == piece.color) {
              valid = false;
              clonedPiece.identity.updateValidMoves();
              for (Position validMove2 in clonedPiece.validMoves) {
                Move moveObject2 = calc2._move(clonedPiece.pos, validMove2, main: true);
                for (Piece enemyClonedPiece2 in calc2.piecesColored[clonedPiece.enemyColor]!) {
                  enemyClonedPiece2.identity.updateValidMoves();
                }

                if (!inCheck(calc2.king[piece.color]!, dontCareAboutPhantoms: false)) {
                  valid = true;
                }
                calc2.undo(moveObject2);
                if (valid) {
                  break;
                }
              }
            } else {
              valid = !inCheck(calc2.king[piece.color]!, dontCareAboutPhantoms: false);
            }
            calc2.undo(moveObject);
            if (valid) {
              validMoves.add(validMove);
              allValidMoves[moveObject.notation] = moveObject;
            }
          }
        } else {
          for (Position validMove in piece.validMoves) {
            Move moveObject = calc2._move(clonedPiece.pos, validMove, main: true);
            for (Piece enemyClonedPiece in calc2.piecesColored[clonedPiece.enemyColor]!) {
              enemyClonedPiece.identity.updateValidMoves();
            }
            if (!inCheck(calc2.king[piece.color]!, dontCareAboutPhantoms: false)) {
              validMoves.add(validMove);
              allValidMoves[moveObject.notation] = moveObject;
            }
            calc2.undo(moveObject);
          }
        }
        piece.validMoves = validMoves;
      }
    }
  }
}

class CalculatorIratusBoard extends IratusBoard implements CalculatorInterface {
  @override
  IratusBoard original;

  CalculatorIratusBoard({required this.original}) : super(original.startFEN.fen, original._game) {
    calculator = null;
  }

  @override
  void clone() {
    piecesByPos = List.filled(original.piecesByPos.length, null);
    for (int i = 0; i < original.pieces.length; i++) {
      pieces[i].copyFrom(original.pieces[i]);
    }
  }

  @override
  Piece getSimulatedPiece(Piece originalPiece) {
    int i = original.pieces.indexOf(originalPiece);
    return pieces[i];
  }
}
