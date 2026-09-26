import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_ide/ai_bridge/models/ai_bridge_models.dart';

void main() {
  test('AI Bridge default permissions are limited but usable', () {
    expect(
      AiBridgePermissionSetCodec.defaults,
      contains(AiBridgePermission.readFiles),
    );
    expect(
      AiBridgePermissionSetCodec.defaults,
      contains(AiBridgePermission.build),
    );
    expect(
      AiBridgePermissionSetCodec.defaults,
      isNot(contains(AiBridgePermission.terminal)),
    );
  });

  test('AI Bridge permission codec round-trips known names', () {
    final decoded = AiBridgePermissionSetCodec.decodeSet([
      'readFiles',
      'writeFiles',
      'terminal',
      'unknown_permission',
    ]);

    expect(decoded, contains(AiBridgePermission.readFiles));
    expect(decoded, contains(AiBridgePermission.writeFiles));
    expect(decoded, contains(AiBridgePermission.terminal));
    expect(decoded.length, 3);
  });

  test('AI Bridge settings preserve endpoint configuration fields', () {
    const settings = AiBridgeSettings(
      enabled: true,
      lanMode: true,
      apiKey: 'xcore_test',
      port: 9876,
    );

    final restored = AiBridgeSettings.fromJson(settings.toJson());

    expect(restored.enabled, isTrue);
    expect(restored.lanMode, isTrue);
    expect(restored.apiKey, 'xcore_test');
    expect(restored.port, 9876);
  });
}
