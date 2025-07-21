import 'package:http/http.dart' as http;
import 'car_controller_interface.dart';
import 'car_commands.dart';

class HttpCarController implements CarControllerInterface {
  static const String defaultBaseUrl = 'http://192.168.0.112:80';
  final String baseUrl;
  final http.Client _client = http.Client();

  HttpCarController({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  @override
  Future<void> initialize() async {
    // HTTP 控制器不需要特別的初始化
  }

  @override
  Future<void> moveForward() async {
    await _sendCommand(CarCommand.moveForward);
  }

  @override
  Future<void> moveBackward() async {
    await _sendCommand(CarCommand.moveBackward);
  }

  @override
  Future<void> stop() async {
    await _sendCommand(CarCommand.stop);
  }

  @override
  Future<void> turnLeft() async {
    await _sendCommand(CarCommand.turnLeft);
  }

  @override
  Future<void> turnRight() async {
    await _sendCommand(CarCommand.turnRight);
  }

  @override
  Future<void> turnStop() async {
    await _sendCommand(CarCommand.turnStop);
  }

  @override
  Future<void> toggleHeadlight(bool isOn) async {
    await _sendCommand(isOn ? CarCommand.headlightOn : CarCommand.headlightOff);
  }

  Future<void> _sendCommand(CarCommand command) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl${command.endpoint}'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send command: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending command: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
