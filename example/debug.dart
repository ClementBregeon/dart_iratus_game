import 'package:iratus_game/iratus_game.dart';
import 'package:iratus_game/src/game.dart';

void main() {
  String fen = '8/8/8/8/8/K4k2/8/8/8/S4n2 w - - - 0-0 0 1';

  IratusGame game = IratusGame.fromFEN(fen);

  ConsoleView.printAllValidMoves(game.board);

  print(game.getPGN().moveText);
}
