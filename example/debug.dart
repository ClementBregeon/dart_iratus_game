import 'package:iratus_game/iratus_game.dart';
import 'package:iratus_game/src/game.dart';

void main() {
  String fen = '8/8/3C_4/8/5c2/2K2k2/8/8/P7/8 w - - d7 0- 1 1';

  IratusGame game = IratusGame.fromFEN(fen);

  game.move('Cd6');
  game.move('Ce5');
  game.move('Ce4');

  print(game.getPGN().moveText);
}
