import 'package:app/l10n/app_localizations.dart';

extension CategorySlug on String {
  /// Localized label for a backend category/domain slug
  /// ("real_estate" -> "Недвижимость"). Loose keyword matching so a new
  /// backend slug degrades to a capitalized slug instead of breaking.
  String categoryLabel(AppLocalizations l10n) {
    if (isEmpty) return this;
    final slug = toLowerCase();

    if (slug.contains('vehicle') || slug.contains('auto') || slug.contains('car') || slug.contains('transport')) {
      return l10n.categoryVehicle;
    }
    if (slug.contains('real') ||
        slug.contains('estate') ||
        slug.contains('apartment') ||
        slug.contains('hous') ||
        slug.contains('property')) {
      return l10n.categoryRealEstate;
    }
    if (slug.contains('rent') || slug.contains('lease')) return l10n.categoryRent;
    if (slug.contains('employ') || slug.contains('work') || slug.contains('labor') || slug.contains('job')) {
      return l10n.categoryEmployment;
    }
    if (slug.contains('loan') || slug.contains('debt') || slug.contains('credit')) return l10n.categoryLoan;
    if (slug.contains('service')) return l10n.categoryService;
    if (slug.contains('gift') || slug.contains('donat')) return l10n.categoryGift;
    if (slug.contains('marri') || slug.contains('family')) return l10n.categoryFamily;
    if (slug.contains('construc') || slug.contains('build')) return l10n.categoryConstruction;
    if (slug.contains('power') || slug.contains('attorney')) return l10n.categoryPowerOfAttorney;
    if (slug.contains('business') || slug.contains('company')) return l10n.categoryBusiness;
    if (slug.contains('sale') || slug.contains('purchase')) return l10n.categorySale;

    final words = replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}
