part of iratus_game;

/// A description of a piece move and all its consequences.
abstract class Move {
  // Private fields
  int _capturesCounter = 0;
  final List<Command> _commands = [];
  int _counter50rule = 0;
  Position? _enPassant;
  late final FEN _fen;
  bool _isLocked = false;
  final Map<String, ExtraMove> _legalSecondMoves = {};
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
  String get nextTurn => _nextTurn;
  String get notation => _notation;

  /// Return true if the move is incomplete.
  ///
  /// 2 cases :
  ///   - when a pawn reaches the end of the board, we wait for a promotion id.
  ///   - when a piece moving twice makes a first move, we wait for the second move.
  bool get waitingForInput => _waitingForPromotion || _waitingForSecondMove;

  // Final fields
  /// A representation of all the squares where the king of the current player can go or not.
  ///
  /// ```dart
  /// Piece currentKing = board.king[board.turn]!;
  /// if (move.antiking[currentKing.pos.index] == true) {
  ///   print('In check');
  /// }
  /// ```
  late final List<bool> antiking;
  final Board board;
  final Map<String, List<String>> capturedPieces = {
    'w': [],
    'b': []
  }; // just for materialistic eval
  final Position end;
  late final bool isLegal;
  final List<Function> notationTransformations = [];
  final Piece piece;
  final Position start;
  late final String turn;
  late int turnNumber;
  late final List<String> validInputs;

  Move(this.board, this.start, this.end)
      : antiking = List.filled(board.nbcols * board.nbrows, false),
        piece = board.getPiece(start)! {
    board._currentMove = this;

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

    final Piece? captured = board.getPiece(end);
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

  /// Defines whether this move is legal or not.
  void _initIsLegal() {
    // A promotion changes neither the position of pieces nor the valid moves of enemies.
    // Therefore, we do not take it into account.

    if (_waitingForSecondMove) {
      // If the move is waiting for a second move, we need to simulate every possible input.

      // First, we iterate through the valid second moves.
      for (Position validMove in piece.identity.getValidMoves()) {
        // We simulate the second move.
        Extra secondMoveCommand = Extra(piece.pos, validMove);
        executeCommand(secondMoveCommand);
        if (secondMoveCommand.move.isLegal) {
          // We validate the second move.
          _legalSecondMoves[secondMoveCommand.move.notation] =
              secondMoveCommand.move;
        }
        // We undo the simulation.
        secondMoveCommand.move.undoCommands();
        _commands.remove(secondMoveCommand);
      }
      // If one input doesn't leave the king in check, the first move is legal.
      isLegal = _legalSecondMoves.isNotEmpty;
      return;
    }

    // We update the enemies antiking squares.
    for (Piece enemy in board.piecesColored[piece.enemyColor]!) {
      // Captured pieces can't check.
      if (enemy.isCaptured) continue;

      // // A phantom's antiking squares can change after a capture.
      // // But here, the move has been made, so, if there was a capture,
      // // the enemy phantom has its final antiking squares.
      // // Therefore, we do not skip Phantom.updateAntiking().

      // Update antiking
      enemy.identity.updateAntiking(antiking);

      // A king can't capture a dynamited piece.
      if (enemy.dynamited) {
        antiking[enemy.pos.index] = true;
      }
    }

    // If the king is not on an enemy's antiking square, the move is legal.
    isLegal = !inCheck(board.king[turn]!, antiking: antiking);
  }

  void _initNotation() {
    /* 
    Iratus Notation Documentation

    All standart chess notation still apply.


      PHANTOM

    When a phantom moves, we note the symbol '~' after the id of the phantomized
    piece.

    Ex : Q~xe4       <- a phantomized queen captured a piece on e4
    Ex : Sc~xe4      <- a phantomized soldier, from c file, captured a piece on e4


      SOLDIER

    A dog state is never shown from a soldier notation.

    When a soldier moves, the movement of the dog is inferred.
    When the soldier is captured, the dog's rage isn't noted either.

    When a soldier promotes to an elite soldier, the characters '=E' are added at
    the end of the notation.

    Ex : Sg9=E       <- a soldier promoted to elite soldier on g9


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

    If the grappled chose a dynamited piece, they both explode.

    Ex : G:Dg2->*     <- a grapple pulled a dog from g2 and they exploded


      PIECE MOVING TWICE

    A piece moving twice has its two moved noted, separated by a hyphen.

    Ex : Ce4-Cxf4    <- an enraged dog when to e4, then captured a piece on f4

    */
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
          for (final validMove in ally.identity.getValidMoves()) {
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
      validInputs = _legalSecondMoves.keys.toList();
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
      // A main move notation is wrote after we gathered all the legal moves,
      // in order to solve ambiguous.
      if (this is ExtraMove) _initNotation();
      _initCapturedPieces();
      _initIsLegal();
      _initValidInputs();
      if (!waitingForInput) {
        // If not waiting for an input, the move is complete.
        lock();
      }
    } else if (command is Notation) {
      _notation = command.notation;
    } else if (command is NotationTransform) {
      notationTransformations.add(command.transform);
    } else if (command is RequirePromotion) {
      _waitingForPromotion = true;
      _nextTurn = piece.color;
    } else if (command is RequireAnotherMove) {
      if (this is! MainMove) {
        throw Exception(
            'A piece cannot move twice if it started moving because of another piece.');
      }
      _waitingForSecondMove = true;
      _nextTurn = piece.color;
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
        throw ArgumentError.value(notation,
            'A promotion notation must be in the format \'=\' + id (upper case)');
      }

      executeCommand(Transform(piece, 'p', notation[1].toLowerCase()));
      _notation += notation.toUpperCase();

      _waitingForPromotion = false;
      _nextTurn = piece.enemyColor;
      lock();
    } else {
      if (!_waitingForSecondMove) {
        throw Exception(
            'Can\'t call the input method if the move is not waiting for input.');
      }

      ExtraMove secondMove = _legalSecondMoves[notation]!;
      Extra extra = Extra(secondMove.start, secondMove.end);
      extra.move = secondMove;
      _commands.add(extra);
      secondMove.redoCommands();

      _notation = '$_notation-${secondMove._notation}';

      _waitingForSecondMove = false;
      _nextTurn = piece.enemyColor;
      lock();

      // _commands.removeWhere((command) => command is Extra && _legalSecondMoves.values.contains(command.move));
    }
  }

  /// Called when the move is finally completed. The fields of the move shouldn't change anymore.
  void lock() {
    _isLocked = true;
    _fen = board.getFEN();
  }

  void redoCommands() {
    board._currentMove = this;
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

/// A move played by the player, it can create extra moves.
class MainMove extends Move {
  MainMove(super.board, super.start, super.end) {
    board._mainCurrentMove = this;
    executeCommand(Main());
  }

  @override
  void redoCommands() {
    board._mainCurrentMove = this;
    super.redoCommands();
  }
}

/// A move automatically played because of a MainMove.
///
/// Example : when the soldier moves, the dog's movement is an ExtraMove.
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
  late ExtraMove move;

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
