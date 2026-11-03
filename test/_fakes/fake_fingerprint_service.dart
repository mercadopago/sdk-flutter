import 'package:mercadopago_sdk_flutter/src/domain/models/device_data.dart';
import 'package:mercadopago_sdk_flutter/src/fingerprint/fingerprint_service.dart';

class FakeFingerprintService extends FingerprintService {
  FakeFingerprintService({
    this.data = const DeviceData.empty(),
    this.collectionBarrier,
    this.onCollect,
  });

  final DeviceData data;
  final Future<void>? collectionBarrier;
  final void Function()? onCollect;

  @override
  Future<DeviceData> collect() async {
    onCollect?.call();
    if (collectionBarrier != null) await collectionBarrier;
    return data;
  }
}
