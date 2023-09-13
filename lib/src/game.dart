library iratus_game;

// import 'board.dart';
import 'fen.dart';
import 'pgn.dart';
import 'piece.dart';
import 'position.dart';
import 'utils.dart';

part 'board.dart';
part 'move.dart';

/// A chess player, regardless of the variant.
class Player {
  final String color;
  final String name;

  /// Return the name, formatted for PGN's player name tag.
  String get formattedName => name;

  Player(this.color, this.name) {
    if (!colors.contains(color)) throw ArgumentError.value(color, 'A Player color must be \'w\' or \'b\'');
  }
}

abstract class Game {
  // Protected fields, with getters
  int _result = 0;
  late String _turn;
  int _winner = 0;

  /// The board of the game.
  Board get board;

  /// The starting date for the game.
  final DateTime date = DateTime.now();

  /// The players engaged in this game.
  ///
  /// ```dart
  /// Player white = game.player['w'];
  /// ```
  final Map<String, Player> player = {'w': Player('w', 'Winston'), 'b': Player('b', 'Bellucci')};

  /// The color of the player who has to make the next move.
  ///
  /// Can be 'w' or 'b'.
  String get turn => _turn;

  /// The result of the game.
  ///
  /// Possible values :
  ///   - 0 : game in progress
  ///   - 1 : checkmate
  ///   - 2 : resignation
  ///   - 3 : time out
  ///   - 4 : stalemate
  ///   - 5 : draw by mutual agreement
  ///   - 6 : draw by repetition
  ///   - 7 : draw by insufficient material
  ///   - 8 : draw by 50-moves rule
  ///   - 9 : game interrupted
  int get result => _result;

  /// A help to understand the result field.
  ///
  /// ```dart
  /// String result = Game.resultDoc[game.result];
  /// print(result); // checkmate ?
  /// ```
  final List<String> resultDoc = [
    'game in progress',
    'checkmate',
    'resignation',
    'time out',
    'stalemate',
    'draw by mutual agreement',
    'draw by repetition',
    'draw by insufficient material',
    'draw by 50-moves rule',
    'game interrupted',
  ];

  /// The winner of the game.
  ///
  /// Possible values :
  ///   - 0 : game in progress
  ///   - 1 : draw
  ///   - 2 : white won
  ///   - 2 : black won
  int get winner => _winner;

  /// A help to understand the winner field.
  ///
  /// ```dart
  /// String winner = Game.winnerDoc[game.winner];
  /// print(result); // white won ?
  /// ```
  final List<String> winnerDoc = [
    'game in progress',
    'draw',
    'white won',
    'black won',
  ];

  /// Update result & winner.
  // TODO : merge with _updateResult()
  void _checkForEnd() {
    if (board.movesHistory.isEmpty) return;
    if (_result > 0) throw ArgumentError('The game has already ended');

    _updateResult();

    if (_result == 1) {
      board.movesHistory.last.addNotationHint('#');
    } else if (inCheck(board.king[turn]!, dontCareAboutPhantoms: false)) {
      board.movesHistory.last.addNotationHint('+'); // TODO : move to move.dart
    }
  }

  /// Update result & winner.
  void _updateResult() {
    if (board.king['w'] == null || board.king['b'] == null) {
      return; // can't stop a game if a king is missing
    }

    Map<String, List<Piece>> remainingPieces = {'w': [], 'b': []};

    for (Piece piece in board.pieces) {
      if (!piece.isCaptured) {
        if (piece.id == 'k') {
          continue;
        }
        remainingPieces[piece.color]!.add(piece);
      }
    }

    String cantMateAlone = 'ben';

    bool insufficient(List<Piece> set) {
      if (set.isEmpty) {
        return true;
      }
      if (set.length == 1) {
        return cantMateAlone.contains(set[0].id);
      }
      if (set.length == 2) {
        return set[0].id == set[1].id;
      }
      return false;
    }

    if (insufficient(remainingPieces['w']!) && insufficient(remainingPieces['b']!)) {
      _result = 7; // draw by insufficient material
      _winner = 1; // draw
      return;
    }

    if (board._fenHistory.length > 5) {
      FEN currentFEN = board._fenHistory.last;
      int count = 1;

      for (FEN fen in board._fenHistory) {
        if (currentFEN == fen) {
          continue;
        }
        if (currentFEN.fenEqualizer == fen.fenEqualizer) {
          count += 1;
        }
      }

      if (count == 3) {
        _result = 6; // draw by repetition
        _winner = 1; // draw
        return;
      }
    }

    for (Piece piece in board.piecesColored[turn]!) {
      if (!piece.isCaptured && piece.validMoves.isNotEmpty) {
        if (board.movesHistory.isNotEmpty && board.movesHistory.last.counter50rule > 100) {
          _result = 8; // draw by 50-moves rule
          _winner = 1; // draw
          return;
        }
        return; // game in progress
      }
    }

    // if this code is executed, it means the current player has to legal move
    Piece currentKing = board.king[turn]!;
    if (inCheck(currentKing, dontCareAboutPhantoms: false)) {
      _result = 1; // checkmate
      _winner = turn == 'b' ? 2 : 3; // ... won
    } else {
      _result = 4; // stalemate
      _winner = 1; // draw
    }
  }

