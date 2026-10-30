/// DOCASA BLE identity & GATT IDs.
///
/// Single source of truth on the app side. Mirrors `docs/BLE-Protocol-Contract.md`
/// v1.0 (frozen 2026-10-30, Decision D-002). UUIDs must never be regenerated here
/// without a Decision-Log entry.
abstract final class DocasaContract {
  static const int protocolVersion = 1;
  static const String deviceName = 'DOCASA-AirPurifier';

  // Custom telemetry service (128-bit, frozen)
  static const String serviceUuid = 'd0ca5a0e-975a-4408-9059-a93d3207072f';
  static const String airQualityUuid = 'd0ca5a22-27ed-4fbe-aa36-dd1ffdc66f7f';
  static const String environmentUuid = 'd0ca5acb-dcfc-4d8f-8a52-b21558697f7e';
  static const String systemStatusUuid = 'd0ca5a8f-1160-4c49-a9ee-138998d9c402';
  static const String filterCountersUuid = 'd0ca5a7a-fd2b-4dbf-932a-855cb6d3ddf0';
  static const String commandUuid = 'd0ca5abd-8a7e-4412-9e96-a01d4656f3f7';

  // Standard services (Contract §3)
  static const String deviceInformationServiceUuid = '180A';
  static const String manufacturerNameUuid = '2A29';
  static const String modelNumberUuid = '2A24';
  static const String firmwareRevisionUuid = '2A26';
  static const String hardwareRevisionUuid = '2A27';
  static const String batteryServiceUuid = '180F';
  static const String batteryLevelUuid = '2A19';

  /// Payload `"v"` field consumed/produced by the codec.
  static const int payloadVersion = 1;
}
