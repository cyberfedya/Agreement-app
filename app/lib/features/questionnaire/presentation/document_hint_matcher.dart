/// Broad groupings of "annoying to type/dictate" fields - used only to
/// decide whether to show the optional document-upload nudge and to rate
/// -limit it per topic. Purely a presentation heuristic: it never changes
/// which question is asked, never skips anything, and never talks to the
/// backend - the Interview Planner and OCR mapping remain the only
/// authorities on interview state and field extraction.
enum DocumentHintCategory { vehicle, realEstate, business, employment, bank }

/// Matches a backend-supplied field label against known "hard to type or
/// dictate" patterns (VIN, cadastral number, IBAN, ...). Matching is
/// intentionally loose (substring, case-insensitive, Russian + common
/// Latin abbreviations) - a false negative just means the nudge doesn't
/// show, which is always safe; there is no false-positive risk that
/// matters, since the nudge is never more than an optional suggestion.
abstract final class DocumentHintMatcher {
  static const Map<DocumentHintCategory, List<String>> _keywords = {
    DocumentHintCategory.vehicle: [
      'vin',
      'вин',
      'номер двигателя',
      'номер кузова',
      'номер шасси',
      'номер рамы',
      'регистрационный номер',
      'гос. номер',
      'госномер',
      'гос номер',
      'техпаспорт',
      'технического паспорта',
      'орган выдачи',
      'дата выдачи',
    ],
    DocumentHintCategory.realEstate: [
      'кадастров',
      'номер квартиры',
      'номер дома',
      'номер здания',
      'площадь',
      'свидетельств',
      'право собственности',
    ],
    DocumentHintCategory.business: [
      'инн',
      'tax id',
      'налогов',
      'регистрационный номер',
      'огрн',
      'номер лицензии',
      'лицензи',
    ],
    DocumentHintCategory.employment: [
      'регистрация компании',
      'регистрационный номер компании',
      'код организации',
      'окпо',
    ],
    DocumentHintCategory.bank: ['номер счета', 'номер счёта', 'р/с', 'мфо', 'iban', 'swift'],
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
