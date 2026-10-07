part of 'pci.dart';

/// Sends card-token requests. Lives inside the `pci` library so the request
/// body — which carries the PAN — is assembled and dispatched without any
/// PAN-bearing object crossing a library boundary.
///
/// It takes the values as parameters rather than through a `NewCardInput`-style
/// object on purpose: such an object would have to be public to travel between
/// libraries, and any consuming app could then read the card number off it.
final class CardTokenRepositoryImpl {
  CardTokenRepositoryImpl(this._api);

  static const String _path = '/v1/card_tokens';

  final ApiClient _api;

  Future<CardToken> createNewCardToken({
    required String cardNumber,
    required String cardholderName,
    required int expirationMonth,
    required int expirationYear,
    required String securityCode,
    required String? documentType,
    required String? documentNumber,
    required DeviceData device,
  }) async {
    final body = <String, dynamic>{
      'card_number': cardNumber,
      'security_code': securityCode,
      'expiration_month': expirationMonth,
      'expiration_year': expirationYear,
      'cardholder': {
        'name': cardholderName,
        if (documentType != null && documentNumber != null)
          'identification': {'type': documentType, 'number': documentNumber},
      },
      if (!device.isEmpty) 'device': device.toJson(),
    };

    return _post(body);
  }

  Future<CardToken> createSavedCardToken({
    required String cardId,
    required String securityCode,
    required int? expirationMonth,
    required int? expirationYear,
    required DeviceData device,
  }) async {
    final body = <String, dynamic>{
      'card_id': cardId,
      'security_code': securityCode,
      'expiration_month': ?expirationMonth,
      'expiration_year': ?expirationYear,
      if (!device.isEmpty) 'device': device.toJson(),
    };

    return _post(body);
  }

  Future<CardToken> _post(Map<String, dynamic> body) async {
    final response = await _api.post(
      _path,
      body: body,
      sendProductIdHeader: true,
    );
    return CardTokenDto.fromJson(response).toDomain();
  }
}
