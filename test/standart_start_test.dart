import 'package:iratus_game/src/game.dart';
import 'package:test/test.dart';

void main() {
  var game = IratusGame();
  var board = game.board;

  test('Game is properly initialized', () {
    expect(game.board.movesHistory.isEmpty, true);
    expect(game.turn == 'w', true);
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

  // FEN TESTS
  // All the pieces are at the same position
  // Turn is applied, even when a piece moving twice has to move again
  // Phantoms are correctly transformed
  // It is possible to have 0, 1 or more phantoms
  // Dynamited pieces are correctly dynamited
  // Linked pieces are correctly linked
  // Castle rights are correctly applied
  // Dynamitables.hasMoved() are kept the same
  // Counter50rule is used
  // TurnNumber is used

  // a pinned piece can't move
  // the king can eat the pawn but not go forward : k7/3r~4/2S(0)1S(1)3/2D(0)KD(1)3/2PpP3/8/8/8/8/8 w - - - 000000-0 0 10
  // promotion checkmate works ?
  // A king protects its pieces from the enemy king
  // fen_test.dart
  // pgn_test.dart
  // TODO : can a pawn capture en passant a promoted pawn ?
}
