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

  /// All the board's position sinc the game started.
  ///
  /// This field is used for checking 3 times repetition.
  final List<FEN> _fenHistory = [];

  /// The game managing the board
  final Game _game;

  /// The color of the player who has to make the next move.
  ///
  /// Can be 'w' or 'b'.
  late String _turn;

  /// All the possible moves in the position
  Map<String, Move> allValidMoves = {};

  /// The board used to simulate moves, to check if the king is in check
  late CalculatorInterface? calculator;

  /// The move currently being calculated
  late Move currentMove;

  /// The kings, sorted by color
  Map<String, Piece?> king = {'w': null, 'b': null};

  /// The last MainMove played
  MainMove? lastMove;

  /// The currentMove or the move who created the currentMove
  late MainMove mainCurrentMove;

  /// All the moves played during the game.
  final List<MainMove> movesHistory = [];

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

  /// The color of the player who has to make the next move.
  ///
  /// Can be 'w' or 'b'.
  String get turn => _turn;

  Iterable<String> get validNotations => waitingForInput ? promotionValidNotations : allValidMoves.keys;

  /// Return true if the last move played needs an input.
  ///
  /// Exemple : when a pawn reaches the end of the board,
  /// the pawn is waiting for a promotion id.
  bool get waitingForInput => pawnToPromote != null;

  Board(String fen, Game game, this.nbrows, this.nbcols)
      : _game = game,
        piecesByPos = List.filled(nbcols * nbrows, null) {
    createPieces(fen);
    _fenHistory.add(startFEN);
    _turn = startFEN.turn;

    // piece.isWidgeted needs to be set after all the pieces creation, because
    // when a piece is phantomized, if it is widgeted, it will try to phantomize
    // the simulated piece, whereas the calculator has not been initialized yet.
    // The simulated piece will transform itself at calculator initialization.
    if (this is! CalculatorInterface) {
      for (Piece piece in pieces) {
        piece.forCalcul = false;
      }
      updateAllValidMoves();
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

    lastMove = move;
    movesHistory.add(move);

    if (this is! CalculatorInterface) {
      (calculator! as Board)._moveFromTo(start, end);
    }
    if (this is CalculatorInterface || !waitingForInput) {
      _turn = move.nextTurn;
      _fenHistory.add(getFEN());
      if (!_duringCalcul) {
        _backMovesHistory.clear();
      }
      updateAllValidMoves();
    }
  }

  /// Move a piece or complete an input request (like promotion)
  void _move(String notation) {
    if (this is CalculatorInterface) throw Exception('A calculator can\'t call the _move() method');

    if (waitingForInput) {
      if (!promotionValidNotations.contains(notation)) {
        throw ArgumentError.value(
            notation, 'A promotion notation must be in the format \'=\' + promotionId (upper case)');
      }
      lastMove!.executeCommand(Transform(pawnToPromote!, 'p', notation[1].toLowerCase()));
      lastMove!._notation += notation.toUpperCase();

      pawnToPromote = null;
      _fenHistory.add(getFEN());
      _backMovesHistory.clear();
      _turn = lastMove!.nextTurn;
      updateAllValidMoves();
      return;
    }

    Move? calcMove = allValidMoves[notation];
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

    lastMove = lastUndoneMove;
    movesHistory.add(lastUndoneMove);

    if (!waitingForInput) {
      _turn = lastUndoneMove.nextTurn;
      _fenHistory.add(getFEN());
    }

    if (this is! CalculatorInterface) {
      (calculator! as Board).redo();
    }

    updateAllValidMoves();
  }

  /// Undo the last move played
  void undo() {
    if (movesHistory.isEmpty) {
      return;
    }

    MainMove undoneMove = movesHistory.removeLast();
    if (!_duringCalcul) {
      _backMovesHistory.add(undoneMove);
    }
    _fenHistory.removeLast();
    _turn = undoneMove.turn;
    lastMove = movesHistory.isEmpty ? null : movesHistory.last;
    pawnToPromote = null; // If was waiting for promotion input

    undoneMove.undoCommands();

    if (this is! CalculatorInterface) {
      (calculator! as Board).undo();
    }

    updateAllValidMoves();
  }

  void updateAllValidMoves();
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
  void updateAllValidMoves() {
    // TODO : Improve !

    // A calculator can't call the updateAllValidMoves() method
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

    allValidMoves.clear();

    bool secondMove = false;
    if (lastMove != null || startFEN.pieceMovingAgain != null) {
      Piece lastMovedPiece = lastMove == null ? startFEN.pieceMovingAgain! : lastMove!.piece;
      // TODO : if (lastMove.pieceMovingAgain)
      if (lastMovedPiece.identity is PieceMovingTwice && (lastMovedPiece.identity as PieceMovingTwice).stillHasToMove) {
        secondMove = true;
        Piece clonedPiece = calc.getSimulatedPiece(lastMovedPiece);
        List<Position> validMoves = [];
        for (Position validMove in lastMovedPiece.validMoves) {
          calc2._moveFromTo(clonedPiece.pos, validMove);
          Move moveObject = calc2.lastMove!;
          for (Piece enemyClonedPiece in calc2.piecesColored[clonedPiece.enemyColor]!) {
            enemyClonedPiece.identity.updateValidMoves();
          }
          if (!inCheck(calc2.king[lastMovedPiece.color]!, dontCareAboutPhantoms: false)) {
            validMoves.add(validMove);
            allValidMoves[moveObject.notation] = moveObject;
          }
          calc2.undo();
        }
        lastMovedPiece.validMoves = validMoves;
        if (lastMovedPiece.validMoves.isEmpty) {
          throw Exception('A piece moving twice started moving, but can\'t make its second move');
        }
      }
    }
    if (secondMove == false) {
      for (Piece piece in piecesColored[_turn]!) {
        if (piece.isCaptured) continue;
        Piece clonedPiece = calc.getSimulatedPiece(piece);
        List<Position> validMoves = [];
        if (piece.identity is PieceMovingTwice && !(piece.identity as PieceMovingTwice).stillHasToMove) {
          for (Position validMove in piece.validMoves) {
            calc2._moveFromTo(clonedPiece.pos, validMove);
            Move moveObject = calc2.lastMove!;
            for (Piece enemyClonedPiece in calc2.piecesColored[clonedPiece.enemyColor]!) {
              enemyClonedPiece.identity.updateValidMoves();
            }
            bool valid;
            if (moveObject.nextTurn == piece.color) {
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
              valid = !inCheck(calc2.king[piece.color]!, dontCareAboutPhantoms: false);
            }
            calc2.undo();
            if (valid) {
              validMoves.add(validMove);
              allValidMoves[moveObject.notation] = moveObject;
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
              allValidMoves[moveObject.notation] = moveObject;
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

  void clone();

  Piece getSimulatedPiece(Piece originalPiece);
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
