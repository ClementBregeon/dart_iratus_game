import 'package:iratus_game/iratus_game.dart';
import 'package:test/test.dart';

void main() {
  test('standart FEN is correctly read & duplicated', () {
    var standartGame = IratusGame();
    expect(standartGame.board.startFEN.fen == standartGame.board.getFEN().fen, true);
  });

  test('en passant FEN is correctly read & duplicated', () {
    var enPassantGame = IratusGame.fromFEN('8/3Pp3/8/8/8/2K2k2/8/8/8/8 b - d7 - 0-0 0 1');
    expect(enPassantGame.board.startFEN.fen == enPassantGame.board.getFEN().fen, true);
  });

  // TODO : castlings

  // TODO : a random complex board
  // TODO : check dynamite moves

  // TODO : a position just before the draw by 50 moves rule
}
