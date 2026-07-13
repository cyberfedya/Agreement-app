extension CategorySlug on String {
  /// Human-readable Russian label for a backend category/domain slug
  /// ("real_estate" -> "Недвижимость"). Loose keyword matching so a new
  /// backend slug degrades to a capitalized slug instead of breaking.
  String get asCategoryLabel {
    if (isEmpty) return this;
    final slug = toLowerCase();

    if (slug.contains('vehicle') || slug.contains('auto') || slug.contains('car') || slug.contains('transport')) {
      return 'Транспорт';
    }
    if (slug.contains('real') ||
        slug.contains('estate') ||
        slug.contains('apartment') ||
        slug.contains('hous') ||
        slug.contains('property')) {
      return 'Недвижимость';
    }
    if (slug.contains('rent') || slug.contains('lease')) return 'Аренда';
    if (slug.contains('employ') || slug.contains('work') || slug.contains('labor') || slug.contains('job')) {
      return 'Работа';
    }
    if (slug.contains('loan') || slug.contains('debt') || slug.contains('credit')) return 'Займы';
    if (slug.contains('service')) return 'Услуги';
    if (slug.contains('gift') || slug.contains('donat')) return 'Дарение';
    if (slug.contains('marri') || slug.contains('family')) return 'Семья';
    if (slug.contains('construc') || slug.contains('build')) return 'Строительство';
    if (slug.contains('power') || slug.contains('attorney')) return 'Доверенности';
    if (slug.contains('business') || slug.contains('company')) return 'Бизнес';
    if (slug.contains('sale') || slug.contains('purchase')) return 'Купля-продажа';

    final words = replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}
