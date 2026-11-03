import 'package:mercadopago_sdk_flutter/src/analytics/analytics_event.dart';
import 'package:mercadopago_sdk_flutter/src/analytics/analytics_service.dart';
import 'package:mercadopago_sdk_flutter/src/core/session_manager.dart';

class FakeAnalyticsService extends AnalyticsService {
  FakeAnalyticsService()
    : super(
        sessionManager: SessionManager(),
        publicKey: 'APP_USR-test',
        siteId: 'MLA',
      );

  final List<AnalyticsEvent> events = [];

  @override
  void track(AnalyticsEvent event) {
    events.add(event);
  }
}
