import 'package:iratus_game/iratus_game.dart';
import 'package:test/test.dart';

void main() {
  // In this starting fen, there is two kings and a white enraged dog.
  // White to move twice.
  String fen = '8/8/3C4/8/8/2K2k2/8/8/8/8 w - - - 1- 0 1';

  IratusGame game = IratusGame.fromFEN(fen);
  String oldTurn = game.board.turn;

  test('After a piece moving twice has moved, it is the only piece who still has valid moves.', () {
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7'))!.id == 'c', true);
    expect(game.board.validNotations.join(', ') == 'Ce7, Cc7, Cd6, Cd8, Kd4, Kb4, Kd5, Kc5, Kb5, Kd3, Kc3, Kb3', true);

    game.move('Cd6');

    expect(game.board.lastMove!.notation == 'Cd6', true);
    expect(game.getPGN().moveText == '1. Cd6', true);
    expect(oldTurn == game.board.turn, true);
    expect(game.board.validNotations.join(', ') == 'Ce6, Cc6, Cd5, Cd7', true);
  });

  test('After a piece moving twice has moved twice, the enemies can move.', () {
    game.move('Ce6');

    expect(game.board.lastMove!.notation == 'Ce6', true);
    expect(game.getPGN().moveText == '1. Cd6-Ce6', true);
    expect(oldTurn != game.board.turn, true);
    expect(game.board.validNotations.join(', ') == 'Kg4, Kg5, Kg3, Kf3, Ke3', true);
  });

  test('After undoing a second move, the piece moving twice is the only one who can move.', () {
    game.undo();

    expect(oldTurn == game.board.turn, true);
    expect(game.board.validNotations.join(', ') == 'Ce6, Cc6, Cd5, Cd7', true);
  });

  test('After redoing a first move, the piece moving twice is the only one who can move.', () {
    game.undo();
    game.redo();

    expect(oldTurn == game.board.turn, true);
    expect(game.board.validNotations.join(', ') == 'Ce6, Cc6, Cd5, Cd7', true);
  });

  test('A double move with check is correctly noted.', () {
    game.redo();
    game.move('Kg4');
    game.move('Ce5');
    game.move('Ce4');

    expect(game.board.lastMove!.notation == 'Ce4+', true);
    expect(game.getPGN().moveText == '1. Cd6-Ce6 Kg4 2. Ce5-Ce4+', true);
  });

  test('The piece moving twice designated by the starting FEN is the only piece who can move.', () {
    // In this starting fen, there is two kings, a black enraged dog, a white pawn and a white
    // dynamited enraged dog who already moved once. White to move and make the second move.
    fen = '8/8/3C_4/8/5c2/2K2k2/8/8/P7/8 w - - d7 0- 1 1';
    game = IratusGame.fromFEN(fen);
    oldTurn = game.board.turn;

    expect(game.board.validNotations.join(', ') == 'Ce7, Cc7, Cd6, Cd8', true);
  });

  test('After this piece has moved twice, the enemies can move.', () {
    game.move('Cd6');

    expect(game.board.lastMove!.notation == 'Cd6', true);
    expect(game.getPGN().moveText == '1. Cd6', true);
    expect(oldTurn != game.board.turn, true);
    expect(game.board.validNotations.join(', ') == 'Cg5, Ce5, Cf6, Kg4, Ke4, Kg5, Kg3, Kf3, Ke3', true);
  });

  test('A check from a piece moving twice works.', () {
    game.move('Ce5');
    game.move('Ce4');

    expect(game.board.lastMove!.notation == 'Ce4+', true);
    expect(game.getPGN().moveText == '1. Cd6 Ce5-Ce4+', true);
    expect(game.board.validNotations.join(', ') == 'Cd5, Kb4, Kc5, Kb5, Kc3, Kb3', true);
  });

  test('A check from a piece moving twice can be intercepted by a dynamited piece.', () {
    game.move('Cd5');

    expect(game.board.lastMove!.notation == 'Cd5', true);
    expect(game.board.validNotations.join(', ') == 'Cd4', true);

    game.move('Cd4');

    expect(game.board.lastMove!.notation == 'Cd4+', true);
    expect(game.board.validNotations.join(', ') == 'Cxd4*, Kg4, Kg5, Kf5, Kg3, Kf3', true);
  });

  test('If a piece moving twice is blown up by dynamite, the turn goes to the enemies.', () {
    game.move('Cxd4*');

    expect(game.board.lastMove!.notation == 'Cxd4*', true);
    expect(game.getPGN().moveText == '1. Cd6 Ce5-Ce4+ 2. Cd5-Cd4+ Cxd4*', true);
    expect(oldTurn == game.board.turn, true);
    expect(game.board.validNotations.join(', ') == 'Kd4, Kb4, Kd5, Kc5, Kb5, Kd3, Kc3, Kb3, a2, a3', true);
  });
}
