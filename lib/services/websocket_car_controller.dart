import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'car_controller_interface.dart';
import 'car_commands.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class WebSocketCarController implements CarControllerInterface {
  static const String defaultWsUrl = 'ws://192.168.0.112:81';
  final String wsUrl;

  WebSocketChannel? _channel;
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<dynamic>.broadcast();
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  ConnectionState _currentState = ConnectionState.disconnected;

  // 公開的串流
  Stream<ConnectionState> get connectionState => _connectionStateController.stream;
  Stream<dynamic> get messages => _messageController.stream;
  ConnectionState get currentState => _currentState;

  WebSocketCarController({String? wsUrl}) : wsUrl = wsUrl ?? defaultWsUrl;

  @override
  Future<void> initialize() async {
    if (_isDisposed) return;

    if (_currentState == ConnectionState.connecting) return;

    _updateState(ConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _updateState(ConnectionState.connected);

      // 監聽訊息
      _channel?.stream.listen(
        (message) {
          if (!_messageController.isClosed) {
            _messageController.add(message);
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleConnectionError();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleConnectionError();
        },
      );

      // 連接成功時發送初始訊息
      _sendMessage('hello');
    } catch (e) {
      print('WebSocket connection failed: $e');
      _handleConnectionError();
    }
  }

  void _sendMessage(String message) {
    if (_currentState != ConnectionState.connected) {
      print('Cannot send message: WebSocket is not connected');
      return;
    }

    try {
      _channel?.sink.add(message);
    } catch (e) {
      print('Error sending message: $e');
      _handleConnectionError();
    }
  }

  Future<void> _sendCommand(CarCommand command) async {
    _sendMessage(command.endpoint);
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

  void _handleConnectionError() {
    _closeConnection();
    _updateState(ConnectionState.error);
    _startReconnectTimer();
  }

  void _startReconnectTimer() {
    _stopReconnectTimer();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentState != ConnectionState.connected) {
        initialize();
      }
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _updateState(ConnectionState newState) {
    _currentState = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
  }

  Future<void> _closeConnection() async {
    try {
      await _channel?.sink.close();
    } catch (e) {
      print('Error closing connection: $e');
    } finally {
      _channel = null;
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _stopReconnectTimer();
    await _closeConnection();
    await _connectionStateController.close();
    await _messageController.close();
  }
}
