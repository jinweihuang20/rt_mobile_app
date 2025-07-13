import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/car_control_service.dart';
import 'services/car_commands.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RC Car Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade700,
          secondary: Colors.blue.shade500,
          surface: const Color.fromARGB(255, 22, 22, 22),
          background: const Color(0xFF121212),
          error: Colors.red.shade700,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 90, 90, 90),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const RCControllerPage(),
    );
  }
}

class RCControllerPage extends StatefulWidget {
  const RCControllerPage({super.key});

  @override
  State<RCControllerPage> createState() => _RCControllerPageState();
}

class _RCControllerPageState extends State<RCControllerPage> with TickerProviderStateMixin {
  final _carService = CarControlService();
  final _isHeadlightOn = ValueNotifier<bool>(false);
  final _steeringDirection = ValueNotifier<String>('無');
  final Map<String, ValueNotifier<bool>> _buttonStates = {};
  final Map<String, AnimationController> _scaleControllers = {};

  @override
  void initState() {
    super.initState();
    // 預先創建所有按鈕的動畫控制器
    for (final direction in ['上', '下', '左', '右']) {
      _scaleControllers[direction] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
      );
    }
  }

  @override
  void dispose() {
    _isHeadlightOn.dispose();
    _steeringDirection.dispose();
    _carService.dispose();
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    for (var state in _buttonStates.values) {
      state.dispose();
    }
    super.dispose();
  }

  ValueNotifier<bool> _getButtonState(String direction) {
    return _buttonStates.putIfAbsent(
      direction,
      () => ValueNotifier<bool>(false),
    );
  }

  void _handleDirectionChange(String direction) {
    switch (direction) {
      case '上':
        _carService.moveForward();
      case '下':
        _carService.moveBackward();
      case '左':
        _steeringDirection.value = '左';
        _carService.turnLeft();
      case '右':
        _steeringDirection.value = '右';
        _carService.turnRight();
      case '停止':
        _carService.stop();
      case '停止轉向':
        _steeringDirection.value = '無';
        _carService.turnStop();
    }
  }

  void _toggleHeadlight() {
    _isHeadlightOn.value = !_isHeadlightOn.value;
    _carService.toggleHeadlight(_isHeadlightOn.value);
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('更多設定選項即將推出...'),
            const SizedBox(height: 16),
            Text('API 端點: ${CarControlService.baseUrl}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RC Car Controller'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 添加車子視覺化
          Center(
            child: _buildCarVisualization(),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: _buildMovementController(),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeadlightControl(),
                const SizedBox(height: 20),
                _buildTurnController(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarVisualization() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isHeadlightOn,
      builder: (context, isHeadlightOn, _) {
        return ValueListenableBuilder<String>(
          valueListenable: _steeringDirection,
          builder: (context, steeringDirection, _) {
            return Container(
              width: 200,
              height: 300,
              child: CustomPaint(
                painter: CarPainter(
                  isHeadlightOn: isHeadlightOn,
                  steeringDirection: steeringDirection,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeadlightControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _isHeadlightOn,
            builder: (context, isOn, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.lightbulb,
                color: isOn ? Colors.amber : Colors.grey.shade600,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _isHeadlightOn,
            builder: (context, isOn, _) => Switch(
              value: isOn,
              onChanged: (_) {
                HapticFeedback.lightImpact();
                _toggleHeadlight();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String direction, IconData icon, bool isTurnButton) {
    final buttonState = _getButtonState(direction);
    final scaleController = _scaleControllers[direction]!;
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: scaleController,
      curve: Curves.easeInOut,
    ));

    return ValueListenableBuilder<bool>(
      valueListenable: buttonState,
      builder: (context, isPressed, _) {
        return GestureDetector(
          onTapDown: (_) {
            buttonState.value = true;
            scaleController.forward();
            HapticFeedback.lightImpact();
            _handleDirectionChange(direction);
          },
          onTapUp: (_) {
            buttonState.value = false;
            scaleController.reverse();
            _handleDirectionChange(isTurnButton ? '停止轉向' : '停止');
          },
          onTapCancel: () {
            buttonState.value = false;
            scaleController.reverse();
            _handleDirectionChange(isTurnButton ? '停止轉向' : '停止');
          },
          child: AnimatedBuilder(
            animation: scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: scaleAnimation.value,
              child: child,
            ),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPressed
                    ? const Color(0xFF1E88E5) // 深藍色
                    : const Color(0xFF2196F3), // 藍色
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(isPressed ? 0.3 : 0.5),
                    blurRadius: isPressed ? 4 : 8,
                    offset: Offset(0, isPressed ? 2 : 4),
                    spreadRadius: isPressed ? 0 : 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovementController() {
    return Container(
      width: 120,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.3),
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton('上', Icons.arrow_upward, false),
          const SizedBox(height: 20),
          _buildControlButton('下', Icons.arrow_downward, false),
        ],
      ),
    );
  }

  Widget _buildTurnController() {
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.3),
        borderRadius: BorderRadius.circular(60),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton('左', Icons.arrow_back, true),
          const SizedBox(width: 20),
          _buildControlButton('右', Icons.arrow_forward, true),
        ],
      ),
    );
  }
}

class CarPainter extends CustomPainter {
  final bool isHeadlightOn;
  final String steeringDirection; // '左', '右', or '無'

  CarPainter({
    required this.isHeadlightOn,
    this.steeringDirection = '無',
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 貨斗（後車廂）- 深灰色
    final cargoBoxPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final cargoBox = Path()
      ..moveTo(size.width * 0.3, size.height * 0.4) // 左上
      ..lineTo(size.width * 0.7, size.height * 0.4) // 右上
      ..lineTo(size.width * 0.7, size.height * 0.8) // 右下
      ..lineTo(size.width * 0.3, size.height * 0.8) // 左下
      ..close();

    canvas.drawPath(cargoBox, cargoBoxPaint);

    // 車頭 - 藍色
    final cabPaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.fill
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cab = Path()
      ..moveTo(size.width * 0.3, size.height * 0.15) // 左上
      ..lineTo(size.width * 0.7, size.height * 0.15) // 右上
      ..lineTo(size.width * 0.7, size.height * 0.4) // 右下
      ..lineTo(size.width * 0.3, size.height * 0.4) // 左下
      ..close();

    canvas.drawPath(cab, cabPaint);

    // 擋風玻璃 - 淺藍色半透明
    final windshieldPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final windshield = Path()
      ..moveTo(size.width * 0.35, size.height * 0.2)
      ..lineTo(size.width * 0.65, size.height * 0.2)
      ..lineTo(size.width * 0.65, size.height * 0.35)
      ..lineTo(size.width * 0.35, size.height * 0.35)
      ..close();

    canvas.drawPath(windshield, windshieldPaint);

    // 車輪 - 黑色
    final wheelPaint = Paint()
      ..color = const Color.fromARGB(255, 92, 92, 92)
      ..style = PaintingStyle.fill;

    // 計算前輪旋轉角度
    double wheelAngle = 0;
    if (steeringDirection == '左') {
      wheelAngle = -0.4; // 約23度
    } else if (steeringDirection == '右') {
      wheelAngle = 0.4;
    }

    // 左前輪（可旋轉）
    canvas.save();
    canvas.translate(size.width * 0.32, size.height * 0.3);
    canvas.rotate(wheelAngle);
    _drawWheel(canvas, size.width * 0.05, wheelPaint);
    canvas.restore();

    // 右前輪（可旋轉）
    canvas.save();
    canvas.translate(size.width * 0.68, size.height * 0.3);
    canvas.rotate(wheelAngle);
    _drawWheel(canvas, size.width * 0.05, wheelPaint);
    canvas.restore();

    // 左後輪（雙輪）

    canvas.save();
    canvas.translate(size.width * 0.32, size.height * 0.67);
    _drawWheel(canvas, size.width * 0.05, wheelPaint);
    canvas.restore();

    // 右後輪（雙輪）

    canvas.save();
    canvas.translate(size.width * 0.68, size.height * 0.67);
    _drawWheel(canvas, size.width * 0.05, wheelPaint);
    canvas.restore();

    // 車頭燈
    final headlightPaint = Paint()
      ..color = isHeadlightOn ? Colors.yellow : Colors.grey.shade400
      ..style = PaintingStyle.fill;

    // 左車頭燈
    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.17),
      size.width * 0.03,
      headlightPaint,
    );

    // 右車頭燈
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.17),
      size.width * 0.03,
      headlightPaint,
    );

    if (isHeadlightOn) {
      // 車頭燈光束效果
      final lightBeamPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.yellow.withOpacity(0.3),
            Colors.yellow.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.17),
          radius: size.width * 0.2,
        ));

      // 整體光束
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.1),
        size.width * 0.3,
        lightBeamPaint,
      );
    }

    // 貨斗邊框和花紋
    final cargoDetailPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 貨斗邊框
    canvas.drawPath(cargoBox, cargoDetailPaint);

    // 車身輪廓
    final outlinePaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(cab, outlinePaint);
  }

  void _drawWheel(Canvas canvas, double radius, Paint paint) {
    // 使用圓角矩形繪製輪胎
    final wheelRect = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 1.4, // 稍微加寬
      height: radius * 2.2, // 高度略小於寬度
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        wheelRect,
        Radius.circular(radius * 0.4), // 圓角半徑
      ),
      paint,
    );

    // // 輪胎花紋（三條平行線）
    // final linePaint = Paint()
    //   ..color = Colors.grey.shade400
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 0.5;

    // final lineSpacing = radius * 0.4;
    // for (var i = -1; i <= 1; i++) {
    //   canvas.drawLine(
    //     Offset(i * lineSpacing, -radius * 0.8),
    //     Offset(i * lineSpacing, radius * 0.8),
    //     linePaint,
    //   );
    // }
  }

  @override
  bool shouldRepaint(CarPainter oldDelegate) {
    return oldDelegate.isHeadlightOn != isHeadlightOn || oldDelegate.steeringDirection != steeringDirection;
  }
}
