import '../main.dart' show appLocale;
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Translations for code with no BuildContext (models, services, top-level
/// helpers). Widgets should keep using AppLocalizations.of(context); the
/// whole MaterialApp rebuilds on a language change, so this stays current.
AppLocalizations get l10n => AppLocalizations(appLocale.value);
