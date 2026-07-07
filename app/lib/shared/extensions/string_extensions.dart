extension CategorySlug on String {
  /// "real_estate" -> "Real estate"
  String get asCategoryLabel {
    if (isEmpty) return this;
    final words = replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}
