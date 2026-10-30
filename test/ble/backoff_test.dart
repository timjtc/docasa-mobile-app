import 'package:docasa_app/ble/fbp/fbp_docasa_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reconnect backoff doubles from 0.5 s to the 8 s cap (Plan §7.15)',
      () {
    final asMs = [for (var i = 1; i <= 7; i++) backoffDelay(i).inMilliseconds];
    expect(asMs, const [500, 1000, 2000, 4000, 8000, 8000, 8000]);
  });
}
