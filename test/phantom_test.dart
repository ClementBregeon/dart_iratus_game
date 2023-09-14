// Phantoms are correctly transformed
// It is possible to have 0, 1 or more phantoms

import 'package:iratus_game/iratus_game.dart';
import 'package:iratus_game/src/game.dart';
import 'package:test/test.dart';

void main() {
  String validMovesToString(Piece piece) {
    return piece.validMoves.map((element) => element.coord).join(', ');
  }

  IratusGame game = IratusGame();
  Board board = game.board;
  Piece wPhantom = board.get(Position.fromCoords(board, 'a0'))!;
  Piece bPhantom = board.get(Position.fromCoords(board, 'a9'))!;

  test('Phantomization works.', () {
    game.move('a4');
    game.move('b5');
    game.move('axb5');

    expect(wPhantom.id == 'f', true);
    expect(bPhantom.id == 'p', true);
  });

  test('Phantomization can be undone.', () {
    game.undo();

    expect(bPhantom.id == 'f', true);
  });

  test('Phantomization can be redone.', () {
    game.redo();

    expect(bPhantom.id == 'p', true);
  });

  test('Multiple phantomization works.', () {
    game.move('a6');
    game.move('bxa6');
    game.move('Rxa6');
    game.move('Rxa6');

    expect(wPhantom.id == 'p', true);
    expect(validMovesToString(wPhantom) == 'a1, a2', true);
    expect(bPhantom.id == 'r', true);
    expect(validMovesToString(bPhantom) == 'a8, a7, a6', true);
  });

  test('A phantom move is noted with the id of the piece followed by \'~\'.', () {
    game.move('R~xa6');

    expect(board.lastMove!.notation == 'R~xa6', true);
  });

  test('A phantom\'s check can be avoiding by capture, turning it into another piece.', () {
    game.move('R~xa6');
    game.move('f5');
    game.move('R~f6');
    game.move('f3');
    game.move('e4');
    game.move('Nc6');
    game.move('Qxf3');
    game.move('Nd4');
    game.move('R~xf8');

    expect(board.lastMove!.notation == 'R~xf8+', true);
    expect(game.board.validNotations.join(', ') == 'Nxc2', true);
  });

  test('A phantom can checkmate.', () {
    game.undo();
    game.undo();
    game.move('Ne5');
    game.move('R~xf8');

    expect(board.lastMove!.notation == 'R~xf8#', true);
  });

  test('A piece protected by the phantom can checkmate.', () {
    game = IratusGame();
    game.move('a4');
    game.move('b5');
    game.move('axb5');
    game.move('a6');
    game.move('bxa6');
    game.move('Rxa6');
    game.move('Rxa6');
    game.move('R~xa6');
    game.move('R~xa6');
    game.move('f5');
    game.move('R~f6');
    game.move('f3');
    game.move('e4');
    game.move('Nc6');
    game.move('Qxf3');
    game.move('Nb4');
    game.move('Qb3');
    game.move('Nc6');
    game.move('Qf7');

    expect(game.board.lastMove!.notation == 'Qf7#', true);
  });

  // TODO : the phantom of a pawn promotion + notation
  // TODO : the phantom of a soldier promotion + notation
}
