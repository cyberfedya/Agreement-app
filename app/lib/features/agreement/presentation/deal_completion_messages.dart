import 'package:app/l10n/app_localizations.dart';

/// Universal, non-hardcoded completion messaging: keyed by
/// (template domain, this party's role code) - both already resolved and
/// carried on [Agreement] once generation happens. Falls back to a single
/// generic message for any domain/role this table doesn't explicitly cover,
/// so new templates never need a code change here.
String dealCompletionMessage(String? domain, String? role, AppLocalizations l10n) {
  switch (domain) {
    case 'vehicle':
      switch (role) {
        case 'seller':
          return l10n.completionVehicleSeller;
        case 'buyer':
          return l10n.completionVehicleBuyer;
      }
    case 'real_estate':
      switch (role) {
        case 'seller':
          return l10n.completionRealEstateSeller;
        case 'buyer':
          return l10n.completionRealEstateBuyer;
        case 'landlord':
          return l10n.completionRealEstateLandlord;
        case 'tenant':
          return l10n.completionRealEstateTenant;
      }
    case 'loan':
      return l10n.completionLoan;
    case 'services':
      return l10n.completionServices;
  }
  return l10n.completionGeneric;
}
