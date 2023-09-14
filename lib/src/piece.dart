import 'game.dart';
import 'position.dart';
import 'utils.dart';

class Piece {
  // Class attributes

  // All the attributes are shared by every pieces, for easier transformations
  // They all have to be initialized

  // Piece
  final Board board;
  final String color;
  final String enemyColor;
  late PieceIdentity _identity;
  Position _pos;
  Move? firstMove;
  bool _hasMovedInAnotherLife = false; // if the game starts from a fen where this piece has already moved
  List<Position> validMoves = [];

  /// A list of attacked squares, where the enemy king can't go
  List<Position> antiking = [];
  bool isCaptured = false;
  bool dynamited = false;
  bool _phantomized = false; // when set to true, can't be set back to false
  bool forCalcul = true;

  /// For calculation pieces
  Piece? original;

  // Getters
  bool get phantomized => _phantomized;
  Position get pos => _pos;
  String get coord => _pos.coord;
  int get row => _pos.row;
  int get col => _pos.col;

  // Identity getters
  PieceIdentity get identity => _identity;
  String get id => _identity.id;
  List<List<int>> get moves => _identity.moves;

  // Dog & Soldier - tricky attribute
  Piece? linkedPiece; // TODO : rethink when transfomation will be done

  Piece(this.board, this.color, this._pos, String id) : enemyColor = (color == "w") ? "b" : "w" {
    if (!colors.contains(color)) throw ArgumentError.value(color, 'A piece color can only be \'w\' or \'b\'');
    if (!ids.contains(id)) throw ArgumentError.value(id, 'Unknown piece id');
    _identity = identitiyConstructors[id]!(this);
    board.addPiece(this);
  }

  /// used by calculator pieces
  void copyFrom(Piece originalPiece) {
    // TODO : remove copyFrom & clone
    isCaptured = originalPiece.isCaptured;
    if (isCaptured) {
      return;
    }

    _pos = originalPiece._pos;
    board.piecesByPos[_pos.index] = this;
    validMoves.clear();
    validMoves.addAll(originalPiece.validMoves);
    firstMove = originalPiece.firstMove;
    dynamited = originalPiece.dynamited;
    original = originalPiece;
    _identity.copyFrom(originalPiece._identity);
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
    return '${id.toUpperCase()}$coord';
  }

  /// Transform a piece into another
  void transform(String pieceId) {
    if (id == pieceId) return;

    _identity = identitiyConstructors[pieceId]!(this);

    if (!forCalcul) {
      board.calculator!.getSimulatedPiece(this).transform(pieceId);
    }
  }

  void uncapture() {
    board.piecesByPos[pos.index] = this;
    isCaptured = false;
  }
}

abstract class PieceIdentity {
  abstract final String id;
  abstract final List<List<int>> moves;

  final Piece p;

  PieceIdentity(this.p);

  /// return wether a piece can go to a square or not
  bool canGoTo(Position pos) {
    Piece? piece = p.board.get(pos);
    if (piece == null) {
      return true;
    } else if (piece.id == 'y') {
      return piece.color == p.color && dynamitables.contains(id) && !p.dynamited;
    } else {
      return piece.color != p.color;
    }
  }

  /// called when this piece is captured
  List<Command> capture(Piece capturer) {
    List<Command> commands = [];

    p.board.piecesByPos[p.pos.index] = null;
    p.isCaptured = true;

    if (p.dynamited && !capturer.isCaptured) {
      commands.add(Capture(capturer, p));
      commands.add(NotationHint('*'));
    }

    if (p.board is IratusBoard) {
      for (final Piece alliedPhantom in (p.board as IratusBoard).phantoms[p.color]!) {
        if (!alliedPhantom.isCaptured) {
          commands.add(Transform(alliedPhantom, alliedPhantom.id, id));
        }
      }
    }

    return commands;
  }

  /// return false if this piece can't actually capture
  /// examples : Dynamite & Grapple
  /// TODO from method to attribute ?
  bool capturerCheck() {
    return true;
  }

  void copyFrom(PieceIdentity identity) {
    if (identity.id != id) {
      throw ArgumentError('Can\'t copy identity from $id to ${identity.id}');
    }
  }

