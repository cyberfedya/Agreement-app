/// Translated fallback text for the handful of exceptions the data layer
/// throws before any [BuildContext]/`AppLocalizations` exists to localize
/// them properly (a dropped connection, a timeout, an unparseable
/// response). Keyed by [LocaleProvider.languageCode] rather than routed
/// through the widget-tree localization system, since [ApiClient] has no
/// access to that system and never should - it's pure data-layer code.
///
/// Deliberately NOT used for [ServerException]/[NotFoundException] messages
/// that already carry real backend-supplied text - that content is the
/// backend's own and is passed through as-is.
abstract final class ApiErrorMessages {
  static const _network = {
    'ru': 'Нет соединения с сервером. Проверьте интернет.',
    'uz': 'Сервер билан алоқа йўқ. Интернетни текширинг.',
    'en': 'No connection to the server. Check your internet.',
  };

  static const _timeout = {
    'ru': 'Сервер долго не отвечает. Попробуйте ещё раз.',
    'uz': 'Сервер узоқ вақт жавоб бермаяпти. Қайта уриниб кўринг.',
    'en': 'The server is taking too long to respond. Please try again.',
  };

  static const _malformedResponse = {
    'ru': 'Сервер вернул неожиданный ответ. Попробуйте обновить.',
    'uz': 'Сервер кутилмаган жавоб қайтарди. Янгилаб кўринг.',
    'en': 'The server returned an unexpected response. Try refreshing.',
  };

  static const _notFound = {'ru': 'Не найдено.', 'uz': 'Топилмади.', 'en': 'Not found.'};

  static const _serverErrorPrefix = {
    'ru': 'Ошибка сервера',
    'uz': 'Сервер хатоси',
    'en': 'Server error',
  };

  static const _missingFields = {
    'ru': 'Сначала ответьте на все обязательные вопросы.',
    'uz': 'Аввал барча мажбурий саволларга жавоб беринг.',
    'en': 'Please answer all required questions first.',
  };

  static const _legalReviewRequired = {
    'ru': 'Договор требует юридической проверки — сформировать его пока нельзя.',
    'uz': 'Шартнома ҳуқуқий текширувни талаб қилади — уни ҳозирча шакллантириб бўлмайди.',
    'en': "This agreement needs legal review — it can't be generated yet.",
  };

  static String network(String languageCode) => _network[languageCode] ?? _network['ru']!;
  static String timeout(String languageCode) => _timeout[languageCode] ?? _timeout['ru']!;
  static String malformedResponse(String languageCode) => _malformedResponse[languageCode] ?? _malformedResponse['ru']!;
  static String notFound(String languageCode) => _notFound[languageCode] ?? _notFound['ru']!;
  static String serverError(String languageCode, int statusCode) =>
      '${_serverErrorPrefix[languageCode] ?? _serverErrorPrefix['ru']!} ($statusCode).';
  static String missingFields(String languageCode) => _missingFields[languageCode] ?? _missingFields['ru']!;
  static String legalReviewRequired(String languageCode) => _legalReviewRequired[languageCode] ?? _legalReviewRequired['ru']!;
}
