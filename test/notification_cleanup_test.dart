import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:germanreminder/notification_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const native = MethodChannel('german_reminder/reminders');
  const legacy = MethodChannel('dexterous.com/flutter/local_notifications');
  final nativeCalls = <MethodCall>[];
  var legacyCalls = 0;
  setUp(() {
    nativeCalls.clear();
    legacyCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(native, (call) async {
      nativeCalls.add(call);
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(legacy, (call) async {
      legacyCalls++;
      throw PlatformException(
          code: 'error',
          message: 'TypeToken must be created with a type argument');
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(native, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(legacy, null);
  });
  test('Android cancellation never reads the broken legacy plugin cache',
      () async {
    final api = NotificationApi(android: true);
    await api.cancel(0);
    await api.cancel(2100);
    await api.cancel(2107);
    expect(legacyCalls, 0);
    expect(nativeCalls.map((c) => c.method), ['cancel', 'cancel', 'cancel']);
    expect(nativeCalls.map((c) => (c.arguments as Map)['id']), [0, 2100, 2107]);
  });
  test(
      'emergency shutdown is a single native operation independent of cache reads',
      () async {
    await NotificationApi(android: true).emergencyDisable();
    expect(legacyCalls, 0);
    expect(nativeCalls.single.method, 'disable');
  });
}
