import 'package:iratus_game/iratus_game.dart';
import 'package:iratus_game/src/game.dart';

void main() {
  String fen = '8/8/3P4/8/8/2K2k2/8/8/8/8 w - - - 1- 0 1';

  IratusGame game = IratusGame.fromFEN(fen);

  ConsoleView.printAllValidMoves(game.board);
  ConsoleView.printBoard(game.board.calculator as CalculatorIratusBoard);
  game.move('d9');
  ConsoleView.printAllValidMoves(game.board);
  ConsoleView.printBoard(game.board.calculator as CalculatorIratusBoard);
  game.move('=Q');
  ConsoleView.printAllValidMoves(game.board);
  ConsoleView.printBoard(game.board.calculator as CalculatorIratusBoard);
  game.move('Kg3');
  ConsoleView.printAllValidMoves(game.board);
  ConsoleView.printBoard(game.board.calculator as CalculatorIratusBoard);

  print(game.board.getFEN());
}