  /// move the piece to a position
  List<Command> goTo(Position pos) {
    List<Command> commands = [];

    int oldPosIndex = p._pos.index;
    p._pos = pos;

    if (p.isCaptured) {
      return commands;
    }

    p.board.piecesByPos[oldPosIndex] = null;
    p.board.piecesByPos[pos.index] = p;

    // if firstMove is null, it is set to board.currentMove
    p.firstMove ??= p.board.currentMove;

    return commands;
  }

  /// redo a move
  void redo(Position pos) {
    goTo(pos);
  }

  /// undo a move
  void undo(Move move) {
    goTo(move.start);
    if (p.firstMove == move) {
      p.firstMove = null;
    }
  }

  /// update a Piece.validMoves
  void updateValidMoves() {
    if (p.isCaptured) return;

    p.validMoves.clear();
    p.antiking.clear();

    for (List<int> move in moves) {
      Position pos;
      try {
        pos = Position.fromRowCol(p.board, row: p.row + move[0], col: p.col + move[1]);
      } catch (e) {
        continue;
      }

      p.antiking.add(pos);
      if (canGoTo(pos)) {
        p.validMoves.add(pos);
      }
    }
  }
}

abstract class RollingPiece extends PieceIdentity {
  final int range = 10;

  RollingPiece(super.container);

  @override
  void updateValidMoves() {
    if (p.isCaptured) return;

    p.validMoves.clear();
    p.antiking.clear();

    for (List<int> move in moves) {
      Position pos;
      try {
        pos = Position.fromRowCol(p.board, row: p.row + move[0], col: p.col + move[1]);
      } catch (e) {
        continue;
      }

      for (int i = 0; i < range; i++) {
        p.antiking.add(pos);
        if (canGoTo(pos)) {
          p.validMoves.add(pos);
          if (p.board.get(pos) != null) break; // capture

          try {
            pos = Position.fromRowCol(p.board, row: pos.row + move[0], col: pos.col + move[1]);
          } catch (e) {
            break;
          }
        } else {
          break;
        }
      }
    }
  }
}

abstract class PieceMovingTwice extends PieceIdentity {
  bool stillHasToMove = false; // TODO : remove usage

  PieceMovingTwice(super.p);

  @override
  List<Command> goTo(Position pos) {
    List<Command> commands = super.goTo(pos);

    // if captured, ignore second move
    // happens when capturing a dynamited piece
    if (p.isCaptured) {
      stillHasToMove = false;
      return commands;
    }

    // else, ask for second move
    // if pulled by the grapple, no second move
    if (p.board.mainCurrentMove.piece == p) {
      stillHasToMove = !stillHasToMove;
      if (stillHasToMove) {
        commands.add(SetMovingAgain(p));
      }
    }

    return commands;
  }

  @override
  void undo(Move move) {
    super.undo(move);

    if (p.board.lastMove == null) {
      stillHasToMove = p.board.startFEN.coordPMA == p.coord;
    } else {
      if (p.forCalcul) {
        // TODO : try to remove
        stillHasToMove = p.board.lastMove!.piece == p.original;
      } else {
        stillHasToMove = p.board.lastMove!.piece == p;
      }
    }
  }

  @override
  void updateValidMoves() {
    if (p.isCaptured) return;

    p.validMoves.clear();
    p.antiking.clear();

    for (List<int> move in moves) {
      Position pos;
      try {
        pos = Position.fromRowCol(p.board, row: p.row + move[0], col: p.col + move[1]);
      } catch (e) {
        continue; // out of board
      }

      p.antiking.add(pos);
      if (canGoTo(pos)) {
        p.validMoves.add(pos);

        // second move

        Piece? piece = p.board.get(pos);
        if (piece != null && piece.dynamited) continue; // no second move when blown by dynamite

        for (List<int> move2 in moves) {
          Position pos2;
          try {
            pos2 = Position.fromRowCol(p.board, row: pos.row + move2[0], col: pos.col + move2[1]);
          } catch (e) {
            continue; // out of board
          }
          if (pos2 == pos) continue; // without this line, a piece moving twice sets its own pos in antiking
          if (p.antiking.contains(pos2)) continue;

          p.antiking.add(pos2);
        }
      }
    }
  }
}

class _Bishop extends RollingPiece {
  @override
  final String id = 'b';
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
  final String id = 'd';
  @override
  final List<List<int>> moves = [];

  _Dog(super.container);

