/// Presentation-layer Russian rendering of the backend's fixed English
/// service phrases (field-state reasons, workflow reasons). The backend
/// stays the source of truth for *which* phrase applies - this only
/// translates the known catalog for display, and any unknown/future
/// phrase falls through unchanged rather than breaking or hiding.
///
/// Parameterized phrases ("Second party proposed: X") are matched by
/// prefix so the dynamic tail (the proposed value, the document keys)
/// survives translation.
library;

const Map<String, String> _exactPhrases = {
  // Workflow reasons (GetDealFieldStatesUseCase.WorkflowReason).
  'One or more fields need explicit agreement before generation/signing.':
      'Есть условия, которые сторонам нужно согласовать перед формированием и подписанием.',
  'Mandatory agreement terms are still missing.': 'Ещё не заполнены обязательные условия договора.',
  'Agreement draft is ready and waiting for the second party.': 'Проект договора готов и ожидает вторую сторону.',
  'Agreement draft is waiting for party agreement/signature.':
      'Проект договора ожидает согласования и подписи сторон.',
  'All mandatory terms have trusted values.': 'Все обязательные условия заполнены подтверждёнными данными.',

  // Field reasons (review + field states).
  'Recorded interview answer': 'Записано из вашего ответа в интервью',
  'Profile, QR, or document metadata field': 'Подставляется из профиля, QR или реквизитов автоматически',
  'Resolved from account profile, second-party QR profile, or legal metadata':
      'Подставляется из профиля, QR-профиля второй стороны или реквизитов',
  'Optional term; not asked during the minimal interview':
      'Необязательное условие — в коротком интервью не спрашивалось',
  'No trusted value available': 'Нет подтверждённого значения',
  'Obsolete because a dependency answer made it irrelevant':
      'Неактуально: другой ответ сделал это условие ненужным',
  'Second party proposed a different value': 'Вторая сторона предложила другое значение',
  'Fills in automatically from an uploaded document': 'Заполнится автоматически из загруженного документа',
};

const List<(String prefix, String replacement)> _prefixPhrases = [
  ('Second party proposed: ', 'Вторая сторона предлагает: '),
  ('Mapped from document field ', 'Распознано из документа: '),
  ('Mapped from ', 'Распознано из документа: '),
  ('Conflicting documents disagree on ', 'Загруженные документы расходятся в данных: '),
];

/// Russian text for a known backend service phrase; the original string
/// when the phrase isn't in the catalog (forward-compatible by design).
String localizeBackendPhrase(String phrase) {
  final exact = _exactPhrases[phrase];
  if (exact != null) return exact;

  for (final (prefix, replacement) in _prefixPhrases) {
    if (phrase.startsWith(prefix)) return replacement + phrase.substring(prefix.length);
  }
  return phrase;
}

/// The backend's canonical OCR field keys (DocumentFieldHintCollection) in
/// Russian - shown on the extraction celebration and the documents sheet.
const Map<String, String> _documentFieldKeys = {
  'vin': 'VIN',
  'brand': 'Марка',
  'model': 'Модель',
  'year': 'Год выпуска',
  'engine_number': 'Номер двигателя',
  'engine_capacity': 'Объём двигателя',
  'engine_power': 'Мощность двигателя',
  'body_number': 'Номер кузова',
  'chassis_number': 'Номер шасси',
  'plate_number': 'Госномер',
  'registration_number': 'Регистрационный номер',
  'issue_date': 'Дата выдачи',
  'cadastre_number': 'Кадастровый номер',
  'area': 'Площадь',
  'rooms': 'Комнат',
  'floor': 'Этаж',
  'amount': 'Сумма',
  'normalized_amount': 'Сумма',
  'price': 'Цена',
  'profile_full_name': 'Ф.И.О.',
  'profile_passport_number': 'Паспорт',
  'profile_birth_date': 'Дата рождения',
  'profile_address': 'Адрес',
};

/// Russian label for a document field key; falls back to a humanized form
/// of the raw key ("engine_number" -> "Engine number") for unknown keys,
/// so new extraction fields still render legibly.
String localizeDocumentFieldKey(String key) {
  final known = _documentFieldKeys[key.toLowerCase()];
  if (known != null) return known;

  final spaced = key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp('([a-zа-я])([A-ZА-Я])'), (m) => '${m[1]} ${m[2]}');
  if (spaced.isEmpty) return spaced;
  return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
}
