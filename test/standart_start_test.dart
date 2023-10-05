import 'package:iratus_game/src/game.dart';
import 'package:test/test.dart';

void main() {
  var game = IratusGame();
  var board = game.board;

  test('Game is properly initialized', () {
    expect(board.movesHistory.isEmpty, true);
    expect(board.turn == 'w', true);
    expect(game.result == 0, true);
    expect(game.winner == 0, true);
  });

  test('IratusBoard is properly initialized', () {
    expect(board.nbcols == 8, true);
    expect(board.nbrows == 10, true);
    expect(board.pieces.length == 48, true);
  });

  test('Colors should work as intended', () {
    expect(board.piecesColored['w']![0].color == 'w', true);
    expect(board.piecesColored['b']![0].color == 'b', true);
  });

  // TODO : PUZZLES
  // Tonado pawns
  // 8/8/2k5/P7/8/2K5/8/8/8/8 w - - - 1- 1 60 => a7 (to prevent the king from touching the a9 square)
}
