part of iratus_game;

typedef FunctionWithStringParameter = void Function(String);

/// Ids of pieces who can't capture other pieces.
final List<Role> cantCapture = [
  Role.grapple,
  Role.dynamite,
];

/// Ids of pieces that can access the same square, and therefore, sometimes,
/// the notation needs clarification.
final List<Role> competitivePieces = [
  Role.bishop,
  Role.enragedDog,
  Role.eliteSoldier,
  Role.phantom,
  Role.knight,
  Role.queen,
  Role.rook,
  Role.soldier,
  Role.dynamite,
];
final List<Role> dynamitables = [
  Role.bishop,
  Role.dog,
  Role.knight,
  Role.pawn,
  Role.soldier,
];
final List<Role> promotionIds = [
  Role.bishop,
  Role.enragedDog,
  Role.eliteSoldier,
  Role.knight,
  Role.queen,
  Role.rook,
];

List<String> promotionValidNotations =
    promotionIds.map((role) => '=${role.char.toUpperCase()}').toList();

final Map<int, String> fileDict = {
  0: 'a',
  1: 'b',
  2: 'c',
  3: 'd',
  4: 'e',
  5: 'f',
  6: 'g',
  7: 'h'
};
final Map<String, int> inversedFileDict = {
  'a': 0,
  'b': 1,
  'c': 2,
  'd': 3,
  'e': 4,
  'f': 5,
  'g': 6,
  'h': 7
};

/// A help to understand the result field.
///
/// ```dart
/// String result = Game.resultDoc[game.result];
/// print(result); // checkmate ?
/// ```
final List<String> resultDoc = [
  'game in progress',
  'checkmate',
  'resignation',
  'time out',
  'stalemate',
  'draw by mutual agreement',
  'draw by repetition',
  'draw by insufficient material',
  'draw by 50-moves rule',
  'game interrupted',
];

/// A help to understand the winner field.
///
/// ```dart
/// String winner = Game.winnerDoc[game.winner];
/// print(result); // white won ?
/// ```
final List<String> winnerDoc = [
  'game in progress',
  'draw',
  'white won',
  'black won',
];

bool dogIsTooFar(Position leashPos, Position dogPos) {
  return (leashPos.row - dogPos.row).abs() > 1 ||
      (leashPos.col - dogPos.col).abs() > 1;
}

Position getNewDogPos(Position leashStart, Position leashEnd) {
  int deltaRow = normed(leashEnd.row - leashStart.row);
  int deltaCol = normed(leashEnd.col - leashStart.col);
  return Position.fromRowCol(leashStart.board,
      row: leashEnd.row - deltaRow, col: leashEnd.col - deltaCol);
}

Piece? getRookAt(String side, Piece king) {
  if (king.id != Role.king) {
    throw ArgumentError.value(
        king, 'The second argument of getRookAt must be a king');
  }
  if (king.hasMoved()) return null;

  Piece? piece;
  if (side == 'left') {
    piece = king.board.getPiece(
        Position.fromRowCol(king.board, row: king.row, col: king.col - 4));
  } else if (side == 'right') {
    piece = king.board.getPiece(
        Position.fromRowCol(king.board, row: king.row, col: king.col + 3));
  } else {
    throw ArgumentError.value(
        side, 'The argument of getRookAt() should be \'left\' or \'right\'.');
  }

  if (piece == null) return piece;
  return piece.id == Role.rook ? piece : null;
}

bool inCheck(Piece king, {List<bool>? antiking}) {
  if (king.id != Role.king) {
    throw ArgumentError.value(king, 'The argument of inCheck must be a king');
  }
  antiking ??= king.board._antiking;
  return antiking[king.pos.index] || king.isCaptured;
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

bool posIsUnderCheck(Position pos, {List<bool>? antiking}) {
  antiking ??= pos.board._antiking;
  return antiking[pos.index];
}
