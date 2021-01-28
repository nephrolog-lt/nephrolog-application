import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nephrogo/ui/authentication/email_password_login_screen.dart';
import 'package:nephrogo_api_client/model/intake.dart';
import 'package:nephrogo_api_client/model/product.dart';

import 'ui/authentication/login_screen.dart';
import 'ui/authentication/registration_screen.dart';
import 'ui/authentication/remind_password.dart';
import 'ui/faq_screen.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/start_screen.dart';
import 'ui/tabs/health_status/health_status_creation_screen.dart';
import 'ui/tabs/health_status/weekly_health_status_screen.dart';
import 'ui/tabs/nutrition/intake_create.dart';
import 'ui/tabs/nutrition/product_search.dart';
import 'ui/tabs/nutrition/weekly_intakes_screen.dart';
import 'ui/tabs/nutrition/weekly_nutrients_screen.dart';
import 'ui/user_profile_screen.dart';

class Routes {
  static const ROUTE_START = 'start';

  static const ROUTE_LOGIN = 'login';
  static const ROUTE_LOGIN_EMAIL_PASSWORD = 'login_email_password';
  static const ROUTE_REGISTRATION = 'registration';
  static const ROUTE_REMIND_PASSWORD = 'remind_password';

  static const ROUTE_HOME = 'home';

  static const ROUTE_ONBOARDING = 'onboarding';

  static const ROUTE_DAILY_WEEKLY_NUTRIENTS_SCREEN = 'weekly_nutrients_screen';
  static const ROUTE_DAILY_WEEKLY_INTAKES_SCREEN =
      'ROUTE_DAILY_WEEKLY_INTAKES_SCREEN';
  static const ROUTE_INTAKE_CREATE = 'ROUTE_INTAKE_CREATE';
  static const ROUTE_PRODUCT_SEARCH = 'ROUTE_PRODUCT_SEARCH';

  static const ROUTE_WEEKLY_HEALTH_STATUS_SCREEN =
      'ROUTE_WEEKLY_HEALTH_STATUS_SCREEN';
  static const ROUTE_HEALTH_STATUS_CREATION = 'ROUTE_HEALTH_STATUS_CREATION';

  static const ROUTE_USER_PROFILE = 'ROUTE_USER_PROFILE';
  static const ROUTE_FAQ = 'frequently_asked_questions';

  static const ROUTE_FORM_SELECT = 'form_select';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case ROUTE_START:
        return MaterialPageRoute(builder: (context) {
          return StartScreen();
        });
      case ROUTE_ONBOARDING:
        return MaterialPageRoute(builder: (context) {
          OnboardingScreenArguments arguments = settings.arguments;

          return OnboardingScreen(exitType: arguments.exitType);
        });
      case ROUTE_LOGIN:
        return MaterialPageRoute(builder: (context) {
          return LoginScreen();
        });
      case ROUTE_REGISTRATION:
        return MaterialPageRoute<UserCredential>(builder: (context) {
          return RegistrationScreen();
        });
      case ROUTE_REMIND_PASSWORD:
        return MaterialPageRoute(builder: (context) {
          return RemindPasswordScreen();
        });
      case ROUTE_LOGIN_EMAIL_PASSWORD:
        return MaterialPageRoute<UserCredential>(builder: (context) {
          return EmailPasswordLoginScreen();
        });
      case ROUTE_HOME:
        return MaterialPageRoute(builder: (context) {
          return HomeScreen();
        });
      case ROUTE_INTAKE_CREATE:
        return MaterialPageRoute<Intake>(builder: (context) {
          IntakeCreateScreenArguments arguments = settings.arguments;

          return IntakeCreateScreen(
            initialProduct: arguments.product ?? arguments.product,
            intake: arguments.intake,
          );
        });
      case ROUTE_PRODUCT_SEARCH:
        return MaterialPageRoute<Product>(builder: (context) {
          ProductSearchType searchType = settings.arguments;

          return ProductSearchScreen(searchType: searchType);
        });
      case ROUTE_HEALTH_STATUS_CREATION:
        return MaterialPageRoute(builder: (context) {
          return HealthStatusCreationScreen();
        });
      case ROUTE_FAQ:
        return MaterialPageRoute(builder: (context) {
          return FrequentlyAskedQuestionsScreen();
        });
      case ROUTE_USER_PROFILE:
        return MaterialPageRoute(builder: (context) {
          UserProfileNextScreenType nextScreenType = settings.arguments;

          return UserProfileScreen(
            nextScreenType: nextScreenType,
          );
        });
      case ROUTE_DAILY_WEEKLY_INTAKES_SCREEN:
        return MaterialPageRoute(builder: (context) {
          return WeeklyIntakesScreen();
        });
      case ROUTE_DAILY_WEEKLY_NUTRIENTS_SCREEN:
        return MaterialPageRoute(builder: (context) {
          WeeklyNutrientsScreenArguments arguments = settings.arguments;

          return WeeklyNutrientsScreen(
            nutrient: arguments.nutrient,
          );
        });
      case ROUTE_WEEKLY_HEALTH_STATUS_SCREEN:
        return MaterialPageRoute(builder: (context) {
          WeeklyHealthStatusScreenArguments arguments = settings.arguments;

          return WeeklyHealthStatusScreen(
            initialHealthIndicator: arguments.initialHealthIndicator,
          );
        });
      default:
        throw Exception('Unable to find route ${settings.name} in routes');
    }
  }
}
