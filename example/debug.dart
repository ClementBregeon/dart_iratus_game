import 'package:iratus_game/iratus_game.dart';

void main() {
  String fen = '8/4p3/8/3P4/8/2K2k2/8/8/8/8 w - - - 0-0 0 1';

  IratusGame game = IratusGame.fromFEN(fen);

  ConsoleView.printAllValidMoves(game.board);
  game.move('d8');
  game.move('exd7');

  print(game.board.getFEN());
}
