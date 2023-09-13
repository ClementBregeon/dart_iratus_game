import 'package:iratus_game/iratus_game.dart';

void main() {
  // In this starting fen, there is two kings and a white pawn.
  // White to move and promote.
  String fen = '8/8/3P4/8/8/2K2k2/8/8/8/8 w - - - 1- 0 10';

  IratusGame game = IratusGame.fromFEN(fen);

  ConsoleView cv = ConsoleView(game: game);
  cv.start();
}
