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

  /// All the notations of the possible moves in the position
  final List<String> allLegalNotations = [];

  /// All the possible moves in the position
  final List<MainMove> allLegalMoves = [];

  /// A representation of all the squares where the king of the current player can go or not.
  ///
  /// ```dart
  /// Piece currentKing = board.king[board.turn]!;
  /// if (board.antiking[currentKing.pos.index] == true) {
  ///   print('In check');
  /// }
  /// ```
  late final List<bool> antiking;

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

  // TODO : update with second move or remove
  Iterable<String> get validNotations => waitingForInput ? lastMove!.validInputs : allLegalNotations;

  /// Return true if the last move played needs an input.
  ///
  /// Exemple : when a pawn reaches the end of the board,
  /// the pawn is waiting for a promotion id.
  bool get waitingForInput => lastMove?.waitingForInput ?? false;

  Board(String fen, Game game, this.nbrows, this.nbcols)
      : _game = game,
        antiking = List.filled(nbcols * nbrows, false),
        piecesByPos = List.filled(nbcols * nbrows, null) {
    createPieces(fen);
    updateAllLegalMoves();
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

  /// Move a piece or complete an input request (like promotion)
  void _move(String notation) {
    if (lastMove?.waitingForInput ?? false) {
      if (!validNotations.contains(notation)) {
        throw ArgumentError.value(notation, 'Unknown move');
      }

      lastMove!.input(notation);

      _backMovesHistory.clear();
      updateAllLegalMoves();
      return;
    }

    if (!allLegalNotations.contains(notation)) {
      throw ArgumentError.value(notation, 'Unknown move');
    }
    MainMove move = allLegalMoves[allLegalNotations.indexOf(notation)];

    move.redoCommands(); // TODO :

    movesHistory.add(move);

    if (!move.waitingForInput) {
      _backMovesHistory.clear();
      updateAllLegalMoves();
    }
  }

  /// Redo the last move undone
  void redo() {
    if (_backMovesHistory.isEmpty) {
      return;
    }

    MainMove lastUndoneMove = _backMovesHistory.removeLast();

    lastUndoneMove.redoCommands();

    movesHistory.add(lastUndoneMove);

    updateAllLegalMoves();
  }

  /// Undo the last move played
  void undo() {
    if (movesHistory.isEmpty) {
      return;
    }

    MainMove undoneMove = movesHistory.removeLast();

    undoneMove.undoCommands();

    if (!_duringCalcul) {
      // _backMovesHistory only stores real moves, not calcul moves
      _backMovesHistory.add(undoneMove);
      updateAllLegalMoves();
    }
  }

  /// Updates board.allLegalMoves
  void updateAllLegalMoves() {
    // Prevent changes to _backMovesHistory
    _duringCalcul = true;

    List<Piece> allies = piecesColored[turn]!;
    List<Piece> enemies = piecesColored[turn == 'w' ? 'b' : 'w']!;

    // This is the field to update.
    allLegalMoves.clear();
    // This also need to be cleared, duh
    allLegalNotations.clear();

    // Clear the antiking board.
    antiking.fillRange(0, antiking.length, false);

    // Fill the antiking board.
    for (Piece enemy in enemies) {
      // Captured pieces can't check.
      if (enemy.isCaptured) continue;

      // Update antiking
      enemy.identity.updateAntiking(antiking);

      // A king can't capture a dynamited piece.
      if (enemy.dynamited) {
        antiking[enemy.pos.index] = true;
      }
    }

    // This is a list of all the valid moves, regardless of checks.
    Map<Position, List<Position>> allValidMoves = {};

    //  Update allValidMoves.
    for (Piece ally in allies) {
      // Captured pieces can't move.
      if (ally.isCaptured) continue;

      allValidMoves[ally.pos] = ally.identity.getValidMoves();
    }

    // Next, we remove the moves that leave the king in check.
    allValidMoves.forEach((Position start, List<Position> ends) {
      for (Position end in ends) {
        // We simulate the move.
        MainMove move = MainMove(this, start, end);
        if (move.isLegal) {
          // We validate the move.
          allLegalMoves.add(move);
        }
        // We remove the simulation
        move.undoCommands();
      }
    });

    // Notations
    // Because two (or more) identical pieces can move to the same square,
    // we only know how to write the notation after we gathered all the legal moves.
    for (MainMove move in allLegalMoves) {
      move._initNotation();
      allLegalNotations.add(move.notation);
    }

    // Enables changes to calculator._backMovesHistory.
    _duringCalcul = false;
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
  }

  @override
  FEN getFEN() {
    return IratusFEN.fromBoard(this);
  }
}
