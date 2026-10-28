/// Official MercadoPago SDK for Flutter.
///
/// Initialize with [MercadoPagoSDK.shared], then build a custom card form with
/// the PCI widgets ([CardNumberField], [SecurityCodeField], and
/// [ExpirationDateField]) and tokenize through [CoreMethods].
library;

// SDK entry point.
export 'src/core/mercadopago_sdk.dart' show MercadoPagoSDK;
export 'src/core/configuration.dart' show Configuration, Country;
export 'src/core/sdk_error.dart'
    show
        SDKError,
        SDKNotInitializedError,
        SDKAlreadyInitializedError,
        SDKInvalidPublicKeyError,
        SDKInvalidCountryError;

// CoreMethods consumes PCI field controllers without exposing raw values.
export 'src/core_methods/core_methods.dart' show CoreMethods;
export 'src/domain/repositories.dart' show ProcessingMode;

// Result + error types.
export 'src/domain/result.dart' show MercadoPagoResult, Success, Failure;
export 'src/domain/errors.dart'
    show
        MercadoPagoError,
        ErrorLocation,
        NetworkError,
        ValidationError,
        InvalidCardNumberError,
        InvalidCvvError,
        InvalidExpirationDateError,
        CardExpiredError,
        BinIsEmptyError,
        UnknownError;

// Domain models exposed to consumers.
export 'src/domain/models/card_token.dart' show CardToken;
export 'src/domain/models/payment_method.dart'
    show
        PaymentMethod,
        PaymentMethodFinancialInstitution,
        PaymentMethodIssuer,
        PaymentMethodCard,
        PaymentMethodCardLength,
        PaymentMethodSecurityCode,
        PaymentMethodPayerCost;
export 'src/domain/models/payment_agreement.dart'
    show PaymentAgreement, AgreementMerchantAccount, AgreementTimeFrame;
export 'src/domain/models/installment.dart'
    show Installment, PayerCost, InstallmentIssuer;
export 'src/domain/models/issuer.dart' show Issuer;
export 'src/domain/models/identification_type.dart' show IdentificationType;
export 'src/domain/models/buyer_identification.dart' show BuyerIdentification;

// PCI input widgets.
// The PCI library is a single Dart library so raw card values cannot be read
// from outside it. Only these four types are part of the public API.
export 'src/pci/pci.dart'
    show CardNumberField, SecurityCodeField, ExpirationDateField, PciFieldState;
