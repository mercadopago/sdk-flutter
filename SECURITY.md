# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | ✅ Current |

## Reporting a vulnerability

If you discover a security vulnerability in this SDK, **do not** open a
public GitHub issue. Instead, report it privately so it can be addressed
before disclosure.

**Contact**: sdk-security@mercadopago.com

Please include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested mitigation

We aim to acknowledge reports within 48 hours and provide a resolution
timeline within 7 business days.

## Security model

This SDK is designed with PCI DSS compliance in mind:

- **Raw card data (number, CVV, expiry) never leaves the SDK.** Input
  widgets hold values in memory; your application code cannot read them.
- **Tokens are short-lived** (~15 minutes). The SDK never persists or
  reuses them.
- **All network traffic uses TLS 1.2+.** No plaintext communication.
- **Device fingerprinting** collects device signals for fraud detection.
  It does not collect personal data, contacts, or location.

See the [README security section](README.md#security) for full details.
