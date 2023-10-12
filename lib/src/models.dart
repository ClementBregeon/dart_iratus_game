enum Role {
  pawn,
  knight,
  bishop,
  rook,
  king,
  queen,
  dog,
  enragedDog,
  soldier,
  eliteSoldier,
  dynamite,
  phantom,
  grapple;

  static Role? fromChar(String ch) {
    switch (ch.toLowerCase()) {
      case 'p':
        return Role.pawn;
      case 'n':
        return Role.knight;
      case 'b':
        return Role.bishop;
      case 'r':
        return Role.rook;
      case 'q':
        return Role.queen;
      case 'k':
        return Role.king;
      case 'd':
        return Role.dog;
      case 'c':
        return Role.enragedDog;
      case 's':
        return Role.soldier;
      case 'e':
        return Role.eliteSoldier;
      case 'y':
        return Role.dynamite;
      case 'f':
        return Role.phantom;
      case 'g':
        return Role.grapple;
      default:
        return null;
    }
  }

  String get char {
    switch (this) {
      case Role.pawn:
        return 'p';
      case Role.knight:
        return 'n';
      case Role.bishop:
        return 'b';
      case Role.rook:
        return 'r';
      case Role.queen:
        return 'q';
      case Role.king:
        return 'k';
      case Role.dog:
        return 'd';
      case Role.enragedDog:
        return 'c';
      case Role.soldier:
        return 's';
      case Role.eliteSoldier:
        return 'e';
      case Role.dynamite:
        return 'y';
      case Role.phantom:
        return 'f';
      case Role.grapple:
        return 'g';
    }
  }
}

enum Side {
  white,
  black;

  Side get opposite => this == Side.white ? Side.black : Side.white;
}
