import 'game.dart';

/// A position on a board.
///
/// Can be seen as an index, a row and col, or a coordinates string.
///
/// The values of the index is col * board.nbrows + row
class Position {
  final Board board;
  final int col;
  final int row;
  final int index; // col * board.nbrows + row
  final String coord;

  @override
  int get hashCode => index;

  Position.fromCoords(this.board, this.coord)
      : col = inversedFileDict[coord[0]]!,
        row = board.nbrows - 1 - int.parse(coord[1]),
        index = (inversedFileDict[coord[0]]! * board.nbrows) +
            (board.nbrows - 1 - int.parse(coord[1])) {
    _checkValidity();
  }

  Position.fromRowCol(this.board, {required this.row, required this.col})
      : coord = fileDict[col]! + (board.nbrows - row - 1).toString(),
        index = col * board.nbrows + row {
    _checkValidity();
  }

  Position.fromIndex(this.board, this.index)
      : coord = fileDict[index ~/ board.nbrows]! +
            (board.nbrows - (index % board.nbrows) - 1).toString(),
        col = index ~/ board.nbrows,
        row = index % board.nbrows {
    _checkValidity();
  }

  @override
  bool operator ==(other) {
    return other is Position && other.index == index;
  }

  Position? add(List<int> move) {
    try {
      return Position.fromRowCol(board, row: row + move[0], col: col + move[1]);
    } catch (e) {
      // out of the board
      return null;
    }
  }

  @override
  String toString() {
    return coord;
  }

  void _checkValidity() {
    if (0 > row ||
        0 > col ||
        row > board.nbrows ||
        col > board.nbcols ||
        coord.length != 2) {
      throw Exception('Wrong position');
    }
  }
}
