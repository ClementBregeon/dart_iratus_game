import 'fen.dart';
import 'game.dart';

/// An object representating an Iratus game.
///
/// Date format : YYYY.MM.DD
///
/// Result possible values :
///   - '1-0' :      white wins
///   - '0-1' :      black wins
///   - '1/2-1/2' :  drawn game
///   - '*' :        game still in progress, game abandoned, or result otherwise unknown
class PGN {
  /// The string storing the game
  late final String pgn;

  /// Tag pairs for meta-data about the game
  final Map<String, String> tagPairs = {};

  /// movetext describes the actual moves of the game
  late final String moveText;

  PGN(Game game) {
    // tags
    tagPairs['Event'] = 'Casual game';
    tagPairs['Site'] = 'iratus.fr';
    tagPairs['Date'] = '${game.date.year}.${game.date.month}.${game.date.day}';
    tagPairs['Time'] = '${game.date.hour}.${game.date.minute}.${game.date.second}';
    tagPairs['White'] = game.player['w']!.formattedName;
    tagPairs['Black'] = game.player['b']!.formattedName;

    // Result
    switch (game.result) {
      case 0: // game in progress
      case 9: // game interrupted
        tagPairs['Result'] = '*';
        break;
      case 1: // checkmate
      case 2: // resignation
      case 3: // time out
        if (game.winner == 2) {
          // white won
          tagPairs['Result'] = '1-0';
        } else if (game.winner == 3) {
          tagPairs['Result'] = '0-1';
        } else {
          throw ArgumentError(game.winner, 'The game has a winner but it is not defined');
        }
        break;
      case 4: // stalemate
      case 5: // draw by mutual agreement
      case 6: // draw by repetition
      case 7: // draw by insufficient material
      case 8: // draw by 50-moves rule
        tagPairs['Result'] = '1/2-1/2';
    }

    // FEN & SetUp
    if (game.board.startFEN.fen != IratusFEN.start) {
      tagPairs['SetUp'] = '1';
      tagPairs['FEN'] = game.board.startFEN.fen;
    }

    // Variant
    if (game is IratusGame) {
      tagPairs['Variant'] = 'Iratus';
    }

    // moveText
    if (game.board.movesHistory.isNotEmpty) {
      int turnNumber = game.board.startFEN.turnNumber;
      List<String> mtList = ['$turnNumber.'];
      String lastColor = '';
      // Move? lastMove = game.board.movesHistory.isNotEmpty ? game.board.movesHistory.last : null;
      for (Move move in game.board.movesHistory) {
        if (move.turn == lastColor) {
          if ('0123456789'.contains(mtList.last[0])) {
            mtList[mtList.length - 2] = '${mtList[mtList.length - 2]}-${move.notation}';
            if (move == game.board.lastMove) {
              // The first black move added turn number to mtList, but the second black move
              // is the last move of the game. So we delete it.
              mtList.removeLast();
            }
          } else {
            mtList.last = '${mtList.last}-${move.notation}';
          }
        } else {
          mtList.add(move.notation);
        }
        lastColor = move.turn;
        if (move.turnNumber > turnNumber && move != game.board.lastMove) {
          turnNumber = move.turnNumber;
          mtList.add('$turnNumber.');
        }
      }
      if (game.result > 0) {
        mtList.add(tagPairs['Result']!);
      }
      moveText = mtList.join(' ');
    } else {
      moveText = '';
    }

    pgn = '${tagPairs.entries.map((entry) => '[${entry.key} "${entry.value}"]').join('\n')}\n\n$moveText';
  }

  @override
  String toString() {
    return pgn;
  }
}
