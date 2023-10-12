part of iratus_game;

class _PieceInformations {
  int col = -1;
  String color = 'n';
  bool dynamited = false;
  Role? id;
  int? linkID;
  bool phantomized = false;
  int row = -1;

  reset() {
    col = -1;
    color = 'n';
    dynamited = false;
    id = null;
    linkID = null;
    phantomized = false;
    row = -1;
  }
}

abstract class FEN {
  abstract final String fen;
  abstract final String fenEqualizer;
}

/// An object representating an Iratus position.
///
/// Works just like a chess FEN
///
/// Rule reminder : a repetition occurs when the fen equalizers are the same
/// fenEqualizer = pieces turn castleRights enPassant
///
///
/// VALUES ORDER
///
/// pieces turn castleRights enPassant dynamitablesHasMoved counter50rule turnNumber
///
///
/// NEW VALUE
///
/// dynamitablesHasMoved :
///
///   listOf0or1 + "-" + listOf0or1
///   exemple : 001110110010000-00000000111011001
///
///   The first list represents the white dynamitable pieces, the seceond represents the black dynamitable pieces.
///   From white's perspective, from left to right then top to bottom.
///
///   0 : the piece has not moved yet
///   1 : the piece already moved
///
///
/// NEW CHARACTERS :
///
/// ~ : after a phantomized piece
/// _ : after a dynamited piece
/// (X) : after a linked piece, X is the link ID
class IratusFEN extends FEN {
  /// The fen representating the standart start position of Iratus.
  static final String start =
      'fd(0)s(0)yys(1)d(1)g/rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR/FD(2)S(2)YYS(3)D(3)G w QKqk - 0000000000000000-0000000000000000 0 1';

  @override
  late final String fen;
  @override
  late final String fenEqualizer; // pieces turn castleRights enPassant
  late final String pieces;
  late final String turn;
  late final String castleRights;

  /// The position where a pawn can go to capture an enemy pawn who just moved 2 squares.
  late final Position? enPassant;

  late final Map<String, String> dynamitablesHasMoved;
  late final int counter50rule;
  late final int turnNumber;

