import 'package:iratus_game/iratus_game.dart';
import 'package:test/test.dart';

void main() {
  // In this starting fen, there is two kings and a white pawn.
  // White to move and promote.
  String fen = '8/8/3P4/8/8/2K2k2/8/8/8/8 w - - - 1- 0 10';

  IratusGame game = IratusGame.fromFEN(fen);
  String oldTurn = game.turn;

  test('The game is waiting for the promotion input', () {
    game.move('d9');
    expect(game.board.pawnToPromote != null, true);
    expect(oldTurn == game.turn, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9'))!.id == 'p', true);
  });

  test('The promotion to a queen works', () {
    game.move('=Q');
    expect(game.board.pawnToPromote == null, true);
    expect(oldTurn != game.turn, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9'))!.id == 'q', true);
  });

  test('An undone promotion unmoves the pawn', () {
    game.undo();
    expect(game.board.pawnToPromote == null, true);
    expect(oldTurn == game.turn, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7'))!.id == 'p', true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9')) == null, true);
  });

  test('A redone promotion doesn\'t wait for promotion input', () {
    game.redo();
    expect(game.board.pawnToPromote == null, true);
    expect(oldTurn != game.turn, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9'))!.id == 'q', true);
  });
}
