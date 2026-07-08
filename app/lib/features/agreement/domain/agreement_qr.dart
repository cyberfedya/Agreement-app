/// QR payload scheme for sharing a generated agreement with the second
/// party. Demo-only: there is no backend persistence yet, so the payload is
/// only resolvable within the same app session/device that generated it.
const _scheme = 'easyagree://agreement/';

String buildAgreementQrPayload(String key) => '$_scheme$key';

String? extractAgreementKey(String payload) =>
    payload.startsWith(_scheme) ? payload.substring(_scheme.length) : null;
