enum CarCommand {
  moveForward('/forward'),
  moveBackward('/backward'),
  stop('/stop'),
  turnLeft('/left'),
  turnRight('/right'),
  turnStop('/center'),
  headlightOn('/light/on'),
  headlightOff('/light/off');

  final String endpoint;
  const CarCommand(this.endpoint);
}
