import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/car_control_service.dart';
import 'services/car_commands.dart';
import 'widgets/car_visualization.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    // 隱藏狀態列，實現全螢幕模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
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
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
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

class _RCControllerPageState extends State<RCControllerPage>
    with TickerProviderStateMixin {
  final _carService = CarControlService();
  final _isHeadlightOn = ValueNotifier<bool>(false);
  final _steeringDirection = ValueNotifier<String>('無');
  final _movementDirection = ValueNotifier<String>('停止');
  final Map<String, ValueNotifier<bool>> _buttonStates = {};
  final Map<String, AnimationController> _scaleControllers = {};

  // 車子入場動畫控制器
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  // 控制按鈕淡入動畫控制器
  late final AnimationController _controlsController;
  late final Animation<double> _controlsAnimation;

  // 方向指示器動畫控制器
  late final AnimationController _directionIndicatorController;
  late final Animation<double> _directionIndicatorAnimation;

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

    // 初始化入場動畫
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    // 初始化控制按鈕動畫
    _controlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _controlsAnimation = CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeOut,
    );

    // 初始化方向指示器動畫
    _directionIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _directionIndicatorAnimation = CurvedAnimation(
      parent: _directionIndicatorController,
      curve: Curves.easeInOut,
    );

    // 延遲1秒後開始入場動畫
    Future.delayed(const Duration(milliseconds: 1000), () {
      _entranceController.forward().then((_) {
        // 車子動畫完成後，開始控制按鈕動畫
        Future.delayed(const Duration(milliseconds: 200), () {
          _controlsController.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _isHeadlightOn.dispose();
    _steeringDirection.dispose();
    _movementDirection.dispose();
    _carService.dispose();
    _entranceController.dispose();
    _controlsController.dispose();
    _directionIndicatorController.dispose();
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
        _movementDirection.value = '前進';
        _directionIndicatorController.forward();
        _carService.moveForward();
      case '下':
        _movementDirection.value = '後退';
        _directionIndicatorController.forward();
        _carService.moveBackward();
      case '左':
        _steeringDirection.value = '左';
        _carService.turnLeft();
      case '右':
        _steeringDirection.value = '右';
        _carService.turnRight();
      case '停止':
        _movementDirection.value = '停止';
        _directionIndicatorController.reverse();
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
      body: Stack(
        children: [
          // 背景網格
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(),
          ),
          // 設定按鈕
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.8),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF2D2D2D),
                  width: 1.5,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: _showSettings,
              ),
            ),
          ),
          // 車子視覺化 - 延伸至螢幕上下
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 300, // 固定寬度
                height: double.infinity, // 延伸至螢幕上下
                margin: const EdgeInsets.symmetric(horizontal: 20), // 左右邊距
                decoration: BoxDecoration(
                  color: const Color.fromARGB(123, 32, 32, 32),
                  border: Border.all(
                    color: const Color.fromARGB(255, 45, 45, 45),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 31, 31, 31)
                          .withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CarVisualization(
                  isHeadlightOn: _isHeadlightOn,
                  steeringDirection: _steeringDirection,
                  movementDirection: _movementDirection,
                  entranceAnimation: _entranceAnimation,
                  directionIndicatorAnimation: _directionIndicatorAnimation,
                ),
              ),
            ),
          ),
          // 左方控制項目
          Positioned(
            left: 60,
            bottom: 30, // 往下靠，符合手部操作範圍
            child: _buildMovementController(),
          ),
          // 右方控制項目
          Positioned(
            right: 20,
            bottom: 30, // 往下靠，符合手部操作範圍
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

  Widget _buildControlButton(
      String direction, IconData icon, bool isTurnButton) {
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
              width: 50, // 稍微縮小按鈕尺寸
              height: 50,
              decoration: BoxDecoration(
                color: isPressed
                    ? const Color(0xFF1E88E5)
                    : const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isPressed
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF42A5F5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0)
                        .withOpacity(isPressed ? 0.3 : 0.5),
                    blurRadius: isPressed ? 4 : 8,
                    offset: Offset(0, isPressed ? 2 : 4),
                    spreadRadius: isPressed ? 0 : 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    if (isPressed)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            center: Alignment.center,
                            radius: 0.8,
                          ),
                        ),
                      ),
                    Center(
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 28, // 稍微縮小圖標尺寸
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovementController() {
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _controlsAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(-20 * (1 - _controlsAnimation.value), 0),
            child: child!,
          ),
        );
      },
      child: Container(
        width: 120,
        height: 180, // 再次減少高度
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.3),
          borderRadius: BorderRadius.circular(60),
          border: Border.all(
            color: const Color(0xFF2D2D2D),
            width: 1.5,
          ),
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
            const SizedBox(height: 15), // 再次縮小間距
            _buildControlButton('下', Icons.arrow_downward, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnController() {
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _controlsAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(20 * (1 - _controlsAnimation.value), 0),
            child: child!,
          ),
        );
      },
      child: Container(
        width: 200,
        height: 100, // 減少高度
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.3),
          borderRadius: BorderRadius.circular(60),
          border: Border.all(
            color: const Color(0xFF2D2D2D),
            width: 1.5,
          ),
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
            const SizedBox(width: 16),
            _buildControlButton('右', Icons.arrow_forward, true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadlightControl() {
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _controlsAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(20 * (1 - _controlsAnimation.value), 0),
            child: child!,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF2D2D2D),
            width: 1.5,
          ),
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
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 129, 129, 129).withOpacity(0.2)
      ..strokeWidth = 1;

    const spacing = 30.0;

    // 繪製垂直線
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 繪製水平線
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
