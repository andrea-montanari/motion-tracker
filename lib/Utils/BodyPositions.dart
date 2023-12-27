enum BodyPositions {
  leftWrist,
  rightWrist,
  leftPocket,
  rightPocket,
  leftAnkle,
  rightAnkle,
  chest,
}

extension MyColorExtension on BodyPositions {
  String get name {
    switch (this) {
      case BodyPositions.leftWrist:
        return 'polso sinistro';
      case BodyPositions.rightWrist:
        return 'polso destro';
      case BodyPositions.leftPocket:
        return 'tasca sinistra';
      case BodyPositions.rightPocket:
        return 'tasca destra';
      case BodyPositions.leftAnkle:
        return 'caviglia sinistra';
      case BodyPositions.rightAnkle:
        return 'caviglia destra';
      case BodyPositions.chest:
        return 'petto';
    }
  }

  String get nameUpperCase {
    switch (this) {
      case BodyPositions.leftWrist:
        return 'Polso sinistro';
      case BodyPositions.rightWrist:
        return 'Polso destro';
      case BodyPositions.leftPocket:
        return 'Tasca sinistra';
      case BodyPositions.rightPocket:
        return 'Tasca destra';
      case BodyPositions.leftAnkle:
        return 'Caviglia sinistra';
      case BodyPositions.rightAnkle:
        return 'Caviglia destra';
      case BodyPositions.chest:
        return 'Petto';
    }
  }

  String get limb {
    switch (this) {
      case BodyPositions.leftWrist:
        return 'il braccio sinistro';
      case BodyPositions.rightWrist:
        return 'il braccio destro';
      case BodyPositions.leftPocket:
        return 'la gamba sinistra';
      case BodyPositions.rightPocket:
        return 'la gamba destra';
      case BodyPositions.leftAnkle:
        return 'la gamba sinistra';
      case BodyPositions.rightAnkle:
        return 'la gamba destra';
      case BodyPositions.chest:
        return 'il petto';
    }
  }
}