import '../../core/api_client.dart';
import '../../domain/models/card_token.dart';
import '../../domain/models/device_data.dart';
import '../../domain/repositories.dart';
import '../dtos/card_token_dto.dart';

class CardTokenRepositoryImpl implements TokenRepository {
  CardTokenRepositoryImpl(this._api);

  static const String _path = '/v1/card_tokens';

  final ApiClient _api;

  @override
  Future<CardToken> createTokenForNewCard(
    NewCardInput input,
    DeviceData device,
  ) async {
    final body = <String, dynamic>{
      'card_number': input.cardNumber,
      'security_code': input.securityCode,
      'expiration_month': input.expirationMonth,
      'expiration_year': input.expirationYear,
      'cardholder': {
        'name': input.cardholderName,
        if (input.documentType != null && input.documentNumber != null)
          'identification': {
            'type': input.documentType,
            'number': input.documentNumber,
          },
      },
      if (!device.isEmpty) 'device': device.toJson(),
    };

    final response =
        await _api.post(_path, body: body, sendProductIdHeader: true);
    return CardTokenDto.fromJson(response).toDomain();
  }

  @override
  Future<CardToken> createTokenForSavedCard(
    SavedCardInput input,
    DeviceData device,
  ) async {
    final body = <String, dynamic>{
      'card_id': input.cardId,
      'security_code': input.securityCode,
      if (input.expirationMonth != null)
        'expiration_month': input.expirationMonth,
      if (input.expirationYear != null)
        'expiration_year': input.expirationYear,
      if (!device.isEmpty) 'device': device.toJson(),
    };

    final response =
        await _api.post(_path, body: body, sendProductIdHeader: true);
    return CardTokenDto.fromJson(response).toDomain();
  }
}
