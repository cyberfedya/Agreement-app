final _styleBlockPattern = RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false);
String sanitizeAgreementHtml(String html) => html.replaceAll(_styleBlockPattern, '');