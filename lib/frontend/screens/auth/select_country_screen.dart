import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:komet/core/config/countries.dart';
import 'package:komet/l10n/app_localizations.dart';
import '../../widgets/glass/ios_auth_chrome.dart';
import '../../widgets/glass/ios_glass.dart';
import '../../widgets/glass/ios_palette.dart';
import '../../widgets/glass/ios_settings_scaffold.dart';
import '../../widgets/glass/ios_symbols.dart';
import '../../widgets/glass/ios_tappable.dart';
import '../../widgets/glass/ios_typography.dart';
import '../../widgets/settings_card.dart';
import '../contacts/contact_sheet_common.dart';

class SelectCountryScreen extends StatefulWidget {
  final CountryName selectedCountry;
  final List<CountryName> countries;

  SelectCountryScreen({
    super.key,
    required this.selectedCountry,
    List<CountryName>? countries,
  }) : countries = countries ?? allCountries;

  @override
  State<SelectCountryScreen> createState() => _SelectCountryScreenState();
}

class _CountrySearchEntry {
  final CountryName country;
  final String ruLower;
  final String enLower;

  const _CountrySearchEntry(this.country, this.ruLower, this.enLower);
}

class _SelectCountryScreenState extends State<SelectCountryScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<CountryName> _sortedCountries = const [];
  List<CountryName> _filteredCountries = const [];
  List<_CountrySearchEntry> _searchEntries = const [];
  String _lang = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == _lang) return;
    _lang = lang;
    _sortedCountries = sortedByDisplayName(widget.countries, lang);
    _searchEntries = _sortedCountries
        .map(
          (c) => _CountrySearchEntry(c, c.ru.toLowerCase(), c.en.toLowerCase()),
        )
        .toList();
    _filteredCountries = _applyFilter(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountryName> _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _sortedCountries;
    final matches = _searchEntries
        .where(
          (e) =>
              e.ruLower.contains(q) ||
              e.enLower.contains(q) ||
              e.country.phoneCode.contains(q),
        )
        .map((e) => e.country)
        .toList();
    if (_looksLikePhoneCode(q)) {
      matches.sort((a, b) {
        final byPrimary =
            (isPrimaryForPhoneCode(b) ? 1 : 0) -
            (isPrimaryForPhoneCode(a) ? 1 : 0);
        if (byPrimary != 0) return byPrimary;
        return a
            .displayName(_lang)
            .toLowerCase()
            .compareTo(b.displayName(_lang).toLowerCase());
      });
    }
    return matches;
  }

  static bool _looksLikePhoneCode(String query) =>
      RegExp(r'^\+?\d+$').hasMatch(query);

  void _filterCountries(String query) {
    setState(() => _filteredCountries = _applyFilter(query));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    if (IosGlass.of(context)) return _buildIos(context, cs, l10n, lang);

    return Scaffold(
      backgroundColor: iosAuthBackground(context),
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(IosSymbols.chevronBack(context), color: cs.onSurface),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: l10n.selectCountrySearchHint,
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: _filterCountries,
              )
            : Text(
                l10n.selectCountryTitle,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredCountries = _sortedCountries;
                }
              });
            },
            icon: Icon(
              _isSearching ? IosSymbols.close(context) : IosSymbols.search(context),
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredCountries.length,
        itemBuilder: (context, index) {
          final country = _filteredCountries[index];
          final isSelected = country.code == widget.selectedCountry.code;

          return ListTile(
            leading: Text(
              country.phoneCode,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            title: Text(
              country.displayName(lang),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: isSelected
                ? Icon(IosSymbols.check(context), color: cs.primary)
                : null,
            onTap: () {
              Navigator.pop(context, country);
            },
          );
        },
      ),
    );
  }

  Widget _buildIos(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    String lang,
  ) {
    final countries = _filteredCountries;
    return IosSettingsScaffold(
      title: l10n.selectCountryTitle,
      useConnectionTitle: false,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: countries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: l10n.selectCountrySearchHint,
                onChanged: _filterCountries,
              ),
            );
          }
          final country = countries[index - 1];
          return _IosCountryRow(
            key: ValueKey(country.code),
            name: country.displayName(lang),
            flag: contactFlagEmoji(country.code),
            phoneCode: country.phoneCode,
            selected: country.code == widget.selectedCountry.code,
            isFirst: index == 1,
            isLast: index == countries.length,
            onTap: () => Navigator.pop(context, country),
          );
        },
      ),
    );
  }
}

class _IosCountryRow extends StatelessWidget {
  final String name;
  final String flag;
  final String phoneCode;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _IosCountryRow({
    super.key,
    required this.name,
    required this.flag,
    required this.phoneCode,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const radius = Radius.circular(IosGroupedSection.defaultRadius);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? radius : Radius.zero,
        bottom: isLast ? radius : Radius.zero,
      ),
      child: ColoredBox(
        color: IosGroupedSection.background(cs),
        child: IosTappable(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: IosPalette.label(cs),
                          fontSize: IosTypography.listTitle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phoneCode,
                      style: TextStyle(
                        color: IosPalette.secondaryLabel(cs),
                        fontSize: IosTypography.listTitle,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        IosSymbols.check(context),
                        color: cs.primary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: IosPalette.separator(cs),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
