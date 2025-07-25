import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class CarVisualization extends StatefulWidget {
  final ValueNotifier<bool> isHeadlightOn;
  final ValueNotifier<bool> entranceHeadlightState;
  final ValueNotifier<String> steeringDirection;
  final ValueNotifier<String> movementDirection;
  final Animation<double> entranceAnimation;
  final Animation<double> directionIndicatorAnimation;

  const CarVisualization({
    super.key,
    required this.isHeadlightOn,
    required this.entranceHeadlightState,
    required this.steeringDirection,
    required this.movementDirection,
    required this.entranceAnimation,
    required this.directionIndicatorAnimation,
  });

  @override
  State<CarVisualization> createState() => _CarVisualizationState();
}

class _CarVisualizationState extends State<CarVisualization>
    with TickerProviderStateMixin {
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _minScale = 0.5;
  double _maxScale = 2.0;

  // Zoom in 動畫控制器
  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化 zoom in 動畫
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // 增加動畫時間，讓變化更漸進
    );

    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 1.10, // 更溫和的放大倍數
    ).animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeOutCubic, // 使用更漸進的曲線，開始慢，結束快
    ));

    // 監聽入場動畫完成，然後開始 zoom in 動畫
    widget.entranceAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 延遲一小段時間後開始 zoom in 動畫
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _zoomController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 方向指示器
        ValueListenableBuilder<String>(
          valueListenable: widget.movementDirection,
          builder: (context, direction, _) {
            return AnimatedBuilder(
              animation: widget.directionIndicatorAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity:
                      widget.directionIndicatorAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12), // 減少邊距
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6), // 減少內邊距
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2D2D2D),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          direction == '前進'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Colors.blue,
                          size: 18, // 縮小圖標
                        ),
                        const SizedBox(width: 6), // 減少間距
                        Text(
                          direction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13, // 縮小字體
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6), // 減少間距
                        Container(
                          width: 32, // 縮小進度條
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade200,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        // 車子視覺化
        Expanded(
          child: AnimatedBuilder(
            animation: widget.entranceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                    0, 60 * (1 - widget.entranceAnimation.value)), // 減少初始偏移
                child: Opacity(
                  opacity: widget.entranceAnimation.value.clamp(0.0, 1.0),
                  child: AnimatedBuilder(
                    animation: _zoomAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _zoomAnimation.value,
                        child: GestureDetector(
                          onScaleStart: (details) {
                            _baseScale = _scale;
                          },
                          onScaleUpdate: (details) {
                            setState(() {
                              _scale = (_baseScale * details.scale)
                                  .clamp(_minScale, _maxScale);
                            });
                          },
                          child: Transform.scale(
                            scale: _scale,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: widget.isHeadlightOn,
                              builder: (context, headlightOn, _) {
                                return ValueListenableBuilder<bool>(
                                  valueListenable:
                                      widget.entranceHeadlightState,
                                  builder: (context, entranceHeadlight, _) {
                                    return ValueListenableBuilder<String>(
                                      valueListenable: widget.steeringDirection,
                                      builder: (context, steeringDir, _) {
                                        return Container(
                                          width: 180, // 車子視覺化寬度
                                          height: 260, // 車子視覺化高度
                                          padding: const EdgeInsets.all(1),
                                          child: CustomPaint(
                                            painter: CarPainter(
                                              isHeadlightOn: headlightOn ||
                                                  entranceHeadlight,
                                              steeringDirection: steeringDir,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
      ..lineTo(size.width * 0.7, size.height * 0.7) // 右下
      ..lineTo(size.width * 0.3, size.height * 0.7) // 左下
      ..close();

    canvas.drawPath(cargoBox, cargoBoxPaint);

    // 車頭 - 藍色
    final cabPaint = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.fill
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cab = Path()
      ..moveTo(size.width * 0.3, size.height * 0.2) // 左上
      ..lineTo(size.width * 0.7, size.height * 0.2) // 右上
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
    canvas.translate(size.width * 0.32, size.height * 0.6);
    _drawWheel(canvas, size.width * 0.05, wheelPaint);
    canvas.restore();

    // 右後輪（雙輪）
    canvas.save();
    canvas.translate(size.width * 0.68, size.height * 0.6);
    _drawWheel(canvas, size.width * 0.05, wheelPaint);
    canvas.restore();

    // 車頭燈
    final headlightPaint = Paint()
      ..color = isHeadlightOn ? Colors.yellow : Colors.grey.shade400
      ..style = PaintingStyle.fill;

    // 左車頭燈
    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.2),
      size.width * 0.03,
      headlightPaint,
    );

    // 右車頭燈
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.2),
      size.width * 0.03,
      headlightPaint,
    );

    if (isHeadlightOn) {
      // 車頭燈錐形光束效果
      final lightBeamPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.yellow.withOpacity(0.4),
            Colors.yellow.withOpacity(0.2),
            Colors.yellow.withOpacity(0.1),
            Colors.yellow.withOpacity(0),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.05),
          radius: size.width * 0.4,
        ));

      // 左車頭燈錐形光束
      final leftBeamPath = Path()
        ..moveTo(size.width * 0.36, size.height * 0.2) // 左車頭燈位置
        ..lineTo(size.width * 0.25, size.height * 0.05) // 左上角
        ..lineTo(size.width * 0.45, size.height * 0.05) // 右上角
        ..close();

      final leftBeamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.yellow.withOpacity(0.3),
            Colors.yellow.withOpacity(0.1),
            Colors.yellow.withOpacity(0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(leftBeamPath, leftBeamPaint);

      // 右車頭燈錐形光束
      final rightBeamPath = Path()
        ..moveTo(size.width * 0.64, size.height * 0.2) // 右車頭燈位置
        ..lineTo(size.width * 0.55, size.height * 0.05) // 左上角
        ..lineTo(size.width * 0.75, size.height * 0.05) // 右上角
        ..close();

      final rightBeamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.yellow.withOpacity(0.3),
            Colors.yellow.withOpacity(0.1),
            Colors.yellow.withOpacity(0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(rightBeamPath, rightBeamPaint);

      // 整體環境光效果
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.05),
        size.width * 0.35,
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
  }

  @override
  bool shouldRepaint(CarPainter oldDelegate) {
    return oldDelegate.isHeadlightOn != isHeadlightOn ||
        oldDelegate.steeringDirection != steeringDirection;
  }
}
