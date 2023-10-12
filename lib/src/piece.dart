part of iratus_game;

List<Position> getPositions(
    {required Position from, required List<List<int>> to}) {
  List<Position> positions = [];

  for (List<int> move in to) {
    Position? pos = from.add(move);
    if (pos != null) positions.add(pos);
  }

  return positions;
}

/// A piece on the board.
///
/// id is the type identifier. Ex : q means Queen.
class Piece {
  // Class attributes

  // All the attributes are shared by every pieces, for easier transformations
  // They all have to be initialized

  // Piece
  final Board board;
  final String color;
  final String enemyColor;
  late PieceIdentity _identity;

  /// An ally piece. Designed for dog-soldier link.
  Piece? _linkedPiece;
  Position _pos;
  Move? firstMove;
  bool _hasMovedInAnotherLife =
      false; // if the game starts from a fen where this piece has already moved

  /// A list of attacked squares, where the enemy king can't go
  List<Position> antiking = [];
  bool isCaptured = false;
  bool dynamited = false;
  bool _phantomized = false; // when set to true, can't be set back to false
  bool forCalcul = true;

  /// For calculation pieces
  Piece? original;

  // Getters
  Piece? get linkedPiece => _linkedPiece;
  bool get phantomized => _phantomized;
  Position get pos => _pos;
  String get coord => _pos.coord;
  int get row => _pos.row;
  int get col => _pos.col;

  // Identity getters
  PieceIdentity get identity => _identity;
  Role get id => _identity.id;
  List<List<int>> get moves => _identity.moves;

  Piece(this.board, this.color, this._pos, Role id)
      : enemyColor = (color == "w") ? "b" : "w" {
    if (!colors.contains(color)) {
      throw ArgumentError.value(
          color, 'A piece color can only be \'w\' or \'b\'');
    }
    _identity = identitiyConstructors[id]!(this);
    board._addPiece(this);
  }

  /// Tells if a piece has already moved or not
  bool hasMoved() {
    return _hasMovedInAnotherLife || firstMove != null;
  }

  /// Set dynamite
  void setDynamite(bool val) {
    dynamited = val;
  }

  /// if the game starts from a fen where this piece has already moved, call this method
  void setUnknownFirstMove() {
    _hasMovedInAnotherLife = true;
  }

  @override
  String toString() {
    return '${id.char.toUpperCase()}$coord';
  }

  /// Transform a piece into another
  void transform(Role pieceId) {
    if (id == pieceId) return;

    _identity = identitiyConstructors[pieceId]!(this);
  }

  void uncapture() {
    board._piecesByPos[pos.index] = this;
    isCaptured = false;
  }
}

abstract class PieceIdentity {
  abstract final Role id;
  abstract final List<List<int>> moves;

  final Piece p;

  PieceIdentity(this.p);

  /// return wether a piece can go to a square or not
  bool canGoTo(Position pos) {
    Piece? piece = p.board.getPiece(pos);
    if (piece == null) {
      return true;
    } else if (piece.id == Role.dynamite) {
      return piece.color == p.color &&
          dynamitables.contains(id) &&
          !p.dynamited;
    } else {
      return piece.color != p.color;
    }
  }

  /// called when this piece is captured
  List<Command> capture(Piece capturer) {
    List<Command> commands = [];

    p.board._piecesByPos[p.pos.index] = null;
    p.isCaptured = true;

    if (p.dynamited && !capturer.isCaptured) {
      commands.add(Capture(capturer, p));
      commands.add(NotationTransform((String notation) => '$notation*'));
    }

    if (p.board is IratusBoard) {
      for (final Piece alliedPhantom
          in (p.board as IratusBoard)._phantoms[p.color]!) {
        if (!alliedPhantom.isCaptured) {
          commands.add(Transform(alliedPhantom, alliedPhantom.id, id));
        }
      }
    }

    return commands;
  }

  /// Get a list of positions where the piece can go.
  List<Position> getValidMoves() {
    if (p.isCaptured) throw Exception('A captured piece can\'t move.');

    List<Position> validMoves = [];

    for (Position pos in getPositions(from: p.pos, to: moves)) {
      if (canGoTo(pos)) {
        validMoves.add(pos);
      }
    }

    return validMoves;
  }

