import 'package:iratus_game/iratus_game.dart';
import 'package:test/test.dart';

void main() {
  String validMovesToString(Piece piece) {
    return piece.validMoves.map((element) => element.coord).join(', ');
  }

  IratusGame game = IratusGame();

  test('From standart start, a dynamite can attach itself 16 pieces.', () {
    for (Piece piece in game.board.pieces) {
      if (piece.id == 'y') expect(piece.validMoves.length == 16, true);
    }
  });

  test('From standart start, knights and bishops can equip the dynamite.', () {
    expect(game.board.validNotations.contains('N+d0'), true);
    expect(game.board.validNotations.contains('B+d0'), true);
    expect(game.board.validNotations.contains('B+e0'), true);
    expect(game.board.validNotations.contains('N+e0'), true);
  });

  test('A dynamite cannot attach itself to a piece who has already moved.', () {
    game.move('e4');
    game.move('e5');

    for (Piece piece in game.board.piecesColored['w']!) {
      if (piece.id == 'y') expect(piece.validMoves.length == 15, true);
    }
  });

  test('Capturing a dynamited piece blows the capturer.', () {
    game.move('Yd+d2');
    game.move('d6');
    game.move('d4');
    game.move('exd4*');

    expect(game.board.get(Position.fromCoords(game.board, 'd4')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'e5')) == null, true);
  });

  test('Undoing a dynamite blow works.', () {
    game.undo();

    expect(game.board.get(Position.fromCoords(game.board, 'd4')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd4'))!.id == 'p', true);
    expect(game.board.get(Position.fromCoords(game.board, 'e5')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'e5'))!.id == 'p', true);
  });

  test('Redoing a dynamite blow works.', () {
    game.redo();

    expect(game.board.get(Position.fromCoords(game.board, 'd4')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'e5')) == null, true);
  });

  test('A king can\'t capture a dynamited piece.', () {
    game.move('Y+g1');
    game.move('Ke7');
    game.move('Nf3');
    game.move('Ke6');
    game.move('Ne5');

    expect(game.board.king['b']!.validMoves.length == 2, true);
    expect(game.board.king['b']!.validMoves.every((element) => element.coord != 'e5'), true);
    expect(validMovesToString(game.board.king['b']!) == 'f6, e7', true);
  });

  test('A dynamited piece can\'t be captured if it creates a discovered check.', () {
    game.move('d5');
    game.move('Qe2');
    game.move('dxe4');
    game.move('Qxe4');
    game.move('f6');
    game.move('Be2');

    Piece pawnF6 = game.board.get(Position.fromCoords(game.board, 'f6'))!;
    expect(pawnF6.validMoves.length == 2, true);
    expect(pawnF6.validMoves.every((element) => element.coord != 'e5'), true);
    expect(validMovesToString(pawnF6) == 'f5, f4', true);
  });
}

// TODO : an enemy can't go to the dynamite
