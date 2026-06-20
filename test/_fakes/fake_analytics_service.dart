import 'package:mercadopago_sdk/src/analytics/analytics_event.dart';
import 'package:mercadopago_sdk/src/analytics/analytics_service.dart';
import 'package:mercadopago_sdk/src/core/session_manager.dart';

class FakeAnalyticsService extends AnalyticsService {
  FakeAnalyticsService() : super(sessionManager: SessionManager());

  final List<AnalyticsEvent> events = [];

  @override
  void track(AnalyticsEvent event) {
    events.add(event);
  }
}