  @override
  List<Command> capture(Piece capturer) {
    List<Command> commands = super.capture(capturer);

    if (!p.linkedPiece!.isCaptured) {
      // If the dog is captured while its soldier is alive, the phantom is an enraged dog instead of classic dog
      for (final Command command in commands) {
        if (command is Transform) {
          command.args[2] = 'c'; // replace 'd' by 'c'
          break;
        }
      }
    }

    return commands;
  }

  @override
  List<Command> goTo(Position pos) {
    final Position oldPos = p.pos;
    List<Command> commands = super.goTo(pos);

    if (dogIsTooFar(p.linkedPiece!.pos, p.pos)) {
      // happens when a dog is pulled by a grapple
      commands.add(Extra(p.linkedPiece!.pos, getNewDogPos(oldPos, p.pos)));
    }
    return commands;
  }
}

class _Dynamite extends PieceIdentity {
  @override
  final String id = 'y';
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
  bool capturerCheck() {
    return false;
  }

  @override
  List<Command> goTo(Position pos) {
    List<Command> commands = [];
    commands.add(Capture(p, p));
    commands.add(SetDynamite(p.board.get(pos)!));
    return commands;
  }

  @override
  void updateValidMoves() {
    if (p.isCaptured) return;

    p.validMoves.clear();

    for (Piece piece in p.board.piecesColored[p.color]!) {
      if (piece.isCaptured ||
          piece.dynamited ||
          piece.phantomized ||
          piece.hasMoved() ||
          !dynamitables.contains(piece.id)) {
        continue;
      }

      p.validMoves.add(piece.pos);
    }
  }
}

class _EliteSoldier extends PieceMovingTwice {
  @override
  final String id = 'e';
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
  final String id = 'c';
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
  final String id = 'g';
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
    Piece? piece = p.board.get(pos);

    // The only piece tha grapple can't move is the unequipped dynamite
    return piece == null ? true : piece.id != 'y';
  }

  @override
  bool capturerCheck() {
    return false;
  }

  @override
  List<Command> goTo(Position pos) {
    Piece? grappled = p.board.get(pos);

    if (grappled == null) return super.goTo(pos);

    return [
      Notation('G:${grappled.id.toUpperCase()}${grappled.coord}->${p.pos.coord}'), // ex : G:Nf6->d4
      Capture(p, p),
      if (grappled.dynamited) Capture(grappled, p) else Extra(grappled.pos, p.pos)
    ];
  }

  @override
  void updateValidMoves() {
    super.updateValidMoves();
    p.antiking.clear();
  }
}

class _King extends PieceIdentity {
  @override
  final String id = 'k';
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

  String castleRights = '00';

  _King(super.container);

  @override
  bool canGoTo(Position pos) {
    if (posIsUnderCheck(pos, dontCareAboutPhantoms: true)) return false;

    Piece? piece = p.board.get(pos);
    if (piece == null) {
      return true;
    } else if (piece.id == 'y') {
      return false;
    } else {
      return piece.color != p.color && !piece.dynamited;
    }
  }

  @override
  void copyFrom(PieceIdentity identity) {
    super.copyFrom(identity);
    castleRights = (identity as _King).castleRights;
  }

  @override
  List<Command> goTo(Position pos) {
    bool hasMoved = p.hasMoved();
    List<Command> commands = super.goTo(pos);

    if (!hasMoved) {
      if (pos.col == 2 && castleRights[0] == '1') {
        // Long castle
        commands.add(Extra(Position.fromRowCol(p.board, row: pos.row, col: pos.col - 2),
            Position.fromRowCol(p.board, row: pos.row, col: pos.col + 1)));
        commands.add(Notation('0-0-0'));
      } else if (pos.col == 6 && castleRights[1] == '1') {
        // Short castle
        commands.add(Extra(Position.fromRowCol(p.board, row: pos.row, col: pos.col + 1),
            Position.fromRowCol(p.board, row: pos.row, col: pos.col - 1)));
        commands.add(Notation('0-0'));
      }
    }

    return commands;
  }

