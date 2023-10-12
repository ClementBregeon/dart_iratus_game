part of iratus_game;

/// An abstract representation of chess boards.
abstract class Board {
  /// All the notations of the possible moves in the position, extept inputs
  final List<String> _allLegalNotations = [];

  /// A representation of all the squares where the king of the current player can go or not.
  ///
  /// ```dart
  /// Piece currentKing = board.king[board.turn]!;
  /// if (board._antiking[currentKing.pos.index] == true) {
  ///   print('In check');
  /// }
  /// ```
  late final List<bool> _antiking;

  /// All the undone moves.
  final List<MainMove> _backMovesHistory = [];

  /// The move currently being calculated
  late Move _currentMove;

  /// Used by calculators. True when calculating the valid moves.
  /// False when duplicating the original's moves.
  ///
  /// This field prevents changes to _backMovesHistory during calculs.
  /// Without it, _backMovesHistory would be mest up by the calculs.
  bool _duringCalcul = false;

  /// The move played by the player, it can create extra moves.
  late MainMove _mainCurrentMove;

  /// All the pieces, the index correspond to piece.pos.index
  final List<Piece?> _piecesByPos;

  /// All the possible moves in the position
  final List<MainMove> allLegalMoves = [];

  /// The kings, sorted by color
  final Map<String, Piece?> king = {'w': null, 'b': null};

  /// The last MainMove played
  MainMove? get lastMove => movesHistory.lastOrNull;

  /// All the moves played during the game.
  final List<MainMove> movesHistory = [];

  /// The number of rows in this board
  final int nbrows;

  /// The number of columns in this board
  final int nbcols;

  /// All the pieces, sorted by time of creation
  final List<Piece> pieces = [];

  /// All the pieces, sorted by color
  final Map<String, List<Piece>> piecesColored = {'w': [], 'b': []};

  /// The FEN of the starting position
  late final IratusFEN startFEN;

  /// The color of the player who has to make the next move.
  ///
  /// Can be 'w' or 'b'.
  String get turn => lastMove?.nextTurn ?? startFEN.turn;

  /// The notations of the valid moves in the position.
  ///
  /// To be given to the method move().
  List<String> get validNotations =>
      waitingForInput ? lastMove!.validInputs : _allLegalNotations;

  /// Return true if the last move played needs an input.
  ///
  /// Exemple : when a pawn reaches the end of the board,
  /// the pawn is waiting for a promotion id.
  bool get waitingForInput => lastMove?.waitingForInput ?? false;

  Board(String fen, Game game, this.nbrows, this.nbcols)
      : _antiking = List.filled(nbcols * nbrows, false),
        _piecesByPos = List.filled(nbcols * nbrows, null) {
    _createPieces(fen);
    _updateAllLegalMoves();
  }

  /// Add a piece in the board. To call only at board initialization.
  void _addPiece(Piece piece) {
    pieces.add(piece);
    _piecesByPos[piece.pos.index] = piece;
    piecesColored[piece.color]!.add(piece);

    if (piece.id == Role.king) {
      if (king[piece.color] != null) {
        throw AssertionError('An army can only have one king');
      }
      king[piece.color] = piece;
    }
  }

  /// Called once, at board creation
  ///
  /// In the implementation, initialize the pieces and calculator fields
  void _createPieces(String fen);

  /// Move a piece or complete an input request (like promotion)
  void _move(String notation) {
    if (lastMove?.waitingForInput ?? false) {
      if (!validNotations.contains(notation)) {
        throw ArgumentError.value(notation, 'Unknown move');
      }

      lastMove!.input(notation);

      _backMovesHistory.clear();
      _updateAllLegalMoves();
      return;
    }

    if (!_allLegalNotations.contains(notation)) {
      throw ArgumentError.value(notation, 'Unknown move');
    }
    MainMove move = allLegalMoves[_allLegalNotations.indexOf(notation)];

    // The move has already been played after the last move, during check calculation
    move.redoCommands();

    movesHistory.add(move);

    if (!move.waitingForInput) {
      _backMovesHistory.clear();
      _updateAllLegalMoves();
    }
  }

  /// Redo the last move undone
  void _redo() {
    if (_backMovesHistory.isEmpty) {
      return;
    }

    MainMove lastUndoneMove = _backMovesHistory.removeLast();

    lastUndoneMove.redoCommands();

    movesHistory.add(lastUndoneMove);

    _updateAllLegalMoves();
  }

  /// Undo the last move played
  void _undo() {
    if (movesHistory.isEmpty) {
      return;
    }

    MainMove undoneMove = movesHistory.removeLast();

    undoneMove.undoCommands();

    if (!_duringCalcul) {
      // _backMovesHistory only stores real moves, not calcul moves
      _backMovesHistory.add(undoneMove);
      _updateAllLegalMoves();
    }
  }

  /// Updates board.allLegalMoves
  void _updateAllLegalMoves() {
    // Prevent changes to _backMovesHistory
    _duringCalcul = true;

    List<Piece> allies = piecesColored[turn]!;
    List<Piece> enemies = piecesColored[turn == 'w' ? 'b' : 'w']!;

    // This is the field to update.
    allLegalMoves.clear();
    // This also need to be cleared, duh
    _allLegalNotations.clear();

    // Clear the antiking board.
    _antiking.fillRange(0, _antiking.length, false);

    // Fill the antiking board.
    for (Piece enemy in enemies) {
      // Captured pieces can't check.
      if (enemy.isCaptured) continue;

      // Update antiking
      enemy.identity.updateAntiking(_antiking);

      // A king can't capture a dynamited piece.
      if (enemy.dynamited) {
        _antiking[enemy.pos.index] = true;
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
      _allLegalNotations.add(move.notation);
    }

    // Enables changes to calculator._backMovesHistory.
    _duringCalcul = false;
  }

  /// Get a piece from a position
  Piece? getPiece(Position pos) {
    return _piecesByPos[pos.index];
  }

  /// return a fen of the current board
  FEN getFEN();
}

/// An object representating the board. It contains the pieces.
class IratusBoard extends Board {
  /// The phantoms, sorted by color
  final Map<String, List<Piece>> _phantoms = {'w': [], 'b': []};

  IratusBoard(String fen, Game game) : super(fen, game, 10, 8);

  @override
  void _addPiece(Piece piece) {
    super._addPiece(piece);
    if (piece.phantomized) {
      _phantoms[piece.color]!.add(piece);
    }
  }

  @override
  void _createPieces(String fen) {
    startFEN = IratusFEN.fromString(fen, this);
  }

  @override
  FEN getFEN() {
    return IratusFEN.fromBoard(this);
  }
}
