import 'package:iratus_game/iratus_game.dart';

void main() {
  IratusGame game = IratusGame();

  // 1
  game.move('Ye+g1');
  game.move('Ye+f8');

  // 2
  game.move('Y+b1');
  game.move('Y+c8');

  // 3
  game.move('g3');
  game.move('e5');

  // 4
  game.move('Bg2');
  game.move('Bc5');

  // 5
  game.move('b3');
  game.move('Bxf2');

  // 6
  game.move('Ke0');
  game.move('Bd4');

  // 7
  game.move('c3');
  game.move('Bb6');

  // 8
  game.move('a4');
  game.move('a5');

  // 9
  game.move('Se1');
  game.move('d5');

  // 10
  game.move('Nf3');
  game.move('f6');

  // 11
  game.move('d4');
  game.move('e4');

  // 12
  game.move('Nh4');
  game.move('Ne7');

  // 13
  game.move('Bf1');
  game.move('g5');

  // 14
  game.move('Ng2');
  game.move('h5');

  // 15
  game.move('Nd2');
  game.move('Sh7');

  // 16
  game.move('Sb1');
  game.move('Sf5');

  // 17
  game.move('Sd3');
  game.move('Be6');

  // 18
  game.move('Sxe4');
  game.move('dxe4');

  // 19
  game.move('Ce3');
  game.move('Cxe4');
  game.move('Bf7');

  // 20
  game.move('h4');
  game.move('Kf9');

  // 21
  game.move('e3');
  game.move('Nbc6');

  // 22
  game.move('hxg5');
  game.move('fxg5');

  // 23
  game.move('Rxh5');
  game.move('Sg4');

  // 24
  game.move('Rxh8');
  game.move('Qxh8');

  // 25
  game.move('Bb5');
  game.move('Nd5');

  // 26
  game.move('Ce5');
  game.move('Cxf5');
  game.move('Nxc3');

  // 27
  game.move('Qf3');
  game.move('Rf8');

  // 28
  game.move('Bxc6');
  game.move('bxc6');

  // 29
  game.move('Qxc6');
  game.move('Kg9');

  // 30
  game.move('Ba3');
  game.move('Se7');

  // 31
  game.move('Qxc3');
  game.move('Bxb3');

  // 32
  game.move('Nxb3*');
  game.move('Rxf5');

  // 33
  game.move('Bxe7');
  game.move('Cd7');
  game.move('Cxe7');

  // 34
  game.move('B~xf5');
  game.move('R~f9');

  // 35
  game.move('B~g6');
  game.move('Qh1');

  // 36
  game.move('Qxc7');
  game.move('Qf1');

  // 37
  game.move('Kd0');
  game.move('Qd3');

  // 38
  game.move('Sc3');
  game.move('Qxg6');

  // 39
  game.move('Qxe7');
  game.move('Kg8');

  // 40
  game.move('d6');
  game.move('Qc2');

  // 41
  game.move('Qxg5');
  game.move('Kf8');

  // 42
  game.move('Rf1');
  game.move('Ke8');

  // 43
  game.move('Qe7');
  game.move('Kd9');

  // 44
  game.move('Rxf9');
  game.move('Kc8');

  // 45
  game.move('d7');
  game.move('Kb8');

  // 46
  game.move('Qc9');
  game.move('Kb7');

  // 47
  game.move('d9');
  game.move('=Q');
  game.move('Ka8');

  // 48
  game.move('Qa6');
  game.move('Ba7');

  // 49
  game.move('Rf8');

  print(game.getPGN());
  print('\n');
  ConsoleView.printBoard(game.board);
  print('\n');
  ConsoleView.printAllValidMoves(game.board);
}