  IratusFEN.fromString(this.fen, Board board) {
    if (!isValidFEN(fen)) throw ArgumentError.value(fen, 'Invalid FEN');

    List<String> parts = fen.split(" ");

    if (parts.length != 7) {
      throw ArgumentError.value(
        fen,
        'Invalid FEN : An Iratus FEN should have 7 values (pieces, turn, casle rights, en passant, dynamitables has moved, counter for 50 moves rules, half turn number)',
      );
    }

    pieces = parts[0];
    turn = parts[1];
    castleRights = parts[2];
    enPassant = parts[3] == '-' ? null : Position.fromCoords(board, parts[3]);
    fenEqualizer = '$pieces $turn $castleRights ${parts[3]}}';
    counter50rule = int.parse(parts[5]);
    turnNumber = int.parse(parts[6]);

    // DYNAMITABLES HAS MOVED
    List<String> splittedDynamitablesHasMoved = parts[4].split('-');
    dynamitablesHasMoved = {
      'w': splittedDynamitablesHasMoved[0],
      'b': splittedDynamitablesHasMoved[1],
    };

    // PIECES
    _PieceInformations pieceInfos = _PieceInformations();
    String firstChar = fen[0].toLowerCase();
    if (!pieceIDs.contains(firstChar)) {
      if (!"12345678".contains(firstChar)) {
        throw ArgumentError.value(firstChar,
            'Invalid FEN :\nA FEN must start with either a piece id or a number.');
      }
    }
    String linkID = '';
    var waitingForLink = {};
    var irow = 0;
    // This var is the bridge between the dynamitablesHasMoved notation
    // and the dynamitables pieces on the board
    var dhmIndexes = {'w': 0, 'b': 0};

    void createPiece(_PieceInformations pieceInfos) {
      Piece piece;
      Position pos =
          Position.fromRowCol(board, row: pieceInfos.row, col: pieceInfos.col);
      if (pieceInfos.phantomized) {
        piece = Piece(board, pieceInfos.color, pos, Role.phantom);
        piece.transform(pieceInfos.id!);
      } else {
        piece = Piece(board, pieceInfos.color, pos, pieceInfos.id!);
      }
      if (pieceInfos.dynamited) {
        piece.setDynamite(true);
      }
      if (pieceInfos.linkID != null) {
        final waitingPiece = waitingForLink[pieceInfos.linkID];
        if (waitingPiece != null) {
          waitingPiece._linkedPiece = piece;
          piece._linkedPiece = waitingPiece;
        } else {
          waitingForLink[pieceInfos.linkID] = piece;
        }
      }
      if (dynamitables.contains(pieceInfos.id)) {
        if (dynamitablesHasMoved[pieceInfos.color]![
                dhmIndexes[pieceInfos.color]!] ==
            '1') {
          piece.setUnknownFirstMove();
        }
        dhmIndexes[pieceInfos.color] = dhmIndexes[pieceInfos.color]! + 1;
      }
    }

    for (final String row in parts[0].split('/')) {
      bool inParenthesis = false;
      int icol = 0;
      for (final int charCode in row.runes) {
        String char = String.fromCharCode(charCode);
        bool charIsNumber = '0123456789'.contains(char);
        // Link ID
        if (inParenthesis) {
          if (char == ')') {
            inParenthesis = false;
            pieceInfos.linkID = int.parse(linkID);
            continue;
          }
          if (!charIsNumber) {
            throw ArgumentError.value(
                row, 'Invalid FEN :\nParentheses only accept numbers.');
          }
          linkID += char;
          continue;
        }
        if (char == "(") {
          inParenthesis = true;
          linkID = "";
          continue;
        }

        // Phantom
        if (char == "~") {
          pieceInfos.phantomized = true;
          continue;
        }

        // Dynamite
        if (char == "_") {
          pieceInfos.dynamited = true;
          continue;
        }

        // Empty spaces
        if (charIsNumber) {
          icol += int.parse(char);
          continue;
        }

        // Piece creation
        if (pieceInfos.id != null) {
          createPiece(pieceInfos);
        }

        // Piece pre-creation
        pieceInfos.reset();
        final charLowerCase = char.toLowerCase(); // white ids are uppercase
        final id = Role.fromChar(charLowerCase);
        if (id == null) {
          throw ArgumentError.value(
              pieceInfos.id, 'Invalid FEN : Unknown piece id');
        }
        pieceInfos.id = id;
        pieceInfos.color = char == charLowerCase ? "b" : "w";
        pieceInfos.row = irow;
        pieceInfos.col = icol;
        icol++;
      }
      irow++;
    }
    createPiece(pieceInfos);

    // CASTLE RIGHTS
    for (final String castle in 'qkQK'.split('')) {
      if (castleRights.contains(castle)) continue;

      Piece? k = board.king[castle == castle.toUpperCase() ? 'w' : 'b'];
      if (k == null) continue; // an army without king
      if (k.col != 4 ||
          (k.color == 'w' && k.row != 8) ||
          (k.color == 'b' && k.row != 1)) {
        k.setUnknownFirstMove();
        continue;
      }
      Piece? rook =
          getRookAt(castle.toUpperCase() == 'K' ? 'right' : 'left', k);
      if (rook != null) {
        rook.setUnknownFirstMove();
      }
    }
  }

