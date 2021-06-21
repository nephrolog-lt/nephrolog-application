import 'package:flutter/material.dart';
import 'package:nephrogo/api/api_service.dart';
import 'package:nephrogo/authentication/authentication_provider.dart';
import 'package:nephrogo/extensions/extensions.dart';
import 'package:nephrogo/l10n/localizations.dart';
import 'package:nephrogo/preferences/app_preferences.dart';
import 'package:nephrogo/routes.dart';
import 'package:nephrogo/ui/general/app_future_builder.dart';
import 'package:nephrogo/ui/general/components.dart';
import 'package:nephrogo_api_client/nephrogo_api_client.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({Key? key}) : super(key: key);

  @override
  _CountryScreenState createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  final _apiService = ApiService();
  final _appPreferences = AppPreferences();
  final _authenticationProvider = AuthenticationProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.appLocalizations.chooseCountry)),
      body: AppFutureBuilder<CountryResponse>(
        future: _apiService.getCountries,
        builder: (context, response) {
          final suggestedCountry = response.suggestedCountry;
          final selectedCountry = response.selectedCountry;

          return ListView(
            children: [
              if (suggestedCountry != null)
                SmallSection(
                  title: context.appLocalizations.recommendedCountry,
                  children: [
                    _CountryTile(
                      country: suggestedCountry,
                      selectedCountry: selectedCountry,
                      onCountrySelected: _onCountrySelected,
                    ),
                  ],
                ),
              SmallSection(
                title: context.appLocalizations.countries,
                showDividers: true,
                children: [
                  for (final country in response.countries)
                    _CountryTile(
                      country: country,
                      selectedCountry: selectedCountry,
                      onCountrySelected: _onCountrySelected,
                    ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _onCountrySelected(Country country) async {
    if (_authenticationProvider.isUserLoggedIn) {
      await _apiService.selectCountry(country.code);
    }
    await _appPreferences.setCountry(country.code);

    if (_authenticationProvider.isUserLoggedIn) {
      Navigator.pop(context);
    } else {
      await Navigator.pushReplacementNamed(
        context,
        Routes.routeStart,
      );
    }
  }
}

class _CountryTile extends StatelessWidget {
  final Country country;
  final void Function(Country selectedCountry) onCountrySelected;
  final Country? selectedCountry;

  const _CountryTile({
    Key? key,
    required this.country,
    required this.onCountrySelected,
    this.selectedCountry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: Text(
        _localizedCountryName(context.appLocalizations) ?? country.name,
      ),
      subtitle: _countrySubtitle(context.appLocalizations),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      leading: SizedBox(
        width: 40,
        height: 40,
        child: FittedBox(
          fit: BoxFit.cover,
          child: Text(country.flagEmoji),
        ),
      ),
      selected: selectedCountry == country,
      onTap: () => onCountrySelected(country),
    );
  }

  String? _localizedCountryName(AppLocalizations appLocalizations) {
    switch (country.code) {
      case 'LT':
        return appLocalizations.lithuania;
      case 'DE':
        return appLocalizations.germany;
      default:
        return null;
    }
  }

  Text? _countrySubtitle(AppLocalizations appLocalizations) {
    final localizedName =
        _localizedCountryName(appLocalizations) ?? country.name;

    if (localizedName != country.name) {
      return Text(country.name);
    } else {
      return null;
    }
  }
}