  /// move the piece to a position
  List<Command> goTo(Position pos) {
    List<Command> commands = [];

    int oldPosIndex = p._pos.index;
    p._pos = pos;

    // if firstMove is null, it is set to board.currentMove
    p.firstMove ??= p.board._currentMove;

    if (p.isCaptured) {
      return commands;
    }

    p.board._piecesByPos[oldPosIndex] = null;
    p.board._piecesByPos[pos.index] = p;

    return commands;
  }

  /// redo a move
  redo(Position pos) {
    goTo(pos);
  }

  /// undo a move
  void undo(Move move) {
    goTo(move.start);
    if (p.firstMove == move) {
      p.firstMove = null;
    }
  }

  /// Add some 'true' in board.antiking
  void updateAntiking(List<bool> antiking) {
    if (p.isCaptured) return;

    for (Position pos in getPositions(from: p.pos, to: moves)) {
      antiking[pos.index] = true;
    }
  }
}

abstract class RollingPiece extends PieceIdentity {
  final int range;

  RollingPiece(Piece container, {int? range})
      : range = range ?? 10,
        super(container);

  @override
  List<Position> getValidMoves() {
    if (p.isCaptured) throw Exception('A captured piece can\'t move.');

    List<Position> validMoves = [];

    for (List<int> move in moves) {
      Position? pos = p.pos.add(move);
      if (pos == null) continue;

      for (int i = 0; i < range; i++) {
        if (canGoTo(pos!)) {
          validMoves.add(pos);

          if (p.board.getPiece(pos) != null) break; // capture
          pos = pos.add(move);
          if (pos == null) break;
        } else {
          break;
        }
      }
    }

    return validMoves;
  }

  @override
  void updateAntiking(List<bool> antiking) {
    if (p.isCaptured) return;

    for (List<int> move in moves) {
      Position? pos = p.pos.add(move);
      if (pos == null) continue;

      for (int i = 0; i < range; i++) {
        antiking[pos!.index] = true;

        if (canGoTo(pos)) {
          if (p.board.getPiece(pos) != null) break; // capture
          pos = pos.add(move);
          if (pos == null) break;
        } else {
          break;
        }
      }
    }
  }
}

abstract class PieceMovingTwice extends PieceIdentity {
  PieceMovingTwice(super.p);

  @override
  List<Command> goTo(Position pos) {
    List<Command> commands = super.goTo(pos);

    /// Return, during the move of a PieceMovingTwice, wether the movement
    /// has to be followed by a second move or not.
    ///
    /// Return true when :
    ///   - the move is the first on the board.
    ///   - the last move was not moving this piece but the main current move is.
    bool hasToMoveAgain() {
      // happens when capturing a dynamited piece
      if (p.isCaptured) return false;

      // a piece cannot move twice if it started moving because of another piece
      // ex : if pulled by the grapple, no second move
      if (p.board._mainCurrentMove.piece != p) return false;

      // this is during the second move
      if (p.board._currentMove is ExtraMove) return false;

      // this is during the first move
      return true;
    }

    if (hasToMoveAgain()) {
      commands.add(RequireAnotherMove());
    }

    return commands;
  }

  @override
  void undo(Move move) {
    // skip call to PieceMovingTwice.goTo() because we don't care about SetMovingAgain
    super.goTo(move.start);

    if (p.firstMove == move) {
      p.firstMove = null;
    }
  }

  @override
  void updateAntiking(List<bool> antiking) {
    if (p.isCaptured) return;

    for (Position pos in getPositions(from: p.pos, to: moves)) {
      antiking[pos.index] = true;
      if (canGoTo(pos)) {
        // no second move when blown by dynamite
        Piece? piece = p.board.getPiece(pos);
        if (piece != null && piece.dynamited) continue;

        // antiking squares accessible at second move
        for (Position pos2 in getPositions(from: pos, to: moves)) {
          // a piece cannot set its own pos in antiking
          if (pos2 == pos) continue;

          antiking[pos2.index] = true;
        }
      }
    }
  }
}

