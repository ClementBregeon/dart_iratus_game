import 'game.dart';
import 'position.dart';

final String colors = 'bw';
final String ids = 'bcdefgknpqrsy';

/// Ids of pieces who can't capture other pieces.
final String cantCapture = 'gy';

/// Ids of pieces that can access the same square, and therefore, sometimes,
/// the notation needs clarification.
final String competitivePieces = 'bcefnqrsy';
final String dynamitables = 'bdnps';
final String promotionIds = 'bcenqr';
List<String> promotionValidNotations = promotionIds.split('').map((char) => '=${char.toUpperCase()}').toList();

final Map<int, String> fileDict = {0: 'a', 1: 'b', 2: 'c', 3: 'd', 4: 'e', 5: 'f', 6: 'g', 7: 'h'};
final Map<String, int> inversedFileDict = {'a': 0, 'b': 1, 'c': 2, 'd': 3, 'e': 4, 'f': 5, 'g': 6, 'h': 7};

bool dogIsTooFar(Position leashPos, Position dogPos) {
  return (leashPos.row - dogPos.row).abs() > 1 || (leashPos.col - dogPos.col).abs() > 1;
}

Position getNewDogPos(Position leashStart, Position leashEnd) {
  int deltaRow = normed(leashEnd.row - leashStart.row);
  int deltaCol = normed(leashEnd.col - leashStart.col);
  return Position.fromRowCol(leashStart.board, row: leashEnd.row - deltaRow, col: leashEnd.col - deltaCol);
}

Piece? getRookAt(String side, Piece king) {
  if (king.id != 'k') throw ArgumentError.value(king, 'The second argument of getRookAt must be a king');
  if (king.hasMoved()) return null;

  Piece? piece;
  if (side == 'left') {
    piece = king.board.get(Position.fromRowCol(king.board, row: king.row, col: king.col - 4));
  } else if (side == 'right') {
    piece = king.board.get(Position.fromRowCol(king.board, row: king.row, col: king.col + 3));
  } else {
    throw ArgumentError.value(side, 'The argument of getRookAt() should be \'left\' or \'right\'.');
  }

  if (piece == null) return piece;
  return piece.id == 'r' ? piece : null;
}

int normed(int x) {
  if (x < 0) {
    return -1;
  } else if (x > 0) {
    return 1;
  } else {
    return 0;
  }
}
