part of iratus_game;

abstract class Move {
  // Private fields
  int _capturesCounter = 0;
  final List<Command> _commands = [];
  int _counter50rule = 0;
  Position? _enPassant;
  late final FEN _fen;
  bool _isLocked = false;
  bool _movingAgain = false; // true if the moved piece has to move again
  late String _nextTurn;
  String _notation = '';
  bool _waitingForPromotion = false;
  bool _waitingForSecondMove = false;

  // Getters
  List<Command> get commands => _commands;
  int get counter50rule => _counter50rule;
  Position? get enPassant => _enPassant;
  String get fen => _fen.fen;
  String get fenEqualizer => _fen.fenEqualizer;
  FEN get fenObject => _fen;
  bool get movingAgain => _movingAgain; // TODO : remove ?
  String get nextTurn => _nextTurn;
  String get notation => _notation;

  /// Return true if the move is incomplete.
  ///
  /// 2 cases :
  ///   - when a pawn reaches the end of the board, we wait for a promotion id.
  ///   - when a piece moving twice makes a first move, we wait for the second move.
  bool get waitingForInput => _waitingForPromotion || _waitingForSecondMove; // TODO : rework

  // Final fields
  final Board board;
  final Map<String, List<String>> capturedPieces = {'w': [], 'b': []}; // just for materialistic eval
  final Position end;
  final List<Function> notationTransformations = [];
  final Piece piece;
  final Position start;
  late final String turn;
  late int turnNumber;
  late List<String> validInputs;

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
          final Piece capturedPiece = command.captured;
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
        if (!ally.isCaptured && trueId(ally) == pieceTrueId && ally != piece) {
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
    for (final Function notationTransform in notationTransformations) {
      nIP = notationTransform(nIP);
      // nIP += hint;
    }

    _notation = nIP;
  }

  void _initValidInputs() {
    if (_waitingForPromotion) {
      validInputs = promotionValidNotations;
    } else if (_waitingForSecondMove) {
      validInputs = []; // TODO
    } else {
      validInputs = [];
    }
  }

  void executeCommand(Command command) {
    if (_isLocked) {
      throw Exception('Can\'t modify a move once it is locked.');
    }

    if (command is Capture) {
      _capturesCounter += 1;
      _counter50rule = 0;
      _commands.add(command);
      _executeCommands(command.captured.identity.capture(command.capturer));
      return;
    } else if (command is Extra) {
      command.move = ExtraMove(board, command.start, command.end);
      command.move.turnNumber = turnNumber;
      _commands.add(command);
    } else if (command is Main) {
      _commands.add(command);
      _executeCommands(piece.identity.goTo(end));
      _initNotation();
      _initCapturedPieces();
      _initValidInputs();
    } else if (command is Notation) {
      _notation = command.notation;
    } else if (command is NotationTransform) {
      notationTransformations.add(command.transform);
    } else if (command is RequirePromotion) {
      _waitingForPromotion = true;
    } else if (command is RequireAnotherMove) {
      if (this is! MainMove) {
        throw Exception('A piece cannot move twice if it started moving because of another piece.');
      }
      _waitingForSecondMove = true;
      _nextTurn = piece.color;
      _movingAgain = true;
    } else if (command is SetDynamite) {
      _commands.add(command);
      command.piece.setDynamite(true);
    } else if (command is SetEnPassant) {
      _enPassant = command.pos;
    } else if (command is Transform) {
      _commands.add(command);
      command.piece.transform(command.newId);
    } else {
      throw ArgumentError.value(command, 'Unknown command');
    }
  }

  /// Called when the move for waitingForInput
  void input(String notation) {
    if (_waitingForPromotion) {
      if (!promotionValidNotations.contains(notation)) {
        throw ArgumentError.value(notation, 'A promotion notation must be in the format \'=\' + id (upper case)');
      }

      executeCommand(Transform(piece, 'p', notation[1].toLowerCase()));
      _notation += notation.toUpperCase();
      lock();
    } else {
      if (!_waitingForSecondMove) {
        throw Exception('Can\'t call the input method if the move is not waiting for input.');
      }
    }
  }

  /// Return whether this move is legal or not.
  /// Should only be called by a calculator.
  bool isLegal() {
    // This method is only designed for calculs.
    if (board is! CalculatorInterface) {
      throw Exception('A real move can\'t call isLegal()');
    }

    // A promotion changes neither the position of pieces nor the valid moves of enemies.
    // Therefore, we do not take it into account.

    // If the move is waiting for a second move, we need to simulate every possible input.
    // If one input doesn't leave the king in check, the first move is legal.
    if (_waitingForSecondMove) {
      // First, we update the valid second moves.
      piece.identity.updateValidMoves();

      for (Position validMove in piece.validMoves) {
        Extra secondMoveCommand = Extra(piece.pos, validMove);
        executeCommand(secondMoveCommand);

        // TODO : is this move legal ?
        // TODO : store second move for valid notation
      }
    }

    // We update the enemies antiking squares.
    for (Piece enemyClonedPiece in board.piecesColored[piece.enemyColor]!) {
      enemyClonedPiece.identity.updateValidMoves();
    }

    // If the king is not on an enemy's antiking square, the move is legal
    // There is no more move for this king's army anymore, so the phantoms won't change.
    return !inCheck(board.king[turn]!, dontCareAboutPhantoms: false);
  }

  /// Called when the move is finally completed. The fields of the move shouldn't change anymore.
  void lock() {
    _isLocked = true;
    _fen = board.getFEN();
  }

  void redoCommands() {
    board.currentMove = this;
    for (final command in _commands) {
      if (command is Extra) {
        command.move.redoCommands();
      } else if (command is Capture) {
        command.captured.identity.capture(command.capturer);
      } else if (command is Main) {
        piece.identity.redo(end);
      } else if (command is SetDynamite) {
        command.piece.setDynamite(true);
      } else if (command is Transform) {
        command.piece.transform(command.newId);
      }
    }
  }

  void undoCommands() {
    for (final Command command in _commands.reversed) {
      if (command is Extra) {
        command.move.undoCommands();
      } else if (command is Capture) {
        command.captured.uncapture();
      } else if (command is Main) {
        piece.identity.undo(this);
      } else if (command is SetDynamite) {
        command.piece.setDynamite(false);
      } else if (command is Transform) {
        command.piece.transform(command.oldId);
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

abstract class Command {}

class Capture extends Command {
  Piece captured;
  Piece capturer;

  Capture(this.captured, this.capturer);
}

class Extra extends Command {
  Position start;
  Position end;
  late Move move;

  Extra(this.start, this.end);
}

class Main extends Command {
  Main();
}

class Notation extends Command {
  String notation;
  Notation(this.notation);
}

class NotationTransform extends Command {
  FunctionWithStringParameter transform;
  NotationTransform(this.transform);
}

class RequirePromotion extends Command {
  RequirePromotion();
}

class RequireAnotherMove extends Command {
  RequireAnotherMove();
}

class SetDynamite extends Command {
  Piece piece;
  SetDynamite(this.piece);
}

class SetEnPassant extends Command {
  Position pos;
  SetEnPassant(this.pos);
}

class Transform extends Command {
  Piece piece;
  String oldId;
  String newId;

  Transform(this.piece, this.oldId, this.newId);
}