class _Bishop extends RollingPiece {
  @override
  final Role id = Role.bishop;
  @override
  final List<List<int>> moves = [
    [-1, 1],
    [-1, -1],
    [1, 1],
    [1, -1],
  ];

  _Bishop(super.container);
}

class _Dog extends PieceIdentity {
  @override
  final Role id = Role.dog;
  @override
  final List<List<int>> moves = [];

  _Dog(super.container);

  @override
  List<Command> capture(Piece capturer) {
    List<Command> commands = super.capture(capturer);

    if (!p._linkedPiece!.isCaptured) {
      // If the dog is captured while its soldier is alive, the phantom is an enraged dog instead of classic dog
      for (final Command command in commands) {
        if (command is Transform) {
          command.newId = Role.enragedDog; // replace Role.dog by Role.dog
          break;
        }
      }
      commands.add(Capture(p.linkedPiece!, capturer));
    }

    return commands;
  }

  @override
  List<Position> getValidMoves() {
    // a dog can't move
    return [];
  }

  @override
  List<Command> goTo(Position pos) {
    final Position oldPos = p.pos;
    List<Command> commands = super.goTo(pos);

    if (dogIsTooFar(p._linkedPiece!.pos, p.pos)) {
      // happens when a dog is pulled by a grapple
      commands.add(Extra(p._linkedPiece!.pos, getNewDogPos(oldPos, p.pos)));
    }
    return commands;
  }

  @override
  void updateAntiking(List<bool> antiking) {
    // a dog can't check
    return;
  }
}

class _Dynamite extends PieceIdentity {
  @override
  final Role id = Role.dynamite;
  @override
  final List<List<int>> moves = [];

  _Dynamite(super.container);

  @override
  List<Command> capture(Piece capturer) {
    List<Command> commands = super.capture(capturer);

    // The phantom should never phantomize into a dynamite
    commands.removeWhere((command) => command is Transform);

    // if an ally came to the dynamite square
    if (capturer != p) {
      commands.add(SetDynamite(capturer));
    }

    return commands;
  }

  @override
  List<Position> getValidMoves() {
    if (p.isCaptured) throw Exception('A captured piece can\'t move.');

    List<Position> validMoves = [];

    for (Piece piece in p.board.piecesColored[p.color]!) {
      if (piece.isCaptured ||
          piece.dynamited ||
          piece.phantomized ||
          piece.hasMoved() ||
          !dynamitables.contains(piece.id)) {
        continue;
      }

      validMoves.add(piece.pos);
    }

    return validMoves;
  }

  @override
  List<Command> goTo(Position pos) {
    List<Command> commands = [];
    commands.add(Capture(p, p));
    commands.add(SetDynamite(p.board.getPiece(pos)!));
    return commands;
  }

  @override
  void updateAntiking(List<bool> antiking) {
    if (p.isCaptured) return;

    antiking[p.pos.index] = true;
  }
}

class _EliteSoldier extends PieceMovingTwice {
  @override
  final Role id = Role.eliteSoldier;
  @override
  final List<List<int>> moves = [
    [-1, 1],
    [-1, -1],
    [1, 1],
    [1, -1],
  ];

  _EliteSoldier(super.container);
}

class _EnragedDog extends PieceMovingTwice {
  @override
  final Role id = Role.enragedDog;
  @override
  final List<List<int>> moves = [
    [0, 1],
    [0, -1],
    [1, 0],
    [-1, 0],
  ];

  _EnragedDog(super.container);
}

class _Grapple extends RollingPiece {
  @override
  final Role id = Role.grapple;
  @override
  final List<List<int>> moves = [
    [0, 1],
    [0, -1],
    [-1, 1],
    [-1, 0],
    [-1, -1],
    [1, 1],
    [1, 0],
    [1, -1],
  ];

  _Grapple(super.container);

  @override
  bool canGoTo(Position pos) {
    Piece? piece = p.board.getPiece(pos);

    // The only piece tha grapple can't move is the unequipped dynamite
    return piece == null ? true : piece.id != Role.dynamite;
  }

