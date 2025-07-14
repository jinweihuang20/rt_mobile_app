import 'package:flutter/material.dart';

class CarVisualization extends StatelessWidget {
  final ValueNotifier<bool> isHeadlightOn;
  final ValueNotifier<String> steeringDirection;
  final ValueNotifier<String> movementDirection;
  final Animation<double> entranceAnimation;
  final Animation<double> directionIndicatorAnimation;

  const CarVisualization({
    super.key,
    required this.isHeadlightOn,
    required this.steeringDirection,
    required this.movementDirection,
    required this.entranceAnimation,
    required this.directionIndicatorAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 方向指示器
        ValueListenableBuilder<String>(
          valueListenable: movementDirection,
          builder: (context, direction, _) {
            return AnimatedBuilder(
              animation: directionIndicatorAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: directionIndicatorAnimation.value.clamp(0.0, 1.0),
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
            animation: entranceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 60 * (1 - entranceAnimation.value)), // 減少初始偏移
                child: Opacity(
                  opacity: entranceAnimation.value.clamp(0.0, 1.0),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isHeadlightOn,
                    builder: (context, headlightOn, _) {
                      return ValueListenableBuilder<String>(
                        valueListenable: steeringDirection,
                        builder: (context, steeringDir, _) {
                          return Container(
                            width: 180, // 車子視覺化寬度
                            height: 260, // 車子視覺化高度
                            padding: const EdgeInsets.all(1),
                            child: CustomPaint(
                              painter: CarPainter(
                                isHeadlightOn: headlightOn,
                                steeringDirection: steeringDir,
                              ),
                            ),
                          );
                        },
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
      // 車頭燈光束效果
      final lightBeamPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.yellow.withOpacity(0.3),
            Colors.yellow.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.2),
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
  }

  @override
  bool shouldRepaint(CarPainter oldDelegate) {
    return oldDelegate.isHeadlightOn != isHeadlightOn ||
        oldDelegate.steeringDirection != steeringDirection;
  }
}
