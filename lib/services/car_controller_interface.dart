/// 定義車輛控制器的介面
abstract class CarControllerInterface {
  /// 初始化控制器
  Future<void> initialize();

  /// 向前移動
  Future<void> moveForward();

  /// 向後移動
  Future<void> moveBackward();

  /// 停止移動
  Future<void> stop();

  /// 向左轉
  Future<void> turnLeft();

  /// 向右轉
  Future<void> turnRight();

  /// 停止轉向
  Future<void> turnStop();

  /// 切換車頭燈
  Future<void> toggleHeadlight(bool isOn);

  /// 釋放資源
  Future<void> dispose();
}
