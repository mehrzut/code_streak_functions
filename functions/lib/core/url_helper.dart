import 'dart:io';

class UrlHelper {
  static const String githubAuthorizeUrl =
      'https://github.com/login/oauth/authorize';
  static const String githubTokenUrl =
      'https://github.com/login/oauth/access_token';
  static const String githubApiUrl = 'https://api.github.com/graphql';

  static String reminderManagerUrl = Platform.environment['REMINDER_URL'] ?? '';
}
