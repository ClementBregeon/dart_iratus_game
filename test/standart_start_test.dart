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

  test('Board is properly initialized', () {
    expect(board.calculator != null, true);
    expect((board.calculator! as CalculatorIratusBoard).calculator == null, true);
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

  // TODO :
  // a pinned piece can't move
  // the king can eat the pawn but not go forward : k7/3r~4/2S(0)1S(1)3/2D(0)KD(1)3/2PpP3/8/8/8/8/8 w - - - 000000-0 0 10
  // game_end_test.dart

  // TODO : PUZZLES

  // Tonado pawns
  // 8/8/2k5/P7/8/2K5/8/8/8/8 w - - - 1- 1 60 => a7 (to prevent the king from touching the a9 square)
}
