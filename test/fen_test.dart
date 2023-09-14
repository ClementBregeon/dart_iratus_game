import 'package:iratus_game/iratus_game.dart';
import 'package:test/test.dart';

void main() {
  test('standart FEN is correctly read & duplicated', () {
    var standartGame = IratusGame();

    expect(standartGame.board.startFEN.fen == standartGame.board.getFEN().fen, true);
  });

  test('en passant is correctly written in FEN', () {
    IratusGame enPassantGame = IratusGame.fromFEN('8/4p3/8/3P4/8/2K2k2/8/8/8/8 w - - - 0-0 0 1');
    enPassantGame.move('d8');

    expect(enPassantGame.board.getFEN().fen == '8/3Pp3/8/8/8/2K2k2/8/8/8/8 b - d7 - 1-0 0 1', true);
  });

  test('en passant FEN is correctly read & duplicated', () {
    IratusGame enPassantGame2 = IratusGame.fromFEN('8/3Pp3/8/8/8/2K2k2/8/8/8/8 b - d7 - 1-0 0 1');

    expect(enPassantGame2.board.startFEN.fen == enPassantGame2.board.getFEN().fen, true);
    expect(
        enPassantGame2.board.validNotations.join(', ') == 'e7, e6, exd7, Kg4, Ke4, Kg5, Kf5, Ke5, Kg3, Kf3, Ke3', true);
  });

  test('moving again is correctly written in FEN', () {
    IratusGame movingAgainGame = IratusGame.fromFEN('8/8/8/3C4/8/2K1k3/8/8/8/8 w - - - - 3 2');
    movingAgainGame.move('Cd5');

    expect(movingAgainGame.board.getFEN().fen == '8/8/8/8/3C4/2K1k3/8/8/8/8 w - - d5 - 4 2', true);
  });

  test('moving again FEN is correctly read & duplicated', () {
    IratusGame movingAgainGame2 = IratusGame.fromFEN('8/8/8/8/3C4/2K1k3/8/8/8/8 w - - d5 - 4 2');

    expect(movingAgainGame2.board.startFEN.fen == movingAgainGame2.board.getFEN().fen, true);
    expect(movingAgainGame2.board.validNotations.join(', ') == 'Ce5, Cc5, Cd4, Cd6', true);
  });

  // FEN TESTS
  // All the pieces are at the same position
  // Turn is applied, even when a piece moving twice has to move again
  // Dynamited pieces are correctly dynamited
  // Dynamitables.hasMoved() are kept the same
  // Counter50rule is used
  // TurnNumber is used

  // TODO : a random complex board
  // TODO : check dynamite moves

  // TODO : a position just before the draw by 50 moves rule
}
