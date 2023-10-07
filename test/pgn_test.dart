import 'package:iratus_game/iratus_game.dart';
import 'package:test/test.dart';

void main() {
  IratusGame game = IratusGame();

  test('start PGN is correctly written.', () {
    PGN pgn = game.getPGN();

    expect(pgn.moveText == '', true);
    expect(pgn.tagPairs['Result'] == '*', true);
    expect(pgn.tagPairs['Variant'] == 'Iratus', true);
  });

  test('In progress game PGN is correctly written.', () {
    // 1
    game.move('f3');
    game.move('e5');
    // 2
    game.move('g4');

    PGN pgn = game.getPGN();

    expect(pgn.moveText == '1. f3 e5 2. g4', true);
    expect(pgn.tagPairs['Result'] == '*', true);
  });

  test('Ended game PGN is correctly written.', () {
    // 2
    game.move('Qh4');

    PGN pgn = game.getPGN();

    expect(pgn.moveText == '1. f3 e5 2. g4 Qh4# 0-1', true);
    expect(pgn.tagPairs['Result'] == '0-1', true);
  });

  test('Starting from black game PGN is correctly written.', () {
    // 6
    IratusGame game2 = IratusGame.fromFEN(
        'fd(0)s(0)yys(1)d(1)g/rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR/FD(2)S(2)YYS(3)D(3)G b QKqk e3 1000000000000000-0000000000000000 0 1');
    game2.move('e5');
    PGN pgn = game2.getPGN();

    expect(pgn.moveText == '1. ... e5', true);
    expect(pgn.tagPairs['Result'] == '*', true);
  });
}