  @override
  List<Command> goTo(Position pos) {
    Piece? grappled = p.board.getPiece(pos);

    if (grappled == null) return super.goTo(pos);

    return [
      // ex : G:Nf6->d4
      // ex : G:Nf6->*     here, the piece on f6 was dynamited
      Notation(
          'G:${grappled.id.char.toUpperCase()}${grappled.coord}->${grappled.dynamited ? '*' : p.pos.coord}'),
      Capture(p, p),
      if (grappled.dynamited)
        Capture(grappled, p)
      else
        Extra(grappled.pos, p.pos)
    ];
  }

  @override
  void updateAntiking(List<bool> antiking) {
    // a grapple can't check
    return;
  }
}

class _King extends PieceIdentity {
  @override
  final Role id = Role.king;
  @override
  final List<List<int>> moves = [
    [0, 1],
    [0, -1],
    [-1, 1],
    [-1, 0],
    [-1, -1],
    [1, 1],
    [1, 0],
    [1, -1],
  ];

  _King(super.container);

  @override
  List<Position> getValidMoves() {
    List<Position> validMoves = super.getValidMoves();

    bool canLongCastle = false;
    bool canShortCastle = false;

    if (!p.hasMoved() && !inCheck(p)) {
      // Long castle
      Piece? leftRook = getRookAt('left', p);
      if (leftRook != null && !leftRook.hasMoved()) {
        canLongCastle = true;
        for (int dx in [-1, -2]) {
          Position pos =
              Position.fromRowCol(p.board, row: p.row, col: p.col + dx);
          if (p.board.getPiece(pos) != null || posIsUnderCheck(pos)) {
            canLongCastle = false;
            break;
          }
        }
        if (p.board.getPiece(
                Position.fromRowCol(p.board, row: p.row, col: p.col - 3)) !=
            null) {
          canLongCastle = false;
        }
        if (canLongCastle) {
          validMoves
              .add(Position.fromRowCol(p.board, row: p.row, col: p.col - 2));
        }
      }
      // Short castle
      Piece? rightRook = getRookAt('right', p);
      if (rightRook != null && !rightRook.hasMoved()) {
        canShortCastle = true;
        for (int dx in [1, 2]) {
          Position pos =
              Position.fromRowCol(p.board, row: p.row, col: p.col + dx);
          if (p.board.getPiece(pos) != null || posIsUnderCheck(pos)) {
            canShortCastle = false;
            break;
          }
        }
        if (canShortCastle) {
          validMoves
              .add(Position.fromRowCol(p.board, row: p.row, col: p.col + 2));
        }
      }
    }

    return validMoves;
  }

  @override
  List<Command> goTo(Position pos) {
    // If pulled by grapple, no castle
    if (p.board._mainCurrentMove.piece != p) return super.goTo(pos);

    bool hasMoved = p.hasMoved();
    Position oldPos = p.pos;
    List<Command> commands = super.goTo(pos);

    if (!hasMoved && ((oldPos.col - pos.col).abs() == 2)) {
      if (pos.col == 2) {
        // Long castle
        commands.add(Extra(
            Position.fromRowCol(p.board, row: pos.row, col: pos.col - 2),
            Position.fromRowCol(p.board, row: pos.row, col: pos.col + 1)));
        commands.add(Notation('0-0-0'));
      } else if (pos.col == 6) {
        // Short castle
        commands.add(Extra(
            Position.fromRowCol(p.board, row: pos.row, col: pos.col + 1),
            Position.fromRowCol(p.board, row: pos.row, col: pos.col - 1)));
        commands.add(Notation('0-0'));
      }
    }

    return commands;
  }
}

class _Knight extends PieceIdentity {
  @override
  final Role id = Role.knight;
  @override
  final List<List<int>> moves = [
    [2, 1],
    [2, -1],
    [-2, 1],
    [-2, -1],
    [1, 2],
    [1, -2],
    [-1, 2],
    [-1, -2],
  ];

  _Knight(super.container);
}

class _Pawn extends PieceIdentity {
  @override
  final Role id = Role.pawn;
  @override
  final List<List<int>> moves;

  final int promotionRow;
  final List<List<int>> attackingMoves;

