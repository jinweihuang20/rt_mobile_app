import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

enum ConnectionState { disconnected, connecting, connected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  String? _host;
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  final _messageController = StreamController<dynamic>.broadcast();
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  // 公開的串流
  Stream<ConnectionState> get connectionState => _connectionStateController.stream;
  Stream<dynamic> get messages => _messageController.stream;

  // 當前連接狀態
  ConnectionState _currentState = ConnectionState.disconnected;
  ConnectionState get currentState => _currentState;

  // 連接到 WebSocket 服務器
  Future<void> connect(String host) async {
    if (_isDisposed) return;

    if (_currentState == ConnectionState.connecting) return;

    _host = host;
    _updateState(ConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(host));
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
    } catch (e) {
      print('WebSocket connection failed: $e');
      _handleConnectionError();
    }
  }

  // 發送訊息
  void send(dynamic message) {
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

  // 斷開連接
  Future<void> disconnect() async {
    _stopReconnectTimer();
    await _closeConnection();
    _updateState(ConnectionState.disconnected);
  }

  // 處理連接錯誤
  void _handleConnectionError() {
    _closeConnection();
    _updateState(ConnectionState.error);
    _startReconnectTimer();
  }

  // 開始重連計時器
  void _startReconnectTimer() {
    _stopReconnectTimer();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_host != null && _currentState != ConnectionState.connected) {
        connect(_host!);
      }
    });
  }

  // 停止重連計時器
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // 更新連接狀態
  void _updateState(ConnectionState newState) {
    _currentState = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
  }

  // 關閉當前連接
  Future<void> _closeConnection() async {
    try {
      await _channel?.sink.close(status.goingAway);
    } catch (e) {
      print('Error closing connection: $e');
    } finally {
      _channel = null;
    }
  }

  // 釋放資源
  void dispose() {
    _isDisposed = true;
    _stopReconnectTimer();
    _closeConnection();
    _connectionStateController.close();
    _messageController.close();
  }
}
