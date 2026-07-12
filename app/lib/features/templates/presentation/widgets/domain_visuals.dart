import 'package:flutter/material.dart';

/// Icon for a template's backend `domain` slug. Loose substring matching
/// (slug wording belongs to the backend catalog and may evolve) with a
/// neutral document icon as the safe fallback - purely visual sugar, no
/// behavior depends on the match.
IconData iconForDomain(String domain) {
  final d = domain.toLowerCase();
  if (d.contains('vehicle') || d.contains('car') || d.contains('auto') || d.contains('transport')) {
    return Icons.directions_car_outlined;
  }
  if (d.contains('rent') || d.contains('lease')) return Icons.key_outlined;
  if (d.contains('real') || d.contains('estate') || d.contains('apartment') || d.contains('property') || d.contains('hous')) {
    return Icons.home_work_outlined;
  }
  if (d.contains('employ') || d.contains('work') || d.contains('labor') || d.contains('job')) {
    return Icons.badge_outlined;
  }
  if (d.contains('loan') || d.contains('debt') || d.contains('credit') || d.contains('money') || d.contains('finan')) {
    return Icons.payments_outlined;
  }
  if (d.contains('service') || d.contains('contract')) return Icons.handshake_outlined;
  if (d.contains('gift') || d.contains('donat')) return Icons.redeem_outlined;
  if (d.contains('marri') || d.contains('family')) return Icons.favorite_outline;
  if (d.contains('power') || d.contains('attorney') || d.contains('legal')) return Icons.gavel_outlined;
  if (d.contains('construc') || d.contains('build')) return Icons.construction_outlined;
  if (d.contains('sale') || d.contains('purchase') || d.contains('sell')) return Icons.sell_outlined;
  return Icons.description_outlined;
}

/// Shared Hero tag so the template's icon flies from the list card into
/// the detail page instead of both fading independently.
String templateHeroTag(String templateKey) => 'template-icon-$templateKey';