  _Pawn(super.container)
      : promotionRow = container.color == 'w' ? 0 : 9,
        moves = container.color == 'w'
            ? [
                [-1, 0],
                [-2, 0]
              ]
            : [
                [1, 0],
                [2, 0]
              ],
        attackingMoves = container.color == 'w'
            ? [
                [-1, 1],
                [-1, -1]
              ]
            : [
                [1, 1],
                [1, -1]
              ];

  @override
  List<Position> getValidMoves() {
    if (p.isCaptured) throw Exception('A captured piece can\'t move.');

    List<Position> validMoves = [];

    for (Position pos in getPositions(from: p.pos, to: moves)) {
      Piece? blocker = p.board.getPiece(pos);
      if (blocker == null) {
        validMoves.add(pos);
      } else if (blocker.id == Role.dynamite && !p.dynamited) {
        validMoves.add(pos);
        break;
      } else {
        break;
      }
    }

    for (Position pos in getPositions(from: p.pos, to: attackingMoves)) {
      Piece? attacked = p.board.getPiece(pos);
      if (attacked == null) {
        Position? enPassant;
        if (p.board.lastMove != null) {
          enPassant = p.board.lastMove!.enPassant;
        } else {
          enPassant = p.board.startFEN.enPassant;
        }

        if (enPassant == pos) {
          validMoves.add(pos);
        }
      } else if (attacked.color != p.color) {
        validMoves.add(pos);
      }
    }

    return validMoves;
  }

  @override
  List<Command> goTo(Position pos) {
    int oldRow = p.row;
    List<Command> commands = super.goTo(pos);

    // If moved two squares, can be en-passant-ed
    // If p.board._currentMove != p.board._mainCurrentMove, the pawn has been pulled by a grapple
    // If p.board._currentMove.end != pos, the function is called from a undo()
    if ((oldRow - p.row).abs() == 2 &&
        p.board._currentMove == p.board._mainCurrentMove &&
        p.board._currentMove.end == pos) {
      Position enPassantPos = Position.fromRowCol(p.board,
          row: p.row + (p.color == 'w' ? 1 : -1), col: p.col);
      commands.add(SetEnPassant(enPassantPos));
    }

    // Promotion
    if (p.row == promotionRow) {
      commands.add(RequirePromotion());
    }

    // Capturing en passant
    Move? lastMove = p.board.lastMove;
    Position? enPassant;
    if (lastMove != null) {
      enPassant = lastMove.enPassant;
    } else {
      enPassant = p.board.startFEN.enPassant;
    }
    if (enPassant != null && enPassant == p.pos) {
      if (lastMove != null) {
        commands.add(Capture(lastMove.piece, p));
      } else {
        // happens when capturing en passant is the first move after a load from fen
        Position enemyPawnPos = Position.fromRowCol(p.board,
            row: enPassant.row + (p.color == 'w' ? 1 : -1), col: enPassant.col);
        Piece? captured = p.board.getPiece(enemyPawnPos);
        if (captured == null || captured.id != Role.pawn) {
          // There is a very rare case, where the pawn moved two squares and promoted,
          // and an enemy pawn is on the first row (which is illegal in classic chess).
          // In this case, the enemy pawn can capture the promoted piece en passant.
          if (captured == null || !promotionIds.contains(captured.id)) {
            throw ArgumentError(
                'Invalid FEN : en-passant doesn\'t match a pawn');
          }
        }
        commands.add(Capture(captured, p));
      }
    }

    return commands;
  }

  @override
  redo(pos) {
    if (p.board._currentMove.notation.contains('=')) {
      // If the redone move has a promotion, skip call to Pawn.redo(), avoiding the promotion choice
      super.goTo(pos);
    } else {
      super.redo(pos);
    }
  }

  @override
  void updateAntiking(List<bool> antiking) {
    if (p.isCaptured) return;

    for (Position pos in getPositions(from: p.pos, to: attackingMoves)) {
      antiking[pos.index] = true;
    }
  }
}

class _Phantom extends PieceIdentity {
  @override
  final Role id = Role.phantom;
  @override
  final List<List<int>> moves = [];

  _Phantom(Piece container) : super(container) {
    container._phantomized = true; // set once for all
  }

  @override
  List<Position> getValidMoves() {
    // an unphantomized phantom can't move
    return [];
  }

