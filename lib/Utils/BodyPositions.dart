enum BodyPositions {
  leftWrist,
  rightWrist,
  leftAnkle,
  rightAnkle,
  leftPocket,
  rightPocket,
  belt,
  chest,
}

extension BodyPositionsExtension on BodyPositions {
  String get name {
    switch (this) {
      case BodyPositions.leftWrist:
        return 'left wrist';
      case BodyPositions.rightWrist:
        return 'right wrist';
      case BodyPositions.leftPocket:
        return 'left pocket';
      case BodyPositions.rightPocket:
        return 'right pocket';
      case BodyPositions.leftAnkle:
        return 'left ankle';
      case BodyPositions.rightAnkle:
        return 'right ankle';
      case BodyPositions.belt:
        return 'belt';
      case BodyPositions.chest:
        return 'chest';
    }
  }

  String get nameUpperCase {
    switch (this) {
      case BodyPositions.leftWrist:
        return 'Left wrist';
      case BodyPositions.rightWrist:
        return 'Right wrist';
      case BodyPositions.leftPocket:
        return 'Left pocket';
      case BodyPositions.rightPocket:
        return 'Right pocket';
      case BodyPositions.leftAnkle:
        return 'Left ankle';
      case BodyPositions.rightAnkle:
        return 'Right ankle';
      case BodyPositions.belt:
        return 'Belt';
      case BodyPositions.chest:
        return 'Chest';
    }
  }

  String get limb {
    switch (this) {
      case BodyPositions.leftWrist:
        return 'the left arm';
      case BodyPositions.rightWrist:
        return 'the right arm';
      case BodyPositions.leftPocket:
        return 'the left leg';
      case BodyPositions.rightPocket:
        return 'the right leg';
      case BodyPositions.leftAnkle:
        return 'the left leg';
      case BodyPositions.rightAnkle:
        return 'the right leg';
      case BodyPositions.belt:
        return 'the belt';
      case BodyPositions.chest:
        return 'the chest';
    }
  }
}