  IratusFEN.fromBoard(Board board) {
    String fenIP = ''; // fen in progress
    dynamitablesHasMoved = {'w': '', 'b': ''};
    Map<String, int> linkedPieces = {'i': 0};

    // Pieces
    for (int row = 0; row < 10; row++) {
      int space = 0;
      for (int col = 0; col < 8; col++) {
        Piece? piece =
            board.getPiece(Position.fromRowCol(board, row: row, col: col));

        if (piece == null) {
          space += 1;
          continue;
        }

        if (space > 0) {
          fenIP += space.toString();
          space = 0;
        }

        if (piece.color == "b") {
          fenIP += piece.id.char;
        } else {
          fenIP += piece.id.char.toUpperCase();
        }

        if (piece.dynamited) {
          fenIP += "_";
        }

        if (piece.phantomized && piece.id != Role.phantom) {
          fenIP += '~';
        }

        if (piece._linkedPiece != null && !piece._linkedPiece!.isCaptured) {
          String pieceCoord = piece.coord;
          String linkedPieceCoord = piece._linkedPiece!.coord;

          if (linkedPieces.containsKey(linkedPieceCoord)) {
            linkedPieces[pieceCoord] = linkedPieces[linkedPieceCoord]!;
          } else {
            linkedPieces[pieceCoord] = linkedPieces['i']!;
            linkedPieces['i'] = linkedPieces['i']! + 1;
          }
          fenIP += "(${linkedPieces[pieceCoord]})";
        }

        if (dynamitables.contains(piece.id)) {
          dynamitablesHasMoved[piece.color] =
              dynamitablesHasMoved[piece.color]! +
                  (piece.hasMoved() ? "1" : "0");
        }
      }

      if (space > 0) {
        fenIP += space.toString();
      }

      if (row < 9) {
        fenIP += "/";
      }
    }

    // Turn
    turn = board.turn;
    fenIP += ' $turn ';

    // Castle Rights
    String allCastleRights = '';
    for (String color in ['w', 'b']) {
      Piece king = board.king[color]!;
      String castleRights = "";
      Piece? leftRook = getRookAt('left', king);
      if (leftRook != null && !leftRook.hasMoved() && !king.hasMoved()) {
        castleRights += 'q';
      }
      Piece? rightRook = getRookAt('right', king);
      if (rightRook != null && !rightRook.hasMoved() && !king.hasMoved()) {
        castleRights += 'k';
      }
      if (color == 'w') {
        castleRights = castleRights.toUpperCase();
      }
      allCastleRights += castleRights;
    }
    fenIP += allCastleRights != '' ? allCastleRights : '-';

    // En Passant
    Move? lastMove = board.lastMove;
    if (lastMove == null) {
      enPassant = board.startFEN.enPassant;
    } else {
      enPassant = lastMove.enPassant;
    }
    // The following is the equivalent of :
    // if (enPassant == null) {
    //   fenIP += ' -';
    // } else {
    //   fenIP += enPassant!.coord;
    // }
    fenIP += ' ${enPassant?.coord ?? '-'}';

    // Same position if same pieces, turn, castleRights & enPassant
    fenEqualizer = fenIP;

    // Dynamitables has moved
    fenIP += ' ${dynamitablesHasMoved['w']}-${dynamitablesHasMoved['b']}';

    // 50 moves rule & Turn number
    if (lastMove != null) {
      fenIP += ' ${lastMove.counter50rule}';
      fenIP += ' ${lastMove.turnNumber}';
    } else {
      fenIP += ' ${board.startFEN.counter50rule}';
      fenIP += ' ${board.startFEN.turnNumber}';
    }

    fen = fenIP;
  }

  @override
  String toString() {
    return fen;
  }
}

final pieceIDs = 'bcdefgknpqrsy';
final validChars = '$pieceIDs${pieceIDs.toUpperCase()}~_()0-9';
final fenRegexPattern =
    '^([$validChars]+\\/){9}[$validChars]+\\s[wb]\\s(-|[KQkq]+)\\s(-|[a-h][1-8])\\s(([01]+)?-([01]+)?)\\s\\d+\\s\\d+\$';
final fenRegex = RegExp(fenRegexPattern);

bool isValidFEN(String fen) {
  // Warning: This function checks the syntax pattern of the FEN notation,
  // but it does not validate the actual chess positions or game rules.
  // Example: 9 pieces in one row will not be detected here
  return fenRegex.hasMatch(fen);
}