  /// Board initialization, after the creation of the board.
  void _init() {
    _turn = board.startFEN.turn;
    board._fenHistory.add(board.startFEN); // TODO : move to Board
    board.updateAllValidMoves();
  }

  /// Return a PGN object, representating the game.
  PGN getPGN() {
    return PGN(this);
  }

  /// Immediately interrupt the game, ending in a draw.
  void interrupt() {
    _result = 9; // game interrupted
    _winner = 1; // draw
  }

  /// Move a piece, following the move notation.
  ///
  /// The argument is a light notation :
  ///   - no check symbol.
  ///   - no mate symbol.
  ///   - no promotion notation.
  ///   - if it moves a piece moving twice, only 1 move at a time.
  void move(String notation) {
    if (_result > 0) throw ArgumentError('The game has already ended');

    if (board.pawnToPromote != null) {
      if (!promotionValidNotations.contains(notation)) {
        throw ArgumentError.value(
            notation, 'A promotion notation must be in the format \'=\' + promotionId (upper case)');
      }
      board.lastMove!.executeCommand(Transform(board.pawnToPromote!, 'p', notation[1].toLowerCase()));
      board.lastMove!.executeCommand(NotationHint(notation.toUpperCase()));

      board.pawnToPromote = null;
      board._fenHistory.add(board.getFEN()); // TODO : move to Board
      board._backMovesHistory.clear(); // same
      _turn = board.lastMove!.nextTurn;
      board.updateAllValidMoves();
      _checkForEnd();

      return;
    }

    Move? calcMove = board.allValidMoves[notation];
    if (calcMove == null) {
      throw ArgumentError.value(notation, 'Unknown move');
    }

    Move currentMove = board._move(calcMove.start, calcMove.end, main: true);
    board.movesHistory.add(currentMove); // TODO : move to Board
    if (board.pawnToPromote == null) {
      _turn = currentMove.nextTurn;
      board._fenHistory.add(board.getFEN()); // TODO : move to Board
      board._backMovesHistory.clear(); // same
      board.updateAllValidMoves();
      _checkForEnd();
    }
  }

  /// Redo the last undone move.
  void redo() {
    if (board._backMovesHistory.isEmpty) {
      return;
    }

    Move lastUndoneMove = board._backMovesHistory.removeLast();

    board.redo(lastUndoneMove);
    board.movesHistory.add(lastUndoneMove);
    _turn = lastUndoneMove.nextTurn; // TODO : move turn to Board
    board.updateAllValidMoves();
    board._fenHistory.add(board.getFEN());
  }

  /// Redo all the undone moves.
  void redoAll() {
    while (board._backMovesHistory.isNotEmpty) {
      redo();
    }
  }

  /// Undo the last move played.
  void undo() {
    if (_result > 0) throw ArgumentError('Can\'t undo a move because the game has ended');

    if (board.movesHistory.isEmpty) {
      return;
    }

    Move lastMove = board.movesHistory.removeLast();
    board._backMovesHistory.add(lastMove);
    board._fenHistory.removeLast();
    board.undo(lastMove);
    _turn = lastMove.turn;
    board.updateAllValidMoves();
  }

  /// Undo all the moves played.
  void undoAll() {
    while (board.movesHistory.isNotEmpty) {
      undo();
    }
  }
}

/// A game with the rules of Iratus.
class IratusGame extends Game {
  @override
  late final Board board;

  /// Initialize a standart Iratus game.
  IratusGame() {
    board = IratusBoard(IratusFEN.start, this);
    _init();
  }

  /// Initialize an Iratus game from a fen string.
  ///
  /// For more details about the fen notation for Iratus, see [IratusFEN].
  IratusGame.fromFEN(String fen) {
    board = IratusBoard(fen, this);
    _init();
  }
}
