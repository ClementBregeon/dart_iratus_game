part of iratus_game;

abstract class Move {
  // Private fields
  int _capturesCounter = 0;
  final List<Command> _commands = [];
  int _counter50rule = 0;
  Position? _enPassant;
  bool _movingAgain = false; // true if the moved piece has to move again
  late String _nextTurn;
  String _notation = '';

  // Getters
  List<Command> get commands => _commands;
  int get counter50rule => _counter50rule;
  Position? get enPassant => _enPassant;
  bool get movingAgain => _movingAgain;
  String get nextTurn => _nextTurn;
  String get notation => _notation;

  // Final fields
  final Board board;
  final Position start;
  final Position end;
  final Piece piece;
  final Map<String, List<String>> capturedPieces = {'w': [], 'b': []}; // just for materialistic eval
  final List<String> notationHints = [];
  late final String turn;
  late int turnNumber;

  Move(this.board, this.start, this.end) : piece = board.get(start)! {
    board.currentMove = this;

    _nextTurn = piece.enemyColor;
    turn = piece.color;

    final String lastMoveTurn;
    final int lastMoveCounter50rule;
    final int lastMoveTurnNumber;
    if (board.lastMove == null) {
      lastMoveTurn = _nextTurn;
      lastMoveCounter50rule = board.startFEN.counter50rule;
      lastMoveTurnNumber = board.startFEN.turnNumber;
    } else {
      Move lastMove = board.lastMove!;
      lastMoveTurn = lastMove.turn;
      lastMoveCounter50rule = lastMove.counter50rule;
      lastMoveTurnNumber = lastMove.turnNumber;
    }

    if (lastMoveTurn != turn) {
      _counter50rule = lastMoveCounter50rule + 1;
      if (lastMoveTurn == "w") {
        turnNumber = lastMoveTurnNumber + 1;
      } else {
        turnNumber = lastMoveTurnNumber;
      }
    } else {
      // happens because of pieces moving twice
      _counter50rule = lastMoveCounter50rule;
      turnNumber = lastMoveTurnNumber;
    }

    final Piece? captured = board.get(end);
    if (captured != null && !cantCapture.contains(piece.id)) {
      executeCommand(Capture(captured, piece));
    }

    if (piece.id == 'p') {
      _counter50rule = 0;
    }
  }

  void _executeCommands(List<Command> commandsToExecute) {
    for (final command in commandsToExecute) {
      executeCommand(command);
    }
  }

  void _initCapturedPieces() {
    // Captured pieces display
    if (board.calculator != null) {
      for (final command in _commands) {
        if (command is Capture) {
          final Piece capturedPiece = command.args[0];
          if (capturedPiece.id == 'y') {
            continue;
          } // dynamite equipment
          capturedPieces[capturedPiece.color]!.add(capturedPiece.id);
          if (capturedPiece.dynamited) {
            capturedPieces[capturedPiece.color]!.add('y');
          }
        }
      }
    }
  }

  void _initNotation() {
    if (_notation != '') {
      return;
    }

    var nIP = ''; // notation in progress

    // piece name
    // A pawn's phantom move is written P~d4
    if (piece.id != 'p' || piece.phantomized) {
      nIP += piece.id.toUpperCase();
    }

    // Phantom notation
    if (piece.phantomized) {
      nIP += '~';
    }

    // Two pieces that can access the same square, and therefore, sometimes,
    // the notation needs clarification
    String trueId(Piece piece) {
      return piece.phantomized ? 'f' : piece.id;
    }

    final String pieceTrueId = trueId(piece);
    if (competitivePieces.contains(pieceTrueId)) {
      final sameTypeAllies = <Piece>[];
      for (final ally in board.piecesColored[piece.color]!) {
        if (trueId(ally) == pieceTrueId && ally != piece) {
          sameTypeAllies.add(ally);
        }
      }
      if (sameTypeAllies.isNotEmpty) {
        final List<Piece> competitiveAllies = [];
        for (final ally in sameTypeAllies) {
          for (final validMove in ally.validMoves) {
            if (end == validMove) {
              competitiveAllies.add(ally);
            }
          }
        }
        final int competitiveAlliesLength = competitiveAllies.length;
        if (competitiveAlliesLength == 1) {
          if (start.col == competitiveAllies[0].col) {
            nIP += start.coord[1];
          } else {
            nIP += start.coord[0];
          }
        } else if (competitiveAlliesLength > 1) {
          var sameCol = false;
          var sameRow = false;
          for (final ally in competitiveAllies) {
            if (ally.col == start.col) {
              sameCol = true;
            }
            if (ally.row == start.row) {
              sameRow = true;
            }
          }
          if (!sameCol) {
            nIP += start.coord[0];
          } else if (!sameRow) {
            nIP += start.coord[1];
          } else {
            nIP += start.coord;
          }
        }
      }
    }

    // captures
    if (_capturesCounter > 0) {
      if (piece.id == 'p') {
        nIP += start.coord[0];
      }
      if (commands.any((element) => element is SetDynamite)) {
        nIP += '+';
      } else {
        nIP += 'x';
      }
    }

    // coordinates
    nIP += end.coord;

    // hints
    for (final String hint in notationHints) {
      nIP += hint;
    }

    _notation = nIP;
  }

