import 'package:iratus_game/iratus_game.dart';
import 'package:iratus_game/src/game.dart';

void main() {
  IratusGame game = IratusGame();

  //
  game.move('e4');
  game.move('e5');

  //
  game.move('Nf3');
  game.move('Nc6');

  //
  game.move('d4');
  game.move('exd4');

  //
  game.move('Nxd4');
  game.move('Bc5');

  //
  game.move('c3');
  game.move('Qf6');

  //
  game.move('Be3');
  game.move('Nge7');

  //
  game.move('Be2');
  game.move('0-0');

  //
  game.move('0-0');
  game.move('d5');

  //
  game.move('Nxc6');
  game.move('Qxc6');

  //
  game.move('exd5');
  game.move('Nxd5');

  //
  game.move('Bf3');
  game.move('Nxe3');

  //
  game.move('Bxc6');
  game.move('Nxd1');

  //
  game.move('Rxd1');
  game.move('bxc6');

  //
  game.move('Yd+b1');
  game.move('Sd7');

  //
  game.move('Nd2');
  game.move('Yd+c8');

  //
  game.move('Ne4');
  game.move('Bb6');

  //
  game.move('Ng5');
  game.move('h6');

  //
  game.move('Nxf7');
  game.move('Rxf7*');

  //
  game.move('b4');
  game.move('c4');

  //
  game.move('N~b2');
  game.move('Sb5');

  //
  game.move('N~xc4');
  game.move('Bxf2');

  //
  game.move('Kxf2');
  game.move('Sxc4');

  //
  game.move('Rd8');
  game.move('Kg9');

  //
  game.move('Re1');
  game.move('Bd7');

  //
  game.move('Rxd7*');
  game.move('Sxa2');

  //
  game.move('Sb1');
  game.move('Rf8');

  //
  game.move('Kg1');
  game.move('c6');

  //
  game.move('Re7');
  game.move('Y+c9');

  //
  game.move('Rxg7');
  game.move('Kh8');

  //
  game.move('Rxa7');
  game.move('P~a8');

  //
  game.move('Ra3');
  game.move('Se7');

  //
  game.move('Rxb3');
  game.move('Sg5');

  //
  game.move('Sd2');
  game.move('Sf4');

  //
  game.move('h4');
  game.move('Sh2');

  //
  game.move('Sf4');
  game.move('Kh7');

  //
  game.move('Y+b0');
  game.move('C~a7');
  game.move('C~b7');

  //
  game.move('c4');
  game.move('Rd8');

  //
  game.move('Sd3');
  game.move('Ra8');

  //
  game.move('Rb1');
  game.move('Ra0');

  //
  game.move('Gf0');
  game.move('Gf7');

  //
  game.move('Sf5');
  game.move('C~c7');
  game.move('C~d7');

  //
  game.move('b6');
  game.move('C~c7');
  game.move('C~b7');

  //
  game.move('Sd7');
  game.move('G:De6->*');

  //
  game.move('Sd6');
  game.move('Ra2');

  //
  game.move('Sf8');
  game.move('Rxg2');

  //
  game.move('Kxg2');
  game.move('Sg1');

  //
  game.move('Sg9=E');
  game.move('Kg6');

  //
  game.move('Cf7');
  game.move('Cg7');
  game.move('R~xg7');

  //
  game.move('Ef8');
  game.move('Exg7');
  game.move('Sh0=E');

  //
  game.move('Rxg1');
  game.move('Exg1');
  game.move('Exf0');

  //
  game.move('Exh6');
  game.move('Eg5');
  game.move('c5');

  //
  game.move('b8');
  game.move('Kf5');

  //
  game.move('b9');
  game.move('=Q');
  game.move('Kg6');

  //
  game.move('Kf3');
  game.move('Kh5');

  //
  game.move('Qd9');

  print(game.getPGN());
  print('\n');
  ConsoleView.printBoard(game.board);
  print('\n');
  ConsoleView.printAllValidMoves(game.board);
}

  // TODO : resign button