  bool posIsUnderCheck(Position pos, {required bool dontCareAboutPhantoms}) {
    for (Piece piece in p.board.piecesColored[p.enemyColor]!) {
      // the phantom's antiking squares can change after a capture
      // so they are taken in account only during calculation
      // and when checking for a mate
      if (dontCareAboutPhantoms == true) {
        if (!piece.forCalcul && piece.phantomized) {
          continue;
        }
      }

      if (!piece.isCaptured) {
        for (Position antiking in piece.antiking) {
          if (pos == antiking) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void updateValidMoves() {
    super.updateValidMoves();

    bool canLongCastle = false;
    bool canShortCastle = false;

    if (!p.hasMoved() && !inCheck(p, dontCareAboutPhantoms: false)) {
      // Long castle
      Piece? leftRook = getRookAt('left', p);
      if (leftRook != null && !leftRook.hasMoved()) {
        canLongCastle = true;
        for (int dx in [-1, -2]) {
          Position pos = Position.fromRowCol(p.board, row: p.row, col: p.col + dx);
          if (p.board.get(pos) != null || posIsUnderCheck(pos, dontCareAboutPhantoms: false)) {
            canLongCastle = false;
            break;
          }
        }
        if (p.board.get(Position.fromRowCol(p.board, row: p.row, col: p.col - 3)) != null) {
          canLongCastle = false;
        }
        if (canLongCastle) {
          p.validMoves.add(Position.fromRowCol(p.board, row: p.row, col: p.col - 2));
        }
      }
      // Short castle
      Piece? rightRook = getRookAt('right', p);
      if (rightRook != null && !rightRook.hasMoved()) {
        canShortCastle = true;
        for (int dx in [1, 2]) {
          Position pos = Position.fromRowCol(p.board, row: p.row, col: p.col + dx);
          if (p.board.get(pos) != null || posIsUnderCheck(pos, dontCareAboutPhantoms: false)) {
            canShortCastle = false;
            break;
          }
        }
        if (canShortCastle) {
          p.validMoves.add(Position.fromRowCol(p.board, row: p.row, col: p.col + 2));
        }
      }
    }

    castleRights = (canLongCastle ? '1' : '0') + (canShortCastle ? '1' : '0');
  }
}

class _Knight extends PieceIdentity {
  @override
  final String id = 'n';
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
  final String id = 'p';
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
  List<Command> goTo(Position pos) {
    int oldRow = p.row;
    List<Command> commands = super.goTo(pos);

    // If moved two squares, can be en-passant-ed
    // If p.board.currentMove != p.board.mainCurrentMove, the pawn has been pulled by a grapple
    // If p.board.currentMove.end != pos, the function is called from a undo()
    if ((oldRow - p.row).abs() == 2 &&
        p.board.currentMove == p.board.mainCurrentMove &&
        p.board.currentMove.end == pos) {
      Position enPassantPos = Position.fromRowCol(p.board, row: p.row + (p.color == 'w' ? 1 : -1), col: p.col);
      commands.add(SetEnPassant(enPassantPos));
    }

    // Promotion
    if (p.row == promotionRow) {
      if (!p.forCalcul) {
        requirePromotionInput();
      }
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
        Position enemyPawnPos =
            Position.fromRowCol(p.board, row: enPassant.row + (p.color == 'w' ? 1 : -1), col: enPassant.col);
        Piece? captured = p.board.get(enemyPawnPos);
        if (captured == null || captured.id != 'p') {
          // There is a very rare case, where the pawn moved two squares and promoted,
          // and an enemy pawn is on the first row (which is illegal in classic chess).
          // In this case, the enemy pawn can capture the promoted piece en passant.
          if (captured == null || !promotionIds.contains(captured.id)) {
            throw ArgumentError('Invalid FEN : en-passant doesn\'t match a pawn');
          }
        }
        commands.add(Capture(captured, p));
      }
    }

    return commands;
  }

  void requirePromotionInput() {
    p.board.pawnToPromote = p;
    // TODO
  }

  @override
  void redo(pos) {
    if (p.board.currentMove.notation.contains('=')) {
      // If the redone move has a promotion, skip call to Pawn.redo(), avoiding the promotion choice
      super.goTo(pos);
    } else {
      super.redo(pos);
    }
  }

  @override
  void updateValidMoves() {
    if (p.isCaptured) return;

    p.validMoves.clear();
    p.antiking.clear();

    for (List<int> move in moves) {
      Position pos;
      try {
        pos = Position.fromRowCol(p.board, row: p.row + move[0], col: p.col + move[1]);
      } catch (e) {
        continue;
      }

      Piece? blocker = p.board.get(pos);
      if (blocker == null) {
        p.validMoves.add(pos);
      } else if (blocker.id == 'y' && !p.dynamited) {
        p.validMoves.add(pos);
        break;
      } else {
        break;
      }
    }

    for (List<int> attack in attackingMoves) {
      Position pos;
      try {
        pos = Position.fromRowCol(p.board, row: p.row + attack[0], col: p.col + attack[1]);
      } catch (e) {
        continue;
      }

      p.antiking.add(pos);

      Piece? blocker = p.board.get(pos);
      if (blocker == null) {
        Position? enPassant;
        if (p.board.lastMove != null) {
          enPassant = p.board.lastMove!.enPassant;
        } else {
          enPassant = p.board.startFEN.enPassant;
        }

        if (enPassant != null && enPassant == pos) {
          p.validMoves.add(pos);
        }
      } else if (blocker.color != p.color) {
        p.validMoves.add(pos);
      }
    }
  }
}

class _Phantom extends PieceIdentity {
  @override
  final String id = 'f';
  @override
  final List<List<int>> moves = [];

  _Phantom(Piece container) : super(container) {
    container._phantomized = true; // set once for all
  }
}

class _Queen extends RollingPiece {
  @override
  final String id = 'q';
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
  final String id = 'r';
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
  final String id = 's';
  @override
  final List<List<int>> moves;
  @override
  final int range = 2; // TODO : check if working

  // TODO : final Dog linkedPiece; ?
  final int promotionRow;

  _Soldier(super.container)
      : promotionRow = container.color == 'w' ? 0 : 9,
        moves = container.color == 'w'
            ? [
                [-1, 1],
                [-1, -1]
              ]
            : [
                [1, 1],
                [1, -1]
              ];

  @override
  bool canGoTo(Position pos) {
    Piece? piece = p.board.get(pos);
    if (piece == null) {
      return true;
    } else if (piece.id == 'y') {
      return piece.color == p.color && dynamitables.contains(id) && !p.dynamited;
    } else {
      return piece.color != p.color && piece.id == 'p'; // the soldier only captures pawns
    }
  }

  @override
  List<Command> capture(Piece capturer) {
    List<Command> commands = super.capture(capturer);

    // If this is the phantom of the soldier
    if (p.phantomized) return commands;

    if (!p.linkedPiece!.isCaptured) {
      // If the dog is still alive when the soldier is captured
      commands.add(Transform(p.linkedPiece!, 'd', 'c'));
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

    if (p.linkedPiece == null) {
      // If this is the phantom of the soldier
      if (p.row == promotionRow) {
        commands.add(Transform(p, id, 'e'));
      }
      return commands;
    }

    if (p.row == promotionRow) {
      commands.add(Transform(p, id, 'e'));
      commands.add(Transform(p.linkedPiece!, p.linkedPiece!.id, 'c'));
    }

    if (dogIsTooFar(p.pos, p.linkedPiece!.pos)) {
      commands.add(Extra(p.linkedPiece!.pos, getNewDogPos(oldPos, p.pos)));
    }

    return commands;
  }

  @override
  void updateValidMoves() {
    super.updateValidMoves();
    p.antiking.clear(); // only captures pawns, can't capture a king
  }
}

Map<String, Function(Piece piece)> identitiyConstructors = {
  'b': (Piece piece) => _Bishop(piece),
  'c': (Piece piece) => _EnragedDog(piece),
  'd': (Piece piece) => _Dog(piece),
  'e': (Piece piece) => _EliteSoldier(piece),
  'f': (Piece piece) => _Phantom(piece),
  'g': (Piece piece) => _Grapple(piece),
  'k': (Piece piece) => _King(piece),
  'n': (Piece piece) => _Knight(piece),
  'p': (Piece piece) => _Pawn(piece),
  'q': (Piece piece) => _Queen(piece),
  'r': (Piece piece) => _Rook(piece),
  's': (Piece piece) => _Soldier(piece),
  'y': (Piece piece) => _Dynamite(piece),
};

bool inCheck(Piece king, {required bool dontCareAboutPhantoms}) {
  if (king.id != 'k') throw ArgumentError.value(king, 'The argument of inCheck must be a king');
  return (king._identity as _King).posIsUnderCheck(king.pos, dontCareAboutPhantoms: dontCareAboutPhantoms);
}

/*
class Bishop extends Piece {
  static String ID = 'b';
  static List<List<int>> MOVES = [
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];

  Bishop(super.board, super.color, super._pos);
}

class Dog extends Piece {
  static String ID = 'd';
  static List<List<int>> MOVES = [];

  Dog(super.board, super.color, super._pos);
}

class Dynamite extends Piece {
  static List<String> DYNAMITABLES = ["p", "n", "b", "d", "s"];
  static String ID = 'y';
  static List<List<int>> MOVES = [];

  Dynamite(super.board, super.color, super._pos);
}

class EliteSoldier extends Piece {
  static String ID = 'e';
  static List<List<int>> MOVES = [
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];

  EliteSoldier(super.board, super.color, super._pos);
}

class EnragedDog extends Piece {
  static String ID = 'c';
  static List<List<int>> MOVES = [
    [0, 1],
    [0, -1],
    [1, 0],
    [-1, 0],
  ];

  EnragedDog(super.board, super.color, super._pos);
}

class Grapple extends Piece {
  static String ID = 'g';
  static List<List<int>> MOVES = [
    [0, 1],
    [0, -1],
    [1, 0],
    [-1, 0],
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];

  Grapple(super.board, super.color, super._pos);
}

class King extends Piece {
  static String ID = 'k';
  static List<List<int>> MOVES = [
    [0, 1],
    [0, -1],
    [-1, 1],
    [-1, 0],
    [-1, -1],
    [1, 1],
    [1, 0],
    [1, -1],
  ];

  King(super.board, super.color, super._pos);

  Rook? getRookAt(String side) {
    if (hasMoved()) return null;

    Piece? piece;

    if (side == 'left') {
      piece = board.get(Position.fromRowCol(board, row: row, col: col - 4));
    } else if (side == 'right') {
      piece = board.get(Position.fromRowCol(board, row: row, col: col + 3));
    } else {
      throw ArgumentError.value(side,
          'The argument of King.getRookAt() should be \'left\' or \'right\'.');
    }

    return piece is Rook ? piece : null;
  }
}

class Knight extends Piece {
  static String ID = 'n';
  static List<List<int>> MOVES = [
    [2, 1],
    [2, -1],
    [-2, 1],
    [-2, -1],
    [1, 2],
    [1, -2],
    [-1, 2],
    [-1, -2],
  ];

  Knight(super.board, super.color, super._pos);
}

class Pawn extends Piece {
  static String ID = "p";
  static List<List<int>> MOVES =
      []; // real implementation is in Pawn.preciseTransform()

  Pawn(super.board, super.color, super._pos) {
    preciseTransform(this);
  }

  @override
  void preciseTransform(Piece piece) {
    if (piece.color == 'b') {
      piece.moves = [
        [1, 0],
        [2, 0],
      ];
      piece.attackingMoves = [
        [1, 1],
        [1, -1],
      ];
      piece.promotionRank = 9;
    } else {
      piece.moves = [
        [-1, 0],
        [-2, 0],
      ];
      piece.attackingMoves = [
        [-1, 1],
        [-1, -1],
      ];
      piece.promotionRank = 0;
    }
  }
}

class Phantom extends Piece {
  static String ID = 'f';
  static List<List<int>> MOVES = [];

  Phantom(super.board, super.color, super._pos);

  @override
  void preciseTransform(Piece piece) {
    if (piece is Phantom) {
      piece.trueId = Phantom.ID;
    }
  }
}

class Queen extends Piece {
  static String ID = 'q';
  static List<List<int>> MOVES = [
    [0, 1],
    [0, -1],
    [1, 0],
    [-1, 0],
    [1, 1],
    [1, -1],
    [-1, 1],
    [-1, -1],
  ];

  Queen(super.board, super.color, super._pos);
}

class Rook extends Piece {
  static String ID = 'r';
  static List<List<int>> MOVES = [
    [0, 1],
    [0, -1],
    [1, 0],
    [-1, 0],
  ];

  Rook(super.board, super.color, super._pos);
}

class Soldier extends Piece {
  static String ID = 's';
  static List<List<int>> MOVES =
      []; // real implementation is in Soldier.preciseTransform()

  Soldier(super.board, super.color, super._pos);
}
*/