  void executeCommand(Command command) {
    final args = command.args;
    switch (command.name) {
      case "capture":
        _capturesCounter += 1;
        _counter50rule = 0;
        _commands.add(command);
        _executeCommands(args[0].identity.capture(args[1]));
        break;
      case "extra":
        final extra = ExtraMove(board, args[0], args[1]);
        extra.turnNumber = turnNumber;
        command.args = [extra];
        _commands.add(command);
        break;
      case "main":
        _commands.add(command);
        _executeCommands(piece.identity.goTo(end));
        _initNotation();
        _initCapturedPieces();
        break;
      case "notation":
        _notation = args[0];
        break;
      case "notationHint":
        notationHints.add(args[0]);
        break;
      case "setDynamite":
        _commands.add(command);
        args[0].setDynamite(true);
        break;
      case "setEnPassant":
        _enPassant = args[0];
        break;
      case "setMovingAgain":
        _nextTurn = args[0].color;
        _movingAgain = true;
        break;
      case "transform":
        _commands.add(command);
        args[0].transform(args[2]);
        break;
      default:
        throw Error();
    }
  }

  void redoCommands() {
    board.currentMove = this;
    for (final command in _commands) {
      switch (command.name) {
        case "extra":
          command.args[0].redoCommands();
          break;
        case "capture":
          command.args[0].capture(command.args[1]);
          break;
        case "main":
          piece.identity.redo(end);
          break;
        case "setDynamite":
          command.args[0].setDynamite(true);
          break;
        case "transform":
          command.args[0].transform(command.args[2]);
          break;
      }
    }
  }

  void undoCommands() {
    for (final Command command in _commands.reversed) {
      switch (command.name) {
        case "extra":
          command.args[0].undoCommands();
          break;
        case "capture":
          command.args[0].uncapture();
          break;
        case "main":
          piece.identity.undo(this);
          break;
        case "setDynamite":
          command.args[0].setDynamite(false);
          break;
        case "transform":
          command.args[0].transform(command.args[1]);
          break;
      }
    }
  }

  @override
  String toString() {
    return notation;
  }
}

class MainMove extends Move {
  MainMove(super.board, super.start, super.end) {
    board.mainCurrentMove = this;
    executeCommand(Main());
  }

  @override
  void redoCommands() {
    board.mainCurrentMove = this;
    super.redoCommands();
  }
}

class ExtraMove extends Move {
  ExtraMove(super.board, super.start, super.end) {
    executeCommand(Main());
  }
}

abstract class Command {
  final String name;
  List<dynamic> args;

  Command(this.name, this.args);
}

class Capture extends Command {
  Capture(Piece captured, Piece capturer) : super('capture', [captured, capturer]);
}

class Extra extends Command {
  Extra(Position start, Position end) : super('extra', [start, end]);
}

class Main extends Command {
  Main() : super('main', []);
}

class Notation extends Command {
  Notation(String notation) : super('notation', [notation]);
}

class NotationHint extends Command {
  NotationHint(String hint) : super('notationHint', [hint]);
}

class SetDynamite extends Command {
  SetDynamite(Piece piece) : super('setDynamite', [piece]);
}

class SetEnPassant extends Command {
  SetEnPassant(Position pos) : super('setEnPassant', [pos]);
}

class SetMovingAgain extends Command {
  SetMovingAgain(Piece piece) : super('setMovingAgain', [piece]);
}

class Transform extends Command {
  Transform(Piece piece, String oldId, String newId) : super('transform', [piece, oldId, newId]);
}
