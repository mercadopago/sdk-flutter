import 'package:mercadopago_flutter_sdk/src/analytics/analytics_event.dart';
import 'package:mercadopago_flutter_sdk/src/analytics/analytics_service.dart';
import 'package:mercadopago_flutter_sdk/src/core/session_manager.dart';

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