  @override
  void updateAntiking(List<bool> antiking) {
    // an unphantomized phantom can't check
    return;
  }
}

class _Queen extends RollingPiece {
  @override
  final Role id = Role.queen;
  @override
  final List<List<int>> moves = [
    [0, 1],
    [0, -1],
    [-1, 1],
    [-1, 0],
    [-1, -1],
    [1, 1],
    [1, 0],
    [1, -1],
  ];

  _Queen(super.container);
}

class _Rook extends RollingPiece {
  @override
  final Role id = Role.rook;
  @override
  final List<List<int>> moves = [
    [0, 1],
    [0, -1],
    [1, 0],
    [-1, 0],
  ];

  _Rook(super.container);
}

class _Soldier extends RollingPiece {
  @override
  final Role id = Role.soldier;
  @override
  final List<List<int>> moves;
  final int promotionRow;

  _Soldier(Piece container)
      : promotionRow = container.color == 'w' ? 0 : 9,
        moves = container.color == 'w'
            ? [
                [-1, 1],
                [-1, -1]
              ]
            : [
                [1, 1],
                [1, -1]
              ],
        super(container, range: 2);

  @override
  bool canGoTo(Position pos) {
    Piece? piece = p.board.getPiece(pos);
    if (piece == null) {
      return true;
    } else if (piece.id == Role.dynamite) {
      return piece.color == p.color &&
          dynamitables.contains(id) &&
          !p.dynamited;
    } else {
      return piece.color != p.color &&
          piece.id == Role.pawn; // the soldier only captures pawns
    }
  }

  @override
  List<Command> capture(Piece capturer) {
    List<Command> commands = super.capture(capturer);

    // If this is the phantom of the soldier
    if (p.phantomized || p._linkedPiece == null) return commands;

    if (!p._linkedPiece!.isCaptured) {
      // If the dog is still alive when the soldier is captured
      commands.add(Transform(p._linkedPiece!, Role.dog, Role.enragedDog));
    } else {
      // Else, the soldier is captured because the dog just got captured
      // In this case, the dog is phantomized, not the soldier
      commands.removeWhere((command) => command is Transform);
    }

    return commands;
  }

  @override
  List<Command> goTo(Position pos) {
    final Position oldPos = p.pos;
    List<Command> commands = super.goTo(pos);

    if (p._linkedPiece == null) {
      // If this is the phantom of the soldier
      if (p.row == promotionRow) {
        commands.add(Transform(p, id, Role.eliteSoldier));
        commands.add(NotationTransform(
            (String notation) => 'S${notation.substring(1)}=E'));
      }
      return commands;
    }

    if (p.row == promotionRow) {
      commands.add(Transform(p, id, Role.eliteSoldier));
      commands
          .add(Transform(p._linkedPiece!, p._linkedPiece!.id, Role.enragedDog));
      commands.add(NotationTransform(
          (String notation) => 'S${notation.substring(1)}=E'));
    }

    if (dogIsTooFar(p.pos, p._linkedPiece!.pos)) {
      commands.add(Extra(p._linkedPiece!.pos, getNewDogPos(oldPos, p.pos)));
    }

    return commands;
  }

  @override
  void updateAntiking(List<bool> antiking) {
    // a soldier can't check
    return;
  }
}

Map<Role, Function(Piece piece)> identitiyConstructors = {
  Role.bishop: (Piece piece) => _Bishop(piece),
  Role.enragedDog: (Piece piece) => _EnragedDog(piece),
  Role.dog: (Piece piece) => _Dog(piece),
  Role.eliteSoldier: (Piece piece) => _EliteSoldier(piece),
  Role.phantom: (Piece piece) => _Phantom(piece),
  Role.grapple: (Piece piece) => _Grapple(piece),
  Role.king: (Piece piece) => _King(piece),
  Role.knight: (Piece piece) => _Knight(piece),
  Role.pawn: (Piece piece) => _Pawn(piece),
  Role.queen: (Piece piece) => _Queen(piece),
  Role.rook: (Piece piece) => _Rook(piece),
  Role.soldier: (Piece piece) => _Soldier(piece),
  Role.dynamite: (Piece piece) => _Dynamite(piece),
};
