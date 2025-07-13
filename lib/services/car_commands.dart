enum CarCommand {
  forward,
  backward,
  left,
  right,
  turnStop,
  stop,
  headlightOn,
  headlightOff;

  String get commandName {
    switch (this) {
      case CarCommand.forward:
        return '前進';
      case CarCommand.backward:
        return '後退';
      case CarCommand.left:
        return '左轉';
      case CarCommand.right:
        return '右轉';
      case CarCommand.turnStop:
        return '停止轉向';
      case CarCommand.stop:
        return '停止';
      case CarCommand.headlightOn:
        return '開啟車燈';
      case CarCommand.headlightOff:
        return '關閉車燈';
    }
  }
}
