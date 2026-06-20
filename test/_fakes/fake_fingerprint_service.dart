import 'package:mercadopago_sdk/src/domain/models/device_data.dart';
import 'package:mercadopago_sdk/src/fingerprint/fingerprint_service.dart';

class FakeFingerprintService extends FingerprintService {
  FakeFingerprintService({this.data = const DeviceData.empty()});

  final DeviceData data;

  @override
  Future<DeviceData> collect() async => data;
}
