import 'package:iratus_game/iratus_game.dart';
import 'package:test/test.dart';

void main() {
  // In this starting fen, there is two kings and a white queen.
  // White to move the quuen.
  String fen = '8/8/8/8/8/K4k2/8/8/8/Q4n2 w - - - -0 0 1';
  IratusGame game = IratusGame.fromFEN(fen);

  test('A rolling piece has rolling moves.', () {
    expect(
        game.board.validNotations.join(', ') ==
            'Kb4, Kb5, Ka5, Kb3, Ka3, Qb0, Qc0, Qd0, Qe0, Qxf0, Qb1, Qc2, Qd3, Qe4, Qf5, Qg6, Qh7, Qa1, Qa2, Qa3',
        true);
  });

  test('A rolling piece can check from a long distance.', () {
    game.move('Qb0');

    expect(game.board.lastMove!.notation == 'Qb0+', true);
    expect(game.board.validNotations.join(', ') == 'Kg4, Ke4, Kf5, Ke5, Kg3, Kf3', true);
  });

  test('A rolling piece can have a short range.', () {
    fen = '8/8/8/8/8/K4k2/8/8/8/S4n2 w - - - 0-0 0 1';
    game = IratusGame.fromFEN(fen);

    expect(game.board.validNotations.join(', ') == 'Kb4, Kb5, Ka5, Kb3, Ka3, Sb1, Sc2', true);
  });
}
