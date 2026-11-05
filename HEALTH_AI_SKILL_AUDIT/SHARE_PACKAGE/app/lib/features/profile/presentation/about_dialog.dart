import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/data/nutrition/dish_catalog.dart';
import 'package:app/design_system/components/brand_mark.dart';
import 'package:app/l10n/app_localizations.dart';

/// About + open-source licences. No network: the licence page is local.
void showAppAbout(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final dishCount = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(dishCountProvider);
  showAboutDialog(
    context: context,
    applicationName: l10n.appTitle,
    applicationVersion: '1.0.0 (1)',
    applicationIcon: const BrandMark(size: 44),
    applicationLegalese: l10n.aboutLegalese,
    children: [
      const SizedBox(height: 12),
      Text(l10n.aboutPrivacy),
      const SizedBox(height: 10),
      Text(l10n.aboutModel(dishCount)),
    ],
  );
}
