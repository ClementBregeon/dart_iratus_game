import 'package:iratus_game/iratus_game.dart';
import 'package:test/test.dart';

void main() {
  test('En passant works in standart situation', () {
    // In this starting fen, there is two kings, a white king and a black pawn.
    // Because of the value 'd8' at the fiels 'enPassant', we know tha the queen is a pawn
    // who just promoted after moving two squares. Black to move and capture the queen.
    IratusGame game = IratusGame.fromFEN('8/4p3/8/3P4/8/2K2k2/8/8/8/8 w - - - 0-0 0 1');

    game.move('d8');

    expect(game.board.get(Position.fromCoords(game.board, 'e8')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'e8'))!.id == 'p', true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8'))!.id == 'p', true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) == null, true);
    expect(game.board.lastMove!.enPassant != null, true);
    expect(game.board.lastMove!.enPassant!.coord == 'd7', true);

    // ConsoleView.printBoard(game.board);
    // ConsoleView.printAllValidMoves(game.board);

    game.move('d7'); // TODO : exd7

    expect(game.board.get(Position.fromCoords(game.board, 'e8')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7'))!.id == 'p', true);
  });

  test('En passant from fen after two squares move', () {
    // In this starting fen, there is two kings, a white king and a black pawn.
    // Because of the value 'd8' at the fiels 'enPassant', we know tha the queen is a pawn
    // who just promoted after moving two squares. Black to move and capture the queen.
    IratusGame game = IratusGame.fromFEN('8/3Pp3/8/8/8/2K2k2/8/8/8/8 b - d7 - 0-0 0 1');

    expect(game.board.get(Position.fromCoords(game.board, 'e8')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'e8'))!.id == 'p', true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8'))!.id == 'p', true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) == null, true);

    game.move('exd7');

    expect(game.board.get(Position.fromCoords(game.board, 'e8')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd7'))!.id == 'p', true);
  });

  test('En passant from fen after two squares move + promotion', () {
    // In this starting fen, there is two kings, a white king and a black pawn.
    // Because of the value 'd8' at the fiels 'enPassant', we know tha the queen is a pawn
    // who just promoted after moving two squares. Black to move and capture the queen.
    IratusGame game = IratusGame.fromFEN('3Qp3/8/8/8/8/2K2k2/8/8/8/8 b - d8 - -0 0 1');

    expect(game.board.get(Position.fromCoords(game.board, 'e9')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'e9'))!.id == 'p', true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9'))!.id == 'q', true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8')) == null, true);

    game.move('exd8');

    expect(game.board.get(Position.fromCoords(game.board, 'e9')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd9')) == null, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8')) is Piece, true);
    expect(game.board.get(Position.fromCoords(game.board, 'd8'))!.id == 'p', true);
  });
}
