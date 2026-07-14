/// Broad groupings of "annoying to type/dictate" fields - used only to
/// decide whether to show the optional document-upload nudge and to rate
/// -limit it per topic. Purely a presentation heuristic: it never changes
/// which question is asked, never skips anything, and never talks to the
/// backend - the Interview Planner and OCR mapping remain the only
/// authorities on interview state and field extraction.
enum DocumentHintCategory { vehicle, realEstate, business, employment, bank, inheritance, court, loan, service }

/// Matches a backend-supplied field label against known "hard to type or
/// dictate" patterns (VIN, cadastral number, IBAN, ...). Matching is
/// intentionally loose (substring, case-insensitive, Russian + common
/// Latin abbreviations) - a false negative just means the nudge doesn't
/// show, which is always safe; there is no false-positive risk that
/// matters, since the nudge is never more than an optional suggestion.
///
/// Deliberately excludes plate/registration numbers, brand/model, year and
/// price from every category below - those are things a person genuinely
/// knows from memory and types faster than they'd photograph a document,
/// mirroring the same distinction FieldEligibilityEngine draws on the
/// backend for which fields are DocumentOnly.
abstract final class DocumentHintMatcher {
  static const Map<DocumentHintCategory, List<String>> _keywords = {
    DocumentHintCategory.vehicle: [
      'vin',
      'вин',
      'номер двигателя',
      'двигател', // covers "двигатель рақами" and question phrasings in both languages
      'номер кузова',
      'кузов',
      'госномер',
      'гос номер',
      'гос. номер',
      'государственный номер',
      'давлат рақам',
      'номер шасси',
      'номер рамы',
      'техпаспорт',
      'технического паспорта',
      'технический паспорт',
      'орган выдачи',
      'дата выдачи',
      'особые отметки',
      'особая отметка',
    ],
    DocumentHintCategory.realEstate: [
      'кадастров',
      'номер квартиры',
      'номер дома',
      'номер здания',
      'площадь',
      'собственност',
    ],
    DocumentHintCategory.business: [
      'инн',
      'tax id',
      'налогов',
      'огрн',
      'номер лицензии',
      'лицензи',
      'свидетельство о регистрации',
      'регистрационное свидетельство',
    ],
    DocumentHintCategory.employment: [
      'регистрация компании',
      'регистрационный номер компании',
      'код организации',
      'окпо',
    ],
    DocumentHintCategory.bank: ['номер счета', 'номер счёта', 'р/с', 'мфо', 'iban', 'swift'],
    DocumentHintCategory.inheritance: [
      'свидетельство о смерти', 'свидетельства о смерти',
      'свидетельство о рождении', 'свидетельства о рождении',
      'нотариальное свидетельство',
      'наследств',
    ],
    DocumentHintCategory.court: [
      'решение суда',
      'судебное решение',
      'номер дела',
      'номер судебного дела',
    ],
    DocumentHintCategory.loan: ['займ', 'кредитный договор', 'договор кредита'],
    DocumentHintCategory.service: [
      'техническое задание',
      'смет',
      'счет-фактура',
      'счет на оплату',
      'накладная',
    ],
  };

  /// Null when [fieldName] doesn't look like a document-friendly field.
  static DocumentHintCategory? categoryFor(String fieldName) {
    final normalized = fieldName.toLowerCase();
    for (final entry in _keywords.entries) {
      if (entry.value.any(normalized.contains)) return entry.key;
    }
    return null;
  }
}
