library iratus_game;

import 'models.dart';
import 'pgn.dart';
import 'position.dart';

part 'board.dart';
part 'fen.dart';
part 'move.dart';
part 'piece.dart';
part 'utils.dart';

/// A chess player, regardless of the variant.
class Player {
  final Side color;
  final String name;

  /// Return the name, formatted for PGN's player name tag.
  String get formattedName => name;

  Player(this.color, this.name);
}

/// An abstract representation of chess games.
abstract class Game {
  // Protected fields, with getters
  int _result = 0;
  int _winner = 0;

  /// The board of the game.
  Board get board;

  /// The starting date for the game.
  final DateTime date = DateTime.now();

  /// The players engaged in this game.
  ///
  /// ```dart
  /// Player white = game.player[Side.white];
  /// ```
  final Map<Side, Player> player = {
    Side.white: Player(Side.white, 'Winston'),
    Side.black: Player(Side.black, 'Bellucci')
  };

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

  /// The winner of the game.
  ///
  /// Possible values :
  ///   - 0 : game in progress
  ///   - 1 : draw
  ///   - 2 : white won
  ///   - 2 : black won
  int get winner => _winner;

  /// Update result & winner.
  void _checkForEnd() {
    if (board.movesHistory.isEmpty) return;
    if (_result > 0) throw ArgumentError('The game has already ended');

    void updateResult() {
      if (board.king[Side.white] == null || board.king[Side.black] == null) {
        return; // can't stop a game if a king is missing
      }

      Map<Side, List<Piece>> remainingPieces = {Side.white: [], Side.black: []};

      for (Piece piece in board.pieces) {
        if (!piece.isCaptured) {
          if (piece.id == Role.king) {
            continue;
          }
          remainingPieces[piece.color]!.add(piece);
        }
      }

      List<Role> cantMateAlone = [
        Role.bishop,
        Role.eliteSoldier,
        Role.knight,
      ];

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

      if (insufficient(remainingPieces[Side.white]!) &&
          insufficient(remainingPieces[Side.black]!)) {
        _result = 7; // draw by insufficient material
        _winner = 1; // draw
        return;
      }

      if (board.movesHistory.length > 6) {
        Move lastMove = board.lastMove!;
        String currentFenEqualizer = lastMove.fenEqualizer;
        int count = 1;

        if (currentFenEqualizer == board.startFEN.fenEqualizer) {
          count += 1;
        }

        for (Move move in board.movesHistory) {
          if (move == lastMove) {
            continue;
          }
          if (currentFenEqualizer == move.fenEqualizer) {
            count += 1;
          }
        }

        // Note : currently, the three time repetion
        // does not include the start position
        if (count == 3) {
          _result = 6; // draw by repetition
          _winner = 1; // draw
          return;
        }
      }

      if (board.validNotations.isNotEmpty) {
        if (board.movesHistory.isNotEmpty &&
            board.movesHistory.last.counter50rule > 100) {
          _result = 8; // draw by 50-moves rule
          _winner = 1; // draw
          return;
        }
        return; // game in progress
      }

      // if this code is executed, it means the current player has to legal move
      Piece currentKing = board.king[board.turn]!;
      if (inCheck(currentKing)) {
        _result = 1; // checkmate
        _winner = board.turn == Side.black ? 2 : 3; // ... won
      } else {
        _result = 4; // stalemate
        _winner = 1; // draw
      }
    }

    updateResult();

    if (_result == 1) {
      board.lastMove!._notation += '#';
    } else if (inCheck(board.king[board.turn]!)) {
      board.lastMove!._notation += '+';
    }
  }

  /// Return a PGN object, representating the game.
  PGN getPGN();

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
  ///
  /// We don't require check and mate symbol, in order to let the player evaluate the move by himself.
  /// The promotion and the second move of a piece moving twice are inputs given after a first move.
  void move(String notation) {
    if (_result > 0) throw ArgumentError('The game has already ended');

    board._move(notation);

    if (board.lastMove!.waitingForInput) {
      // wait for promotion input or second move
      return;
    }

    _checkForEnd();
  }

  /// Redo the last undone move.
  void redo() {
    board._redo();
  }

  /// Redo all the undone moves.
  void redoAll() {
    while (board._backMovesHistory.isNotEmpty) {
      redo();
    }
  }

  /// The player designed by the color resigns.
  void resign(Side color) {
    if (_result > 0) throw ArgumentError('The game has already ended');

    _result = 2;
    _winner = color == Side.white ? 3 : 2;
  }

  /// Undo the last move played.
  void undo() {
    board._undo();
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
  }

  /// Initialize an Iratus game from a fen string.
  ///
  /// For more details about the fen notation for Iratus, see [IratusFEN].
  IratusGame.fromFEN(String fen) {
    board = IratusBoard(fen, this);
  }

  /// Initialize an Iratus game from the moves noted in a pgn string.
  ///
  /// For more details about the pgn notation for Iratus, see [IratusPGN].
  IratusGame.fromPGN(String pgnString) {
    PGN pgn = IratusPGN.fromString(pgnString);

    // player names
    String? whiteName = pgn.tagPairs['White'];
    if (whiteName != null) player[Side.white] = Player(Side.white, whiteName);
    String? blackName = pgn.tagPairs['Black'];
    if (blackName != null) player[Side.black] = Player(Side.black, blackName);

    // board initialization
    String? startFen = pgn.tagPairs['FEN'];
    board = IratusBoard(startFen ?? IratusFEN.start, this);

    // moves
    List<String> moves = pgn.moveText
        .split(' ')
        .where((e) => e.isNotEmpty && !'0123456789*.'.contains(e[0]))
        .toList();

    for (String moveNotation in moves) {
      moveNotation = moveNotation.replaceAll(RegExp(r'[+#]$'), '');
      if (moveNotation.contains('=')) {
        List<String> splitted = moveNotation.split('=');
        move(splitted[0]);
        move('=${splitted[1]}');
      } else if (moveNotation.contains('-')) {
        List<String> splitted = moveNotation.split('-');
        move(splitted[0]);
        move(splitted[1]);
      } else {
        move(moveNotation);
      }
    }
  }

  @override
  IratusPGN getPGN() {
    return IratusPGN(this);
  }
}
