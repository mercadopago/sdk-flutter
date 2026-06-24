/// Official MercadoPago SDK for Flutter.
///
/// Three integration paths are supported:
///
/// * [MercadoPagoSDK.shared] for global initialization and access to the
///   low-level [CoreMethods] API.
/// * [MercadoPagoCheckout] for a hosted, opinionated UI (CardSave and
///   CardTransaction flows).
/// * Standalone PCI widgets ([CardNumberField], [SecurityCodeField],
///   [ExpirationDateField]) for building a fully custom UI on top of
///   [CoreMethods].
library mercadopago_flutter_sdk;

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

// CoreMethods.
// Card data inputs (NewCardData, SavedCardData) are intentionally not
// exported — the public API takes PciFieldState controllers so the SDK
// is the only code that ever reads raw card values.
export 'src/core_methods/core_methods.dart' show CoreMethods;
export 'src/domain/repositories.dart' show ProcessingMode;

// Result + error types.
export 'src/domain/result.dart'
    show MercadoPagoResult, Success, Failure, Cancelled;
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
        InitializationFailedError,
        UnknownError,
        CardFieldError,
        CardNumberFieldError,
        SecurityCodeFieldError,
        ExpirationDateFieldError;

// Domain models exposed to consumers.
export 'src/domain/models/card_token.dart' show CardToken;
export 'src/domain/models/payment_method.dart' show PaymentMethod;
export 'src/domain/models/installment.dart'
    show Installment, PayerCost, InstallmentIssuer;
export 'src/domain/models/issuer.dart' show Issuer;
export 'src/domain/models/identification_type.dart' show IdentificationType;
export 'src/domain/models/card_save_result.dart' show CardSaveResult;
export 'src/domain/models/card_transaction_result.dart'
    show CardTransactionResult;
export 'src/domain/models/mp_cancel_context.dart'
    show MPCancelContext, CheckoutStep;

// PCI input widgets.
export 'src/components/card_number_field.dart' show CardNumberField;
export 'src/components/security_code_field.dart' show SecurityCodeField;
export 'src/components/expiration_date_field.dart' show ExpirationDateField;
export 'src/components/pci_field_state.dart' show PciFieldState;

// Hosted checkout UI.
export 'src/checkout/mercadopago_checkout.dart'
    show
        MercadoPagoCheckout,
        CardSaveCheckoutBuilder,
        CardTransactionCheckoutBuilder;
export 'src/checkout/checkout_appearance.dart' show MPCheckoutAppearance;
