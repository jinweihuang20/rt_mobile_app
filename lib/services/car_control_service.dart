import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'car_commands.dart';

class CarControlService {
  static const String baseUrl = 'https://smartcamcurtainbackendserver.fly.dev/api';
  static final CarControlService _instance = CarControlService._internal();

  DateTime? _lastCommandTime;
  final _debounceInterval = const Duration(milliseconds: 200); // 增加防抖間隔
  http.Client? _client;
  String? _lastCommand;

  factory CarControlService() {
    return _instance;
  }

  CarControlService._internal() {
    _client = http.Client();
  }

  void dispose() {
    _client?.close();
    _client = null;
  }

  Future<void> _sendCommand(String endpoint, Map<String, dynamic> data) async {
    if (_client == null) {
      _client = http.Client();
    }

    // 防抖動檢查
    final now = DateTime.now();
    // if (_lastCommandTime != null && now.difference(_lastCommandTime!) < _debounceInterval) {
    //   print('命令被防抖動機制攔截');
    //   return;
    // }
    _lastCommandTime = now;

    // 檢查命令是否重複
    final commandKey = '$endpoint${jsonEncode(data)}';
    // if (commandKey == _lastCommand) {
    //   print('重複命令被攔截');
    //   return;
    // }
    _lastCommand = commandKey;

    try {
      final response = await _client!
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 2)); // 減少超時時間

      if (response.statusCode == 200) {
        print('命令發送成功 - Endpoint: $endpoint');
        return;
      }
      print('請求失敗: ${response.statusCode}');
    } catch (e) {
      print('命令發送失敗: $e');
      // 如果是連接問題，重新創建客戶端
      if (e is SocketException || e is HttpException) {
        _client?.close();
        _client = http.Client();
      }
    }
  }

  // 前進
  Future<void> moveForward() async {
    await _sendCommand('RTCar/Forward?deviceID=endpoint-demo', {
      'command': CarCommand.forward.name,
      'action': 'start',
    });
  }

  // 後退
  Future<void> moveBackward() async {
    await _sendCommand('RTCar/Backward?deviceID=endpoint-demo', {
      'command': CarCommand.backward.name,
      'action': 'start',
    });
  }

  // 左轉
  Future<void> turnLeft() async {
    await _sendCommand('RTCar/Left?deviceID=endpoint-demo', {
      'command': CarCommand.left.name,
      'action': 'start',
    });
  }

  // 右轉
  Future<void> turnRight() async {
    await _sendCommand('RTCar/Right?deviceID=endpoint-demo', {
      'command': CarCommand.right.name,
      'action': 'start',
    });
  }

  // 停止轉向
  Future<void> turnStop() async {
    await _sendCommand('RTCar/NoTurn?deviceID=endpoint-demo', {
      'command': CarCommand.turnStop.name,
      'action': 'start',
    });
  }

  // 停止
  Future<void> stop() async {
    await _sendCommand('RTCar/stop?deviceID=endpoint-demo', {
      'command': CarCommand.stop.name,
      'action': 'stop',
    });
  }

  // 控制車頭燈
  Future<void> toggleHeadlight(bool isOn) async {
    final endpoint = isOn ? 'RTCar/headlighton' : 'RTCar/headlightoff';
    await _sendCommand('$endpoint?deviceID=endpoint-demo', {});
  }

  // 設定速度
  Future<void> setSpeed(int speed) async {
    await _sendCommand('RTCar/speed?deviceID=endpoint-demo', {
      'speed': speed,
    });
  }
}
